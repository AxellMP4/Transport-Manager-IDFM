import Foundation

@main
struct GTFSProvenanceSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Le smoke attend une archive GTFS de qualité synthétique.")
        }

        let bundledSHA256 = GTFSImportProvenance.bundledArchiveSHA256
        let publicDataHub = GTFSImportProvenance.publicDataHub.metadata
        precondition(publicDataHub.datasetID == "offre-horaires-tc-gtfs-idfm")
        precondition(publicDataHub.url == "https://data.iledefrance.fr/explore/dataset/offre-horaires-tc-gtfs-idfm/")
        precondition(publicDataHub.license == "Licence Mobilité")

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

        let previousBundledSHA256 = "3c3fe0eb7e165dde283ff87489339b48b4c3dcf69be011cc7ae2bc78d1764500"
        let previousBundledLegacy = try decodeVersion(
            datasetID: "offre-horaires-tc-gtfs-idfm",
            sha256: previousBundledSHA256
        )
        precondition(previousBundledLegacy.sourceProvenanceIsDeclared)
        precondition(previousBundledLegacy.displaySourceTitle == previousBundledLegacy.sourceTitle)

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

        verifyTripMotifGrouping()
        try verifyMissingStopDiagnostics(in: URL(fileURLWithPath: CommandLine.arguments[1]))

        print("PASS: GTFS provenance, trip motifs, and missing-stop diagnostics")
    }

    private static func verifyMissingStopDiagnostics(in archiveURL: URL) throws {
        let inspection = try GTFSFeedInspector.inspect(archiveURL)
        let quality = inspection.quality
        precondition(quality.tripsWithMissingStopCoordinates == 1)
        precondition(quality.tripsWithMissingStopRecords == 1)
        precondition(quality.missingStopIDRowCount == 1)

        let issuesByTripID = Dictionary(uniqueKeysWithValues: (quality.tripIssues ?? []).map { ($0.tripID, $0) })
        guard let missingStopRecord = issuesByTripID["trip-missing-stop-record"],
              let missingCoordinates = issuesByTripID["trip-missing-coordinates"],
              let missingStopID = issuesByTripID["trip-missing-stop-id"] else {
            fatalError("Chaque anomalie d’arrêt doit conserver le diagnostic de sa course.")
        }
        precondition(
            missingStopRecord.stopIDsWithoutCoordinates == nil
                && missingStopRecord.stopIDsMissingFromFeed == ["stop-not-in-feed"]
                && missingStopRecord.issueKinds.contains(.missingStopRecord)
                && !missingStopRecord.issueKinds.contains(.missingStopCoordinates)
                && missingStopRecord.summary.contains("stop_id absent de stops.txt"),
            "Un identifiant sans fiche stops.txt ne doit pas être appelé arrêt sans coordonnées."
        )
        precondition(
            missingCoordinates.stopIDsWithoutCoordinates == ["stop-no-coordinates"]
                && missingCoordinates.stopIDsMissingFromFeed == nil
                && missingCoordinates.issueKinds.contains(.missingStopCoordinates)
                && !missingCoordinates.issueKinds.contains(.missingStopRecord)
                && missingCoordinates.summary.contains("arrêts sans coordonnées"),
            "Un arrêt présent dans stops.txt mais sans coordonnées doit rester explicitement identifiable."
        )
        precondition(
            missingStopID.missingStopIDRowCount == 1
                && missingStopID.summary.contains("1 ligne de passage sans stop_id"),
            "Une ligne stop_times sans stop_id doit rester séparée des autres erreurs d’arrêt."
        )
        precondition(quality.hasScheduleIssues, "Ces anomalies doivent signaler un audit d’horaires à contrôler.")
    }

    private static func verifyTripMotifGrouping() {
        let orderedStops = [("stop-a", 10), ("stop-b", 20)]
        let schedules = [
            makeTripSchedule("trip-b", routeID: "IDFM:C1", shapeID: "shape-a", stops: orderedStops.reversed().map { $0 }),
            makeTripSchedule("trip-a", routeID: "IDFM:C1", shapeID: "shape-a", stops: orderedStops),
            makeTripSchedule("trip-sequence", routeID: "IDFM:C1", shapeID: "shape-a", stops: [("stop-a", 10), ("stop-c", 30)]),
            makeTripSchedule("trip-shape", routeID: "IDFM:C1", shapeID: "shape-b", stops: orderedStops),
            makeTripSchedule("trip-route", routeID: "IDFM:C2", shapeID: "shape-a", stops: orderedStops),
            makeTripSchedule("trip-empty", routeID: "IDFM:C1", shapeID: "shape-a", stops: [])
        ]

        let motifs = GTFSServiceTripMotifCatalog.build(from: schedules)
        precondition(motifs.count == 4, "A motif must split when route, shape, or ordered stop sequence differs.")
        precondition(
            Set(motifs.flatMap(\.tripIDs)) == Set(["trip-a", "trip-b", "trip-sequence", "trip-shape", "trip-route"]),
            "A trip without stops must not appear in a cartographic motif."
        )

        let commonMotif = motifs.first {
            $0.routeID == "IDFM:C1"
                && $0.shapeID == "shape-a"
                && $0.orderedStopSequence == [
                    GTFSStopSequenceEntry(stopID: "stop-a", stopSequence: 10),
                    GTFSStopSequenceEntry(stopID: "stop-b", stopSequence: 20)
                ]
        }
        precondition(commonMotif?.tripIDs == ["trip-a", "trip-b"], "The motif should sort trips and stops consistently.")
        precondition(
            GTFSServiceTripMotifCatalog.build(from: schedules.reversed().map { $0 }).map(\.id) == motifs.map(\.id),
            "The motif index order should not depend on GTFS archive row order."
        )
    }

    private static func makeTripSchedule(
        _ tripID: String,
        routeID: String,
        shapeID: String?,
        stops: [(String, Int)]
    ) -> GTFSServiceTripSchedule {
        GTFSServiceTripSchedule(
            tripID: tripID,
            routeID: routeID,
            serviceID: "service-1",
            directionID: nil,
            headsign: nil,
            stops: stops.map { stopID, sequence in
                GTFSServiceTripStopTime(
                    stopID: stopID,
                    stopSequence: sequence,
                    arrivalSeconds: nil,
                    departureSeconds: nil,
                    shapeDistanceTraveled: nil
                )
            },
            shapeID: shapeID
        )
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
