import CloudKit
import Combine
import CryptoKit
import Foundation

private struct CloudCareerEnvelope: Codable, Sendable {
    let schemaVersion: Int
    let sessionID: String
    let sourceUpdatedAt: Date
    let deviceID: String
    let networkVersions: SimulationDataVersions
    let gtfsVersion: NetworkVersion
    let geometryVersion: NetworkGeometryVersion
    let contractVersion: NetworkContractVersion
    let lineReferenceVersion: NetworkLineReferenceVersion
    let sources: [NetworkDataSource]
    let assignments: [DepotLineAssignment]
}

private struct CloudCareerArchiveManifest: Codable, Sendable {
    struct Entry: Codable, Hashable, Sendable {
        let path: String
        let byteCount: UInt64
        let sha256: String
    }

    let schemaVersion: Int
    let entries: [Entry]
}

private enum CloudCareerArchiveError: LocalizedError {
    case missingPinnedVersion(String)
    case missingAssignment(String)
    case invalidArchive
    case unsafePath
    case checksumMismatch(String)
    case oversizedArchive

    var errorDescription: String? {
        switch self {
        case let .missingPinnedVersion(id): "La version réseau épinglée par cette carrière manque sur cet appareil : \(id)."
        case let .missingAssignment(id): "Le rattachement de ligne \(id) utilisé par cette carrière manque sur cet appareil."
        case .invalidArchive: "La sauvegarde iCloud contient un paquet réseau illisible."
        case .unsafePath: "La sauvegarde iCloud contient un chemin de fichier invalide."
        case let .checksumMismatch(path): "Le fichier réseau \(path) ne correspond pas à son empreinte; il n’a pas été installé."
        case .oversizedArchive: "Le paquet réseau iCloud dépasse les limites de sécurité locales."
        }
    }
}

private enum CloudCareerArchive {
    private static let magic = Data("TMIDFM1\n".utf8)
    private static let chunkSize = 1_048_576
    private static let maximumManifestBytes = 2_000_000
    private static let maximumFileCount = 20_000
    private static let maximumTotalBytes: UInt64 = 8 * 1_024 * 1_024 * 1_024
    private static let allowedRootDirectories: Set<String> = ["versions", "geometries", "contracts", "line-references"]

    static func makeArchive(root: URL, directories: [URL], destination: URL) throws {
        var fileURLs: [URL] = []
        for directory in Set(directories.map(\.standardizedFileURL)) {
            guard directory.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path + "/") else {
                throw CloudCareerArchiveError.unsafePath
            }
            guard FileManager.default.fileExists(atPath: directory.path) else {
                throw CloudCareerArchiveError.invalidArchive
            }
            guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            ) else {
                throw CloudCareerArchiveError.invalidArchive
            }
            for case let fileURL as URL in enumerator {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                if values.isSymbolicLink == true { throw CloudCareerArchiveError.unsafePath }
                if values.isRegularFile == true { fileURLs.append(fileURL.standardizedFileURL) }
            }
        }

        fileURLs = Array(Set(fileURLs)).sorted { $0.path < $1.path }
        guard !fileURLs.isEmpty, fileURLs.count <= maximumFileCount else {
            throw CloudCareerArchiveError.invalidArchive
        }

        var entries: [CloudCareerArchiveManifest.Entry] = []
        var totalBytes: UInt64 = 0
        for fileURL in fileURLs {
            let relativePath = String(fileURL.path.dropFirst(root.standardizedFileURL.path.count + 1))
            guard isSafeRelativePath(relativePath) else { throw CloudCareerArchiveError.unsafePath }
            let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            let byteCount = UInt64(max(0, values.fileSize ?? 0))
            totalBytes += byteCount
            guard totalBytes <= maximumTotalBytes else { throw CloudCareerArchiveError.oversizedArchive }
            entries.append(.init(path: relativePath, byteCount: byteCount, sha256: try checksum(fileURL)))
        }

        let manifest = CloudCareerArchiveManifest(schemaVersion: 1, entries: entries)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let manifestData = try encoder.encode(manifest)
        guard manifestData.count <= maximumManifestBytes else { throw CloudCareerArchiveError.oversizedArchive }

        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let output = try FileHandle(forWritingTo: destination)
        defer { try? output.close() }
        try output.write(contentsOf: magic)
        var manifestSize = UInt64(manifestData.count).littleEndian
        try withUnsafeBytes(of: &manifestSize) { try output.write(contentsOf: Data($0)) }
        try output.write(contentsOf: manifestData)
        for fileURL in fileURLs {
            let input = try FileHandle(forReadingFrom: fileURL)
            defer { try? input.close() }
            while let chunk = try input.read(upToCount: chunkSize), !chunk.isEmpty {
                try output.write(contentsOf: chunk)
            }
        }
        try output.synchronize()
    }

    static func installArchive(from source: URL, into root: URL) throws {
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }
        guard try readExactly(magic.count, from: input) == magic else { throw CloudCareerArchiveError.invalidArchive }
        let lengthData = try readExactly(8, from: input)
        let manifestSize = lengthData.enumerated().reduce(UInt64(0)) { partial, item in
            partial | (UInt64(item.element) << (UInt64(item.offset) * 8))
        }
        guard manifestSize > 0, manifestSize <= maximumManifestBytes else {
            throw CloudCareerArchiveError.invalidArchive
        }
        let manifestData = try readExactly(Int(manifestSize), from: input)
        let manifest = try JSONDecoder().decode(CloudCareerArchiveManifest.self, from: manifestData)
        guard manifest.schemaVersion == 1,
              !manifest.entries.isEmpty,
              manifest.entries.count <= maximumFileCount,
              Set(manifest.entries.map(\.path)).count == manifest.entries.count else {
            throw CloudCareerArchiveError.invalidArchive
        }
        let totalBytes = manifest.entries.reduce(UInt64(0)) { $0 &+ $1.byteCount }
        guard totalBytes <= maximumTotalBytes else { throw CloudCareerArchiveError.oversizedArchive }

        let stagingRoot = FileManager.default.temporaryDirectory
            .appending(path: "TransportManagerIDFM-iCloud-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: stagingRoot) }

        for entry in manifest.entries {
            guard isSafeRelativePath(entry.path) else { throw CloudCareerArchiveError.unsafePath }
            let stagedURL = stagingRoot.appending(path: entry.path)
            try FileManager.default.createDirectory(at: stagedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: stagedURL.path, contents: nil)
            let output = try FileHandle(forWritingTo: stagedURL)
            defer { try? output.close() }
            var remaining = entry.byteCount
            var hasher = SHA256()
            while remaining > 0 {
                let requestedCount = Int(min(UInt64(chunkSize), remaining))
                let chunk = try readExactly(requestedCount, from: input)
                hasher.update(data: chunk)
                try output.write(contentsOf: chunk)
                remaining -= UInt64(chunk.count)
            }
            try output.synchronize()
            let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
            guard digest == entry.sha256 else { throw CloudCareerArchiveError.checksumMismatch(entry.path) }
        }

        for entry in manifest.entries {
            let stagedURL = stagingRoot.appending(path: entry.path)
            let destinationURL = root.appending(path: entry.path).standardizedFileURL
            guard destinationURL.path.hasPrefix(root.standardizedFileURL.path + "/") else {
                throw CloudCareerArchiveError.unsafePath
            }
            try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: stagedURL, to: destinationURL)
        }
    }

    private static func isSafeRelativePath(_ path: String) -> Bool {
        let components = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard let root = components.first,
              allowedRootDirectories.contains(root),
              !path.hasPrefix("/"),
              !path.contains("\\"),
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { return false }
        return true
    }

    private static func checksum(_ url: URL) throws -> String {
        var hasher = SHA256()
        let input = try FileHandle(forReadingFrom: url)
        defer { try? input.close() }
        while let chunk = try input.read(upToCount: chunkSize), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func readExactly(_ count: Int, from handle: FileHandle) throws -> Data {
        var result = Data()
        result.reserveCapacity(count)
        while result.count < count {
            guard let chunk = try handle.read(upToCount: count - result.count), !chunk.isEmpty else {
                throw CloudCareerArchiveError.invalidArchive
            }
            result.append(chunk)
        }
        return result
    }
}

@MainActor
final class CloudCareerSyncManager: ObservableObject {
    @Published private(set) var statusMessage = "iCloud non vérifié"
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var isSyncing = false
    @Published private(set) var hasConflict = false

    private enum SyncResolution {
        case automatic
        case preferDevice
        case preferCloud
    }

    private struct PreparedSave {
        let envelope: CloudCareerEnvelope
        let envelopeData: Data
        let saveURL: URL
        let networkArchiveURL: URL
        let localUpdatedAt: Date
    }

    private struct Checkpoint: Codable {
        let changeTag: String
        let localUpdatedAt: Date
    }

    private static let containerIdentifier = "iCloud.fr.axel.transport-manager-idfm"
    private static let sharedRecordID = CKRecord.ID(recordName: "shared-career-v1")
    private static let syncRecordType = "CareerSync"
    private static let backupRecordType = "CareerBackup"
    private static let schemaVersion = 1
    private static let syncDebounceNanoseconds: UInt64 = 10_000_000_000
    private static let minimumUploadInterval: TimeInterval = 120

    private let container = CKContainer(identifier: containerIdentifier)
    private var scheduledSync: Task<Void, Never>?
    private var lastUploadAttemptAt: Date?
    private var deviceID: String {
        let key = "transportManager.cloud.deviceID"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }

    func scheduleSynchronization(with engine: SimulationEngine, library: NetworkLibrary) {
        scheduledSync?.cancel()
        scheduledSync = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.syncDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            await self?.synchronize(with: engine, library: library)
        }
    }

    func synchronize(with engine: SimulationEngine, library: NetworkLibrary) async {
        await synchronize(with: engine, library: library, resolution: .automatic)
    }

    func resolveConflict(usingCloud: Bool, with engine: SimulationEngine, library: NetworkLibrary) async {
        await synchronize(with: engine, library: library, resolution: usingCloud ? .preferCloud : .preferDevice)
    }

    private func synchronize(
        with engine: SimulationEngine,
        library: NetworkLibrary,
        resolution: SyncResolution
    ) async {
        guard !isSyncing else { return }
        isSyncing = true
        statusMessage = "Synchronisation iCloud…"
        defer { isSyncing = false }

        do {
            let accountStatus = try await container.accountStatus()
            guard accountStatus == .available else {
                statusMessage = Self.accountStatusMessage(accountStatus)
                return
            }

            let remoteRecord = try await fetchSharedRecord()
            guard let localSession = engine.session else {
                if let remoteRecord {
                    try await download(remoteRecord, into: engine, library: library)
                } else {
                    statusMessage = "Aucune carrière iCloud à récupérer"
                }
                return
            }

            guard let remoteRecord else {
                try await upload(localSession: localSession, engine: engine, library: library, replacing: nil)
                return
            }

            let remoteEnvelope = try decodeEnvelope(from: remoteRecord)
            let checkpoint = loadCheckpoint(for: localSession.id)
            if resolution == .preferCloud {
                try await download(remoteRecord, into: engine, library: library)
                return
            }
            if resolution == .preferDevice {
                try await backupAndReplace(localSession: localSession, engine: engine, library: library, remote: remoteRecord)
                return
            }

            guard remoteEnvelope.sessionID == localSession.id else {
                hasConflict = true
                statusMessage = "Une autre carrière est déjà dans iCloud. Choisissez quelle partie conserver sur cet appareil."
                return
            }

            if let checkpoint,
               let remoteTag = remoteRecord.recordChangeTag,
               remoteTag != checkpoint.changeTag {
                if localSession.updatedAt > checkpoint.localUpdatedAt {
                    try await preserveConflict(localSession: localSession, engine: engine, library: library)
                    hasConflict = true
                    statusMessage = "La partie iCloud a changé ailleurs. Votre progression locale est conservée comme copie de secours; choisissez quelle version continuer."
                } else {
                    try await download(remoteRecord, into: engine, library: library)
                }
                return
            }

            if remoteEnvelope.sourceUpdatedAt > localSession.updatedAt {
                try await download(remoteRecord, into: engine, library: library)
            } else if localSession.updatedAt > remoteEnvelope.sourceUpdatedAt {
                try await upload(localSession: localSession, engine: engine, library: library, replacing: remoteRecord)
            } else {
                storeCheckpoint(remoteRecord, sessionID: localSession.id, localUpdatedAt: localSession.updatedAt)
                hasConflict = false
                statusMessage = "Carrière synchronisée avec iCloud"
                lastSyncedAt = Date()
            }
        } catch {
            statusMessage = Self.userMessage(for: error)
        }
    }

    private func upload(
        localSession: SimulationSession,
        engine: SimulationEngine,
        library: NetworkLibrary,
        replacing record: CKRecord?
    ) async throws {
        if let lastUploadAttemptAt,
           Date().timeIntervalSince(lastUploadAttemptAt) < Self.minimumUploadInterval,
           record != nil {
            statusMessage = "Sauvegarde iCloud prévue dans moins de deux minutes"
            return
        }

        let prepared = try await prepare(localSession: localSession, engine: engine)
        defer {
            try? FileManager.default.removeItem(at: prepared.saveURL)
            try? FileManager.default.removeItem(at: prepared.networkArchiveURL)
        }

        let targetRecord = record ?? CKRecord(recordType: Self.syncRecordType, recordID: Self.sharedRecordID)
        do {
            try populate(targetRecord, prepared: prepared)
            let savedRecord = try await container.privateCloudDatabase.save(targetRecord)
            lastUploadAttemptAt = Date()
            storeCheckpoint(savedRecord, sessionID: prepared.envelope.sessionID, localUpdatedAt: prepared.localUpdatedAt)
            hasConflict = false
            statusMessage = "Carrière et réseau sauvegardés dans iCloud"
            lastSyncedAt = Date()
        } catch let error as CKError where error.code == .serverRecordChanged {
            try await createBackupRecord(prepared)
            hasConflict = true
            statusMessage = "Une modification concurrente est détectée. Votre partie locale est conservée dans iCloud comme copie de secours."
        }
    }

    private func backupAndReplace(
        localSession: SimulationSession,
        engine: SimulationEngine,
        library: NetworkLibrary,
        remote: CKRecord
    ) async throws {
        try await preserveConflict(localSession: localSession, engine: engine, library: library)
        let latestRemote = try await fetchSharedRecord() ?? remote
        try await upload(localSession: localSession, engine: engine, library: library, replacing: latestRemote)
    }

    private func preserveConflict(
        localSession: SimulationSession,
        engine: SimulationEngine,
        library: NetworkLibrary
    ) async throws {
        let prepared = try await prepare(localSession: localSession, engine: engine)
        defer {
            try? FileManager.default.removeItem(at: prepared.saveURL)
            try? FileManager.default.removeItem(at: prepared.networkArchiveURL)
        }
        try await createBackupRecord(prepared)
    }

    private func createBackupRecord(_ prepared: PreparedSave) async throws {
        let safeSessionID = prepared.envelope.sessionID.replacingOccurrences(of: "[^A-Za-z0-9-]", with: "-", options: .regularExpression)
        let recordID = CKRecord.ID(recordName: "backup-\(safeSessionID.prefix(24))-\(deviceID.prefix(8))-\(UUID().uuidString)")
        let backup = CKRecord(recordType: Self.backupRecordType, recordID: recordID)
        try populate(backup, prepared: prepared)
        _ = try await container.privateCloudDatabase.save(backup)
    }

    private func download(_ record: CKRecord, into engine: SimulationEngine, library: NetworkLibrary) async throws {
        let envelope = try decodeEnvelope(from: record)
        guard let saveAsset = record["saveAsset"] as? CKAsset,
              let saveURL = saveAsset.fileURL,
              let networkAsset = record["networkAsset"] as? CKAsset,
              let networkURL = networkAsset.fileURL else {
            throw CloudCareerArchiveError.invalidArchive
        }

        let saveData = try Data(contentsOf: saveURL)
        _ = try JSONDecoder.iso8601.decode(SimulationSession.self, from: saveData)
        let root = try NetworkVersionStore.rootDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try await Task.detached(priority: .utility) {
            try CloudCareerArchive.installArchive(from: networkURL, into: root)
        }.value

        var catalog = try NetworkVersionStore.loadCatalog()
        catalog.versions = Self.upserting(envelope.gtfsVersion, into: catalog.versions)
        catalog.geometryVersions = Self.upserting(envelope.geometryVersion, into: catalog.geometryVersions)
        catalog.contractVersions = Self.upserting(envelope.contractVersion, into: catalog.contractVersions)
        catalog.lineReferenceVersions = Self.upserting(envelope.lineReferenceVersion, into: catalog.lineReferenceVersions)
        catalog.sources = Self.merging(envelope.sources, with: catalog.sources)
        catalog.activeVersionID = envelope.networkVersions.gtfsID
        catalog.activeGeometryVersionID = envelope.networkVersions.routeGeometryID
        catalog.activeContractVersionID = envelope.networkVersions.contractID
        catalog.activeLineReferenceVersionID = envelope.networkVersions.lineReferenceID
        try NetworkVersionStore.saveCatalog(catalog)

        let currentAssignments = try DepotAssignmentStore.load()
        let mergedAssignments = Self.mergingAssignments(envelope.assignments, with: currentAssignments)
        try DepotAssignmentStore.save(mergedAssignments)
        try engine.importSaveData(saveData)
        await library.reloadSnapshotsFromDisk()

        let checkpointRecord = try await fetchSharedRecord() ?? record
        storeCheckpoint(checkpointRecord, sessionID: envelope.sessionID, localUpdatedAt: engine.session?.updatedAt ?? envelope.sourceUpdatedAt)
        hasConflict = false
        statusMessage = "Carrière et réseau récupérés depuis iCloud"
        lastSyncedAt = Date()
    }

    private func prepare(localSession: SimulationSession, engine: SimulationEngine) async throws -> PreparedSave {
        let saveData = try engine.exportSaveData()
        let updatedSession = engine.session ?? localSession
        let catalog = try NetworkVersionStore.loadCatalog()
        guard let gtfs = catalog.versions.first(where: { $0.id == updatedSession.networkVersions.gtfsID }),
              let geometry = catalog.geometryVersions.first(where: { $0.id == updatedSession.networkVersions.routeGeometryID }),
              let contract = catalog.contractVersions.first(where: { $0.id == updatedSession.networkVersions.contractID }),
              let lineReference = catalog.lineReferenceVersions.first(where: { $0.id == updatedSession.networkVersions.lineReferenceID }) else {
            throw CloudCareerArchiveError.missingPinnedVersion(updatedSession.networkVersions.gtfsID)
        }

        let assignmentsByID = Dictionary(uniqueKeysWithValues: try DepotAssignmentStore.load().map { ($0.id, $0) })
        let assignments = try (updatedSession.assignmentRecordIDs ?? []).map { id -> DepotLineAssignment in
            guard let assignment = assignmentsByID[id] else { throw CloudCareerArchiveError.missingAssignment(id) }
            return assignment
        }
        let root = try NetworkVersionStore.rootDirectory()
        let directories = [gtfs.archiveRelativePath, geometry.archiveRelativePath, contract.archiveRelativePath, lineReference.archiveRelativePath]
            .map { root.appending(path: $0).deletingLastPathComponent().standardizedFileURL }
        let temporaryID = UUID().uuidString
        let saveURL = FileManager.default.temporaryDirectory.appending(path: "career-\(temporaryID).json")
        let networkArchiveURL = FileManager.default.temporaryDirectory.appending(path: "career-network-\(temporaryID).bin")
        try saveData.write(to: saveURL, options: .atomic)
        do {
            try await Task.detached(priority: .utility) {
                try CloudCareerArchive.makeArchive(root: root, directories: directories, destination: networkArchiveURL)
            }.value
        } catch {
            try? FileManager.default.removeItem(at: saveURL)
            try? FileManager.default.removeItem(at: networkArchiveURL)
            throw error
        }

        let envelope = CloudCareerEnvelope(
            schemaVersion: Self.schemaVersion,
            sessionID: updatedSession.id,
            sourceUpdatedAt: updatedSession.updatedAt,
            deviceID: deviceID,
            networkVersions: updatedSession.networkVersions,
            gtfsVersion: gtfs,
            geometryVersion: geometry,
            contractVersion: contract,
            lineReferenceVersion: lineReference,
            sources: catalog.sources,
            assignments: assignments
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let envelopeData = try encoder.encode(envelope)
        return PreparedSave(
            envelope: envelope,
            envelopeData: envelopeData,
            saveURL: saveURL,
            networkArchiveURL: networkArchiveURL,
            localUpdatedAt: updatedSession.updatedAt
        )
    }

    private func populate(_ record: CKRecord, prepared: PreparedSave) throws {
        record["schemaVersion"] = Self.schemaVersion as CKRecordValue
        record["sessionID"] = prepared.envelope.sessionID as CKRecordValue
        record["sourceUpdatedAt"] = prepared.localUpdatedAt as CKRecordValue
        record["deviceID"] = deviceID as CKRecordValue
        record["envelope"] = prepared.envelopeData as CKRecordValue
        record["saveAsset"] = CKAsset(fileURL: prepared.saveURL)
        record["networkAsset"] = CKAsset(fileURL: prepared.networkArchiveURL)
    }

    private func fetchSharedRecord() async throws -> CKRecord? {
        do {
            return try await container.privateCloudDatabase.record(for: Self.sharedRecordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func decodeEnvelope(from record: CKRecord) throws -> CloudCareerEnvelope {
        guard let data = record["envelope"] as? Data else { throw CloudCareerArchiveError.invalidArchive }
        let envelope = try JSONDecoder.iso8601.decode(CloudCareerEnvelope.self, from: data)
        guard envelope.schemaVersion == Self.schemaVersion,
              envelope.sessionID == (record["sessionID"] as? String),
              envelope.networkVersions.gtfsID == envelope.gtfsVersion.id,
              envelope.networkVersions.routeGeometryID == envelope.geometryVersion.id,
              envelope.networkVersions.contractID == envelope.contractVersion.id,
              envelope.networkVersions.lineReferenceID == envelope.lineReferenceVersion.id else {
            throw CloudCareerArchiveError.invalidArchive
        }
        return envelope
    }

    private func loadCheckpoint(for sessionID: String) -> Checkpoint? {
        guard let data = UserDefaults.standard.data(forKey: checkpointKey(sessionID)) else { return nil }
        return try? JSONDecoder.iso8601.decode(Checkpoint.self, from: data)
    }

    private func storeCheckpoint(_ record: CKRecord, sessionID: String, localUpdatedAt: Date) {
        guard let changeTag = record.recordChangeTag,
              let data = try? JSONEncoder.iso8601.encode(Checkpoint(changeTag: changeTag, localUpdatedAt: localUpdatedAt)) else { return }
        UserDefaults.standard.set(data, forKey: checkpointKey(sessionID))
    }

    private func checkpointKey(_ sessionID: String) -> String {
        "transportManager.cloud.checkpoint.\(sessionID)"
    }

    private static func upserting<Value: Identifiable>(_ value: Value, into values: [Value]) -> [Value] where Value.ID == String {
        values.filter { $0.id != value.id } + [value]
    }

    private static func merging(_ incoming: [NetworkDataSource], with local: [NetworkDataSource]) -> [NetworkDataSource] {
        var byID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for source in incoming { byID[source.id] = source }
        return byID.values.sorted { $0.id < $1.id }
    }

    private static func mergingAssignments(_ incoming: [DepotLineAssignment], with local: [DepotLineAssignment]) -> [DepotLineAssignment] {
        var byID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for assignment in incoming {
            if (byID[assignment.id]?.recordedAt ?? .distantPast) <= assignment.recordedAt {
                byID[assignment.id] = assignment
            }
        }
        return byID.values.sorted { $0.id < $1.id }
    }

    private static func accountStatusMessage(_ status: CKAccountStatus) -> String {
        switch status {
        case .available: "Compte iCloud disponible"
        case .noAccount: "Connectez-vous à iCloud pour synchroniser cette carrière"
        case .restricted: "iCloud est restreint sur cet appareil; la sauvegarde locale continue"
        case .couldNotDetermine, .temporarilyUnavailable: "État du compte iCloud indisponible; réessayez plus tard"
        @unknown default: "État du compte iCloud non reconnu"
        }
    }

    private static func userMessage(for error: Error) -> String {
        if let cloudError = error as? CKError {
            switch cloudError.code {
            case .notAuthenticated: return "Connectez-vous à iCloud pour synchroniser cette carrière"
            case .quotaExceeded: return "Le stockage iCloud est plein; la carrière locale est conservée"
            case .networkUnavailable, .networkFailure: return "Réseau indisponible; la carrière reste sauvegardée sur cet appareil"
            case .permissionFailure, .missingEntitlement: return "La capacité iCloud de l’app n’est pas provisionnée pour cette équipe Apple"
            default: return "Synchronisation iCloud impossible : \(cloudError.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
}

private extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
