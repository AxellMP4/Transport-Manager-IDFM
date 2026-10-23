import Foundation

@main
struct GTFSProvenanceSmoke {
    static func main() throws {
        let bundledSHA256 = GTFSImportProvenance.bundledArchiveSHA256

        let unverified = try decodeVersion(
            datasetID: "offre-horaires-tc-gtfs-idfm",
            sha256: "legacy-different-archive"
        )
        precondition(!unverified.sourceProvenanceIsDeclared)
        precondition(unverified.displaySourceTitle == "Source GTFS à vérifier")
        precondition(unverified.displayLicense == "À vérifier")
        precondition(unverified.sourceTitle == "Historical source label")
        precondition(unverified.license == "Historical license label")

        let bundledLegacy = try decodeVersion(
            datasetID: "offre-horaires-tc-gtfs-idfm",
            sha256: bundledSHA256
        )
        precondition(bundledLegacy.sourceProvenanceIsDeclared)
        precondition(bundledLegacy.displaySourceTitle == bundledLegacy.sourceTitle)

        let explicitFalse = try decodeVersion(
            datasetID: "offre-horaires-tc-gtfs-idfm",
            sha256: bundledSHA256,
            declared: false
        )
        precondition(!explicitFalse.sourceProvenanceIsDeclared)

        let explicitTrue = try decodeVersion(
            datasetID: "manual-gtfs-unverified",
            sha256: "other-archive",
            declared: true
        )
        precondition(explicitTrue.sourceProvenanceIsDeclared)

        let roundTrip = try JSONDecoder().decode(
            NetworkVersion.self,
            from: JSONEncoder().encode(unverified)
        )
        precondition(!roundTrip.sourceProvenanceIsDeclared)
        precondition(roundTrip.displaySourceTitle == "Source GTFS à vérifier")

        print("PASS: legacy migration, explicit provenance precedence, and Codable round-trip")
    }

    private static func decodeVersion(
        datasetID: String,
        sha256: String,
        declared: Bool? = nil
    ) throws -> NetworkVersion {
        var payload: [String: Any] = [
            "id": sha256,
            "importedAt": 0,
            "validFrom": NSNull(),
            "validThrough": NSNull(),
            "sourceIDs": ["gtfs"],
            "sourceDatasetID": datasetID,
            "sourceTitle": "Historical source label",
            "sourceURL": "https://example.invalid/source",
            "license": "Historical license label",
            "licenseURL": "https://example.invalid/license",
            "originalFilename": "feed.zip",
            "archiveRelativePath": "versions/feed.zip",
            "sha256": sha256,
            "busRouteCount": 1,
            "busStopCount": 2,
            "feedStopCount": 2,
            "gtfsQuality": NSNull()
        ]
        if let declared {
            payload["sourceProvenanceIsDeclared"] = declared
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try JSONDecoder().decode(NetworkVersion.self, from: data)
    }
}
