import Foundation

@main
struct RegionalCoverageMatrixSmoke {
    static func main() throws {
        let serviceDate = try requireDate("20261102")
        let route = GTFSRouteSummary(routeID: "IDFM:C00001", shortName: "T1", longName: "Test line")
        let secondTrip = GTFSServiceTripSchedule(
            tripID: "trip-2",
            routeID: route.routeID,
            serviceID: "weekday",
            directionID: "0",
            headsign: "Terminus B",
            stops: [],
            shapeID: "invalid-shape"
        )
        let thirdTrip = GTFSServiceTripSchedule(
            tripID: "trip-3",
            routeID: route.routeID,
            serviceID: "weekday",
            directionID: "0",
            headsign: "Terminus C",
            stops: [],
            shapeID: nil
        )
        let inspection = try fixtureInspection(route: route, secondTrip: secondTrip, thirdTrip: thirdTrip, containsFrequenciesFile: false)
        let documents = try LineDocumentStore.parseCSV(data: Data([
            "ID_Line,Document_Name,URL,Type,date_validite",
            "C00001,Plan de ligne,https://example.test/plan.pdf,PLAN,2026-01-01/2026-12-31",
            "C00001,Fiche horaire,https://example.test/timetable.pdf,HORAIRE,2026-11-03/2026-12-31",
            "C00001,URL invalide,not-a-url,PLAN,2026-01-01/2026-12-31"
        ].joined(separator: "\n").utf8))
        let reference = lineReference(
            id: "C00001#0",
            idLine: "C00001",
            shortName: "T1",
            validFrom: "2026-01-01",
            validTo: "2026-12-31"
        )
        let unknownDateReference = lineReference(
            id: "C00002#1",
            idLine: "C00002",
            shortName: "T2",
            validFrom: "",
            validTo: ""
        )
        let nonBusReference = lineReference(
            id: "C00003#2",
            idLine: "C00003",
            shortName: "RER X",
            validFrom: "2026-01-01",
            validTo: "2026-12-31",
            mode: "rail"
        )
        let geometry = NetworkRouteGeometry(
            id: "IDFM:C00001#0",
            lineID: "IDFM:C00001",
            shortName: "T1",
            longName: "Test line",
            operatorName: "",
            color: "",
            updated: "2026-10-20",
            paths: [[
                GeographicCoordinate(latitude: 48.8, longitude: 2.3),
                GeographicCoordinate(latitude: 48.81, longitude: 2.31)
            ]]
        )

        let matrix = RegionalCoverageMatrixBuilder.build(
            serviceDate: serviceDate,
            references: [reference, unknownDateReference, nonBusReference],
            inspection: inspection,
            documents: documents,
            geometries: [geometry]
        )
        try expect(matrix.summary.candidateBusRecordCount == 2, "active bus source rows should be retained")
        try expect(matrix.summary.eligibleOnServiceDateCount == 1, "source date validity should be date-scoped")
        try expect(matrix.summary.unknownDateValidityCount == 1, "unknown validity should stay visible")
        try expect(matrix.summary.uniqueGTFSLineCount == 1, "canonical ID_Line route matching should be exact")
        try expect(matrix.summary.missingGTFSLineCount == 1, "missing GTFS routes should be counted")
        try expect(matrix.summary.exactCommercialGeometryLineCount == 1, "commercial geometry should be joined by line ID")

        guard let row = matrix.lines.first(where: { $0.idLine == "C00001" }) else {
            throw SmokeError.failed("matrix omitted the matched line")
        }
        try expect(row.routeVariants.count == 1, "matched line should retain its GTFS variant")
        try expect(row.routeVariants[0].activeTripTemplateCount == 3, "active trip templates should use the service calendar")
        try expect(row.routeVariants[0].activeDepartureCount == 2, "departure count should include active trips")
        try expect(row.routeVariants[0].activeTripsWithoutDepartureCount == 1, "active templates without departure rows should remain visible")
        try expect(row.activityStatus == .partialDepartureCoverage, "a line with both departures and missing departure rows should be flagged")
        try expect(row.routeVariants[0].shapeCoverage?.tripsWithShapeReference == 2, "trip shape references should be counted")
        try expect(row.routeVariants[0].shapeCoverage?.tripsWithAvailableShape == 1, "available trip shapes should be counted")
        try expect(row.routeVariants[0].shapeCoverage?.tripsWithInvalidShape == 1, "invalid trip shapes should stay distinct")
        try expect(row.routeVariants[0].tripShapeIssues.count == 2, "each active course without an available shape should be individually identified")
        try expect(row.routeVariants[0].tripShapeIssues.contains(where: { $0.status == .noReference }), "missing shape references should be identified by trip")
        try expect(row.plans.count == 1 && row.timetables.count == 1, "plans and timetables should be separate")
        try expect(row.plans[0].validity == .validOnServiceDate, "valid document dates should be interpreted")
        try expect(row.timetables[0].validity == .outsideValidity, "expired/future document dates should be visible")
        try expect(row.malformedDocumentCount == 1, "malformed source links should be retained as issues")
        try expect(row.reasons.contains("malformed_line_document_records_for_id_line"), "line-level issue reason should be visible")
        guard let noMatchRow = matrix.lines.first(where: { $0.idLine == "C00002" }) else {
            throw SmokeError.failed("matrix omitted the unverified source record")
        }
        try expect(noMatchRow.reasons.contains("no_plan_link"), "a missing plan must be explained independently from a timetable link")
        try expect(noMatchRow.reasons.contains("no_timetable_link"), "a missing timetable must be explained")

        let frequencyInspection = try fixtureInspection(route: route, secondTrip: secondTrip, thirdTrip: thirdTrip, containsFrequenciesFile: true)
        let frequencyMatrix = RegionalCoverageMatrixBuilder.build(
            serviceDate: serviceDate,
            references: [reference],
            inspection: frequencyInspection,
            documents: documents,
            geometries: [geometry]
        )
        try expect(frequencyMatrix.lines[0].activityStatus == .frequencyExpansionNotEvaluable, "frequency-based service must not claim exact departures")
        try expect(frequencyMatrix.lines[0].routeVariants[0].activeDepartureCount == nil, "frequency expansion must leave exact departure count unknown")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        try expect(try encoder.encode(matrix) == encoder.encode(matrix), "matrix JSON encoding should be deterministic")
        print("PASS: regional line coverage preserves source rows, dates, route variants, activity, trip shapes, commercial geometry, documents, and uncertainty reasons")
    }

    private static func fixtureInspection(
        route: GTFSRouteSummary,
        secondTrip: GTFSServiceTripSchedule,
        thirdTrip: GTFSServiceTripSchedule,
        containsFrequenciesFile: Bool
    ) throws -> GTFSFeedInspection {
        let firstTrip = GTFSServiceTripSchedule(
            tripID: "trip-1",
            routeID: route.routeID,
            serviceID: "weekday",
            directionID: "0",
            headsign: "Terminus A",
            stops: [],
            shapeID: "shape-1"
        )
        let quality = GTFSImportQuality(
            busTripCount: 3,
            tripScheduleCount: 3,
            tripsWithoutStopTimes: 0,
            tripsWithIncompleteTimes: 0,
            tripsWithInvalidChronology: 0,
            tripsWithMissingStopCoordinates: 0,
            tripsWithMissingStopRecords: 0,
            tripsWithTooFewStops: 0,
            tripsWithInvalidStopSequence: 0,
            tripsWithoutShapeReference: 1,
            tripsWithUnavailableShape: 1,
            tripsWithUnmatchedShapeStops: 0,
            referencedShapeCount: 2,
            availableShapeCount: 1,
            invalidShapeCount: 1,
            invalidShapeIDs: ["invalid-shape"],
            invalidStopTimeRowCount: 0,
            missingStopIDRowCount: 0,
            tripsWithoutActiveServiceDates: 0,
            containsFrequenciesFile: containsFrequenciesFile,
            tripIssues: []
        )
        return GTFSFeedInspection(
            busRouteCount: 1,
            busRoutes: [route],
            busStops: [],
            serviceCalendars: [GTFSServiceCalendar(serviceID: "weekday", activeDates: [20261102])],
            busTripDepartures: [
                GTFSServiceTripDeparture(tripID: "trip-1", routeID: route.routeID, serviceID: "weekday", departureSeconds: 21_600),
                GTFSServiceTripDeparture(tripID: "trip-2", routeID: route.routeID, serviceID: "weekday", departureSeconds: 21_900)
            ],
            busTripSchedules: [firstTrip, secondTrip, thirdTrip],
            busTripShapes: GTFSShapeDataset(
                references: [
                    GTFSServiceTripShapeReference(tripID: "trip-1", shapeID: "shape-1"),
                    GTFSServiceTripShapeReference(tripID: "trip-2", shapeID: "invalid-shape")
                ],
                shapes: [GTFSRouteShape(shapeID: "shape-1", points: [])]
            ),
            transferRuleIndex: nil,
            quality: quality,
            busStopCount: 0,
            feedStopCount: 0,
            validFrom: try requireDate("20261029"),
            validThrough: try requireDate("20261130")
        )
    }

    private static func lineReference(
        id: String,
        idLine: String,
        shortName: String,
        validFrom: String,
        validTo: String,
        mode: String = "bus"
    ) -> NetworkLineReference {
        NetworkLineReference(
            id: id,
            idLine: idLine,
            nameLine: "Test \(shortName)",
            shortNameLine: shortName,
            transportMode: mode,
            transportSubmode: "localBus",
            lineType: "regular",
            operatorRef: "operator-test",
            additionalOperatorsRef: "",
            operatorName: "Test Operator",
            networkName: "Test Network",
            webColor: "#000000",
            validFrom: validFrom,
            validTo: validTo,
            status: "active",
            attributes: [:]
        )
    }

    private static func requireDate(_ value: String) throws -> Date {
        guard let date = GTFSServiceDate.date(from: value) else { throw SmokeError.failed("invalid date fixture") }
        return date
    }

    private static func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        guard try condition() else { throw SmokeError.failed(message) }
    }
}

private enum SmokeError: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case let .failed(message): "Regional coverage smoke failed: \(message)"
        }
    }
}
