import Foundation
import Darwin

@main
struct CloudCareerArchiveSmoke {
    static func main() {
        do {
            try pinnedVersionFilesSurviveArchiveRoundTrip()
            try exportedSaveTimestampWinsAgainstAnOlderLocalCopy()
            try overflowingManifestIsRejectedBeforeStaging()
            print("PASS: pinned network files round-trip, exported timestamps drive conflict checks, and oversized manifests are rejected")
        } catch {
            fputs("FAIL: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func pinnedVersionFilesSurviveArchiveRoundTrip() throws {
        let workspace = FileManager.default.temporaryDirectory
            .appending(path: "TransportManagerIDFM-archive-smoke-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: workspace) }

        let sourceRoot = workspace.appending(path: "source", directoryHint: .isDirectory)
        let restoredRoot = workspace.appending(path: "restored", directoryHint: .isDirectory)
        let pinnedPaths = [
            "versions/gtfs-version/idfm-gtfs.zip",
            "geometries/geometry-version/route-geometries.json",
            "contracts/contract-version/contract-features.json",
            "line-references/reference-version/line-references.json"
        ]
        let contents = [
            Data([0, 1, 2, 3, 255]),
            Data("geometry index".utf8),
            Data("contract index".utf8),
            Data("line reference index".utf8)
        ]
        var directories: [URL] = []
        for (path, bytes) in zip(pinnedPaths, contents) {
            let fileURL = sourceRoot.appending(path: path)
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try bytes.write(to: fileURL)
            directories.append(fileURL.deletingLastPathComponent())
        }

        let archiveURL = workspace.appending(path: "career-network.bin")
        try CloudCareerArchive.makeArchive(root: sourceRoot, directories: directories, destination: archiveURL)
        try CloudCareerArchive.installArchive(from: archiveURL, into: restoredRoot)

        for (path, expectedContents) in zip(pinnedPaths, contents) {
            let restoredURL = restoredRoot.appending(path: path)
            let actualContents = try Data(contentsOf: restoredURL)
            precondition(actualContents == expectedContents, "The pinned file \(path) must be restored byte for byte.")
        }
    }

    private static func overflowingManifestIsRejectedBeforeStaging() throws {
        let workspace = FileManager.default.temporaryDirectory
            .appending(path: "TransportManagerIDFM-oversized-manifest-smoke-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: workspace) }
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)

        let manifest = Data(#"{"schemaVersion":1,"entries":[{"path":"versions/one/file","byteCount":18446744073709551615,"sha256":""},{"path":"versions/two/file","byteCount":1,"sha256":""}]}"#.utf8)
        var manifestLength = UInt64(manifest.count).littleEndian
        var archive = Data("TMIDFM1\n".utf8)
        withUnsafeBytes(of: &manifestLength) { archive.append(contentsOf: $0) }
        archive.append(manifest)
        let archiveURL = workspace.appending(path: "overflowing-manifest.bin")
        try archive.write(to: archiveURL)

        do {
            try CloudCareerArchive.installArchive(from: archiveURL, into: workspace.appending(path: "installed"))
            preconditionFailure("A manifest whose byte counts overflow UInt64 must be rejected.")
        } catch let error as CloudCareerArchiveError {
            guard case .oversizedArchive = error else {
                throw SmokeFailure.unexpectedArchiveError(error.localizedDescription)
            }
        }
    }

    private static func exportedSaveTimestampWinsAgainstAnOlderLocalCopy() throws {
        let localUpdatedAt = Date(timeIntervalSince1970: 1_762_000_000)
        let exportedSaveUpdatedAt = localUpdatedAt.addingTimeInterval(30)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let saveData = try encoder.encode(ExportedSaveTimestamp(updatedAt: exportedSaveUpdatedAt))

        let sourceUpdatedAt = try CloudCareerSyncPolicy.sourceUpdatedAt(from: saveData)
        precondition(sourceUpdatedAt == exportedSaveUpdatedAt, "Conflict metadata must use the timestamp inside the exported save asset.")
        precondition(
            CloudCareerSyncPolicy.remoteIsNewer(remoteUpdatedAt: sourceUpdatedAt, localUpdatedAt: localUpdatedAt),
            "A stale local copy with no checkpoint must prefer the newer exported save."
        )
    }

    private struct ExportedSaveTimestamp: Encodable {
        let updatedAt: Date
    }
}

private enum SmokeFailure: LocalizedError {
    case unexpectedArchiveError(String)

    var errorDescription: String? {
        switch self {
        case let .unexpectedArchiveError(message): "Expected oversizedArchive, got: \(message)"
        }
    }
}
