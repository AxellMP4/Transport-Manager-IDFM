import CryptoKit
import Foundation

struct GTFSFeedInspection: Sendable {
    let busRouteCount: Int
    let busRoutes: [GTFSRouteSummary]
    let busStops: [GTFSStopSummary]
    let serviceCalendars: [GTFSServiceCalendar]
    let busTripDepartures: [GTFSServiceTripDeparture]
    let busTripSchedules: [GTFSServiceTripSchedule]
    let busTripShapes: GTFSShapeDataset
    let quality: GTFSImportQuality
    let busStopCount: Int
    let feedStopCount: Int
    let validFrom: Date?
    let validThrough: Date?
}

enum GTFSFeedInspectionStage: Equatable, Sendable {
    case readingArchive
    case readingRoutes
    case readingTrips
    case readingStopTimes
    case readingStops
    case readingShapes
    case readingCalendars
    case tripDiagnostics
    case summarizing
    case saving
    case inspectionComplete
    case complete

    var title: String {
        switch self {
        case .readingArchive: "Ouverture de l’archive GTFS"
        case .readingRoutes: "Lecture des lignes GTFS"
        case .readingTrips: "Lecture des courses GTFS"
        case .readingStopTimes: "Lecture des horaires et arrêts desservis"
        case .readingStops: "Lecture des coordonnées des arrêts"
        case .readingShapes: "Lecture des géométries de lignes"
        case .readingCalendars: "Lecture des calendriers de service"
        case .tripDiagnostics: "Analyse des courses, arrêts et géométries"
        case .summarizing: "Calcul des indicateurs de qualité GTFS"
        case .saving: "Enregistrement de la version du réseau"
        case .inspectionComplete: "Analyse GTFS terminée"
        case .complete: "Import GTFS terminé"
        }
    }
}

struct GTFSFeedInspectionProgress: Equatable, Sendable {
    let stage: GTFSFeedInspectionStage
    let completed: Int?
    let total: Int?

    init(stage: GTFSFeedInspectionStage, completed: Int? = nil, total: Int? = nil) {
        self.stage = stage
        self.completed = completed
        self.total = total
    }

    var message: String {
        guard stage == .tripDiagnostics, let completed, let total else { return stage.title }
        return "\(stage.title) · \(completed.formatted()) / \(total.formatted()) courses"
    }

    var fraction: Double? {
        guard stage == .tripDiagnostics, let completed, let total, total > 0 else { return nil }
        return min(1, max(0, Double(completed) / Double(total)))
    }
}

enum GTFSFeedImportError: LocalizedError {
    case invalidArchive
    case missingFiles([String])
    case invalidRoutesTable
    case invalidTripsTable
    case invalidStopTimesTable
    case invalidCalendarTable
    case invalidCalendarDatesTable
    case invalidStopsTable
    case invalidShapesTable
    case noBusRoutes
    case noStops
    case noGeolocatedBusStops
    case noServiceDates

    var errorDescription: String? {
        switch self {
        case .invalidArchive:
            "Ce fichier n’est pas une archive GTFS lisible."
        case let .missingFiles(files):
            "Le GTFS ne contient pas les fichiers requis : \(files.joined(separator: ", "))."
        case .invalidRoutesTable:
            "Le fichier routes.txt ne contient pas les colonnes route_id et route_type attendues."
        case .invalidTripsTable:
            "Le fichier trips.txt ne contient pas les colonnes trip_id, route_id et service_id attendues."
        case .invalidStopTimesTable:
            "Le fichier stop_times.txt ne contient pas les colonnes trip_id, stop_id, stop_sequence et les horaires attendus."
        case .invalidCalendarTable:
            "Le fichier calendar.txt ne contient pas les colonnes de service et de jours de semaine attendues."
        case .invalidCalendarDatesTable:
            "Le fichier calendar_dates.txt ne contient pas les colonnes service_id, date et exception_type attendues."
        case .invalidStopsTable:
            "Le fichier stops.txt ne contient pas les colonnes stop_id, stop_lat et stop_lon attendues."
        case .invalidShapesTable:
            "Le fichier shapes.txt ne contient pas les colonnes de géométrie GTFS attendues."
        case .noBusRoutes:
            "Aucune ligne de bus n’a été trouvée dans le GTFS. Vérifiez que vous avez choisi l’offre IDFM complète."
        case .noStops:
            "Le fichier stops.txt ne contient aucun arrêt ou station."
        case .noGeolocatedBusStops:
            "Aucun arrêt de bus avec coordonnées n’a pu être relié aux courses du GTFS."
        case .noServiceDates:
            "Aucune période de circulation n’a pu être lue dans calendar.txt ou calendar_dates.txt."
        }
    }
}

enum GTFSFeedInspector {
    static func inspect(
        _ archiveURL: URL,
        progress: ((GTFSFeedInspectionProgress) -> Void)? = nil
    ) throws -> GTFSFeedInspection {
        progress?(GTFSFeedInspectionProgress(stage: .readingArchive))
        let archive: ZIPArchiveReader
        do {
            archive = try ZIPArchiveReader(url: archiveURL)
        } catch let error as ZIPArchiveError {
            throw error
        } catch {
            throw GTFSFeedImportError.invalidArchive
        }

        let routesEntry = archive.entry(named: "routes.txt")
        let stopsEntry = archive.entry(named: "stops.txt")
        let tripsEntry = archive.entry(named: "trips.txt")
        let stopTimesEntry = archive.entry(named: "stop_times.txt")
        let calendarEntry = archive.entry(named: "calendar.txt")
        let calendarDatesEntry = archive.entry(named: "calendar_dates.txt")
        let shapesEntry = archive.entry(named: "shapes.txt")

        var missingFiles: [String] = []
        if routesEntry == nil { missingFiles.append("routes.txt") }
        if stopsEntry == nil { missingFiles.append("stops.txt") }
        if tripsEntry == nil { missingFiles.append("trips.txt") }
        if stopTimesEntry == nil { missingFiles.append("stop_times.txt") }
        if calendarEntry == nil && calendarDatesEntry == nil {
            missingFiles.append("calendar.txt ou calendar_dates.txt")
        }
        guard missingFiles.isEmpty else { throw GTFSFeedImportError.missingFiles(missingFiles) }
        guard let routesEntry,
              let stopsEntry,
              let tripsEntry,
              let stopTimesEntry else {
            throw GTFSFeedImportError.invalidArchive
        }

        progress?(GTFSFeedInspectionProgress(stage: .readingRoutes))
        let routeCollector = BusRouteCollector()
        let routesTable = CSVTableReader(columnsOfInterest: ["route_id", "route_type", "route_short_name", "route_long_name"]) {
            routeCollector.consume($0)
        }
        try routesTable.consume(archive.data(for: routesEntry))
        routesTable.finish()
        guard routesTable.hasColumn("route_id"), routesTable.hasColumn("route_type") else {
            throw GTFSFeedImportError.invalidRoutesTable
        }
        guard routeCollector.busRouteCount > 0 else { throw GTFSFeedImportError.noBusRoutes }

        progress?(GTFSFeedInspectionProgress(stage: .readingTrips))
        let tripCollector = BusTripCollector(busRouteIDs: routeCollector.routeIDs)
        let tripsTable = CSVTableReader(columnsOfInterest: ["trip_id", "route_id", "service_id", "direction_id", "trip_headsign", "shape_id"]) {
            tripCollector.consume($0)
        }
        try tripsTable.consume(archive.data(for: tripsEntry))
        tripsTable.finish()
        guard tripsTable.hasColumn("trip_id"), tripsTable.hasColumn("route_id"), tripsTable.hasColumn("service_id") else {
            throw GTFSFeedImportError.invalidTripsTable
        }

        progress?(GTFSFeedInspectionProgress(stage: .readingStopTimes))
        let stopRouteCollector = BusStopRouteCollector(tripByID: tripCollector.tripByID)
        let stopTimesTable = CSVTableReader(columnsOfInterest: ["trip_id", "stop_id", "stop_sequence", "arrival_time", "departure_time", "shape_dist_traveled"]) {
            stopRouteCollector.consume($0)
        }
        try stopTimesTable.consume(archive.data(for: stopTimesEntry))
        stopTimesTable.finish()
        guard stopTimesTable.hasColumn("trip_id"),
              stopTimesTable.hasColumn("stop_id"),
              stopTimesTable.hasColumn("stop_sequence"),
              stopTimesTable.hasColumn("arrival_time") || stopTimesTable.hasColumn("departure_time") else {
            throw GTFSFeedImportError.invalidStopTimesTable
        }

        progress?(GTFSFeedInspectionProgress(stage: .readingStops))
        let stopCollector = BusStopCollector(
            routeIDsByStopID: stopRouteCollector.routeIDsByStopID,
            routeDirectionsByStopID: stopRouteCollector.routeDirectionsByStopID
        )
        let stopsTable = CSVTableReader(columnsOfInterest: ["stop_id", "stop_name", "stop_lat", "stop_lon"]) {
            stopCollector.consume($0)
        }
        try stopsTable.consume(archive.data(for: stopsEntry))
        stopsTable.finish()
        guard stopsTable.hasColumn("stop_id"), stopsTable.rowCount > 0 else {
            throw GTFSFeedImportError.noStops
        }
        guard stopsTable.hasColumn("stop_lat"), stopsTable.hasColumn("stop_lon") else {
            throw GTFSFeedImportError.invalidStopsTable
        }
        guard !stopCollector.stops.isEmpty else { throw GTFSFeedImportError.noGeolocatedBusStops }

        let tripShapeReferences = tripCollector.tripByID.compactMap { tripID, trip in
            trip.shapeID.map { GTFSServiceTripShapeReference(tripID: tripID, shapeID: $0) }
        }.sorted { $0.tripID < $1.tripID }
        let busTripShapes: GTFSShapeDataset
        var invalidShapeIDs = Set<String>()
        if let shapesEntry {
            progress?(GTFSFeedInspectionProgress(stage: .readingShapes))
            let shapeCollector = BusRouteShapeCollector(referencedShapeIDs: Set(tripShapeReferences.map(\.shapeID)))
            let table = CSVTableReader(columnsOfInterest: [
                "shape_id", "shape_pt_lat", "shape_pt_lon", "shape_pt_sequence", "shape_dist_traveled"
            ]) {
                shapeCollector.consume($0)
            }
            try table.consume(archive.data(for: shapesEntry))
            table.finish()
            guard ["shape_id", "shape_pt_lat", "shape_pt_lon", "shape_pt_sequence"].allSatisfy(table.hasColumn) else {
                throw GTFSFeedImportError.invalidShapesTable
            }
            busTripShapes = GTFSShapeDataset(references: tripShapeReferences, shapes: shapeCollector.shapes)
            invalidShapeIDs = shapeCollector.invalidShapeIDs
        } else {
            busTripShapes = GTFSShapeDataset(references: tripShapeReferences, shapes: [])
        }

        progress?(GTFSFeedInspectionProgress(stage: .readingCalendars))
        let busTripSchedules = stopRouteCollector.tripSchedules
        let tripIDs = Set(tripCollector.tripByID.keys)
        let schedulesByTripID = stopRouteCollector.collectedStopTimesByTripID
        let geolocatedStopIDs = Set(stopCollector.stops.map(\.stopID))
        let stopIDsInFeed = stopCollector.stopIDsInFeed
        let availableShapeIDs = Set(busTripShapes.shapes.map(\.shapeID))
        let dateRange = GTFSServiceDateRange()
        let serviceCalendarIndex = GTFSServiceCalendarIndex()
        if let calendarEntry {
            let table = CSVTableReader(columnsOfInterest: [
                "service_id", "start_date", "end_date",
                "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
            ]) {
                dateRange.consumeCalendarRow($0)
                serviceCalendarIndex.consumeCalendarRow($0)
            }
            try table.consume(archive.data(for: calendarEntry))
            table.finish()
            let requiredColumns = [
                "service_id", "start_date", "end_date",
                "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
            ]
            guard requiredColumns.allSatisfy(table.hasColumn) else {
                throw GTFSFeedImportError.invalidCalendarTable
            }
        }
        if let calendarDatesEntry {
            let table = CSVTableReader(columnsOfInterest: ["service_id", "date", "exception_type"]) {
                dateRange.consumeExceptionRow($0)
                serviceCalendarIndex.consumeExceptionRow($0)
            }
            try table.consume(archive.data(for: calendarDatesEntry))
            table.finish()
            let requiredColumns = ["service_id", "date", "exception_type"]
            guard requiredColumns.allSatisfy(table.hasColumn) else {
                throw GTFSFeedImportError.invalidCalendarDatesTable
            }
        }
        guard let validFrom = dateRange.validFrom, let validThrough = dateRange.validThrough else {
            throw GTFSFeedImportError.noServiceDates
        }

        let serviceCalendars = serviceCalendarIndex.calendars
        let serviceIDsWithActiveDates = Set(serviceCalendars.lazy
            .filter { !$0.activeDates.isEmpty }
            .map(\.serviceID))
        let tripsWithoutActiveServiceDates = tripCollector.tripByID.values.filter { trip in
            trip.serviceID.isEmpty || !serviceIDsWithActiveDates.contains(trip.serviceID)
        }.count
        progress?(GTFSFeedInspectionProgress(stage: .tripDiagnostics, completed: 0, total: tripIDs.count))
        let tripIssues = Self.tripIssues(
            tripByID: tripCollector.tripByID,
            schedulesByTripID: schedulesByTripID,
            geolocatedStopIDs: geolocatedStopIDs,
            stopIDsInFeed: stopIDsInFeed,
            availableShapeIDs: availableShapeIDs,
            shapesByID: Dictionary(uniqueKeysWithValues: busTripShapes.shapes.map { ($0.shapeID, $0) }),
            stopsByID: Dictionary(uniqueKeysWithValues: stopCollector.stops.map { ($0.stopID, $0) }),
            serviceIDsWithActiveDates: serviceIDsWithActiveDates,
            invalidStopTimeRowsByTripID: stopRouteCollector.invalidStopTimeRowsByTripID,
            missingStopIDRowsByTripID: stopRouteCollector.missingStopIDRowsByTripID,
            progress: progress
        )
        progress?(GTFSFeedInspectionProgress(stage: .summarizing))
        let quality = GTFSImportQuality(
            busTripCount: tripIDs.count,
            tripScheduleCount: busTripSchedules.count,
            tripsWithoutStopTimes: tripIDs.subtracting(schedulesByTripID.keys).count,
            tripsWithIncompleteTimes: tripIDs.filter { tripID in
                guard let stops = schedulesByTripID[tripID], !stops.isEmpty else { return false }
                return Self.hasIncompleteTimes(stops)
            }.count,
            tripsWithInvalidChronology: tripIDs.filter { tripID in
                guard let stops = schedulesByTripID[tripID], !stops.isEmpty else { return false }
                return Self.hasInvalidChronology(stops)
            }.count,
            tripsWithMissingStopCoordinates: tripIDs.filter { tripID in
                schedulesByTripID[tripID, default: []].contains {
                    stopIDsInFeed.contains($0.stopID) && !geolocatedStopIDs.contains($0.stopID)
                }
            }.count,
            tripsWithMissingStopRecords: tripIDs.filter { tripID in
                schedulesByTripID[tripID, default: []].contains { !stopIDsInFeed.contains($0.stopID) }
            }.count,
            tripsWithTooFewStops: tripIDs.filter { tripID in
                schedulesByTripID[tripID, default: []].count < 2
            }.count,
            tripsWithInvalidStopSequence: tripIDs.filter { tripID in
                Self.hasInvalidStopSequence(schedulesByTripID[tripID, default: []])
            }.count,
            tripsWithoutShapeReference: max(0, tripIDs.count - tripShapeReferences.count),
            tripsWithUnavailableShape: tripShapeReferences.filter { reference in
                !availableShapeIDs.contains(reference.shapeID)
            }.count,
            tripsWithUnmatchedShapeStops: tripIssues.filter {
                $0.issueKinds.contains(.stopsNotMatchedToShape)
            }.count,
            referencedShapeCount: Set(tripShapeReferences.map(\.shapeID)).count,
            availableShapeCount: busTripShapes.shapes.count,
            invalidShapeCount: invalidShapeIDs.count,
            invalidShapeIDs: invalidShapeIDs.sorted(),
            invalidStopTimeRowCount: stopRouteCollector.invalidStopTimeRowCount,
            missingStopIDRowCount: stopRouteCollector.missingStopIDRowCount,
            tripsWithoutActiveServiceDates: tripsWithoutActiveServiceDates,
            containsFrequenciesFile: archive.entry(named: "frequencies.txt") != nil,
            tripIssues: tripIssues
        )

        let inspection = GTFSFeedInspection(
            busRouteCount: routeCollector.busRouteCount,
            busRoutes: routeCollector.routes,
            busStops: stopCollector.stops,
            serviceCalendars: serviceCalendars,
            busTripDepartures: stopRouteCollector.tripDepartures,
            busTripSchedules: busTripSchedules,
            busTripShapes: busTripShapes,
            quality: quality,
            busStopCount: stopCollector.stops.count,
            feedStopCount: stopsTable.rowCount,
            validFrom: validFrom,
            validThrough: validThrough
        )
        progress?(GTFSFeedInspectionProgress(stage: .inspectionComplete))
        return inspection
    }

    private static func hasIncompleteTimes(_ stops: [GTFSServiceTripStopTime]) -> Bool {
        let orderedStops = stops.sorted { $0.stopSequence < $1.stopSequence }
        return orderedStops.enumerated().contains { index, stop in
            let scheduledTime = index == 0 ? stop.departureSeconds : (stop.arrivalSeconds ?? stop.departureSeconds)
            guard let scheduledTime else { return true }
            return stop.departureSeconds.map { $0 < scheduledTime } ?? false
        }
    }

    private static func hasInvalidChronology(_ stops: [GTFSServiceTripStopTime]) -> Bool {
        let orderedStops = stops.sorted {
            if $0.stopSequence != $1.stopSequence { return $0.stopSequence < $1.stopSequence }
            return $0.stopID < $1.stopID
        }
        var previousTime: Int?
        for (index, stop) in orderedStops.enumerated() {
            guard let scheduledTime = index == 0 ? stop.departureSeconds : (stop.arrivalSeconds ?? stop.departureSeconds) else {
                continue
            }
            if let previousTime, scheduledTime < previousTime { return true }
            if let departureTime = stop.departureSeconds, departureTime < scheduledTime { return true }
            previousTime = scheduledTime
        }
        return false
    }

    private static func hasInvalidStopSequence(_ stops: [GTFSServiceTripStopTime]) -> Bool {
        let sequences = stops.map(\.stopSequence).sorted()
        return zip(sequences, sequences.dropFirst()).contains { $0.0 == $0.1 }
    }

    private static func tripIssues(
        tripByID: [String: BusTripReference],
        schedulesByTripID: [String: [GTFSServiceTripStopTime]],
        geolocatedStopIDs: Set<String>,
        stopIDsInFeed: Set<String>,
        availableShapeIDs: Set<String>,
        shapesByID: [String: GTFSRouteShape],
        stopsByID: [String: GTFSStopSummary],
        serviceIDsWithActiveDates: Set<String>,
        invalidStopTimeRowsByTripID: [String: Int],
        missingStopIDRowsByTripID: [String: Int],
        progress: ((GTFSFeedInspectionProgress) -> Void)?
    ) -> [GTFSImportTripIssue] {
        var shapeAlignmentCache: [GTFSStopShapeProjectionKey: GTFSShapeStopAlignment] = [:]
        let tripIDs = tripByID.keys.sorted()
        var issues: [GTFSImportTripIssue] = []
        for (tripIndex, tripID) in tripIDs.enumerated() {
            guard let trip = tripByID[tripID] else { continue }
            let stops = schedulesByTripID[tripID, default: []].sorted {
                if $0.stopSequence != $1.stopSequence { return $0.stopSequence < $1.stopSequence }
                return $0.stopID < $1.stopID
            }
            let invalidRowCount = invalidStopTimeRowsByTripID[tripID, default: 0]
            let missingStopIDRowCount = missingStopIDRowsByTripID[tripID, default: 0]
            let stopIDsMissingFromFeed = stops.compactMap { stopTime in
                stopIDsInFeed.contains(stopTime.stopID) ? nil : stopTime.stopID
            }
            let stopIDsWithoutCoordinates = stops.compactMap { stopTime in
                stopIDsInFeed.contains(stopTime.stopID) && !geolocatedStopIDs.contains(stopTime.stopID)
                    ? stopTime.stopID
                    : nil
            }
            let shapeAlignment: GTFSShapeStopAlignment? = {
                guard stopIDsWithoutCoordinates.isEmpty,
                      stopIDsMissingFromFeed.isEmpty,
                      stops.count >= 2,
                      let shapeID = trip.shapeID,
                      let shape = shapesByID[shapeID] else { return nil }
                let cacheKey = GTFSStopShapeProjectionKey(
                    shapeID: shapeID,
                    stops: stops.map {
                        GTFSStopShapeProjectionKey.Stop(
                            stopID: $0.stopID,
                            stopSequence: $0.stopSequence,
                            shapeDistanceTraveled: $0.shapeDistanceTraveled
                        )
                    }
                )
                if let cachedAlignment = shapeAlignmentCache[cacheKey] { return cachedAlignment }
                let alignment = NetworkVersionStore.projectStopSequenceToShape(
                    stops,
                    stopsByID: stopsByID,
                    shape: shape
                )
                shapeAlignmentCache[cacheKey] = alignment
                return alignment
            }()
            var issueKinds = Set<GTFSImportTripIssueKind>()
            let stopIDsNotMatchedToShape: [String]?
            let stopProjectionDiagnostics: [GTFSStopShapeProjectionDiagnostic]?

            if stops.isEmpty { issueKinds.insert(.missingStopTimes) }
            if !stops.isEmpty, hasIncompleteTimes(stops) { issueKinds.insert(.incompleteTimes) }
            if !stops.isEmpty, hasInvalidChronology(stops) { issueKinds.insert(.invalidChronology) }
            if !stopIDsWithoutCoordinates.isEmpty {
                issueKinds.insert(.missingStopCoordinates)
            }
            if !stopIDsMissingFromFeed.isEmpty { issueKinds.insert(.missingStopRecord) }
            if stops.count < 2 { issueKinds.insert(.tooFewStops) }
            if hasInvalidStopSequence(stops) { issueKinds.insert(.invalidStopSequence) }
            if let shapeID = trip.shapeID {
                if !availableShapeIDs.contains(shapeID) { issueKinds.insert(.unavailableShape) }
            } else {
                issueKinds.insert(.missingShapeReference)
            }
            if stopIDsWithoutCoordinates.isEmpty,
               stopIDsMissingFromFeed.isEmpty,
               let shapeAlignment,
               !shapeAlignment.unmatchedStopIDs.isEmpty {
                issueKinds.insert(.stopsNotMatchedToShape)
                stopIDsNotMatchedToShape = shapeAlignment.unmatchedStopIDs
                stopProjectionDiagnostics = shapeAlignment.diagnostics.isEmpty ? nil : shapeAlignment.diagnostics
            } else {
                stopIDsNotMatchedToShape = nil
                stopProjectionDiagnostics = nil
            }
            if trip.serviceID.isEmpty || !serviceIDsWithActiveDates.contains(trip.serviceID) {
                issueKinds.insert(.inactiveService)
            }
            if invalidRowCount > 0 { issueKinds.insert(.invalidStopTimeRows) }
            if missingStopIDRowCount > 0 { issueKinds.insert(.missingStopID) }

            if !issueKinds.isEmpty {
                issues.append(GTFSImportTripIssue(
                    routeID: trip.routeID,
                    tripID: tripID,
                    shapeID: trip.shapeID,
                    issueKinds: issueKinds,
                    invalidStopTimeRowCount: invalidRowCount,
                    missingStopIDRowCount: missingStopIDRowCount > 0 ? missingStopIDRowCount : nil,
                    stopIDsWithoutCoordinates: stopIDsWithoutCoordinates.isEmpty ? nil : stopIDsWithoutCoordinates,
                    stopIDsMissingFromFeed: stopIDsMissingFromFeed.isEmpty ? nil : stopIDsMissingFromFeed,
                    stopIDsNotMatchedToShape: stopIDsNotMatchedToShape,
                    stopProjectionDiagnostics: stopProjectionDiagnostics,
                    orderedStopSequence: stops.isEmpty ? nil : stops.map {
                        GTFSStopSequenceEntry(stopID: $0.stopID, stopSequence: $0.stopSequence)
                    }
                ))
            }
            if (tripIndex + 1).isMultiple(of: 5_000) || tripIndex + 1 == tripIDs.count {
                progress?(GTFSFeedInspectionProgress(
                    stage: .tripDiagnostics,
                    completed: tripIndex + 1,
                    total: tripIDs.count
                ))
            }
        }
        return issues
    }
}

private final class BusRouteCollector {
    private var routesByID: [String: GTFSRouteSummary] = [:]

    var busRouteCount: Int { routesByID.count }
    var routeIDs: Set<String> { Set(routesByID.keys) }
    var routes: [GTFSRouteSummary] {
        routesByID.values.sorted {
            let left = $0.displayName.localizedStandardCompare($1.displayName)
            return left == .orderedSame ? $0.routeID < $1.routeID : left == .orderedAscending
        }
    }

    func consume(_ row: [String: String]) {
        guard let routeID = row["route_id"], !routeID.isEmpty,
              let routeType = Int(row["route_type"] ?? "") else { return }

        let isBus = routeType == 3 || (700...799).contains(routeType)
        if isBus {
            routesByID[routeID] = GTFSRouteSummary(
                routeID: routeID,
                shortName: (row["route_short_name"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                longName: (row["route_long_name"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }
}

private final class BusTripCollector {
    private let busRouteIDs: Set<String>
    private(set) var tripByID: [String: BusTripReference] = [:]

    init(busRouteIDs: Set<String>) {
        self.busRouteIDs = busRouteIDs
    }

    func consume(_ row: [String: String]) {
        guard let tripID = row["trip_id"], !tripID.isEmpty,
              let routeID = row["route_id"], busRouteIDs.contains(routeID) else { return }
        let rawShapeID = row["shape_id"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        tripByID[tripID] = BusTripReference(
            routeID: routeID,
            serviceID: (row["service_id"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            directionID: (row["direction_id"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            headsign: (row["trip_headsign"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            shapeID: rawShapeID?.isEmpty == false ? rawShapeID : nil
        )
    }
}

private struct BusTripReference {
    let routeID: String
    let serviceID: String
    let directionID: String
    let headsign: String
    let shapeID: String?
}

private struct GTFSShapeStopAlignment {
    let progresses: [Double]?
    let unmatchedStopIDs: [String]
    let diagnostics: [GTFSStopShapeProjectionDiagnostic]
}

private struct GTFSShapeProjectionCandidate {
    let errorMeters: Double
    let progress: Double
    let segment: Int
}

private struct GTFSShapeProjectionPathState {
    let candidate: GTFSShapeProjectionCandidate
    let cost: Double
    let predecessorIndex: Int?
}

private struct GTFSStopShapeProjectionKey: Hashable {
    struct Stop: Hashable {
        let stopID: String
        let stopSequence: Int
        let shapeDistanceTraveled: Double?
    }

    let shapeID: String
    let stops: [Stop]
}

private struct BusStopDirectionKey: Hashable {
    let routeID: String
    let directionID: String
    let headsign: String
}

private struct BusStopDirectionSchedule {
    var serviceHours: Set<GTFSServiceHour> = []
    var hasIncompleteSchedule = false
}

private final class BusRouteShapeCollector {
    private let referencedShapeIDs: Set<String>
    private var pointsByShapeID: [String: [GTFSShapePoint]] = [:]
    private var malformedPointShapeIDs = Set<String>()

    var shapes: [GTFSRouteShape] {
        pointsByShapeID.compactMap { shapeID, points in
            let ordered = points.sorted {
                if $0.sequence != $1.sequence { return $0.sequence < $1.sequence }
                if $0.latitude != $1.latitude { return $0.latitude < $1.latitude }
                return $0.longitude < $1.longitude
            }
            guard !malformedPointShapeIDs.contains(shapeID),
                  ordered.count >= 2,
                  Set(ordered.map(\.sequence)).count == ordered.count,
                  hasPositiveLength(ordered) else { return nil }
            return GTFSRouteShape(shapeID: shapeID, points: ordered)
        }
        .sorted { $0.shapeID < $1.shapeID }
    }

    var invalidShapeIDs: Set<String> {
        var invalidIDs = malformedPointShapeIDs
        for (shapeID, points) in pointsByShapeID {
            let sequences = points.map(\.sequence)
            if points.count < 2 || Set(sequences).count != sequences.count {
                invalidIDs.insert(shapeID)
            } else if !hasPositiveLength(points.sorted { $0.sequence < $1.sequence }) {
                invalidIDs.insert(shapeID)
            }
        }
        return invalidIDs
    }

    private func hasPositiveLength(_ points: [GTFSShapePoint]) -> Bool {
        guard points.count >= 2 else { return false }
        for (previous, current) in zip(points, points.dropFirst()) {
            let meanLatitude = (previous.latitude + current.latitude) / 2 * .pi / 180
            let deltaX = (current.longitude - previous.longitude) * cos(meanLatitude) * 111_320
            let deltaY = (current.latitude - previous.latitude) * 111_320
            if hypot(deltaX, deltaY) > 0 { return true }
        }
        return false
    }

    init(referencedShapeIDs: Set<String>) {
        self.referencedShapeIDs = referencedShapeIDs
    }

    func consume(_ row: [String: String]) {
        guard let shapeID = row["shape_id"], referencedShapeIDs.contains(shapeID) else { return }
        guard let sequence = Int((row["shape_pt_sequence"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)), sequence >= 0,
              let latitude = Double((row["shape_pt_lat"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double((row["shape_pt_lon"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)),
              latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            malformedPointShapeIDs.insert(shapeID)
            return
        }
        let rawDistance = row["shape_dist_traveled"].flatMap(Double.init)
        let distance = rawDistance.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        pointsByShapeID[shapeID, default: []].append(GTFSShapePoint(
            sequence: sequence,
            latitude: latitude,
            longitude: longitude,
            distanceTraveled: distance
        ))
    }
}

private final class BusStopRouteCollector {
    private let tripByID: [String: BusTripReference]
    private var routeIDsByStopIDStorage: [String: Set<String>] = [:]
    private var routeDirectionsByStopIDStorage: [String: [BusStopDirectionKey: BusStopDirectionSchedule]] = [:]
    private var firstStopByTripID: [String: (stopSequence: Int, departureSeconds: Int?)] = [:]
    private var stopTimesByTripID: [String: [GTFSServiceTripStopTime]] = [:]
    private(set) var invalidStopTimeRowCount = 0
    private(set) var invalidStopTimeRowsByTripID: [String: Int] = [:]
    private(set) var missingStopIDRowCount = 0
    private(set) var missingStopIDRowsByTripID: [String: Int] = [:]

    var routeIDsByStopID: [String: Set<String>] { routeIDsByStopIDStorage }
    var collectedStopTimesByTripID: [String: [GTFSServiceTripStopTime]] { stopTimesByTripID }
    var tripDepartures: [GTFSServiceTripDeparture] {
        firstStopByTripID.compactMap { tripID, firstStop in
            guard let trip = tripByID[tripID], !trip.serviceID.isEmpty,
                  let departureSeconds = firstStop.departureSeconds else { return nil }
            return GTFSServiceTripDeparture(
                tripID: tripID,
                routeID: trip.routeID,
                serviceID: trip.serviceID,
                departureSeconds: departureSeconds
            )
        }
        .sorted {
            if $0.serviceID != $1.serviceID { return $0.serviceID < $1.serviceID }
            return $0.tripID < $1.tripID
        }
    }
    var tripSchedules: [GTFSServiceTripSchedule] {
        stopTimesByTripID.compactMap { tripID, stops in
            guard let trip = tripByID[tripID], !trip.serviceID.isEmpty, !stops.isEmpty else { return nil }
            return GTFSServiceTripSchedule(
                tripID: tripID,
                routeID: trip.routeID,
                serviceID: trip.serviceID,
                directionID: trip.directionID.isEmpty ? nil : trip.directionID,
                headsign: trip.headsign.isEmpty ? nil : trip.headsign,
                stops: stops.sorted {
                    if $0.stopSequence != $1.stopSequence { return $0.stopSequence < $1.stopSequence }
                    return $0.stopID < $1.stopID
                },
                shapeID: trip.shapeID
            )
        }
        .sorted { $0.tripID < $1.tripID }
    }
    var routeDirectionsByStopID: [String: [GTFSStopRouteDirection]] {
        routeDirectionsByStopIDStorage.mapValues { directions in
            directions.map { key, schedule in
                GTFSStopRouteDirection(
                    routeID: key.routeID,
                    directionID: key.directionID,
                    headsign: key.headsign,
                    serviceHours: schedule.serviceHours.sorted {
                        if $0.serviceID != $1.serviceID { return $0.serviceID < $1.serviceID }
                        return $0.hourOffset < $1.hourOffset
                    },
                    hasIncompleteSchedule: schedule.hasIncompleteSchedule
                )
            }
            .sorted {
                if $0.routeID != $1.routeID { return $0.routeID < $1.routeID }
                if $0.headsign != $1.headsign { return $0.headsign < $1.headsign }
                return $0.directionID < $1.directionID
            }
        }
    }

    init(tripByID: [String: BusTripReference]) {
        self.tripByID = tripByID
    }

    func consume(_ row: [String: String]) {
        guard let tripID = row["trip_id"],
              let trip = tripByID[tripID] else { return }
        guard let stopID = row["stop_id"], !stopID.isEmpty else {
            invalidStopTimeRowCount += 1
            invalidStopTimeRowsByTripID[tripID, default: 0] += 1
            missingStopIDRowCount += 1
            missingStopIDRowsByTripID[tripID, default: 0] += 1
            return
        }

        if let sequence = Int((row["stop_sequence"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)), sequence >= 0 {
            stopTimesByTripID[tripID, default: []].append(GTFSServiceTripStopTime(
                stopID: stopID,
                stopSequence: sequence,
                arrivalSeconds: GTFSClockTime.secondsOffset(from: row["arrival_time"]),
                departureSeconds: GTFSClockTime.secondsOffset(from: row["departure_time"]),
                shapeDistanceTraveled: row["shape_dist_traveled"].flatMap(Double.init).flatMap {
                    $0.isFinite && $0 >= 0 ? $0 : nil
                }
            ))
            let seconds = GTFSClockTime.secondsOffset(from: row["departure_time"])
            if let currentFirstStop = firstStopByTripID[tripID] {
                if sequence < currentFirstStop.stopSequence {
                    firstStopByTripID[tripID] = (sequence, seconds)
                } else if sequence == currentFirstStop.stopSequence,
                          currentFirstStop.departureSeconds == nil,
                          let seconds {
                    firstStopByTripID[tripID] = (sequence, seconds)
                }
            } else {
                firstStopByTripID[tripID] = (sequence, seconds)
            }
        } else {
            invalidStopTimeRowCount += 1
            invalidStopTimeRowsByTripID[tripID, default: 0] += 1
        }

        routeIDsByStopIDStorage[stopID, default: []].insert(trip.routeID)
        guard !trip.headsign.isEmpty || !trip.directionID.isEmpty else { return }
        let direction = BusStopDirectionKey(
            routeID: trip.routeID,
            directionID: trip.directionID,
            headsign: trip.headsign
        )
        var directions = routeDirectionsByStopIDStorage[stopID, default: [:]]
        var schedule = directions[direction, default: BusStopDirectionSchedule()]
        let departureTime = row["departure_time"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let arrivalTime = row["arrival_time"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let time = departureTime?.isEmpty == false ? departureTime : arrivalTime
        if !trip.serviceID.isEmpty,
           let hourOffset = GTFSClockTime.hourOffset(from: time) {
            schedule.serviceHours.insert(GTFSServiceHour(serviceID: trip.serviceID, hourOffset: hourOffset))
        } else {
            schedule.hasIncompleteSchedule = true
        }
        directions[direction] = schedule
        routeDirectionsByStopIDStorage[stopID] = directions
    }
}

private enum GTFSClockTime {
    static func secondsOffset(from value: String?) -> Int? {
        guard let value else { return nil }
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = cleanedValue.split(separator: ":", omittingEmptySubsequences: false)
        guard components.count == 3,
              components.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              let second = Int(components[2]),
              (0...99).contains(hour), (0..<60).contains(minute), (0..<60).contains(second) else { return nil }
        return hour * 3_600 + minute * 60 + second
    }

    static func hourOffset(from value: String?) -> Int? {
        secondsOffset(from: value).map { $0 / 3_600 }
    }

    static func date(serviceDateKey: Int, secondsOffset: Int, calendar: Calendar) -> Date? {
        guard secondsOffset >= 0 else { return nil }
        let year = serviceDateKey / 10_000
        let month = (serviceDateKey / 100) % 100
        let day = serviceDateKey % 100
        var serviceComponents = DateComponents()
        serviceComponents.calendar = calendar
        serviceComponents.timeZone = calendar.timeZone
        serviceComponents.year = year
        serviceComponents.month = month
        serviceComponents.day = day

        let dayOffset = secondsOffset / 86_400
        let secondsInDay = secondsOffset % 86_400
        guard let serviceDay = calendar.date(from: serviceComponents),
              calendar.component(.year, from: serviceDay) == year,
              calendar.component(.month, from: serviceDay) == month,
              calendar.component(.day, from: serviceDay) == day,
              let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: serviceDay) else { return nil }
        var timeComponents = calendar.dateComponents([.era, .year, .month, .day], from: targetDay)
        timeComponents.calendar = calendar
        timeComponents.timeZone = calendar.timeZone
        timeComponents.hour = secondsInDay / 3_600
        timeComponents.minute = (secondsInDay % 3_600) / 60
        timeComponents.second = secondsInDay % 60
        guard let departure = calendar.date(from: timeComponents) else { return nil }
        let resolvedTime = calendar.dateComponents([.hour, .minute, .second], from: departure)
        guard resolvedTime.hour == timeComponents.hour,
              resolvedTime.minute == timeComponents.minute,
              resolvedTime.second == timeComponents.second else { return nil }
        return departure
    }
}

private enum GTFSTripScheduleError: LocalizedError {
    case missingTrip(String)
    case missingStopCoordinates(String)
    case missingStopTime(String)
    case outOfOrderTimes
    case tooFewStops

    var errorDescription: String? {
        switch self {
        case let .missingTrip(tripID):
            "La course GTFS \(tripID) n’a pas de séquence d’arrêts archivée."
        case let .missingStopCoordinates(stopID):
            "L’arrêt GTFS \(stopID) n’a pas de coordonnées exploitables."
        case let .missingStopTime(stopID):
            "L’arrêt GTFS \(stopID) n’a pas d’horaire exploitable ; aucun passage n’a été inventé."
        case .outOfOrderTimes:
            "Les horaires GTFS de cette course ne sont pas chronologiques."
        case .tooFewStops:
            "La course GTFS ne contient pas assez d’arrêts géolocalisés pour être affectée."
        }
    }
}

private final class BusStopCollector {
    private let routeIDsByStopID: [String: Set<String>]
    private let routeDirectionsByStopID: [String: [GTFSStopRouteDirection]]
    private var stopsByID: [String: GTFSStopSummary] = [:]
    private(set) var stopIDsInFeed = Set<String>()

    var stops: [GTFSStopSummary] {
        stopsByID.values.sorted {
            let nameOrder = $0.name.localizedStandardCompare($1.name)
            return nameOrder == .orderedSame ? $0.stopID < $1.stopID : nameOrder == .orderedAscending
        }
    }

    init(
        routeIDsByStopID: [String: Set<String>],
        routeDirectionsByStopID: [String: [GTFSStopRouteDirection]]
    ) {
        self.routeIDsByStopID = routeIDsByStopID
        self.routeDirectionsByStopID = routeDirectionsByStopID
    }

    func consume(_ row: [String: String]) {
        guard let stopID = row["stop_id"], !stopID.isEmpty else { return }
        stopIDsInFeed.insert(stopID)
        guard
              let routeIDs = routeIDsByStopID[stopID],
              let latitude = Double(row["stop_lat"] ?? ""), latitude.isFinite,
              (-90...90).contains(latitude),
              let longitude = Double(row["stop_lon"] ?? ""), longitude.isFinite,
              (-180...180).contains(longitude) else { return }

        let name = (row["stop_name"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        stopsByID[stopID] = GTFSStopSummary(
            stopID: stopID,
            name: name.isEmpty ? stopID : name,
            latitude: latitude,
            longitude: longitude,
            routeIDs: routeIDs.sorted(),
            routeDirections: routeDirectionsByStopID[stopID] ?? []
        )
    }
}

private final class GTFSServiceDateRange {
    private(set) var validFrom: Date?
    private(set) var validThrough: Date?

    func consumeCalendarRow(_ row: [String: String]) {
        include(start: row["start_date"], end: row["end_date"])
    }

    func consumeExceptionRow(_ row: [String: String]) {
        guard Int(row["exception_type"] ?? "") == 1 else { return }
        include(start: row["date"], end: row["date"])
    }

    private func include(start: String?, end: String?) {
        if let start, let date = Self.parseDate(start) {
            validFrom = min(validFrom ?? date, date)
        }
        if let end, let date = Self.parseDate(end) {
            validThrough = max(validThrough ?? date, date)
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        GTFSServiceDate.date(from: value)
    }
}

enum GTFSServiceDate {
    static let parisTimeZone = TimeZone(identifier: "Europe/Paris") ?? TimeZone(secondsFromGMT: 0) ?? .current

    static func calendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func date(from value: String) -> Date? {
        guard value.count == 8, value.allSatisfy(\.isNumber) else { return nil }
        let year = Int(value.prefix(4)) ?? 0
        let monthStart = value.index(value.startIndex, offsetBy: 4)
        let dayStart = value.index(monthStart, offsetBy: 2)
        guard let month = Int(value[monthStart..<dayStart]),
              let day = Int(value[dayStart...]) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = calendar(timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
        guard let date = calendar.date(from: components),
              calendar.component(.year, from: date) == year,
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == day else { return nil }
        return date
    }

    static func key(for date: Date, timeZone: TimeZone) -> Int? {
        let components = calendar(timeZone: timeZone).dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else { return nil }
        return year * 10_000 + month * 100 + day
    }

    static func key(from value: String) -> Int? {
        guard let date = date(from: value) else { return nil }
        return key(for: date, timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
    }
}

private final class GTFSServiceCalendarIndex {
    private let weekdayColumns = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    private var activeDatesByServiceID: [String: Set<Int>] = [:]
    private var exceptionByServiceID: [String: [Int: Bool]] = [:]

    func consumeCalendarRow(_ row: [String: String]) {
        guard let serviceID = Self.cleaned(row["service_id"]),
              let startValue = row["start_date"],
              let endValue = row["end_date"],
              let startDate = GTFSServiceDate.date(from: startValue),
              let endDate = GTFSServiceDate.date(from: endValue),
              startDate <= endDate else { return }

        if activeDatesByServiceID[serviceID] == nil {
            activeDatesByServiceID[serviceID] = []
        }
        let calendar = GTFSServiceDate.calendar(timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
        var date = startDate
        while date <= endDate {
            let weekday = calendar.component(.weekday, from: date)
            let column = weekdayColumns[weekday - 1]
            if row[column] == "1", let dateKey = GTFSServiceDate.key(for: date, timeZone: calendar.timeZone) {
                activeDatesByServiceID[serviceID, default: []].insert(dateKey)
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
    }

    func consumeExceptionRow(_ row: [String: String]) {
        guard let serviceID = Self.cleaned(row["service_id"]),
              let dateValue = row["date"],
              let dateKey = GTFSServiceDate.key(from: dateValue),
              let exceptionType = Int(row["exception_type"] ?? "") else { return }
        switch exceptionType {
        case 1:
            exceptionByServiceID[serviceID, default: [:]][dateKey] = true
        case 2:
            exceptionByServiceID[serviceID, default: [:]][dateKey] = false
        default:
            break
        }
    }

    var calendars: [GTFSServiceCalendar] {
        let serviceIDs = Set(activeDatesByServiceID.keys).union(exceptionByServiceID.keys)
        return serviceIDs.sorted().map { serviceID in
            var activeDates = activeDatesByServiceID[serviceID] ?? []
            for (date, isActive) in exceptionByServiceID[serviceID] ?? [:] {
                if isActive {
                    activeDates.insert(date)
                } else {
                    activeDates.remove(date)
                }
            }
            return GTFSServiceCalendar(serviceID: serviceID, activeDates: activeDates.sorted())
        }
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let value else { return nil }
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}

final class CSVTableReader {
    private let columnsOfInterest: Set<String>
    private let captureAllColumns: Bool
    private let onRow: ([String: String]) -> Void
    private var headers: [String]?
    private var fieldSeparator: UInt8 = 0x2C
    private var hasDetectedFieldSeparator = false
    private var fieldBytes: [UInt8] = []
    private var rowFields: [String] = []
    private var isInsideQuotedField = false
    private var quotePending = false
    private var skipLineFeedAfterCarriageReturn = false

    private(set) var rowCount = 0

    init(
        columnsOfInterest: Set<String>,
        captureAllColumns: Bool = false,
        onRow: @escaping ([String: String]) -> Void
    ) {
        self.columnsOfInterest = columnsOfInterest
        self.captureAllColumns = captureAllColumns
        self.onRow = onRow
    }

    func hasColumn(_ name: String) -> Bool {
        headers?.contains(name) == true
    }

    func consume(_ data: Data) throws {
        if !hasDetectedFieldSeparator {
            fieldSeparator = Self.detectFieldSeparator(in: data)
            hasDetectedFieldSeparator = true
        }
        for byte in data {
            consume(byte)
        }
    }

    private static func detectFieldSeparator(in data: Data) -> UInt8 {
        var counts: [UInt8: Int] = [0x2C: 0, 0x3B: 0, 0x09: 0]
        var isInsideQuotedField = false
        var index = data.startIndex

        while index < data.endIndex {
            let byte = data[index]
            if byte == 0x22 {
                let nextIndex = data.index(after: index)
                if isInsideQuotedField, nextIndex < data.endIndex, data[nextIndex] == 0x22 {
                    index = data.index(after: nextIndex)
                    continue
                }
                isInsideQuotedField.toggle()
            } else if !isInsideQuotedField {
                if byte == 0x0A || byte == 0x0D { break }
                if counts[byte] != nil { counts[byte, default: 0] += 1 }
            }
            index = data.index(after: index)
        }

        var separator: UInt8 = 0x2C
        for candidate: UInt8 in [0x3B, 0x09] where counts[candidate, default: 0] > counts[separator, default: 0] {
            separator = candidate
        }
        return separator
    }

    func finish() {
        if quotePending {
            quotePending = false
            isInsideQuotedField = false
        }
        guard !fieldBytes.isEmpty || !rowFields.isEmpty else { return }
        finishRecord()
    }

    private func consume(_ byte: UInt8) {
        if skipLineFeedAfterCarriageReturn {
            skipLineFeedAfterCarriageReturn = false
            if byte == 0x0A { return }
        }

        if isInsideQuotedField {
            if quotePending {
                if byte == 0x22 {
                    fieldBytes.append(0x22)
                    quotePending = false
                    return
                }
                quotePending = false
                isInsideQuotedField = false
                consumeOutsideQuotes(byte)
                return
            }
            if byte == 0x22 {
                quotePending = true
            } else {
                fieldBytes.append(byte)
            }
            return
        }

        consumeOutsideQuotes(byte)
    }

    private func consumeOutsideQuotes(_ byte: UInt8) {
        switch byte {
        case 0x22 where fieldBytes.isEmpty:
            isInsideQuotedField = true
        case let separator where separator == fieldSeparator:
            finishField()
        case 0x0D:
            finishRecord()
            skipLineFeedAfterCarriageReturn = true
        case 0x0A:
            finishRecord()
        default:
            fieldBytes.append(byte)
        }
    }

    private func finishField() {
        rowFields.append(String(decoding: fieldBytes, as: UTF8.self))
        fieldBytes.removeAll(keepingCapacity: true)
    }

    private func finishRecord() {
        finishField()
        if headers == nil {
            headers = rowFields.enumerated().map { index, value in
                let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return index == 0 ? normalized.replacingOccurrences(of: "\u{FEFF}", with: "") : normalized
            }
        } else if !rowFields.allSatisfy(\.isEmpty) {
            rowCount += 1
            var values: [String: String] = [:]
            for (index, header) in (headers ?? []).enumerated() where captureAllColumns || columnsOfInterest.contains(header) {
                guard index < rowFields.count else { continue }
                values[header] = rowFields[index]
            }
            onRow(values)
        }
        rowFields.removeAll(keepingCapacity: true)
    }
}

private enum NetworkVersionStoreError: LocalizedError {
    case versionNotFound
    case archiveUnavailable
    case archiveChecksumMismatch

    var errorDescription: String? {
        switch self {
        case .versionNotFound: "La version GTFS à actualiser est introuvable."
        case .archiveUnavailable: "L’archive GTFS conservée localement est indisponible."
        case .archiveChecksumMismatch: "L’archive locale ne correspond plus à l’empreinte de la version; l’audit n’a pas été remplacé."
        }
    }
}

enum NetworkVersionStore {
    private static let folderName = "TransportManagerIDFM"
    private static let catalogFilename = "NetworkCatalog.json"

    static func rootDirectory() throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return base.appending(path: folderName, directoryHint: .isDirectory)
    }

    static func loadCatalog() throws -> NetworkCatalog {
        let catalogURL = try rootDirectory().appending(path: catalogFilename)
        guard FileManager.default.fileExists(atPath: catalogURL.path) else { return .initial }
        let data = try Data(contentsOf: catalogURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(NetworkCatalog.self, from: data)
    }

    static func saveCatalog(_ catalog: NetworkCatalog) throws {
        let root = try rootDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(catalog).write(to: root.appending(path: catalogFilename), options: .atomic)
    }

    static func refreshTripIssueSequences(for versionID: String) throws -> NetworkCatalog {
        let initialCatalog = try loadCatalog()
        guard let version = initialCatalog.versions.first(where: { $0.id == versionID }) else {
            throw NetworkVersionStoreError.versionNotFound
        }
        guard let archiveURL = version.archiveURL,
              FileManager.default.fileExists(atPath: archiveURL.path) else {
            throw NetworkVersionStoreError.archiveUnavailable
        }
        guard try digest(of: archiveURL) == version.sha256 else {
            throw NetworkVersionStoreError.archiveChecksumMismatch
        }

        let quality = try GTFSFeedInspector.inspect(archiveURL).quality
        var latestCatalog = try loadCatalog()
        guard let versionIndex = latestCatalog.versions.firstIndex(where: { $0.id == versionID }) else {
            throw NetworkVersionStoreError.versionNotFound
        }
        latestCatalog.versions[versionIndex].gtfsQuality = quality
        try saveCatalog(latestCatalog)
        return latestCatalog
    }

    static func importGTFS(
        from sourceURL: URL,
        provenance: GTFSImportProvenance = .unverifiedManual,
        progress: ((GTFSFeedInspectionProgress) -> Void)? = nil
    ) throws -> NetworkCatalog {
        let inspection = try GTFSFeedInspector.inspect(sourceURL, progress: progress)
        progress?(GTFSFeedInspectionProgress(stage: .saving))
        let sha256 = try digest(of: sourceURL)
        let versionFolderName = String(sha256.prefix(20))
        let relativeArchivePath = "versions/\(versionFolderName)/idfm-gtfs.zip"
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(versionFolderName)", directoryHint: .isDirectory)
        let archiveDestination = root.appending(path: relativeArchivePath)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: versionDirectory, withIntermediateDirectories: true)
        if !fileManager.fileExists(atPath: archiveDestination.path) {
            try fileManager.copyItem(at: sourceURL, to: archiveDestination)
        }
        let indexEncoder = JSONEncoder()
        indexEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try indexEncoder.encode(inspection.busRoutes).write(
            to: versionDirectory.appending(path: "bus-routes.json"),
            options: .atomic
        )
        try indexEncoder.encode(inspection.busStops).write(
            to: versionDirectory.appending(path: "bus-stops.json"),
            options: .atomic
        )
        try indexEncoder.encode(inspection.serviceCalendars).write(
            to: versionDirectory.appending(path: "service-calendars.json"),
            options: .atomic
        )
        try indexEncoder.encode(inspection.busTripDepartures).write(
            to: versionDirectory.appending(path: "trip-departures.json"),
            options: .atomic
        )
        try indexEncoder.encode(inspection.busTripSchedules).write(
            to: versionDirectory.appending(path: "trip-stop-times-v2.json"),
            options: .atomic
        )
        try indexEncoder.encode(inspection.busTripShapes).write(
            to: versionDirectory.appending(path: "trip-shapes.json"),
            options: .atomic
        )

        let source = provenance.metadata
        let version = NetworkVersion(
            id: sha256,
            importedAt: Date(),
            validFrom: inspection.validFrom,
            validThrough: inspection.validThrough,
            sourceIDs: ["gtfs"],
            sourceDatasetID: source.datasetID,
            sourceTitle: source.title,
            sourceURL: source.url,
            license: source.license,
            licenseURL: source.licenseURL,
            sourceProvenanceIsDeclared: provenance != .unverifiedManual,
            originalFilename: sourceURL.lastPathComponent,
            archiveRelativePath: relativeArchivePath,
            sha256: sha256,
            busRouteCount: inspection.busRouteCount,
            busStopCount: inspection.busStopCount,
            feedStopCount: inspection.feedStopCount,
            gtfsQuality: inspection.quality
        )

        var catalog = try loadCatalog()
        catalog.versions.removeAll { $0.id == version.id }
        catalog.versions.append(version)
        catalog.versions.sort { $0.importedAt < $1.importedAt }
        catalog.activeVersionID = version.id
        catalog.sources = catalog.sources.map { source in
            var updated = source
            if source.id == "gtfs" { updated.state = .imported }
            return updated
        }
        LineReferenceStore.refreshCoverage(
            in: &catalog,
            routes: inspection.busRoutes,
            forGTFSVersionID: version.id
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let manifest = try encoder.encode(version)
        try manifest.write(to: versionDirectory.appending(path: "manifest.json"), options: .atomic)
        let catalogData = try encoder.encode(catalog)
        try catalogData.write(to: root.appending(path: catalogFilename), options: .atomic)
        progress?(GTFSFeedInspectionProgress(stage: .complete))
        return catalog
    }

    static func loadBusRoutes(for version: NetworkVersion) throws -> [GTFSRouteSummary] {
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let routesURL = versionDirectory.appending(path: "bus-routes.json")
        return try JSONDecoder().decode([GTFSRouteSummary].self, from: Data(contentsOf: routesURL))
    }

    static func loadBusStops(for version: NetworkVersion) throws -> [GTFSStopSummary] {
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let stopsURL = versionDirectory.appending(path: "bus-stops.json")
        return try JSONDecoder().decode([GTFSStopSummary].self, from: Data(contentsOf: stopsURL))
    }

    static func loadServiceCalendars(for version: NetworkVersion) throws -> [GTFSServiceCalendar] {
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let calendarsURL = versionDirectory.appending(path: "service-calendars.json")
        guard FileManager.default.fileExists(atPath: calendarsURL.path) else { return [] }
        return try JSONDecoder().decode([GTFSServiceCalendar].self, from: Data(contentsOf: calendarsURL))
    }

    static func loadTripDepartures(for version: NetworkVersion) throws -> [GTFSServiceTripDeparture] {
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let departuresURL = versionDirectory.appending(path: "trip-departures.json")
        if FileManager.default.fileExists(atPath: departuresURL.path) {
            return try JSONDecoder().decode([GTFSServiceTripDeparture].self, from: Data(contentsOf: departuresURL))
        }

        // Older imported versions keep their source ZIP. Rebuild this index on demand
        // rather than making the player import the same feed again.
        guard let archiveURL = version.archiveURL,
              FileManager.default.fileExists(atPath: archiveURL.path) else { return [] }
        let departures = try GTFSFeedInspector.inspect(archiveURL).busTripDepartures
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(departures).write(to: departuresURL, options: .atomic)
        return departures
    }

    static func loadTripSchedules(for version: NetworkVersion) throws -> [GTFSServiceTripSchedule] {
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let schedulesURL = versionDirectory.appending(path: "trip-stop-times-v2.json")
        if FileManager.default.fileExists(atPath: schedulesURL.path) {
            return try JSONDecoder().decode([GTFSServiceTripSchedule].self, from: Data(contentsOf: schedulesURL))
        }

        guard let archiveURL = version.archiveURL,
              FileManager.default.fileExists(atPath: archiveURL.path) else {
            let legacyURL = versionDirectory.appending(path: "trip-stop-times.json")
            guard FileManager.default.fileExists(atPath: legacyURL.path) else { return [] }
            return try JSONDecoder().decode([GTFSServiceTripSchedule].self, from: Data(contentsOf: legacyURL))
        }
        let schedules = try GTFSFeedInspector.inspect(archiveURL).busTripSchedules
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(schedules).write(to: schedulesURL, options: .atomic)
        return schedules
    }

    static func loadTripMotifs(for version: NetworkVersion) throws -> [GTFSServiceTripMotif] {
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let motifsURL = versionDirectory.appending(path: "trip-motifs-v1.json")
        if FileManager.default.fileExists(atPath: motifsURL.path) {
            return try JSONDecoder().decode([GTFSServiceTripMotif].self, from: Data(contentsOf: motifsURL))
        }

        let schedules = try loadTripSchedules(for: version)
        let motifs = GTFSServiceTripMotifCatalog.build(from: schedules)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(motifs).write(to: motifsURL, options: .atomic)
        return motifs
    }

    static func loadTripShapeDataset(for version: NetworkVersion) throws -> GTFSShapeDataset {
        let root = try rootDirectory()
        let versionDirectory = root.appending(path: "versions/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let shapesURL = versionDirectory.appending(path: "trip-shapes.json")
        if FileManager.default.fileExists(atPath: shapesURL.path) {
            return try JSONDecoder().decode(GTFSShapeDataset.self, from: Data(contentsOf: shapesURL))
        }
        guard let archiveURL = version.archiveURL,
              FileManager.default.fileExists(atPath: archiveURL.path) else {
            return GTFSShapeDataset(references: [], shapes: [])
        }
        let dataset = try GTFSFeedInspector.inspect(archiveURL).busTripShapes
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(dataset).write(to: shapesURL, options: .atomic)
        return dataset
    }

    static func loadTripShape(for version: NetworkVersion, tripID: String) throws -> GTFSRouteShape? {
        let schedules = try loadTripSchedules(for: version)
        let dataset = try loadTripShapeDataset(for: version)
        let shapeID = schedules.first(where: { $0.tripID == tripID })?.shapeID
            ?? dataset.shapeID(for: tripID)
        guard let shapeID else { return nil }
        return dataset.shapes.first(where: { $0.shapeID == shapeID })
    }

    static func loadTripGeometryReview(for version: NetworkVersion, tripID: String) throws -> GTFSGeometryReview? {
        guard let schedule = try loadTripSchedules(for: version).first(where: { $0.tripID == tripID }) else {
            return nil
        }

        let stopsByID = Dictionary(
            try loadBusStops(for: version).map { ($0.stopID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let dataset = try loadTripShapeDataset(for: version)
        let shapeID = schedule.shapeID ?? dataset.shapeID(for: tripID)
        let shape = shapeID.flatMap { id in dataset.shapes.first(where: { $0.shapeID == id }) }
        let stops = schedule.stops.map { stopTime in
            let stop = stopsByID[stopTime.stopID]
            return GTFSGeometryReviewStop(
                stopID: stopTime.stopID,
                sequence: stopTime.stopSequence,
                name: stop?.name,
                latitude: stop?.latitude,
                longitude: stop?.longitude
            )
        }

        return GTFSGeometryReview(
            tripID: tripID,
            routeID: schedule.routeID,
            shapeID: shapeID,
            shapePoints: shape?.points ?? [],
            stops: stops
        )
    }

    static func loadTripShapes(for version: NetworkVersion, tripIDs: Set<String>) throws -> [String: GTFSRouteShape] {
        guard !tripIDs.isEmpty else { return [:] }
        let schedules = try loadTripSchedules(for: version)
        let dataset = try loadTripShapeDataset(for: version)
        let shapeIDsByTripID = Dictionary(
            uniqueKeysWithValues: dataset.references.map { ($0.tripID, $0.shapeID) }
        )
        let shapeIDsByID = Dictionary(uniqueKeysWithValues: dataset.shapes.map { ($0.shapeID, $0) })
        let shapeIDsFromSchedules = Dictionary(
            uniqueKeysWithValues: schedules.compactMap { schedule in
                schedule.shapeID.map { (schedule.tripID, $0) }
            }
        )
        return tripIDs.reduce(into: [:]) { result, tripID in
            guard let shapeID = shapeIDsFromSchedules[tripID] ?? shapeIDsByTripID[tripID],
                  let shape = shapeIDsByID[shapeID] else { return }
            result[tripID] = shape
        }
    }

    static func loadRouteShapes(
        for version: NetworkVersion,
        routeIDs: Set<String>,
        serviceDateKey: Int
    ) throws -> [String: [GTFSRouteShape]] {
        guard !routeIDs.isEmpty else { return [:] }
        let activeServiceIDs = Set(try loadServiceCalendars(for: version).compactMap { calendar in
            calendar.activeDates.contains(serviceDateKey) ? calendar.serviceID : nil
        })
        guard !activeServiceIDs.isEmpty else { return [:] }

        let departures = try loadTripDepartures(for: version).filter {
            routeIDs.contains($0.routeID) && activeServiceIDs.contains($0.serviceID)
        }
        guard !departures.isEmpty else { return [:] }

        let dataset = try loadTripShapeDataset(for: version)
        let shapeIDsByTripID = Dictionary(uniqueKeysWithValues: dataset.references.map { ($0.tripID, $0.shapeID) })
        let shapesByID = Dictionary(uniqueKeysWithValues: dataset.shapes.map { ($0.shapeID, $0) })
        var result: [String: [GTFSRouteShape]] = [:]
        var seenByRoute: [String: Set<String>] = [:]
        for departure in departures {
            guard let shapeID = shapeIDsByTripID[departure.tripID],
                  let shape = shapesByID[shapeID],
                  shape.points.count >= 2,
                  seenByRoute[departure.routeID, default: []].insert(shapeID).inserted else { continue }
            result[departure.routeID, default: []].append(shape)
        }
        return result.mapValues { $0.sorted { $0.shapeID < $1.shapeID } }
    }

    static func loadScheduledTripStopVisits(
        for version: NetworkVersion,
        tripID: String,
        serviceDateKey: Int
    ) throws -> [ScheduledTripStopVisit] {
        guard let schedule = try loadTripSchedules(for: version).first(where: { $0.tripID == tripID }) else {
            throw GTFSTripScheduleError.missingTrip(tripID)
        }
        let stopsByID = Dictionary(uniqueKeysWithValues: try loadBusStops(for: version).map { ($0.stopID, $0) })
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let shapeDataset = try loadTripShapeDataset(for: version)
        let shapeID = schedule.shapeID ?? shapeDataset.shapeID(for: tripID)
        let shape = shapeID.flatMap { id in shapeDataset.shapes.first(where: { $0.shapeID == id }) }
        let shapeAlignment = shape.map {
            Self.projectStopSequenceToShape(schedule.stops, stopsByID: stopsByID, shape: $0)
        }
        let matchedProgresses = shapeAlignment?.progresses
        var visits: [ScheduledTripStopVisit] = []
        var previousTime = Date.distantPast

        for (index, stopTime) in schedule.stops.enumerated() {
            guard let stop = stopsByID[stopTime.stopID] else {
                throw GTFSTripScheduleError.missingStopCoordinates(stopTime.stopID)
            }
            let arrivalAt = stopTime.arrivalSeconds.flatMap {
                GTFSClockTime.date(serviceDateKey: serviceDateKey, secondsOffset: $0, calendar: calendar)
            }
            let departureAt = stopTime.departureSeconds.flatMap {
                GTFSClockTime.date(serviceDateKey: serviceDateKey, secondsOffset: $0, calendar: calendar)
            }
            let scheduledAt = index == 0 ? departureAt : (arrivalAt ?? departureAt)
            guard let scheduledAt else {
                throw GTFSTripScheduleError.missingStopTime(stopTime.stopID)
            }
            guard scheduledAt >= previousTime,
                  departureAt.map({ $0 >= scheduledAt }) ?? true else {
                throw GTFSTripScheduleError.outOfOrderTimes
            }
            previousTime = scheduledAt
            visits.append(ScheduledTripStopVisit(
                stopID: stop.stopID,
                stopName: stop.name,
                stopSequence: stopTime.stopSequence,
                latitude: stop.latitude,
                longitude: stop.longitude,
                scheduledAt: scheduledAt,
                departureAt: departureAt,
                movementToNext: nil,
                movementGeometrySource: nil
            ))
        }

        guard visits.count >= 2 else { throw GTFSTripScheduleError.tooFewStops }
        for index in visits.indices.dropLast() {
            let start = visits[index]
            let end = visits[index + 1]
            guard let startsAt = start.departureAt,
                  startsAt < end.scheduledAt else { continue }

            let shapeSegment: [BusMovementCoordinate]? = if let shape, let matchedProgresses {
                Self.shapeCoordinates(
                    on: shape,
                    from: matchedProgresses[index],
                    through: matchedProgresses[index + 1]
                )
            } else {
                nil
            }
            let usableShapeSegment = shapeSegment.flatMap { $0.count >= 2 ? $0 : nil }
            let coordinates = usableShapeSegment
                ?? [
                    BusMovementCoordinate(latitude: start.latitude, longitude: start.longitude),
                    BusMovementCoordinate(latitude: end.latitude, longitude: end.longitude)
                ]
            let source: ServiceMovementGeometrySource = usableShapeSegment == nil
                ? .stopCoordinateEstimate
                : .gtfsShape
            visits[index] = ScheduledTripStopVisit(
                stopID: start.stopID,
                stopName: start.stopName,
                stopSequence: start.stopSequence,
                latitude: start.latitude,
                longitude: start.longitude,
                scheduledAt: start.scheduledAt,
                departureAt: start.departureAt,
                movementToNext: coordinates,
                movementGeometrySource: source
            )
        }
        return visits
    }

    static func loadRouteTimetable(
        for version: NetworkVersion,
        routeID: String,
        serviceDateKey: Int
    ) throws -> GTFSRouteTimetable {
        let activeServiceIDs = Set(
            try loadServiceCalendars(for: version)
                .filter { $0.activeDates.contains(serviceDateKey) }
                .map(\.serviceID)
        )
        guard !activeServiceIDs.isEmpty else {
            return GTFSRouteTimetable(trips: [], unusableTripCount: 0)
        }

        let schedules = try loadTripSchedules(for: version).filter {
            $0.routeID == routeID && activeServiceIDs.contains($0.serviceID)
        }
        let stopsByID = Dictionary(
            try loadBusStops(for: version).map { ($0.stopID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        var trips: [GTFSRouteServiceTrip] = []
        var unusableTripCount = 0

        for schedule in schedules {
            do {
                let visits = try Self.timetableStopVisits(
                    for: schedule,
                    serviceDateKey: serviceDateKey,
                    calendar: calendar,
                    stopsByID: stopsByID
                )
                trips.append(GTFSRouteServiceTrip(
                    tripID: schedule.tripID,
                    routeID: schedule.routeID,
                    serviceDateKey: serviceDateKey,
                    directionID: schedule.directionID ?? "",
                    headsign: schedule.headsign ?? "",
                    stops: visits
                ))
            } catch {
                unusableTripCount += 1
            }
        }

        return GTFSRouteTimetable(
            trips: trips.sorted { lhs, rhs in
                let lhsStart = lhs.stops.first?.scheduledAt ?? .distantFuture
                let rhsStart = rhs.stops.first?.scheduledAt ?? .distantFuture
                if lhsStart != rhsStart { return lhsStart < rhsStart }
                return lhs.tripID < rhs.tripID
            },
            unusableTripCount: unusableTripCount
        )
    }

    private static func timetableStopVisits(
        for schedule: GTFSServiceTripSchedule,
        serviceDateKey: Int,
        calendar: Calendar,
        stopsByID: [String: GTFSStopSummary]
    ) throws -> [ScheduledTripStopVisit] {
        var visits: [ScheduledTripStopVisit] = []
        var previousTime = Date.distantPast

        for (index, stopTime) in schedule.stops.enumerated() {
            guard let stop = stopsByID[stopTime.stopID] else {
                throw GTFSTripScheduleError.missingStopCoordinates(stopTime.stopID)
            }
            let arrivalAt = stopTime.arrivalSeconds.flatMap {
                GTFSClockTime.date(serviceDateKey: serviceDateKey, secondsOffset: $0, calendar: calendar)
            }
            let departureAt = stopTime.departureSeconds.flatMap {
                GTFSClockTime.date(serviceDateKey: serviceDateKey, secondsOffset: $0, calendar: calendar)
            }
            let scheduledAt = index == 0 ? departureAt : (arrivalAt ?? departureAt)
            guard let scheduledAt else {
                throw GTFSTripScheduleError.missingStopTime(stopTime.stopID)
            }
            guard scheduledAt >= previousTime,
                  departureAt.map({ $0 >= scheduledAt }) ?? true else {
                throw GTFSTripScheduleError.outOfOrderTimes
            }
            previousTime = scheduledAt
            visits.append(ScheduledTripStopVisit(
                stopID: stop.stopID,
                stopName: stop.name,
                stopSequence: stopTime.stopSequence,
                latitude: stop.latitude,
                longitude: stop.longitude,
                scheduledAt: scheduledAt,
                departureAt: departureAt,
                movementToNext: nil,
                movementGeometrySource: nil
            ))
        }

        guard visits.count >= 2 else { throw GTFSTripScheduleError.tooFewStops }
        return visits
    }

    fileprivate static func projectStopSequenceToShape(
        _ stopTimes: [GTFSServiceTripStopTime],
        stopsByID: [String: GTFSStopSummary],
        shape: GTFSRouteShape
    ) -> GTFSShapeStopAlignment {
        let stopIDs = stopTimes.map(\.stopID)
        guard shape.points.count >= 2 else {
            return GTFSShapeStopAlignment(
                progresses: nil,
                unmatchedStopIDs: stopIDs,
                diagnostics: stopTimes.map {
                    GTFSStopShapeProjectionDiagnostic(
                        stopSequence: $0.stopSequence,
                        closestForwardDistanceMeters: nil,
                        reason: .invalidShapeGeometry
                    )
                }
            )
        }
        let cumulative = cumulativeShapeDistances(shape.points)
        guard let totalDistance = cumulative.last, totalDistance > 0 else {
            return GTFSShapeStopAlignment(
                progresses: nil,
                unmatchedStopIDs: stopIDs,
                diagnostics: stopTimes.map {
                    GTFSStopShapeProjectionDiagnostic(
                        stopSequence: $0.stopSequence,
                        closestForwardDistanceMeters: nil,
                        reason: .invalidShapeGeometry
                    )
                }
            )
        }
        let shapeMeasures = shape.points.map(\.distanceTraveled)
        let canUseShapeMeasures = shapeMeasures.allSatisfy { $0 != nil }
            && zip(shapeMeasures.compactMap { $0 }, shapeMeasures.compactMap { $0 }.dropFirst()).allSatisfy { pair in
                pair.0 <= pair.1
            }

        var progress: [Double?] = []
        var unmatchedStopIDs: [String] = []
        var diagnostics: [GTFSStopShapeProjectionDiagnostic] = []
        var firstAllowedSegment = 0
        var previousProgress = 0.0
        let projectionToleranceMeters = Double(GTFSStopShapeProjectionIssueReason.projectionToleranceMeters)
        for stopTime in stopTimes {
            guard let stop = stopsByID[stopTime.stopID] else {
                unmatchedStopIDs.append(stopTime.stopID)
                diagnostics.append(GTFSStopShapeProjectionDiagnostic(
                    stopSequence: stopTime.stopSequence,
                    closestForwardDistanceMeters: nil,
                    reason: .missingStopCoordinates
                ))
                progress.append(nil)
                continue
            }
            var position: (progress: Double, segment: Int)?
            var projectionCandidate: (errorMeters: Double, progress: Double, segment: Int)?
            if canUseShapeMeasures,
               let measuredDistance = stopTime.shapeDistanceTraveled {
                let measuredPosition = shapeProgress(forShapeDistance: measuredDistance, shape: shape, cumulative: cumulative)
                if let measuredPosition, measuredPosition.progress + 0.000_001 >= previousProgress {
                    position = measuredPosition
                }
            }
            if position == nil {
                projectionCandidate = project(
                    stop: stop,
                    onto: shape.points,
                    cumulative: cumulative,
                    fromSegment: firstAllowedSegment,
                    notBeforeProgress: previousProgress
                )
                if let projectionCandidate,
                   projectionCandidate.errorMeters <= projectionToleranceMeters {
                    position = (projectionCandidate.progress, projectionCandidate.segment)
                } else {
                    unmatchedStopIDs.append(stopTime.stopID)
                    diagnostics.append(GTFSStopShapeProjectionDiagnostic(
                        stopSequence: stopTime.stopSequence,
                        closestForwardDistanceMeters: projectionCandidate.map { Int($0.errorMeters.rounded()) },
                        reason: projectionCandidate.map { _ in GTFSStopShapeProjectionIssueReason.outsideForwardTolerance }
                            ?? .noForwardShapeSegment
                    ))
                    progress.append(nil)
                    continue
                }
            }
            guard let position else {
                unmatchedStopIDs.append(stopTime.stopID)
                diagnostics.append(GTFSStopShapeProjectionDiagnostic(
                    stopSequence: stopTime.stopSequence,
                    closestForwardDistanceMeters: nil,
                    reason: .noForwardShapeSegment
                ))
                progress.append(nil)
                continue
            }
            guard position.progress + 0.000_001 >= previousProgress else {
                if projectionCandidate == nil {
                    projectionCandidate = project(
                        stop: stop,
                        onto: shape.points,
                        cumulative: cumulative,
                        fromSegment: firstAllowedSegment,
                        notBeforeProgress: previousProgress
                    )
                }
                unmatchedStopIDs.append(stopTime.stopID)
                diagnostics.append(GTFSStopShapeProjectionDiagnostic(
                    stopSequence: stopTime.stopSequence,
                    closestForwardDistanceMeters: projectionCandidate.map { Int($0.errorMeters.rounded()) },
                    reason: .nonMonotonicProgress
                ))
                progress.append(nil)
                continue
            }
            previousProgress = max(previousProgress, position.progress)
            firstAllowedSegment = max(firstAllowedSegment, position.segment)
            progress.append(previousProgress)
        }
        let fullyProjectedProgresses = progress.count == stopTimes.count && progress.allSatisfy { $0 != nil }
            ? progress.compactMap { $0 }
            : nil
        if fullyProjectedProgresses == nil,
           stopTimes.allSatisfy({ $0.shapeDistanceTraveled == nil }),
           let loopAwareProgresses = projectStopSequenceAsCompletePath(
                stopTimes,
                stopsByID: stopsByID,
                shape: shape,
                cumulative: cumulative,
                toleranceMeters: projectionToleranceMeters
           ) {
            return GTFSShapeStopAlignment(progresses: loopAwareProgresses, unmatchedStopIDs: [], diagnostics: [])
        }
        return GTFSShapeStopAlignment(
            progresses: fullyProjectedProgresses,
            unmatchedStopIDs: unmatchedStopIDs,
            diagnostics: diagnostics
        )
    }

    private static func projectStopSequenceAsCompletePath(
        _ stopTimes: [GTFSServiceTripStopTime],
        stopsByID: [String: GTFSStopSummary],
        shape: GTFSRouteShape,
        cumulative: [Double],
        toleranceMeters: Double
    ) -> [Double]? {
        guard !stopTimes.isEmpty,
              shape.points.count == cumulative.count,
              let totalDistance = cumulative.last,
              totalDistance > 0 else { return nil }

        var candidatesByStop: [[GTFSShapeProjectionCandidate]] = []
        candidatesByStop.reserveCapacity(stopTimes.count)
        for stopTime in stopTimes {
            guard let stop = stopsByID[stopTime.stopID] else { return nil }
            let candidates = allProjections(
                of: stop,
                onto: shape.points,
                cumulative: cumulative
            )
            .filter { $0.errorMeters <= toleranceMeters }
            .sorted {
                if $0.progress != $1.progress { return $0.progress < $1.progress }
                if $0.errorMeters != $1.errorMeters { return $0.errorMeters < $1.errorMeters }
                return $0.segment < $1.segment
            }
            guard !candidates.isEmpty else { return nil }
            candidatesByStop.append(candidates)
        }

        var statesByStop: [[GTFSShapeProjectionPathState]] = []
        statesByStop.reserveCapacity(candidatesByStop.count)
        statesByStop.append(candidatesByStop[0].map { candidate in
            GTFSShapeProjectionPathState(
                candidate: candidate,
                cost: candidate.errorMeters * candidate.errorMeters,
                predecessorIndex: nil
            )
        })

        for stopIndex in 1..<candidatesByStop.count {
            let previousStates = statesByStop[stopIndex - 1]
            let candidates = candidatesByStop[stopIndex]
            var previousIndex = 0
            var bestPreviousIndex: Int?
            var nextStates: [GTFSShapeProjectionPathState] = []
            nextStates.reserveCapacity(candidates.count)

            for candidate in candidates {
                while previousIndex < previousStates.count,
                      previousStates[previousIndex].candidate.progress <= candidate.progress + 0.000_001 {
                    if let currentBestIndex = bestPreviousIndex {
                        if previousStates[previousIndex].cost < previousStates[currentBestIndex].cost {
                            bestPreviousIndex = previousIndex
                        }
                    } else {
                        bestPreviousIndex = previousIndex
                    }
                    previousIndex += 1
                }
                guard let bestPreviousIndex else { continue }
                nextStates.append(GTFSShapeProjectionPathState(
                    candidate: candidate,
                    cost: previousStates[bestPreviousIndex].cost + candidate.errorMeters * candidate.errorMeters,
                    predecessorIndex: bestPreviousIndex
                ))
            }
            guard !nextStates.isEmpty else { return nil }
            statesByStop.append(nextStates)
        }

        guard let lastStateIndex = statesByStop.last?.indices.min(by: {
            statesByStop[statesByStop.count - 1][$0].cost < statesByStop[statesByStop.count - 1][$1].cost
        }) else { return nil }
        var selectedIndices = Array(repeating: 0, count: statesByStop.count)
        selectedIndices[selectedIndices.count - 1] = lastStateIndex
        if selectedIndices.count > 1 {
            for stopIndex in stride(from: selectedIndices.count - 1, through: 1, by: -1) {
                guard let predecessor = statesByStop[stopIndex][selectedIndices[stopIndex]].predecessorIndex else {
                    return nil
                }
                selectedIndices[stopIndex - 1] = predecessor
            }
        }
        return statesByStop.indices.map { stopIndex in
            statesByStop[stopIndex][selectedIndices[stopIndex]].candidate.progress
        }
    }

    private static func allProjections(
        of stop: GTFSStopSummary,
        onto points: [GTFSShapePoint],
        cumulative: [Double]
    ) -> [GTFSShapeProjectionCandidate] {
        guard points.count >= 2, cumulative.count == points.count,
              let totalDistance = cumulative.last, totalDistance > 0 else { return [] }
        let latitudeScale = cos(stop.latitude * .pi / 180)
        return points.indices.dropLast().compactMap { segment in
            let start = points[segment]
            let end = points[segment + 1]
            let startX = (start.longitude - stop.longitude) * latitudeScale
            let startY = start.latitude - stop.latitude
            let deltaX = (end.longitude - start.longitude) * latitudeScale
            let deltaY = end.latitude - start.latitude
            let lengthSquared = deltaX * deltaX + deltaY * deltaY
            let fraction = lengthSquared == 0
                ? 0
                : min(1, max(0, -(startX * deltaX + startY * deltaY) / lengthSquared))
            let errorX = startX + deltaX * fraction
            let errorY = startY + deltaY * fraction
            let errorMeters = hypot(errorX, errorY) * 111_320
            let distance = cumulative[segment] + (cumulative[segment + 1] - cumulative[segment]) * fraction
            return GTFSShapeProjectionCandidate(
                errorMeters: errorMeters,
                progress: distance / totalDistance,
                segment: segment
            )
        }
    }

    private static func shapeProgress(
        forShapeDistance target: Double,
        shape: GTFSRouteShape,
        cumulative: [Double]
    ) -> (progress: Double, segment: Int)? {
        guard shape.points.count == cumulative.count,
              let firstMeasure = shape.points.first?.distanceTraveled,
              let lastMeasure = shape.points.last?.distanceTraveled,
              target >= firstMeasure, target <= lastMeasure else { return nil }
        for upperIndex in shape.points.indices.dropFirst() {
            guard let upperMeasure = shape.points[upperIndex].distanceTraveled,
                  let lowerMeasure = shape.points[upperIndex - 1].distanceTraveled,
                  target <= upperMeasure else { continue }
            let fraction = upperMeasure == lowerMeasure ? 0 : (target - lowerMeasure) / (upperMeasure - lowerMeasure)
            let distance = cumulative[upperIndex - 1]
                + (cumulative[upperIndex] - cumulative[upperIndex - 1]) * fraction
            guard let totalDistance = cumulative.last, totalDistance > 0 else { return nil }
            return (distance / totalDistance, upperIndex - 1)
        }
        guard let totalDistance = cumulative.last, totalDistance > 0 else { return nil }
        return (1, shape.points.count - 2)
    }

    private static func project(
        stop: GTFSStopSummary,
        onto points: [GTFSShapePoint],
        cumulative: [Double],
        fromSegment firstAllowedSegment: Int,
        notBeforeProgress minimumProgress: Double
    ) -> (errorMeters: Double, progress: Double, segment: Int)? {
        guard points.count >= 2, cumulative.count == points.count,
              let totalDistance = cumulative.last, totalDistance > 0 else { return nil }
        let latitudeScale = cos(stop.latitude * .pi / 180)
        var best: (errorMeters: Double, progress: Double, segment: Int)?
        var minimumErrorMeters = Double.infinity
        // GTFS shape coordinates are rounded to 1e-6 degrees. Within that sub-meter range,
        // prefer the earliest forward occurrence so repeated stops stay in sequence.
        let coordinatePrecisionTieToleranceMeters = 0.25
        for segment in max(0, firstAllowedSegment)..<(points.count - 1) {
            let start = points[segment]
            let end = points[segment + 1]
            let startX = (start.longitude - stop.longitude) * latitudeScale
            let startY = start.latitude - stop.latitude
            let deltaX = (end.longitude - start.longitude) * latitudeScale
            let deltaY = end.latitude - start.latitude
            let lengthSquared = deltaX * deltaX + deltaY * deltaY
            let fraction: Double
            if lengthSquared == 0 {
                fraction = 0
            } else {
                fraction = min(1, max(0, -(startX * deltaX + startY * deltaY) / lengthSquared))
            }
            let errorX = startX + deltaX * fraction
            let errorY = startY + deltaY * fraction
            let errorMeters = hypot(errorX, errorY) * 111_320
            let segmentLength = cumulative[segment + 1] - cumulative[segment]
            let distance = cumulative[segment] + segmentLength * fraction
            let progress = distance / totalDistance
            guard progress + 0.000_001 >= minimumProgress else { continue }
            let projected = (errorMeters, progress, segment)
            if errorMeters < minimumErrorMeters {
                minimumErrorMeters = errorMeters
                if best == nil || best!.errorMeters > minimumErrorMeters + coordinatePrecisionTieToleranceMeters {
                    best = projected
                } else if progress < best!.progress {
                    best = projected
                }
            } else if errorMeters <= minimumErrorMeters + coordinatePrecisionTieToleranceMeters,
                      best == nil || progress < best!.progress {
                best = projected
            }
        }
        guard let best else { return nil }
        return (best.errorMeters, best.progress, best.segment)
    }

    private static func shapeCoordinates(
        on shape: GTFSRouteShape,
        from startProgress: Double,
        through endProgress: Double
    ) -> [BusMovementCoordinate]? {
        guard startProgress.isFinite, endProgress.isFinite,
              startProgress >= 0, endProgress <= 1,
              endProgress > startProgress else { return nil }
        let cumulative = cumulativeShapeDistances(shape.points)
        guard let totalDistance = cumulative.last, totalDistance > 0 else { return nil }
        let startDistance = totalDistance * startProgress
        let endDistance = totalDistance * endProgress
        guard let start = coordinate(on: shape.points, cumulative: cumulative, at: startDistance),
              let end = coordinate(on: shape.points, cumulative: cumulative, at: endDistance) else { return nil }
        var coordinates = [start]
        for index in shape.points.indices where cumulative[index] > startDistance && cumulative[index] < endDistance {
            coordinates.append(BusMovementCoordinate(
                latitude: shape.points[index].latitude,
                longitude: shape.points[index].longitude
            ))
        }
        coordinates.append(end)
        return coordinates
    }

    private static func coordinate(
        on points: [GTFSShapePoint],
        cumulative: [Double],
        at distance: Double
    ) -> BusMovementCoordinate? {
        guard points.count >= 2, points.count == cumulative.count else { return nil }
        for index in points.indices.dropFirst() {
            guard distance <= cumulative[index] else { continue }
            let segmentLength = cumulative[index] - cumulative[index - 1]
            let fraction = segmentLength == 0 ? 0 : (distance - cumulative[index - 1]) / segmentLength
            return BusMovementCoordinate(
                latitude: points[index - 1].latitude + (points[index].latitude - points[index - 1].latitude) * fraction,
                longitude: points[index - 1].longitude + (points[index].longitude - points[index - 1].longitude) * fraction
            )
        }
        guard let last = points.last else { return nil }
        return BusMovementCoordinate(latitude: last.latitude, longitude: last.longitude)
    }

    private static func cumulativeShapeDistances(_ points: [GTFSShapePoint]) -> [Double] {
        guard !points.isEmpty else { return [] }
        var cumulative = [0.0]
        cumulative.reserveCapacity(points.count)
        for index in points.indices.dropFirst() {
            let previous = points[index - 1]
            let current = points[index]
            let meanLatitude = (previous.latitude + current.latitude) / 2 * .pi / 180
            let deltaX = (current.longitude - previous.longitude) * cos(meanLatitude) * 111_320
            let deltaY = (current.latitude - previous.latitude) * 111_320
            cumulative.append(cumulative.last! + hypot(deltaX, deltaY))
        }
        return cumulative
    }

    static func loadServiceDepartures(
        for version: NetworkVersion,
        routeIDs: Set<String>,
        from start: Date,
        through end: Date
    ) throws -> [ScheduledServiceDeparture] {
        guard start < end, !routeIDs.isEmpty else { return [] }
        let departureRecords = try loadTripDepartures(for: version)
        let departuresByServiceID = Dictionary(
            grouping: departureRecords.filter { routeIDs.contains($0.routeID) },
            by: \.serviceID
        )
        var activeDatesByServiceID: [String: Set<Int>] = [:]
        for calendar in try loadServiceCalendars(for: version) {
            activeDatesByServiceID[calendar.serviceID] = Set(calendar.activeDates)
        }

        let timeZone = GTFSServiceDate.parisTimeZone
        let calendar = GTFSServiceDate.calendar(timeZone: timeZone)
        let startOfDay = calendar.startOfDay(for: start)
        guard let firstServiceDate = calendar.date(byAdding: .day, value: -4, to: startOfDay) else { return [] }
        let lastServiceDate = calendar.startOfDay(for: end)
        var results: [ScheduledServiceDeparture] = []
        var serviceDate = firstServiceDate

        while serviceDate <= lastServiceDate {
            guard let serviceDateKey = GTFSServiceDate.key(for: serviceDate, timeZone: timeZone) else { break }
            let activeServiceIDs = activeDatesByServiceID.compactMap { serviceID, activeDates in
                activeDates.contains(serviceDateKey) ? serviceID : nil
            }.sorted()
            for serviceID in activeServiceIDs {
                for trip in departuresByServiceID[serviceID] ?? [] {
                    guard let departureAt = GTFSClockTime.date(
                        serviceDateKey: serviceDateKey,
                        secondsOffset: trip.departureSeconds,
                        calendar: calendar
                    ), departureAt >= start, departureAt < end else { continue }
                    results.append(ScheduledServiceDeparture(
                        tripID: trip.tripID,
                        routeID: trip.routeID,
                        serviceDateKey: serviceDateKey,
                        departureAt: departureAt
                    ))
                }
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: serviceDate) else { break }
            serviceDate = nextDate
        }

        return results.sorted {
            if $0.departureAt != $1.departureAt { return $0.departureAt < $1.departureAt }
            if $0.routeID != $1.routeID { return $0.routeID < $1.routeID }
            return $0.tripID < $1.tripID
        }
    }

    private static func digest(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty {
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
