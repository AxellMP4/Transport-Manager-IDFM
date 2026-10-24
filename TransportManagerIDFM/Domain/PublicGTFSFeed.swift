import Foundation

enum PublicGTFSFeedError: LocalizedError, Equatable {
    case nonHTTPResponse
    case httpStatus(Int)
    case emptyArchive
    case invalidArchive

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
        }
    }
}

enum PublicGTFSFeed {
    static let downloadURL = URL(string: "https://eu.ftp.opendatasoft.com/stif/GTFS/IDFM-gtfs.zip")!

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
    }
}
