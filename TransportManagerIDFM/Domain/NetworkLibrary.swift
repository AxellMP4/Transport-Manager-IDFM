import Combine
import CryptoKit
import Foundation

enum NetworkImportState: Equatable, Sendable {
    case idle
    case importing
    case imported
    case failed(String)

    var isImporting: Bool {
        if case .importing = self { return true }
        return false
    }

    var errorMessage: String? {
        guard case let .failed(message) = self else { return nil }
        return message
    }
}

private enum NetworkLibraryError: LocalizedError {
    case missingPinnedGTFSVersion(String)
    case missingDepotServiceAudit(String)
    case missingActiveAssignmentVersions
    case unknownAssignmentDepot
    case unknownAssignmentRoute
    case unknownAssignmentContract
    case invalidAssignmentEvidence
    case invalidLineReferenceResponse
    case lineReferenceHTTPStatus(Int)
    case emptyLineReferenceResponse
    case invalidLineDocumentsResponse
    case lineDocumentsHTTPStatus(Int)
    case emptyLineDocumentsResponse
    case invalidRouteGeometryResponse
    case routeGeometryHTTPStatus(Int)
    case emptyRouteGeometryResponse
    case invalidContractGeometryResponse
    case contractGeometryHTTPStatus(Int)
    case emptyContractGeometryResponse

    var errorDescription: String? {
        switch self {
        case let .missingPinnedGTFSVersion(versionID):
            "La version GTFS épinglée par cette partie est introuvable : \(versionID)."
        case let .missingDepotServiceAudit(depotID):
            "L’audit GTFS du dépôt \(depotID) n’a pas été construit."
        case .missingActiveAssignmentVersions:
            "Importez un GTFS et un contour de contrat actifs avant d’enregistrer un rattachement."
        case .unknownAssignmentDepot:
            "Le COB choisi n’appartient pas au scénario actif."
        case .unknownAssignmentRoute:
            "La ligne choisie ne figure pas dans le GTFS actif. Rechargez le catalogue des lignes."
        case .unknownAssignmentContract:
            "Le contrat choisi doit être celui du scénario et figurer dans les contours importés."
        case .invalidAssignmentEvidence:
            "Une source web valide est requise. Une corroboration doit comporter au moins une source supplémentaire."
        case .invalidLineReferenceResponse:
            "Le portail IDFM a renvoyé une réponse inattendue pour le référentiel des lignes."
        case let .lineReferenceHTTPStatus(status):
            "Le téléchargement du référentiel IDFM a échoué (HTTP \(status)). Réessayez ou importez le CSV manuellement."
        case .emptyLineReferenceResponse:
            "Le portail IDFM a renvoyé un fichier vide. Réessayez ou importez le CSV manuellement."
        case .invalidLineDocumentsResponse:
            "Le portail IDFM a renvoyé une réponse inattendue pour les plans et fiches horaires."
        case let .lineDocumentsHTTPStatus(status):
            "Le téléchargement des plans et fiches horaires a échoué (HTTP \(status)). Réessayez ou importez le CSV manuellement."
        case .emptyLineDocumentsResponse:
            "Le portail IDFM a renvoyé un fichier de plans et fiches horaires vide. Réessayez ou importez le CSV manuellement."
        case .invalidRouteGeometryResponse:
            "Le portail IDFM a renvoyé une réponse inattendue pour les tracés de bus."
        case let .routeGeometryHTTPStatus(status):
            "Le téléchargement des tracés IDFM a échoué (HTTP \(status)). Réessayez ou importez le GeoJSON manuellement."
        case .emptyRouteGeometryResponse:
            "Le portail IDFM a renvoyé un GeoJSON vide. Réessayez ou importez le fichier manuellement."
        case .invalidContractGeometryResponse:
            "Le portail IDFM a renvoyé une réponse inattendue pour les contours de contrats."
        case let .contractGeometryHTTPStatus(status):
            "Le téléchargement des contours de contrats a échoué (HTTP \(status)). Réessayez ou importez le GeoJSON manuellement."
        case .emptyContractGeometryResponse:
            "Le portail IDFM a renvoyé un GeoJSON de contrats vide. Réessayez ou importez le fichier manuellement."
        }
    }
}

private enum BundledSnapshotBootstrapError: LocalizedError {
    enum Source: Equatable, Sendable {
        case gtfs
        case geometry
        case lineReference
        case lineDocuments
        case contracts
    }

    case missingResource(Source, String)
    case importFailed(Source, String)

    var source: Source {
        switch self {
        case let .missingResource(source, _), let .importFailed(source, _): source
        }
    }

    var errorDescription: String? {
        switch self {
        case let .missingResource(_, filename):
            "La ressource IDFM intégrée au projet est introuvable : \(filename)."
        case let .importFailed(source, reason):
            "L’import initial de \(source.label) a échoué : \(reason)"
        }
    }
}

private extension BundledSnapshotBootstrapError.Source {
    var label: String {
        switch self {
        case .gtfs: "du réseau GTFS"
        case .geometry: "des tracés commerciaux"
        case .lineReference: "du référentiel des lignes"
        case .lineDocuments: "des plans et horaires"
        case .contracts: "des contours de contrats"
        }
    }
}

private enum BundledGTFSArchiveAssemblyError: LocalizedError {
    case integrityMismatch(expectedBytes: UInt64, actualBytes: UInt64, expectedSHA256: String, actualSHA256: String)

    var errorDescription: String? {
        switch self {
        case let .integrityMismatch(expectedBytes, actualBytes, expectedSHA256, actualSHA256):
            "L’archive GTFS intégrée est incomplète ou altérée (\(actualBytes) octets, SHA-256 \(actualSHA256), attendus : \(expectedBytes) octets et \(expectedSHA256))."
        }
    }
}

private enum BundledGTFSArchiveAssembler {
    private static let expectedByteCount: UInt64 = 150_163_693
    private static let expectedSHA256 = GTFSImportProvenance.bundledArchiveSHA256
    static func assemble() throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appending(path: "idfm-gtfs-2026-10-24-bundled.zip")
        try? FileManager.default.removeItem(at: destination)
        guard FileManager.default.createFile(atPath: destination.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let output = try FileHandle(forWritingTo: destination)
        var assembledByteCount: UInt64 = 0
        var hasher = SHA256()
        do {
            let resources = Bundle.main.urls(forResourcesWithExtension: "bin", subdirectory: nil) ?? []
            let partURLs = try PublicGTFSFeed.orderedFragments(
                resources,
                named: "idfm-gtfs-2026-10-24-part"
            )
            for partURL in partURLs {
                let input = try FileHandle(forReadingFrom: partURL)
                defer { try? input.close() }
                while true {
                    guard let chunk = try input.read(upToCount: 1_048_576), !chunk.isEmpty else { break }
                    hasher.update(data: chunk)
                    assembledByteCount += UInt64(chunk.count)
                    try output.write(contentsOf: chunk)
                }
            }
            let actualSHA256 = hasher.finalize().map { String(format: "%02x", $0) }.joined()
            guard assembledByteCount == expectedByteCount, actualSHA256 == expectedSHA256 else {
                throw BundledGTFSArchiveAssemblyError.integrityMismatch(
                    expectedBytes: expectedByteCount,
                    actualBytes: assembledByteCount,
                    expectedSHA256: expectedSHA256,
                    actualSHA256: actualSHA256
                )
            }
            try output.synchronize()
            try output.close()
        } catch {
            try? output.close()
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
        return destination
    }
}

@MainActor
final class NetworkLibrary: ObservableObject {
    @Published private(set) var catalog: NetworkCatalog
    @Published private(set) var importState: NetworkImportState = .idle
    @Published private(set) var busRoutes: [GTFSRouteSummary] = []
    @Published private(set) var busRoutesVersionID: String?
    @Published private(set) var isLoadingBusRoutes = false
    @Published private(set) var busRoutesError: String?
    @Published private(set) var busStops: [GTFSStopSummary] = []
    @Published private(set) var isLoadingBusStops = false
    @Published private(set) var busStopsError: String?
    @Published private(set) var serviceCalendarsByID: [String: Set<Int>] = [:]
    @Published private(set) var isLoadingServiceCalendars = false
    @Published private(set) var serviceCalendarsError: String?
    @Published private(set) var isRefreshingTripIssueSequences = false
    @Published private(set) var tripIssueSequenceRefreshError: String?
    @Published private(set) var routeGeometries: [NetworkRouteGeometry] = []
    @Published private(set) var routeGeometryVersionID: String?
    @Published private(set) var geometryImportState: NetworkImportState = .idle
    @Published private(set) var isLoadingRouteGeometries = false
    @Published private(set) var routeGeometriesError: String?
    @Published private(set) var contractFeatures: [NetworkContractFeature] = []
    @Published private(set) var contractImportState: NetworkImportState = .idle
    @Published private(set) var isLoadingContracts = false
    @Published private(set) var contractsError: String?
    @Published private(set) var lineReferences: [NetworkLineReference] = []
    @Published private(set) var lineReferenceVersionID: String?
    @Published private(set) var lineReferenceImportState: NetworkImportState = .idle
    @Published private(set) var isLoadingLineReferences = false
    @Published private(set) var lineReferencesError: String?
    private(set) var lineReferenceIndex: [String: NetworkLineReference] = [:]
    @Published private(set) var lineDocuments: [NetworkLineDocument] = []
    @Published private(set) var lineDocumentVersionID: String?
    @Published private(set) var lineDocumentImportState: NetworkImportState = .idle
    @Published private(set) var isLoadingLineDocuments = false
    @Published private(set) var lineDocumentsError: String?
    @Published private(set) var depotAssignments: [DepotLineAssignment] = []
    @Published private(set) var depotAssignmentStoreError: String?
    private var bundledSnapshotSeedTask: Task<NetworkCatalog, Error>?
    private var didSeedBundledSnapshots = false
    private var officialGeometryCoverageCacheKey: String?
    private var officialGeometryCoverageRouteIDs: Set<String> = []

    init() {
        catalog = (try? NetworkVersionStore.loadCatalog()) ?? .initial
        do {
            depotAssignments = try DepotAssignmentStore.load()
        } catch {
            depotAssignmentStoreError = "Le registre des rattachements n’a pas pu être lu : \(error.localizedDescription)"
        }
    }

    func seedBundledIDFMSnapshotsIfNeeded() async {
        guard !didSeedBundledSnapshots else { return }

        let task: Task<NetworkCatalog, Error>
        if let bundledSnapshotSeedTask {
            task = bundledSnapshotSeedTask
        } else {
            lineReferenceImportState = .importing
            lineDocumentImportState = .importing
            contractImportState = .importing
            if catalog.activeVersion == nil {
                importState = .importing
            }
            if catalog.activeGeometryVersion == nil {
                geometryImportState = .importing
            }
            lineReferencesError = nil
            lineDocumentsError = nil
            contractsError = nil
            task = Task.detached(priority: .utility) {
                var catalog = try NetworkVersionStore.loadCatalog()

                if catalog.activeVersion == nil {
                    let source = BundledSnapshotBootstrapError.Source.gtfs
                    do {
                        let url = try BundledGTFSArchiveAssembler.assemble()
                        catalog = try NetworkVersionStore.importGTFS(from: url, provenance: .publicMirror)
                    } catch {
                        throw BundledSnapshotBootstrapError.importFailed(source, error.localizedDescription)
                    }
                }

                if catalog.activeLineReferenceVersion == nil {
                    let source = BundledSnapshotBootstrapError.Source.lineReference
                    guard let url = Bundle.main.url(forResource: "idfm-lines-2026-10-20", withExtension: "csv") else {
                        throw BundledSnapshotBootstrapError.missingResource(source, "idfm-lines-2026-10-20.csv")
                    }
                    do {
                        catalog = try LineReferenceStore.importCSV(
                            data: Data(contentsOf: url),
                            originalFilename: url.lastPathComponent
                        ).catalog
                    } catch {
                        throw BundledSnapshotBootstrapError.importFailed(source, error.localizedDescription)
                    }
                }

                if catalog.activeLineDocumentVersion == nil {
                    let source = BundledSnapshotBootstrapError.Source.lineDocuments
                    guard let url = Bundle.main.url(forResource: "idfm-line-documents-2026-10-20", withExtension: "csv") else {
                        throw BundledSnapshotBootstrapError.missingResource(source, "idfm-line-documents-2026-10-20.csv")
                    }
                    do {
                        catalog = try LineDocumentStore.importCSV(
                            data: Data(contentsOf: url),
                            originalFilename: url.lastPathComponent
                        ).catalog
                    } catch {
                        throw BundledSnapshotBootstrapError.importFailed(source, error.localizedDescription)
                    }
                }

                if catalog.activeContractVersion == nil {
                    let source = BundledSnapshotBootstrapError.Source.contracts
                    guard let url = Bundle.main.url(forResource: "idfm-contract-contours-2026-10-20", withExtension: "geojson") else {
                        throw BundledSnapshotBootstrapError.missingResource(source, "idfm-contract-contours-2026-10-20.geojson")
                    }
                    do {
                        catalog = try ContractGeometryStore.importGeoJSON(
                            data: Data(contentsOf: url),
                            originalFilename: url.lastPathComponent
                        ).catalog
                    } catch {
                        throw BundledSnapshotBootstrapError.importFailed(source, error.localizedDescription)
                    }
                }

                if catalog.activeGeometryVersion == nil {
                    let source = BundledSnapshotBootstrapError.Source.geometry
                    guard let url = Bundle.main.url(forResource: "idfm-route-geometries-2026-10-20", withExtension: "zip") else {
                        throw BundledSnapshotBootstrapError.missingResource(source, "idfm-route-geometries-2026-10-20.zip")
                    }
                    do {
                        let archive = try ZIPArchiveReader(url: url)
                        guard let entry = archive.entry(named: "idfm-bus-lines-2026-10-20.geojson") else {
                            throw ZIPArchiveError.malformed
                        }
                        catalog = try RouteGeometryStore.importGeoJSON(
                            data: archive.data(for: entry),
                            originalFilename: entry.filename
                        ).catalog
                    } catch {
                        throw BundledSnapshotBootstrapError.importFailed(source, error.localizedDescription)
                    }
                }

                return try NetworkVersionStore.loadCatalog()
            }
            bundledSnapshotSeedTask = task
        }

        do {
            catalog = try await task.value
            didSeedBundledSnapshots = true
            lineReferenceImportState = .imported
            lineDocumentImportState = .imported
            contractImportState = .imported
            geometryImportState = .imported
            if catalog.activeVersion != nil {
                importState = .imported
            }
            bundledSnapshotSeedTask = nil
        } catch {
            bundledSnapshotSeedTask = nil
            if let latestCatalog = try? await Task.detached(priority: .utility, operation: {
                try NetworkVersionStore.loadCatalog()
            }).value {
                catalog = latestCatalog
            }
            let message = error.localizedDescription
            if let failure = error as? BundledSnapshotBootstrapError {
                switch failure.source {
                case .gtfs:
                    importState = .failed(message)
                case .geometry:
                    geometryImportState = .failed(message)
                case .lineReference:
                    lineReferencesError = message
                    lineReferenceImportState = .failed(message)
                case .lineDocuments:
                    lineDocumentsError = message
                    lineDocumentImportState = .failed(message)
                case .contracts:
                    contractsError = message
                    contractImportState = .failed(message)
                }
            }
            if !(error is BundledSnapshotBootstrapError && (error as? BundledSnapshotBootstrapError)?.source == .lineReference) {
                lineReferenceImportState = catalog.activeLineReferenceVersion == nil ? .idle : .imported
            }
            if !(error is BundledSnapshotBootstrapError && (error as? BundledSnapshotBootstrapError)?.source == .lineDocuments) {
                lineDocumentImportState = catalog.activeLineDocumentVersion == nil ? .idle : .imported
            }
            if !(error is BundledSnapshotBootstrapError && (error as? BundledSnapshotBootstrapError)?.source == .contracts) {
                contractImportState = catalog.activeContractVersion == nil ? .idle : .imported
            }
            if !(error is BundledSnapshotBootstrapError && (error as? BundledSnapshotBootstrapError)?.source == .gtfs) {
                importState = catalog.activeVersion == nil ? .idle : .imported
            }
            if !(error is BundledSnapshotBootstrapError && (error as? BundledSnapshotBootstrapError)?.source == .geometry) {
                geometryImportState = catalog.activeGeometryVersion == nil ? .idle : .imported
            }
        }
    }

    func importGTFS(from sourceURL: URL, provenance: GTFSImportProvenance = .unverifiedManual) {
        guard !importState.isImporting else { return }
        importState = .importing
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()

        Task {
            await importGTFSArchive(
                from: sourceURL,
                provenance: provenance,
                shouldStopAccessing: shouldStopAccessing
            )
        }
    }

    func downloadLatestPublicGTFS() {
        guard !importState.isImporting else { return }
        importState = .importing

        Task {
            var downloadedTemporaryURL: URL?
            var stagedArchiveURL: URL?
            defer {
                if let downloadedTemporaryURL {
                    try? FileManager.default.removeItem(at: downloadedTemporaryURL)
                }
                if let stagedArchiveURL {
                    try? FileManager.default.removeItem(at: stagedArchiveURL)
                }
            }

            do {
                let downloadSession = PublicGTFSFeed.makeDownloadSession()
                let publicArchiveURL: URL
                let sourceProvenance: GTFSImportProvenance
                do {
                    let (recordData, recordResponse) = try await downloadSession.data(
                        from: PublicGTFSFeed.latestFileRecordURL
                    )
                    guard let recordHTTPResponse = recordResponse as? HTTPURLResponse else {
                        throw PublicGTFSFeedError.nonHTTPResponse
                    }
                    guard (200..<300).contains(recordHTTPResponse.statusCode) else {
                        throw PublicGTFSFeedError.httpStatus(recordHTTPResponse.statusCode)
                    }

                    let currentFileURL = try PublicGTFSFeed.resolveLatestDownloadURL(from: recordData)
                    let (downloadedURL, response) = try await downloadSession.download(from: currentFileURL)
                    downloadedTemporaryURL = downloadedURL
                    try PublicGTFSFeed.validateDownloadedArchive(at: downloadedURL, response: response)
                    publicArchiveURL = downloadedURL
                    sourceProvenance = .publicDataHub
                } catch {
                    let dataHubError = error
                    if let previousDownload = downloadedTemporaryURL {
                        try? FileManager.default.removeItem(at: previousDownload)
                        downloadedTemporaryURL = nil
                    }

                    do {
                        let (downloadedURL, response) = try await downloadSession.download(
                            from: PublicGTFSFeed.downloadURL
                        )
                        downloadedTemporaryURL = downloadedURL
                        try PublicGTFSFeed.validateDownloadedArchive(at: downloadedURL, response: response)
                        publicArchiveURL = downloadedURL
                        sourceProvenance = .publicMirror
                    } catch {
                        importState = .failed(
                            "IDFM Datahub : \(dataHubError.localizedDescription)\n" +
                            "Miroir PAN : \(error.localizedDescription)"
                        )
                        return
                    }
                }

                let stagedURL = FileManager.default.temporaryDirectory
                    .appending(path: "idfm-public-gtfs-\(UUID().uuidString).zip")
                try FileManager.default.moveItem(at: publicArchiveURL, to: stagedURL)
                downloadedTemporaryURL = nil
                stagedArchiveURL = stagedURL

                await importGTFSArchive(from: stagedURL, provenance: sourceProvenance)
            } catch {
                importState = .failed(error.localizedDescription)
            }
        }
    }

    private func prepareForGTFSImport() {
        busRoutes = []
        busRoutesVersionID = nil
        busRoutesError = nil
        busStops = []
        busStopsError = nil
        serviceCalendarsByID = [:]
        serviceCalendarsError = nil
    }

    private func importGTFSArchive(
        from sourceURL: URL,
        provenance: GTFSImportProvenance,
        shouldStopAccessing: Bool = false
    ) async {
        defer {
            if shouldStopAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let updatedCatalog = try await Task.detached(priority: .userInitiated) {
                try NetworkVersionStore.importGTFS(from: sourceURL, provenance: provenance)
            }.value
            catalog = updatedCatalog
            prepareForGTFSImport()
            await loadBusRoutes()
            await loadBusStops()
            await loadServiceCalendars()
            importState = .imported
        } catch {
            importState = .failed(error.localizedDescription)
        }
    }

    func refreshTripIssueSequences(for versionID: String) async {
        guard !isRefreshingTripIssueSequences,
              !importState.isImporting,
              catalog.activeVersion?.id == versionID else { return }
        isRefreshingTripIssueSequences = true
        tripIssueSequenceRefreshError = nil
        defer { isRefreshingTripIssueSequences = false }

        do {
            let refreshedCatalog = try await Task.detached(priority: .utility) {
                try NetworkVersionStore.refreshTripIssueSequences(for: versionID)
            }.value
            guard catalog.activeVersion?.id == versionID else { return }
            catalog = refreshedCatalog
        } catch {
            tripIssueSequenceRefreshError = error.localizedDescription
        }
    }

    func loadBusRoutes() async {
        guard !isLoadingBusRoutes, let version = catalog.activeVersion,
              busRoutesVersionID != version.id else { return }
        isLoadingBusRoutes = true
        busRoutesError = nil
        if busRoutesVersionID != version.id {
            busRoutes = []
            busRoutesVersionID = nil
        }
        defer { isLoadingBusRoutes = false }

        do {
            let routes = try await Task.detached(priority: .userInitiated) {
                try NetworkVersionStore.loadBusRoutes(for: version)
            }.value
            guard catalog.activeVersion?.id == version.id else { return }
            busRoutes = routes
            busRoutesVersionID = version.id
        } catch {
            busRoutesError = error.localizedDescription
        }
    }

    func loadBusStops() async {
        guard !isLoadingBusStops, let version = catalog.activeVersion else { return }
        isLoadingBusStops = true
        busStopsError = nil
        defer { isLoadingBusStops = false }

        do {
            busStops = try await Task.detached(priority: .userInitiated) {
                try NetworkVersionStore.loadBusStops(for: version)
            }.value
        } catch {
            busStopsError = error.localizedDescription
        }
    }

    func loadServiceCalendars() async {
        guard !isLoadingServiceCalendars, let version = catalog.activeVersion else { return }
        isLoadingServiceCalendars = true
        serviceCalendarsError = nil
        defer { isLoadingServiceCalendars = false }

        do {
            let calendars = try await Task.detached(priority: .userInitiated) {
                try NetworkVersionStore.loadServiceCalendars(for: version)
            }.value
            serviceCalendarsByID = calendars.reduce(into: [:]) { result, calendar in
                result[calendar.serviceID] = Set(calendar.activeDates)
            }
        } catch {
            serviceCalendarsError = error.localizedDescription
        }
    }

    func loadScheduledDepartures(
        gtfsVersionID: String,
        routeIDs: Set<String>,
        from start: Date,
        through end: Date
    ) async throws -> [ScheduledServiceDeparture] {
        guard let version = catalog.versions.first(where: { $0.id == gtfsVersionID }) else {
            throw NetworkLibraryError.missingPinnedGTFSVersion(gtfsVersionID)
        }
        return try await Task.detached(priority: .userInitiated) {
            try NetworkVersionStore.loadServiceDepartures(for: version, routeIDs: routeIDs, from: start, through: end)
        }.value
    }

    func loadScheduledTripStopVisits(
        gtfsVersionID: String,
        tripID: String,
        serviceDateKey: Int
    ) async throws -> [ScheduledTripStopVisit] {
        guard let version = catalog.versions.first(where: { $0.id == gtfsVersionID }) else {
            throw NetworkLibraryError.missingPinnedGTFSVersion(gtfsVersionID)
        }
        return try await Task.detached(priority: .userInitiated) {
            try NetworkVersionStore.loadScheduledTripStopVisits(
                for: version,
                tripID: tripID,
                serviceDateKey: serviceDateKey
            )
        }.value
    }

    func loadRouteTimetable(
        gtfsVersionID: String,
        routeID: String,
        serviceDateKey: Int
    ) async throws -> GTFSRouteTimetable {
        guard let version = catalog.versions.first(where: { $0.id == gtfsVersionID }) else {
            throw NetworkLibraryError.missingPinnedGTFSVersion(gtfsVersionID)
        }
        return try await Task.detached(priority: .userInitiated) {
            try NetworkVersionStore.loadRouteTimetable(
                for: version,
                routeID: routeID,
                serviceDateKey: serviceDateKey
            )
        }.value
    }

    func loadScheduledTripShapes(
        gtfsVersionID: String,
        tripIDs: Set<String>
    ) async throws -> [String: GTFSRouteShape] {
        guard let version = catalog.versions.first(where: { $0.id == gtfsVersionID }) else {
            throw NetworkLibraryError.missingPinnedGTFSVersion(gtfsVersionID)
        }
        return try await Task.detached(priority: .userInitiated) {
            try NetworkVersionStore.loadTripShapes(for: version, tripIDs: tripIDs)
        }.value
    }

    func loadTripGeometryReview(
        gtfsVersionID: String,
        tripID: String
    ) async throws -> GTFSGeometryReview? {
        guard let version = catalog.versions.first(where: { $0.id == gtfsVersionID }) else {
            throw NetworkLibraryError.missingPinnedGTFSVersion(gtfsVersionID)
        }
        return try await Task.detached(priority: .userInitiated) {
            try NetworkVersionStore.loadTripGeometryReview(for: version, tripID: tripID)
        }.value
    }

    func loadTripMotifs(gtfsVersionID: String) async throws -> [GTFSServiceTripMotif] {
        guard let version = catalog.versions.first(where: { $0.id == gtfsVersionID }) else {
            throw NetworkLibraryError.missingPinnedGTFSVersion(gtfsVersionID)
        }
        return try await Task.detached(priority: .userInitiated) {
            try NetworkVersionStore.loadTripMotifs(for: version)
        }.value
    }

    func loadRouteShapes(
        gtfsVersionID: String,
        routeIDs: Set<String>,
        serviceDateKey: Int
    ) async throws -> [String: [GTFSRouteShape]] {
        guard let version = catalog.versions.first(where: { $0.id == gtfsVersionID }) else {
            throw NetworkLibraryError.missingPinnedGTFSVersion(gtfsVersionID)
        }
        return try await Task.detached(priority: .userInitiated) {
            try NetworkVersionStore.loadRouteShapes(
                for: version,
                routeIDs: routeIDs,
                serviceDateKey: serviceDateKey
            )
        }.value
    }

    func operationalDepotAssignments(
        scenarioID: String,
        depotID: String,
        gtfsVersionID: String,
        contractVersionID: String
    ) -> [DepotLineAssignment] {
        depotAssignments.filter {
            $0.scenarioID == scenarioID
                && $0.depotID == depotID
                && $0.gtfsVersionID == gtfsVersionID
                && $0.contractVersionID == contractVersionID
                && $0.isOperationallyUsable
        }
    }

    func saveDepotAssignment(
        scenario: ScenarioDefinition,
        depotID: String,
        routeID: String,
        contractID: String,
        evidenceStatus: DepotAssignmentEvidenceStatus,
        evidenceTitle: String,
        evidenceURL: String,
        additionalEvidenceURLs: [String],
        evidenceDate: Date?,
        evidenceDateIsVerified: Bool,
        notes: String
    ) throws {
        guard let gtfsVersion = catalog.activeVersion,
              let contractVersion = catalog.activeContractVersion else {
            throw NetworkLibraryError.missingActiveAssignmentVersions
        }
        guard scenario.referenceDepots.contains(where: { $0.id == depotID }) else {
            throw NetworkLibraryError.unknownAssignmentDepot
        }
        guard busRoutes.contains(where: { $0.routeID == routeID }) else {
            throw NetworkLibraryError.unknownAssignmentRoute
        }
        guard contractID == scenario.idfmBusContractID,
              contractFeatures.contains(where: { $0.contractID == contractID }) else {
            throw NetworkLibraryError.unknownAssignmentContract
        }

        let assignment = DepotLineAssignment(
            id: UUID().uuidString,
            scenarioID: scenario.id,
            depotID: depotID,
            routeID: routeID,
            contractID: contractID,
            gtfsVersionID: gtfsVersion.id,
            contractVersionID: contractVersion.id,
            evidenceStatus: evidenceStatus,
            evidenceTitle: evidenceTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            evidenceURL: evidenceURL.trimmingCharacters(in: .whitespacesAndNewlines),
            additionalEvidenceURLs: additionalEvidenceURLs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
            evidenceDate: evidenceDate,
            evidenceDateIsVerified: evidenceDateIsVerified,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            recordedAt: Date()
        )
        guard assignment.hasValidEvidence,
              !evidenceStatus.isOperationallyUsable || (evidenceDate != nil && evidenceDateIsVerified) else {
            throw NetworkLibraryError.invalidAssignmentEvidence
        }

        var updated = depotAssignments.filter { $0.scopeKey != assignment.scopeKey }
        updated.append(assignment)
        try DepotAssignmentStore.save(updated)
        depotAssignments = updated
        depotAssignmentStoreError = nil
    }

    func removeDepotAssignment(id: String) throws {
        let updated = depotAssignments.filter { $0.id != id }
        try DepotAssignmentStore.save(updated)
        depotAssignments = updated
        depotAssignmentStoreError = nil
    }

    func isDirectionScheduled(_ direction: GTFSStopRouteDirection, at moment: Date) -> Bool? {
        guard !direction.serviceHours.isEmpty else { return nil }
        let timeZone = GTFSServiceDate.parisTimeZone
        let calendar = GTFSServiceDate.calendar(timeZone: timeZone)
        guard let version = catalog.activeVersion,
              let validFrom = version.validFrom,
              let validThrough = version.validThrough,
              let firstServiceDate = GTFSServiceDate.key(for: validFrom, timeZone: TimeZone(secondsFromGMT: 0) ?? .current),
              let lastServiceDate = GTFSServiceDate.key(for: validThrough, timeZone: TimeZone(secondsFromGMT: 0) ?? .current),
              let selectedDateKey = GTFSServiceDate.key(for: calendar.startOfDay(for: moment), timeZone: timeZone),
              (firstServiceDate...lastServiceDate).contains(selectedDateKey) else { return nil }

        let selectedHour = calendar.component(.hour, from: moment)
        let matchingHours = direction.serviceHours.filter { $0.hourOffset % 24 == selectedHour }
        guard !matchingHours.isEmpty else { return direction.hasIncompleteSchedule ? nil : false }

        let selectedDay = calendar.startOfDay(for: moment)
        var hasUnknownService = false
        for serviceHour in matchingHours {
            guard let activeDates = serviceCalendarsByID[serviceHour.serviceID] else {
                hasUnknownService = true
                continue
            }
            guard let serviceDate = calendar.date(
                byAdding: .day,
                value: -(serviceHour.hourOffset / 24),
                to: selectedDay
            ),
            let serviceDateKey = GTFSServiceDate.key(for: serviceDate, timeZone: timeZone) else { continue }
            guard (firstServiceDate...lastServiceDate).contains(serviceDateKey) else {
                hasUnknownService = true
                continue
            }
            if activeDates.contains(serviceDateKey) { return true }
        }
        return direction.hasIncompleteSchedule || hasUnknownService ? nil : false
    }

    func importRouteGeometries(from sourceURL: URL) {
        guard !geometryImportState.isImporting else { return }
        geometryImportState = .importing
        routeGeometriesError = nil
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()

        Task {
            defer {
                if shouldStopAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try RouteGeometryStore.importGeoJSON(from: sourceURL)
                }.value
                catalog = result.catalog
                routeGeometries = result.geometries
                routeGeometryVersionID = result.catalog.activeGeometryVersion?.id
                geometryImportState = .imported
            } catch {
                routeGeometriesError = error.localizedDescription
                geometryImportState = .failed(error.localizedDescription)
            }
        }
    }

    func downloadLatestRouteGeometries() {
        guard !geometryImportState.isImporting else { return }
        geometryImportState = .importing
        routeGeometriesError = nil

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: RouteGeometryStore.latestGeoJSONExportURL)
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkLibraryError.invalidRouteGeometryResponse
                }
                guard (200..<300).contains(response.statusCode) else {
                    throw NetworkLibraryError.routeGeometryHTTPStatus(response.statusCode)
                }
                guard !data.isEmpty else { throw NetworkLibraryError.emptyRouteGeometryResponse }

                let result = try await Task.detached(priority: .userInitiated) {
                    try RouteGeometryStore.importGeoJSON(data: data, originalFilename: "idfm-bus-line-traces.geojson")
                }.value
                catalog = result.catalog
                routeGeometries = result.geometries
                routeGeometryVersionID = result.catalog.activeGeometryVersion?.id
                geometryImportState = .imported
            } catch {
                routeGeometriesError = error.localizedDescription
                geometryImportState = .failed(error.localizedDescription)
            }
        }
    }

    func loadActiveRouteGeometries() async {
        guard !isLoadingRouteGeometries else { return }

        while true {
            guard let version = catalog.activeGeometryVersion else {
                routeGeometries = []
                routeGeometryVersionID = nil
                return
            }
            guard routeGeometryVersionID != version.id else { return }

            isLoadingRouteGeometries = true
            routeGeometriesError = nil
            routeGeometries = []
            routeGeometryVersionID = nil

            do {
                let geometries = try await Task.detached(priority: .userInitiated) {
                    try RouteGeometryStore.loadGeometries(for: version)
                }.value
                isLoadingRouteGeometries = false
                guard catalog.activeGeometryVersion?.id == version.id else { continue }
                routeGeometries = geometries
                routeGeometryVersionID = version.id
                geometryImportState = .imported
                return
            } catch {
                isLoadingRouteGeometries = false
                guard catalog.activeGeometryVersion?.id == version.id else { continue }
                routeGeometriesError = error.localizedDescription
                geometryImportState = .failed(error.localizedDescription)
                return
            }
        }
    }

    func clearRouteGeometryError() {
        if case .failed = geometryImportState { geometryImportState = .idle }
        routeGeometriesError = nil
    }

    func reportRouteGeometryError(_ message: String) {
        routeGeometriesError = message
        geometryImportState = .failed(message)
    }

    func importContracts(from sourceURL: URL) {
        guard !contractImportState.isImporting else { return }
        contractImportState = .importing
        contractsError = nil
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()

        Task {
            defer {
                if shouldStopAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try ContractGeometryStore.importGeoJSON(from: sourceURL)
                }.value
                catalog = result.catalog
                contractFeatures = result.features
                contractImportState = .imported
            } catch {
                contractsError = error.localizedDescription
                contractImportState = .failed(error.localizedDescription)
            }
        }
    }

    func downloadLatestContracts() {
        guard !contractImportState.isImporting else { return }
        contractImportState = .importing
        contractsError = nil

        Task {
            do {
                let sourceDataProcessedAt: Date?
                do {
                    let (metadataData, metadataResponse) = try await URLSession.shared.data(from: ContractGeometryStore.sourceMetadataURL)
                    if let metadataResponse = metadataResponse as? HTTPURLResponse,
                       (200..<300).contains(metadataResponse.statusCode) {
                        sourceDataProcessedAt = ContractGeometryStore.sourceDataProcessedAt(from: metadataData)
                    } else {
                        sourceDataProcessedAt = nil
                    }
                } catch {
                    sourceDataProcessedAt = nil
                }

                let (data, response) = try await URLSession.shared.data(from: ContractGeometryStore.latestGeoJSONExportURL)
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkLibraryError.invalidContractGeometryResponse
                }
                guard (200..<300).contains(response.statusCode) else {
                    throw NetworkLibraryError.contractGeometryHTTPStatus(response.statusCode)
                }
                guard !data.isEmpty else { throw NetworkLibraryError.emptyContractGeometryResponse }

                let result = try await Task.detached(priority: .userInitiated) {
                    try ContractGeometryStore.importGeoJSON(
                        data: data,
                        originalFilename: "contours-des-contrats.geojson",
                        sourceDataProcessedAt: sourceDataProcessedAt
                    )
                }.value
                catalog = result.catalog
                contractFeatures = result.features
                contractImportState = .imported
            } catch {
                contractsError = error.localizedDescription
                contractImportState = .failed(error.localizedDescription)
            }
        }
    }

    func loadActiveContracts() async {
        guard !isLoadingContracts, let version = catalog.activeContractVersion else { return }
        isLoadingContracts = true
        contractsError = nil
        defer { isLoadingContracts = false }

        do {
            contractFeatures = try await Task.detached(priority: .userInitiated) {
                try ContractGeometryStore.loadFeatures(for: version)
            }.value
            contractImportState = .imported
        } catch {
            contractsError = error.localizedDescription
            contractImportState = .failed(error.localizedDescription)
        }
    }

    func clearContractError() {
        if case .failed = contractImportState { contractImportState = .idle }
        contractsError = nil
    }

    func reportContractError(_ message: String) {
        contractsError = message
        contractImportState = .failed(message)
    }

    func importLineReferences(from sourceURL: URL) {
        guard !lineReferenceImportState.isImporting else { return }
        lineReferenceImportState = .importing
        lineReferencesError = nil
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()

        Task {
            defer {
                if shouldStopAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try LineReferenceStore.importCSV(from: sourceURL)
                }.value
                catalog = result.catalog
                setLineReferences(result.references)
                lineReferenceImportState = .imported
            } catch {
                lineReferencesError = error.localizedDescription
                lineReferenceImportState = .failed(error.localizedDescription)
            }
        }
    }

    func downloadLatestLineReferences() {
        guard !lineReferenceImportState.isImporting else { return }
        lineReferenceImportState = .importing
        lineReferencesError = nil

        Task {
            do {
                let sourceDataProcessedAt: Date?
                do {
                    let (metadataData, metadataResponse) = try await URLSession.shared.data(from: LineReferenceStore.sourceMetadataURL)
                    if let metadataResponse = metadataResponse as? HTTPURLResponse,
                       (200..<300).contains(metadataResponse.statusCode) {
                        sourceDataProcessedAt = LineReferenceStore.sourceDataProcessedAt(from: metadataData)
                    } else {
                        sourceDataProcessedAt = nil
                    }
                } catch {
                    sourceDataProcessedAt = nil
                }

                let (data, response) = try await URLSession.shared.data(from: LineReferenceStore.latestCSVExportURL)
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkLibraryError.invalidLineReferenceResponse
                }
                guard (200..<300).contains(response.statusCode) else {
                    throw NetworkLibraryError.lineReferenceHTTPStatus(response.statusCode)
                }
                guard !data.isEmpty else { throw NetworkLibraryError.emptyLineReferenceResponse }

                let result = try await Task.detached(priority: .userInitiated) {
                    try LineReferenceStore.importCSV(
                        data: data,
                        originalFilename: "idfm-line-reference.csv",
                        sourceDataProcessedAt: sourceDataProcessedAt
                    )
                }.value
                catalog = result.catalog
                setLineReferences(result.references)
                lineReferenceImportState = .imported
            } catch {
                lineReferencesError = error.localizedDescription
                lineReferenceImportState = .failed(error.localizedDescription)
            }
        }
    }

    func loadActiveLineReferences() async {
        guard !isLoadingLineReferences, let version = catalog.activeLineReferenceVersion,
              lineReferenceVersionID != version.id else { return }
        isLoadingLineReferences = true
        lineReferencesError = nil
        if lineReferenceVersionID != version.id {
            lineReferences = []
            lineReferenceIndex = [:]
            lineReferenceVersionID = nil
        }
        defer { isLoadingLineReferences = false }

        do {
            let references = try await Task.detached(priority: .userInitiated) {
                try LineReferenceStore.loadReferences(for: version)
            }.value
            guard catalog.activeLineReferenceVersion?.id == version.id else { return }
            setLineReferences(references)
            lineReferenceImportState = .imported
        } catch {
            lineReferencesError = error.localizedDescription
            lineReferenceImportState = .failed(error.localizedDescription)
        }
    }

    func importLineDocuments(from sourceURL: URL) {
        guard !lineDocumentImportState.isImporting else { return }
        lineDocumentImportState = .importing
        lineDocumentsError = nil
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()

        Task {
            defer {
                if shouldStopAccessing { sourceURL.stopAccessingSecurityScopedResource() }
            }
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try LineDocumentStore.importCSV(from: sourceURL)
                }.value
                catalog = result.catalog
                lineDocuments = result.documents
                lineDocumentVersionID = result.catalog.activeLineDocumentVersion?.id
                lineDocumentImportState = .imported
            } catch {
                lineDocumentsError = error.localizedDescription
                lineDocumentImportState = .failed(error.localizedDescription)
            }
        }
    }

    func downloadLatestLineDocuments() {
        guard !lineDocumentImportState.isImporting else { return }
        lineDocumentImportState = .importing
        lineDocumentsError = nil

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: LineDocumentStore.latestCSVExportURL)
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkLibraryError.invalidLineDocumentsResponse
                }
                guard (200..<300).contains(response.statusCode) else {
                    throw NetworkLibraryError.lineDocumentsHTTPStatus(response.statusCode)
                }
                guard !data.isEmpty else { throw NetworkLibraryError.emptyLineDocumentsResponse }

                let result = try await Task.detached(priority: .userInitiated) {
                    try LineDocumentStore.importCSV(data: data, originalFilename: "idfm-line-documents.csv")
                }.value
                catalog = result.catalog
                lineDocuments = result.documents
                lineDocumentVersionID = result.catalog.activeLineDocumentVersion?.id
                lineDocumentImportState = .imported
            } catch {
                lineDocumentsError = error.localizedDescription
                lineDocumentImportState = .failed(error.localizedDescription)
            }
        }
    }

    func loadActiveLineDocuments() async {
        guard !isLoadingLineDocuments else { return }

        while true {
            guard let version = catalog.activeLineDocumentVersion else {
                lineDocuments = []
                lineDocumentVersionID = nil
                return
            }
            guard lineDocumentVersionID != version.id else { return }

            isLoadingLineDocuments = true
            lineDocumentsError = nil
            lineDocuments = []
            lineDocumentVersionID = nil

            do {
                let documents = try await Task.detached(priority: .userInitiated) {
                    try LineDocumentStore.loadDocuments(for: version)
                }.value
                isLoadingLineDocuments = false
                guard catalog.activeLineDocumentVersion?.id == version.id else { continue }
                lineDocuments = documents
                lineDocumentVersionID = version.id
                lineDocumentImportState = .imported
                return
            } catch {
                isLoadingLineDocuments = false
                guard catalog.activeLineDocumentVersion?.id == version.id else { continue }
                lineDocumentsError = error.localizedDescription
                lineDocumentImportState = .failed(error.localizedDescription)
                return
            }
        }
    }

    func documents(for route: GTFSRouteSummary) -> [NetworkLineDocument] {
        guard let reference = lineReference(for: route) else { return [] }
        let idLine = LineReferenceMatcher.canonicalIdentifier(reference.idLine)
        return lineDocuments.filter {
            LineReferenceMatcher.canonicalIdentifier($0.idLine) == idLine
        }.sorted {
            if $0.documentType != $1.documentType { return $0.documentType < $1.documentType }
            return $0.documentName.localizedStandardCompare($1.documentName) == .orderedAscending
        }
    }

    func depotLineCoverage(
        depotID: String,
        serviceDate: Date,
        operatedRouteIDs: Set<String> = []
    ) -> DepotLineCoverage {
        let serviceDateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone)
        let site = DepotLineRoster.selectableSites.first { $0.id == depotID }
        let gtfsVersion = catalog.activeVersion
        let referenceVersion = catalog.activeLineReferenceVersion
        let documentVersion = catalog.activeLineDocumentVersion
        let geometryVersion = catalog.activeGeometryVersion
        let hasLoadedLineReferenceCatalog = referenceVersion != nil
            && lineReferenceVersionID == referenceVersion?.id
            && lineReferencesError == nil
        let hasLoadedGTFSRouteCatalog = gtfsVersion != nil
            && busRoutesVersionID == gtfsVersion?.id
            && busRoutesError == nil
        let hasLoadedLineDocumentCatalog = documentVersion != nil
            && lineDocumentVersionID == documentVersion?.id
            && lineDocumentsError == nil
        let hasLoadedRouteGeometryCatalog = geometryVersion != nil
            && routeGeometryVersionID == geometryVersion?.id
            && routeGeometriesError == nil
        let tracedRouteIDs: Set<String>
        if hasLoadedGTFSRouteCatalog && hasLoadedRouteGeometryCatalog {
            let cacheKey = "\(gtfsVersion?.id ?? "no-gtfs")|\(geometryVersion?.id ?? "no-geometry")"
            if officialGeometryCoverageCacheKey != cacheKey {
                officialGeometryCoverageCacheKey = cacheKey
                officialGeometryCoverageRouteIDs = RouteGeometryMatcher.routeIDsWithOfficialGeometry(
                    among: busRoutes,
                    geometries: routeGeometries
                )
            }
            tracedRouteIDs = officialGeometryCoverageRouteIDs
        } else {
            tracedRouteIDs = []
        }
        let documentedRows = DepotLineRoster.rows.filter { $0.isVisible(atSite: depotID, on: serviceDate) }
        let candidateRows = hasLoadedLineReferenceCatalog
            ? DepotContractLineScope.candidateRows(
                for: site,
                references: lineReferences,
                serviceDate: serviceDate,
                excluding: documentedRows
            )
            : []
        let rows = documentedRows + candidateRows
        let activeBusReferences = hasLoadedLineReferenceCatalog ? lineReferences.filter {
            $0.transportMode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "BUS"
                && $0.isActive(on: serviceDate) == true
        } : []

        struct LineRecord {
            var rows: [DepotLineRosterRow] = []
            var referenceIDs: Set<String> = []
            var hadAmbiguousNameMatch = false
        }

        var records: [String: LineRecord] = [:]
        for row in rows {
            let explicitID = row.canonicalLineID
                .map(LineReferenceMatcher.canonicalIdentifier)
                .flatMap { $0.isEmpty ? nil : $0 }
            let normalizedName = row.line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let nameMatches = Set(activeBusReferences.filter {
                $0.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == normalizedName
            }.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) }.filter { !$0.isEmpty })
            let resolvedID = explicitID ?? (nameMatches.count == 1 ? nameMatches.first : nil)
            let key = resolvedID.map { "id:\($0)" } ?? "name:\(normalizedName)"
            var record = records[key, default: LineRecord()]
            record.rows.append(row)
            if let resolvedID { record.referenceIDs.insert(resolvedID) }
            if explicitID == nil && nameMatches.count > 1 { record.hadAmbiguousNameMatch = true }
            records[key] = record
        }

        let canonicalOperatedRouteIDs = Set(operatedRouteIDs.map(LineReferenceMatcher.canonicalIdentifier))

        var linesWithGTFS = 0
        var routeVariantIDs = Set<String>()
        var tracedLineKeys = Set<String>()
        var planLineKeys = Set<String>()
        var timetableLineKeys = Set<String>()
        var ambiguousReferenceCount = 0
        var missingReferenceCount = 0
        var missingGTFSCount = 0
        var unconfirmedEvidenceCount = 0
        var routesWithoutPlansByID: [String: DepotRouteDocumentGap] = [:]
        var routesWithoutTimetablesByID: [String: DepotRouteDocumentGap] = [:]

        for (key, record) in records {
            let lineID = record.referenceIDs.count == 1 ? record.referenceIDs.first : nil
            if record.hadAmbiguousNameMatch || record.referenceIDs.count > 1 {
                ambiguousReferenceCount += 1
            } else if let lineID,
                      !activeBusReferences.contains(where: {
                          LineReferenceMatcher.canonicalIdentifier($0.idLine) == lineID
                      }) {
                missingReferenceCount += 1
            } else if lineID == nil {
                missingReferenceCount += 1
            }

            let matchingRoutes = hasLoadedGTFSRouteCatalog ? lineID.map { id in
                busRoutes.filter { LineReferenceMatcher.canonicalIdentifier($0.routeID) == id }
            } ?? [] : []
            let routeIDs = Set(matchingRoutes.map(\.routeID))
            routeVariantIDs.formUnion(routeIDs)
            if !matchingRoutes.isEmpty {
                linesWithGTFS += 1
                if matchingRoutes.contains(where: { tracedRouteIDs.contains($0.routeID) }) {
                    tracedLineKeys.insert(key)
                }
            } else if lineID != nil {
                missingGTFSCount += 1
            }

            let importedDocuments = hasLoadedLineDocumentCatalog ? lineID.map { id in
                lineDocuments.filter { LineReferenceMatcher.canonicalIdentifier($0.idLine) == id }
            } ?? [] : []
            let curatedDocuments = record.rows.flatMap(\.publicDocuments)
            let allDocumentTypes = importedDocuments.compactMap { document -> String? in
                guard document.destination != nil else { return nil }
                return document.documentType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            } + curatedDocuments.compactMap { document -> String? in
                guard ["http", "https"].contains(document.url.scheme?.lowercased() ?? ""),
                      document.url.host != nil else { return nil }
                return document.type.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            }
            if allDocumentTypes.contains("PLAN") { planLineKeys.insert(key) }
            let hasTimetableDocument = !Set(allDocumentTypes).isDisjoint(with: ["HORAIRE", "FICHE HORAIRE"])
            if hasTimetableDocument {
                timetableLineKeys.insert(key)
            }
            let lineName = record.rows.map(\.line).sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }.first ?? activeBusReferences.first(where: {
                LineReferenceMatcher.canonicalIdentifier($0.idLine) == (lineID ?? "")
            })?.displayName ?? lineID ?? key
            for route in matchingRoutes {
                if !allDocumentTypes.contains("PLAN") {
                    routesWithoutPlansByID[route.routeID] = DepotRouteDocumentGap(
                        lineName: lineName,
                        routeID: route.routeID
                    )
                }
                if !hasTimetableDocument {
                    routesWithoutTimetablesByID[route.routeID] = DepotRouteDocumentGap(
                        lineName: lineName,
                        routeID: route.routeID
                    )
                }
            }

            let rosterConfirmed = record.rows.contains { $0.evidenceStatus(on: serviceDate) == .confirmed }
            let assignmentConfirmed = !Set(routeIDs.map(LineReferenceMatcher.canonicalIdentifier))
                .isDisjoint(with: canonicalOperatedRouteIDs)
            if !rosterConfirmed && !assignmentConfirmed { unconfirmedEvidenceCount += 1 }
        }

        return DepotLineCoverage(
            depotID: depotID,
            serviceDateKey: serviceDateKey,
            gtfsVersionID: hasLoadedGTFSRouteCatalog ? gtfsVersion?.id : nil,
            lineReferenceVersionID: hasLoadedLineReferenceCatalog ? referenceVersion?.id : nil,
            lineDocumentVersionID: hasLoadedLineDocumentCatalog ? lineDocumentVersionID : nil,
            routeGeometryVersionID: hasLoadedRouteGeometryCatalog ? routeGeometryVersionID : nil,
            hasLoadedLineReferenceCatalog: hasLoadedLineReferenceCatalog,
            hasLoadedGTFSRouteCatalog: hasLoadedGTFSRouteCatalog,
            hasLoadedLineDocumentCatalog: hasLoadedLineDocumentCatalog,
            hasLoadedRouteGeometryCatalog: hasLoadedRouteGeometryCatalog,
            uniqueLineCount: records.count,
            linesWithGTFS: linesWithGTFS,
            routeVariantCount: routeVariantIDs.count,
            linesWithOfficialTraces: tracedLineKeys.count,
            linesWithPlans: planLineKeys.count,
            linesWithTimetables: timetableLineKeys.count,
            ambiguousReferenceCount: ambiguousReferenceCount,
            missingReferenceCount: missingReferenceCount,
            missingGTFSCount: missingGTFSCount,
            unconfirmedDepotEvidenceCount: unconfirmedEvidenceCount,
            routesWithoutPlans: routesWithoutPlansByID.values.sorted {
                if $0.lineName != $1.lineName {
                    return $0.lineName.localizedStandardCompare($1.lineName) == .orderedAscending
                }
                return $0.routeID.localizedStandardCompare($1.routeID) == .orderedAscending
            },
            routesWithoutTimetables: routesWithoutTimetablesByID.values.sorted {
                if $0.lineName != $1.lineName {
                    return $0.lineName.localizedStandardCompare($1.lineName) == .orderedAscending
                }
                return $0.routeID.localizedStandardCompare($1.routeID) == .orderedAscending
            }
        )
    }

    func depotGTFSServiceAudit(depotID: String, serviceDate: Date) async throws -> DepotGTFSServiceAudit {
        let audits = try await depotGTFSServiceAudits(depotIDs: [depotID], serviceDate: serviceDate)
        guard let audit = audits[depotID] else {
            throw NetworkLibraryError.missingDepotServiceAudit(depotID)
        }
        return audit
    }

    /// Audits several depots with one GTFS departures-index read. The route service
    /// index is shared by every depot, so decoding its large archive once is enough.
    func depotGTFSServiceAudits(
        depotIDs: [String],
        serviceDate: Date
    ) async throws -> [String: DepotGTFSServiceAudit] {
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let serviceDayStart = calendar.startOfDay(for: serviceDate)
        let serviceDateKey = GTFSServiceDate.key(for: serviceDayStart, timeZone: GTFSServiceDate.parisTimeZone)
        let version = catalog.activeVersion
        let referenceVersion = catalog.activeLineReferenceVersion
        let activeBusReferences = lineReferences.filter {
            $0.transportMode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "BUS"
                && $0.isActive(on: serviceDayStart) == true
        }
        let hasReferenceCatalog = referenceVersion != nil
            && lineReferenceVersionID == referenceVersion?.id
            && lineReferencesError == nil
            && !lineReferences.isEmpty

        struct LineDraft {
            let referenceMatch: DepotLineReferenceAuditMatch
            var lineNames = Set<String>()
            var routeIDs = Set<String>()
            var evidenceStatuses = Set<DepotLineEvidenceStatus>()
            var announcedServiceClaimsByID: [String: DepotLineRosterClaim] = [:]
        }

        let routesByCanonicalID = Dictionary(grouping: busRoutes) {
            LineReferenceMatcher.canonicalIdentifier($0.routeID)
        }
        var draftsByDepotID: [String: [String: LineDraft]] = [:]

        for depotID in Set(depotIDs).sorted() {
            let site = DepotLineRoster.selectableSites.first { $0.id == depotID }
            let documentedRows = DepotLineRoster.rows.filter {
                $0.isVisible(atSite: depotID, on: serviceDayStart)
            }
            let candidateRows = hasReferenceCatalog
                ? DepotContractLineScope.candidateRows(
                    for: site,
                    references: lineReferences,
                    serviceDate: serviceDayStart,
                    excluding: documentedRows
                )
                : []
            var drafts: [String: LineDraft] = [:]

            for row in documentedRows + candidateRows {
                let explicitID = row.canonicalLineID
                    .map(LineReferenceMatcher.canonicalIdentifier)
                    .flatMap { $0.isEmpty ? nil : $0 }
                let normalizedName = row.line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                let matchingReferenceIDs: Set<String>

                if let explicitID {
                    matchingReferenceIDs = Set(activeBusReferences.compactMap { reference in
                        LineReferenceMatcher.canonicalIdentifier(reference.idLine) == explicitID ? explicitID : nil
                    })
                } else {
                    matchingReferenceIDs = Set(activeBusReferences.compactMap { reference in
                        guard reference.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == normalizedName else { return nil }
                        let idLine = LineReferenceMatcher.canonicalIdentifier(reference.idLine)
                        return idLine.isEmpty ? nil : idLine
                    })
                }

                let referenceMatch: DepotLineReferenceAuditMatch
                if !hasReferenceCatalog {
                    referenceMatch = .unavailable
                } else if matchingReferenceIDs.count == 1, let idLine = matchingReferenceIDs.first {
                    referenceMatch = .unique(idLine: idLine)
                } else if matchingReferenceIDs.count > 1 {
                    referenceMatch = .ambiguous(idLines: matchingReferenceIDs.sorted {
                        $0.localizedStandardCompare($1) == .orderedAscending
                    })
                } else {
                    referenceMatch = .missing
                }

                let groupKey = referenceMatch.idLine.map { "id:\($0)" }
                    ?? "name:\(normalizedName)|\(referenceMatch.summary)"
                var draft = drafts[groupKey] ?? LineDraft(referenceMatch: referenceMatch)
                draft.lineNames.insert(row.line)
                draft.evidenceStatuses.insert(row.evidenceStatus(on: serviceDayStart))
                for claim in row.claims where claim.kind == .announcedService && claim.isVisible(on: serviceDayStart) {
                    draft.announcedServiceClaimsByID[claim.id] = claim
                }
                if let idLine = referenceMatch.idLine,
                   let version,
                   busRoutesVersionID == version.id {
                    draft.routeIDs.formUnion(routesByCanonicalID[idLine, default: []].map(\.routeID))
                }
                drafts[groupKey] = draft
            }

            draftsByDepotID[depotID] = drafts
        }

        let utcTimeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let firstValidDateKey = version?.validFrom.flatMap {
            GTFSServiceDate.key(for: $0, timeZone: utcTimeZone)
        }
        let lastValidDateKey = version?.validThrough.flatMap {
            GTFSServiceDate.key(for: $0, timeZone: utcTimeZone)
        }
        let serviceDayEnd = calendar.date(byAdding: .day, value: 1, to: serviceDayStart)
        let serviceAvailability: DepotGTFSServiceAuditAvailability
        if version == nil {
            serviceAvailability = .feedUnavailable
        } else if let version,
                  busRoutesVersionID != version.id || busRoutesError != nil {
            serviceAvailability = .routeIndexUnavailable
        } else if let firstValidDateKey,
                  let lastValidDateKey,
                  let serviceDateKey,
                  serviceDayEnd != nil {
            if firstValidDateKey > lastValidDateKey {
                serviceAvailability = .validityUnknown
            } else if (firstValidDateKey...lastValidDateKey).contains(serviceDateKey) {
                serviceAvailability = .ready
            } else {
                serviceAvailability = .outsideFeedValidity
            }
        } else {
            serviceAvailability = .validityUnknown
        }

        let allRouteIDs = Set(draftsByDepotID.values.flatMap { drafts in
            drafts.values.flatMap(\.routeIDs)
        })
        var departureCountsByRouteID: [String: Int] = [:]
        if serviceAvailability == .ready,
           let version,
           let serviceDayEnd,
           !allRouteIDs.isEmpty {
            let departures = try await loadScheduledDepartures(
                gtfsVersionID: version.id,
                routeIDs: allRouteIDs,
                from: serviceDayStart,
                through: serviceDayEnd
            )
            for departure in departures {
                departureCountsByRouteID[departure.routeID, default: 0] += 1
            }
        }

        var audits: [String: DepotGTFSServiceAudit] = [:]
        for (depotID, drafts) in draftsByDepotID {
            let entries = drafts.values.map { draft in
                let routeIDs = draft.routeIDs.sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }
                let departureCount: Int? = serviceAvailability == .ready && !routeIDs.isEmpty
                    ? routeIDs.reduce(0) { $0 + departureCountsByRouteID[$1, default: 0] }
                    : nil
                let lineName = draft.lineNames.sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }.first ?? draft.referenceMatch.idLine ?? "Ligne inconnue"
                return DepotLineServiceAuditEntry(
                    lineName: lineName,
                    referenceMatch: draft.referenceMatch,
                    routeIDs: routeIDs,
                    scheduledDepartureCount: departureCount,
                    evidenceStatuses: draft.evidenceStatuses.sorted {
                        $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending
                    },
                    announcedServiceClaims: draft.announcedServiceClaimsByID.values.sorted {
                        $0.sourceTitle.localizedStandardCompare($1.sourceTitle) == .orderedAscending
                    }
                )
            }.sorted {
                if $0.lineName != $1.lineName {
                    return $0.lineName.localizedStandardCompare($1.lineName) == .orderedAscending
                }
                return $0.id.localizedStandardCompare($1.id) == .orderedAscending
            }

            audits[depotID] = DepotGTFSServiceAudit(
                depotID: depotID,
                serviceDateKey: serviceDateKey,
                gtfsVersionID: version?.id,
                lineReferenceVersionID: referenceVersion?.id,
                availability: serviceAvailability,
                entries: entries
            )
        }
        return audits
    }

    func clearLineDocumentError() {
        if case .failed = lineDocumentImportState { lineDocumentImportState = .idle }
        lineDocumentsError = nil
    }

    func reportLineDocumentError(_ message: String) {
        lineDocumentsError = message
        lineDocumentImportState = .failed(message)
    }

    func clearLineReferenceError() {
        if case .failed = lineReferenceImportState { lineReferenceImportState = .idle }
        lineReferencesError = nil
    }

    func reportLineReferenceError(_ message: String) {
        lineReferencesError = message
        lineReferenceImportState = .failed(message)
    }

    func lineReference(for route: GTFSRouteSummary) -> NetworkLineReference? {
        LineReferenceMatcher.reference(for: route, using: lineReferenceIndex)
    }

    private func setLineReferences(_ references: [NetworkLineReference]) {
        lineReferences = references
        lineReferenceIndex = LineReferenceMatcher.uniqueIndex(for: references)
        lineReferenceVersionID = catalog.activeLineReferenceVersion?.id
    }

    func clearImportError() {
        if case .failed = importState { importState = .idle }
    }

    func reportImportError(_ message: String) {
        importState = .failed(message)
    }
}
