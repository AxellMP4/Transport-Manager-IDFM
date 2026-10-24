import Foundation

@main
struct PublishedGTFSFeedSmoke {
    static func main() throws {
        let expectedURL = URL(string: "https://eu.ftp.opendatasoft.com/stif/GTFS/IDFM-gtfs.zip")!
        precondition(PublicGTFSFeed.downloadURL == expectedURL, "Le miroir GTFS public doit viser le ZIP officiel.")

        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appending(path: "published-gtfs-smoke-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let validArchive = temporaryDirectory.appending(path: "feed.zip")
        try Data([0x50, 0x4B, 0x03, 0x04, 0x01]).write(to: validArchive)
        try PublicGTFSFeed.validateDownloadedArchive(at: validArchive, response: httpResponse(status: 200))

        try expectRejected(status: 404, archive: validArchive, expected: .httpStatus(404))

        let emptyArchive = temporaryDirectory.appending(path: "empty.zip")
        try Data().write(to: emptyArchive)
        try expectRejected(status: 200, archive: emptyArchive, expected: .emptyArchive)

        let htmlResponse = URLResponse(
            url: PublicGTFSFeed.downloadURL,
            mimeType: "text/html",
            expectedContentLength: 5,
            textEncodingName: "utf-8"
        )
        try expectRejected(archive: validArchive, response: htmlResponse, expected: .nonHTTPResponse)

        let htmlArchive = temporaryDirectory.appending(path: "error.html")
        try Data("<html>".utf8).write(to: htmlArchive)
        try expectRejected(status: 200, archive: htmlArchive, expected: .invalidArchive)

        print("PASS: public GTFS HTTP status and ZIP validation")
    }

    private static func httpResponse(status: Int) -> URLResponse {
        HTTPURLResponse(
            url: PublicGTFSFeed.downloadURL,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/zip"]
        )!
    }

    private static func expectRejected(
        status: Int,
        archive: URL,
        expected: PublicGTFSFeedError
    ) throws {
        try expectRejected(archive: archive, response: httpResponse(status: status), expected: expected)
    }

    private static func expectRejected(
        archive: URL,
        response: URLResponse,
        expected: PublicGTFSFeedError
    ) throws {
        do {
            try PublicGTFSFeed.validateDownloadedArchive(at: archive, response: response)
            fatalError("Le téléchargement aurait dû échouer avec \(expected).")
        } catch let error as PublicGTFSFeedError {
            precondition(error == expected, "Erreur inattendue : \(error), attendue : \(expected).")
        }
    }
}
