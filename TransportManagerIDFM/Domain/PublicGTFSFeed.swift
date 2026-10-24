import Foundation

enum PublicGTFSFeedError: LocalizedError, Equatable {
    case nonHTTPResponse
    case httpStatus(Int)
    case emptyArchive
    case invalidArchive
    case missingRequiredFile(String)
    case noFragments(String)
    case missingFragment(String)

    var errorDescription: String? {
        switch self {
        case .nonHTTPResponse:
            "Le miroir IDFM a renvoyé une réponse inattendue."
        case let .httpStatus(status):
            "Le téléchargement du GTFS public a échoué (HTTP \(status))."
        case .emptyArchive:
            "Le miroir IDFM a renvoyé une archive GTFS vide."
        case .invalidArchive:
            "Le miroir IDFM n’a pas renvoyé un ZIP GTFS valide."
        case let .missingRequiredFile(filename):
            "Le ZIP GTFS public ne contient pas le fichier requis \(filename)."
        case let .noFragments(prefix):
            "Aucun fragment GTFS ne porte le préfixe \(prefix)."
        case let .missingFragment(name):
            "Le fragment GTFS \(name) est manquant."
        }
    }
}

enum PublicGTFSFeed {
    static let downloadURL = URL(string: "https://eu.ftp.opendatasoft.com/stif/GTFS/IDFM-gtfs.zip")!
    private static let requiredTableFiles = ["routes.txt", "trips.txt", "stops.txt", "stop_times.txt"]

    static func orderedFragments(_ urls: [URL], named prefix: String) throws -> [URL] {
        let prefixWithSeparator = "\(prefix)-"
        let fragments = urls.compactMap { url -> (index: Int, url: URL)? in
            let filename = url.lastPathComponent
            guard filename.hasPrefix(prefixWithSeparator), filename.hasSuffix(".bin") else { return nil }
            let indexText = filename.dropFirst(prefixWithSeparator.count).dropLast(".bin".count)
            guard let index = Int(indexText), index >= 0 else { return nil }
            return (index, url)
        }.sorted { $0.index < $1.index }

        guard !fragments.isEmpty else { throw PublicGTFSFeedError.noFragments(prefix) }
        for (expectedIndex, fragment) in fragments.enumerated() where fragment.index != expectedIndex {
            throw PublicGTFSFeedError.missingFragment(String(format: "%@-%02d.bin", prefix, expectedIndex))
        }
        return fragments.map(\.url)
    }

    static func validateDownloadedArchive(at url: URL, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PublicGTFSFeedError.nonHTTPResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw PublicGTFSFeedError.httpStatus(httpResponse.statusCode)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let byteCount = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        guard byteCount > 0 else {
            throw PublicGTFSFeedError.emptyArchive
        }

        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let signature = try file.read(upToCount: 4) ?? Data()
        guard signature == Data([0x50, 0x4B, 0x03, 0x04]) else {
            throw PublicGTFSFeedError.invalidArchive
        }

        let archive: ZIPArchiveReader
        do {
            archive = try ZIPArchiveReader(url: url)
        } catch {
            throw PublicGTFSFeedError.invalidArchive
        }

        for filename in requiredTableFiles where archive.entry(named: filename) == nil {
            throw PublicGTFSFeedError.missingRequiredFile(filename)
        }
    }
}
