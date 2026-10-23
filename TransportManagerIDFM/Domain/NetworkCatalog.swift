import Foundation

enum SourceImportState: String, Codable, Hashable, Sendable {
    case waitingForImport
    case imported
    case needsReview

    var label: String {
        switch self {
        case .waitingForImport: "À importer"
        case .imported: "Importée"
        case .needsReview: "À vérifier"
        }
    }
}

struct NetworkDataSource: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let purpose: String
    let url: String
    var state: SourceImportState

    var destination: URL? { URL(string: url) }
}

struct GTFSRouteSummary: Codable, Hashable, Identifiable, Sendable {
    let routeID: String
    let shortName: String
    let longName: String

    var id: String { routeID }
    var displayName: String {
        if !shortName.isEmpty { return shortName }
        if !longName.isEmpty { return longName }
        return routeID
    }
    var secondaryName: String? {
        guard !longName.isEmpty, longName != displayName else { return nil }
        return longName
    }
}

struct GTFSStopSummary: Codable, Hashable, Identifiable, Sendable {
    let stopID: String
    let name: String
    let latitude: Double
    let longitude: Double
    let routeIDs: [String]
    let routeDirections: [GTFSStopRouteDirection]

    var id: String { stopID }

    init(
        stopID: String,
        name: String,
        latitude: Double,
        longitude: Double,
        routeIDs: [String],
        routeDirections: [GTFSStopRouteDirection] = []
    ) {
        self.stopID = stopID
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.routeIDs = routeIDs
        self.routeDirections = routeDirections
    }

    private enum CodingKeys: String, CodingKey {
        case stopID
        case name
        case latitude
        case longitude
        case routeIDs
        case routeDirections
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        stopID = try values.decode(String.self, forKey: .stopID)
        name = try values.decode(String.self, forKey: .name)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
        routeIDs = try values.decode([String].self, forKey: .routeIDs)
        routeDirections = try values.decodeIfPresent([GTFSStopRouteDirection].self, forKey: .routeDirections) ?? []
    }
}

struct GTFSStopRouteDirection: Codable, Hashable, Identifiable, Sendable {
    let routeID: String
    let directionID: String
    let headsign: String
    let serviceHours: [GTFSServiceHour]
    let hasIncompleteSchedule: Bool

    init(
        routeID: String,
        directionID: String,
        headsign: String,
        serviceHours: [GTFSServiceHour] = [],
        hasIncompleteSchedule: Bool = true
    ) {
        self.routeID = routeID
        self.directionID = directionID
        self.headsign = headsign
        self.serviceHours = serviceHours
        self.hasIncompleteSchedule = hasIncompleteSchedule
    }

    private enum CodingKeys: String, CodingKey {
        case routeID
        case directionID
        case headsign
        case serviceHours
        case hasIncompleteSchedule
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        routeID = try values.decode(String.self, forKey: .routeID)
        directionID = try values.decode(String.self, forKey: .directionID)
        headsign = try values.decode(String.self, forKey: .headsign)
        serviceHours = try values.decodeIfPresent([GTFSServiceHour].self, forKey: .serviceHours) ?? []
        hasIncompleteSchedule = try values.decodeIfPresent(Bool.self, forKey: .hasIncompleteSchedule) ?? true
    }

    var id: String { "\(routeID)|\(directionID)|\(headsign)" }
}

struct GTFSServiceHour: Codable, Hashable, Identifiable, Sendable {
    let serviceID: String
    let hourOffset: Int

    var id: String { "\(serviceID)|\(hourOffset)" }
}

struct GTFSServiceCalendar: Codable, Hashable, Identifiable, Sendable {
    let serviceID: String
    let activeDates: [Int]

    var id: String { serviceID }
}

struct GTFSServiceTripDeparture: Codable, Hashable, Identifiable, Sendable {
    let tripID: String
    let routeID: String
    let serviceID: String
    let departureSeconds: Int

    var id: String { "\(serviceID)|\(tripID)" }
}

struct GTFSServiceTripStopTime: Codable, Hashable, Identifiable, Sendable {
    let stopID: String
    let stopSequence: Int
    let arrivalSeconds: Int?
    let departureSeconds: Int?
    let shapeDistanceTraveled: Double?

    var id: String { "\(stopSequence)|\(stopID)" }
}

struct GTFSServiceTripSchedule: Codable, Hashable, Identifiable, Sendable {
    let tripID: String
    let routeID: String
    let serviceID: String
    let directionID: String?
    let headsign: String?
    let stops: [GTFSServiceTripStopTime]
    let shapeID: String?

    var id: String { tripID }
}

struct GTFSShapePoint: Codable, Hashable, Sendable {
    let sequence: Int
    let latitude: Double
    let longitude: Double
    let distanceTraveled: Double?
}

struct GTFSRouteShape: Codable, Hashable, Identifiable, Sendable {
    let shapeID: String
    let points: [GTFSShapePoint]

    var id: String { shapeID }
}

struct GTFSServiceTripShapeReference: Codable, Hashable, Sendable {
    let tripID: String
    let shapeID: String
}

struct GTFSShapeDataset: Codable, Hashable, Sendable {
    let references: [GTFSServiceTripShapeReference]
    let shapes: [GTFSRouteShape]

    func shapeID(for tripID: String) -> String? {
        references.first(where: { $0.tripID == tripID })?.shapeID
    }
}

struct NetworkLineReference: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let idLine: String
    let nameLine: String
    let shortNameLine: String
    let transportMode: String
    let transportSubmode: String
    let lineType: String
    let operatorRef: String
    let additionalOperatorsRef: String
    let operatorName: String
    let networkName: String
    let webColor: String
    let validFrom: String
    let validTo: String
    let status: String
    let attributes: [String: String]

    var displayName: String {
        if !shortNameLine.isEmpty { return shortNameLine }
        if !nameLine.isEmpty { return nameLine }
        return idLine
    }

    var busContractID: String? {
        for (key, value) in attributes where key.lowercased().filter({ $0.isLetter || $0.isNumber }) == "idbuscontrat" {
            let contractID = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !contractID.isEmpty { return contractID }
        }
        return nil
    }

    func isActive(on date: Date) -> Bool? {
        guard let selectedDateKey = GTFSServiceDate.key(for: date, timeZone: GTFSServiceDate.parisTimeZone),
              let validFromKey = Self.dateKey(validFrom) else { return nil }
        guard validFromKey <= selectedDateKey else { return false }

        let trimmedValidTo = validTo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValidTo.isEmpty else { return true }
        guard let validToKey = Self.dateKey(trimmedValidTo), validToKey >= validFromKey else { return nil }
        return selectedDateKey <= validToKey
    }

    private static func dateKey(_ value: String) -> Int? {
        let components = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-", omittingEmptySubsequences: false)
        guard components.count == 3,
              components[0].count == 4,
              components[1].count == 2,
              components[2].count == 2,
              components.allSatisfy({ $0.allSatisfy(\.isNumber) }) else { return nil }
        guard let date = GTFSServiceDate.date(from: components.joined()) else { return nil }
        return GTFSServiceDate.key(for: date, timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
    }
}

struct GeographicCoordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

struct NetworkRouteGeometry: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let lineID: String
    let shortName: String
    let longName: String
    let operatorName: String
    let color: String
    let updated: String
    let paths: [[GeographicCoordinate]]
}

struct NetworkGeometryVersion: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let importedAt: Date
    let sourceDatasetID: String
    let sourceTitle: String
    let sourceURL: String
    let license: String
    let licenseURL: String
    let attribution: String
    let originalFilename: String
    let archiveRelativePath: String
    let sha256: String
    let featureCount: Int
}

struct NetworkContractFeature: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let contractID: String?
    let name: String?
    let operatorName: String?
    let attributes: [String: ContractJSONValue]
    let outlines: [[GeographicCoordinate]]

    var sourceObjectID: String? {
        guard let key = attributes.keys.sorted().first(where: {
            $0.lowercased().filter { $0.isLetter || $0.isNumber } == "objectid"
        }) else { return nil }
        return attributes[key]?.textValue
    }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        if let contractID, !contractID.isEmpty { return "Contrat \(contractID)" }
        return "Contour à identifier"
    }
}

struct NetworkContractVersion: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let importedAt: Date
    let sourceDataProcessedAt: Date?
    let sourceDatasetID: String
    let sourceTitle: String
    let sourceURL: String
    let license: String
    let licenseURL: String
    let attribution: String
    let originalFilename: String
    let archiveRelativePath: String
    let sha256: String
    let featureCount: Int
    let unresolvedFeatureCount: Int
}

struct NetworkLineReferenceVersion: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let importedAt: Date
    let sourceDataProcessedAt: Date?
    let sourceDatasetID: String
    let sourceTitle: String
    let sourceURL: String
    let license: String
    let licenseURL: String
    let attribution: String
    let originalFilename: String
    let archiveRelativePath: String
    let sha256: String
    let lineCount: Int
    var gtfsCoverage: [NetworkLineReferenceCoverage]
}

struct NetworkLineDocument: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let idLine: String
    let documentName: String
    let documentURL: String
    let documentType: String
    let lineName: String
    let attributes: [String: String]

    var destination: URL? {
        guard let url = URL(string: documentURL),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil else { return nil }
        return url
    }

    var typeLabel: String {
        switch documentType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "PLAN": "Plan de ligne"
        case "HORAIRE", "FICHE HORAIRE": "Fiche horaire"
        default: documentType.isEmpty ? "Document IDFM" : documentType
        }
    }
}

struct NetworkLineDocumentImportIssue: Codable, Hashable, Sendable {
    let sourceRecordNumber: Int
    let reason: String
    let idLine: String?
    let documentName: String?
    let documentURL: String?
    let attributes: [String: String]
}

struct NetworkLineDocumentVersion: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let importedAt: Date
    let sourceDatasetID: String
    let sourceTitle: String
    let sourceURL: String
    let license: String
    let licenseURL: String
    let attribution: String
    let originalFilename: String
    let archiveRelativePath: String
    let sha256: String
    let recordCount: Int
    let skippedRecordCount: Int
    let importIssuesRelativePath: String?
}

struct NetworkLineReferenceCoverage: Identifiable, Codable, Hashable, Sendable {
    let gtfsVersionID: String
    let matchedRouteCount: Int
    let unmatchedRouteIDs: [String]

    var id: String { gtfsVersionID }
    var isComplete: Bool { matchedRouteCount > 0 && unmatchedRouteIDs.isEmpty }
}

/// A deduplicated, date-aware view of the public network data associated with one depot.
/// Line counts are keyed by unique ID_Line when available, with unresolved commercial
/// names retained as separate entries so they remain visible in the coverage denominator.
struct DepotLineCoverage: Hashable, Sendable {
    let depotID: String
    let serviceDateKey: Int?
    let gtfsVersionID: String?
    let lineReferenceVersionID: String?
    let lineDocumentVersionID: String?
    let routeGeometryVersionID: String?
    let uniqueLineCount: Int
    let linesWithGTFS: Int
    let routeVariantCount: Int
    let linesWithOfficialTraces: Int
    let linesWithPlans: Int
    let linesWithTimetables: Int
    let ambiguousReferenceCount: Int
    let missingReferenceCount: Int
    let missingGTFSCount: Int
    let unconfirmedDepotEvidenceCount: Int

    var planCoverage: String { "\(linesWithPlans)/\(uniqueLineCount)" }
    var timetableCoverage: String { "\(linesWithTimetables)/\(uniqueLineCount)" }
    var traceCoverage: String { "\(linesWithOfficialTraces)/\(uniqueLineCount)" }
    var gtfsCoverage: String { "\(linesWithGTFS)/\(uniqueLineCount)" }
}

enum GTFSImportTripIssueKind: String, Codable, CaseIterable, Hashable, Sendable {
    case missingStopTimes
    case incompleteTimes
    case invalidChronology
    case missingStopCoordinates
    case tooFewStops
    case invalidStopSequence
    case missingShapeReference
    case unavailableShape
    case stopsNotMatchedToShape
    case missingStopID
    case inactiveService
    case invalidStopTimeRows

    var displayName: String {
        switch self {
        case .missingStopTimes: "aucune séquence d’arrêts"
        case .incompleteTimes: "horaires incomplets"
        case .invalidChronology: "horaires non chronologiques"
        case .missingStopCoordinates: "arrêts sans coordonnées"
        case .tooFewStops: "moins de deux arrêts"
        case .invalidStopSequence: "séquence d’arrêts dupliquée"
        case .missingShapeReference: "forme non référencée"
        case .unavailableShape: "forme absente ou invalide"
        case .stopsNotMatchedToShape: "arrêts non projetables sur la forme GTFS"
        case .missingStopID: "identifiant d’arrêt manquant"
        case .inactiveService: "aucune date de service active"
        case .invalidStopTimeRows: "lignes de passage invalides"
        }
    }
}

struct GTFSImportTripIssue: Codable, Hashable, Identifiable, Sendable {
    let routeID: String
    let tripID: String
    let issueKinds: Set<GTFSImportTripIssueKind>
    let invalidStopTimeRowCount: Int
    let missingStopIDRowCount: Int?
    let stopIDsWithoutCoordinates: [String]?
    let stopIDsNotMatchedToShape: [String]?

    var id: String { "\(routeID)|\(tripID)" }

    var summary: String {
        var labels = GTFSImportTripIssueKind.allCases
            .filter { $0 != .invalidStopTimeRows && $0 != .missingStopID && issueKinds.contains($0) }
            .map(\.displayName)
        let missingStopIDRowCount = missingStopIDRowCount ?? 0
        if missingStopIDRowCount > 0 {
            let unit = missingStopIDRowCount == 1 ? "ligne de passage" : "lignes de passage"
            labels.append("\(missingStopIDRowCount) \(unit) sans stop_id")
        }
        let otherInvalidStopTimeRowCount = max(0, invalidStopTimeRowCount - missingStopIDRowCount)
        if otherInvalidStopTimeRowCount > 0 {
            let unit = otherInvalidStopTimeRowCount == 1 ? "ligne de passage invalide" : "lignes de passage invalides"
            labels.append("\(otherInvalidStopTimeRowCount) \(unit)")
        }
        return labels.joined(separator: " · ")
    }
}

struct GTFSImportQuality: Codable, Hashable, Sendable {
    let busTripCount: Int
    let tripScheduleCount: Int
    let tripsWithoutStopTimes: Int
    let tripsWithIncompleteTimes: Int
    let tripsWithInvalidChronology: Int
    let tripsWithMissingStopCoordinates: Int
    let tripsWithTooFewStops: Int
    let tripsWithInvalidStopSequence: Int
    let tripsWithoutShapeReference: Int
    let tripsWithUnavailableShape: Int
    /// Trips whose geolocated stop sequence cannot be projected monotonically
    /// onto its referenced GTFS shape. Nil for catalogs imported by older builds.
    let tripsWithUnmatchedShapeStops: Int?
    let referencedShapeCount:
    let availableShapeCount: Int
    let invalidShapeCount: Int
    let invalidStopTimeRowCount: Int
    /// Rows rejected specifically because stop_id was blank. Nil in older catalogs.
    let missingStopIDRowCount: Int?
    /// Number of bus trips with a blank service_id or no dates active after
    /// applying calendar.txt and calendar_dates.txt. Nil for older catalogs.
    let tripsWithoutActiveServiceDates: Int?
    /// Whether frequencies.txt was present in the imported feed. Nil for older catalogs.
    let containsFrequenciesFile: Bool?
    /// Per-trip diagnostics for the imported version. Nil for older catalogs.
    let tripIssues: [GTFSImportTripIssue]?

    var hasScheduleIssues: Bool {
        tripsWithoutStopTimes > 0
            || tripsWithIncompleteTimes > 0
            || tripsWithInvalidChronology > 0
            || tripsWithMissingStopCoordinates > 0
            || tripsWithTooFewStops > 0
            || tripsWithInvalidStopSequence > 0
            || invalidStopTimeRowCount > 0
            || (missingStopIDRowCount ?? 0) > 0
    }

    var hasShapeIssues: Bool {
        tripsWithoutShapeReference > 0
            || tripsWithUnavailableShape > 0
            || (tripsWithUnmatchedShapeStops ?? 0) > 0
            || invalidShapeCount > 0
    }

    var hasServiceCalendarIssues: Bool {
        (tripsWithoutActiveServiceDates ?? 0) > 0
    }

    var hasUnsupportedFrequencyData: Bool {
        containsFrequenciesFile == true
    }
}

struct NetworkVersion: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let importedAt: Date
    let validFrom: Date?
    let validThrough: Date?
    let sourceIDs: [String]
    let sourceDatasetID: String
    let sourceTitle: String
    let sourceURL: String
    let license: String
    let licenseURL: String
    let originalFilename: String
    let archiveRelativePath: String
    let sha256: String
    let busRouteCount: Int
    let busStopCount: Int
    let feedStopCount: Int
    let gtfsQuality: GTFSImportQuality?

    var archiveURL: URL? {
        try? NetworkVersionStore.rootDirectory()
            .appending(path: archiveRelativePath)
    }
}

struct NetworkCatalog: Codable, Hashable, Sendable {
    var versions: [NetworkVersion]
    var activeVersionID: String?
    var geometryVersions: [NetworkGeometryVersion]
    var activeGeometryVersionID: String?
    var contractVersions: [NetworkContractVersion]
    var activeContractVersionID: String?
    var lineReferenceVersions: [NetworkLineReferenceVersion]
    var activeLineReferenceVersionID: String?
    var lineDocumentVersions: [NetworkLineDocumentVersion]
    var activeLineDocumentVersionID: String?
    var sources: [NetworkDataSource]

    var activeVersion: NetworkVersion? {
        guard let activeVersionID else { return nil }
        return versions.first { $0.id == activeVersionID }
    }

    var activeGeometryVersion: NetworkGeometryVersion? {
        guard let activeGeometryVersionID else { return nil }
        return geometryVersions.first { $0.id == activeGeometryVersionID }
    }

    var activeContractVersion: NetworkContractVersion? {
        guard let activeContractVersionID else { return nil }
        return contractVersions.first { $0.id == activeContractVersionID }
    }

    var activeLineReferenceVersion: NetworkLineReferenceVersion? {
        guard let activeLineReferenceVersionID else { return nil }
        return lineReferenceVersions.first { $0.id == activeLineReferenceVersionID }
    }

    var activeLineDocumentVersion: NetworkLineDocumentVersion? {
        guard let activeLineDocumentVersionID else { return nil }
        return lineDocumentVersions.first { $0.id == activeLineDocumentVersionID }
    }

    var activeLineReferenceCoverage: NetworkLineReferenceCoverage? {
        guard let activeVersion else { return nil }
        return activeLineReferenceVersion?.gtfsCoverage.first { $0.gtfsVersionID == activeVersion.id }
    }

    var isPlayable: Bool {
        guard let activeVersion,
              activeGeometryVersion != nil,
              let activeContractVersion,
              activeContractVersion.featureCount > activeContractVersion.unresolvedFeatureCount,
              activeLineReferenceVersion != nil,
              let activeLineReferenceCoverage,
              activeLineReferenceCoverage.isComplete,
              activeLineReferenceCoverage.matchedRouteCount == activeVersion.busRouteCount else { return false }
        let contractsSourceIsAvailable = sources.contains {
            $0.id == "contracts" && $0.state != .waitingForImport
        }
        return activeVersion.sourceIDs.contains("gtfs")
            && sources.first { $0.id == "routes" }?.state == .imported
            && contractsSourceIsAvailable
            && sources.first { $0.id == "line-reference" }?.state == .imported
    }

    static let initial = NetworkCatalog(
        versions: [],
        activeVersionID: nil,
        geometryVersions: [],
        activeGeometryVersionID: nil,
        contractVersions: [],
        activeContractVersionID: nil,
        lineReferenceVersions: [],
        activeLineReferenceVersionID: nil,
        lineDocumentVersions: [],
        activeLineDocumentVersionID: nil,
        sources: [
            NetworkDataSource(
                id: "gtfs",
                title: "Offre théorique GTFS IDFM",
                purpose: "Courses, horaires, calendriers et arrêts",
                url: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm",
                state: .waitingForImport
            ),
            NetworkDataSource(
                id: "routes",
                title: "Tracés commerciaux des bus",
                purpose: "Géométries des parcours affichés sur la carte",
                url: "https://data.iledefrance-mobilites.fr/explore/dataset/traces-des-lignes-regulieres-de-bus-en-ile-de-france/",
                state: .waitingForImport
            ),
            NetworkDataSource(
                id: "line-reference",
                title: "Référentiel des lignes",
                purpose: "Identifiants, noms et états des lignes",
                url: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/referentiel-des-lignes",
                state: .waitingForImport
            ),
            NetworkDataSource(
                id: "contracts",
                title: "Contours des contrats bus",
                purpose: "Réseaux, lots et exploitants",
                url: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/contours-des-contrats",
                state: .waitingForImport
            ),
            NetworkDataSource(
                id: "plans",
                title: "Plans et fiches horaires",
                purpose: "Liens officiels vers les plans et fiches horaires par ligne",
                url: "https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/",
                state: .waitingForImport
            )
        ]
    )
}

enum RouteGeometryMatcher {
    static func matches(
        route: GTFSRouteSummary,
        among routes: [GTFSRouteSummary],
        geometries: [NetworkRouteGeometry]
    ) -> [NetworkRouteGeometry] {
        let exactMatches = geometries.filter { $0.lineID == route.routeID }
        if !exactMatches.isEmpty { return exactMatches }

        guard !route.shortName.isEmpty else { return [] }
        let matchingRoutes = routes.filter { $0.shortName.localizedCaseInsensitiveCompare(route.shortName) == .orderedSame }
        guard matchingRoutes.count == 1 else { return [] }
        let matchingGeometries = geometries.filter { $0.shortName.localizedCaseInsensitiveCompare(route.shortName) == .orderedSame }
        guard Set(matchingGeometries.map(\.lineID)).count == 1 else { return [] }
        return matchingGeometries
    }
}

extension NetworkVersion {
    private enum CodingKeys: String, CodingKey {
        case id
        case importedAt
        case validFrom
        case validThrough
        case sourceIDs
        case sourceDatasetID
        case sourceTitle
        case sourceURL
        case license
        case licenseURL
        case originalFilename
        case archiveRelativePath
        case sha256
        case busRouteCount
        case busStopCount
        case feedStopCount
        case gtfsQuality
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        importedAt = try values.decode(Date.self, forKey: .importedAt)
        validFrom = try values.decodeIfPresent(Date.self, forKey: .validFrom)
        validThrough = try values.decodeIfPresent(Date.self, forKey: .validThrough)
        sourceIDs = try values.decode([String].self, forKey: .sourceIDs)
        sourceDatasetID = try values.decode(String.self, forKey: .sourceDatasetID)
        sourceTitle = try values.decode(String.self, forKey: .sourceTitle)
        sourceURL = try values.decode(String.self, forKey: .sourceURL)
        license = try values.decode(String.self, forKey: .license)
        licenseURL = try values.decode(String.self, forKey: .licenseURL)
        originalFilename = try values.decode(String.self, forKey: .originalFilename)
        archiveRelativePath = try values.decode(String.self, forKey: .archiveRelativePath)
        sha256 = try values.decode(String.self, forKey: .sha256)
        busRouteCount = try values.decode(Int.self, forKey: .busRouteCount)
        busStopCount = try values.decodeIfPresent(Int.self, forKey: .busStopCount) ?? 0
        feedStopCount = try values.decode(Int.self, forKey: .feedStopCount)
        gtfsQuality = try values.decodeIfPresent(GTFSImportQuality.self, forKey: .gtfsQuality)
    }
}

extension NetworkCatalog {
    private enum CodingKeys: String, CodingKey {
        case versions
        case activeVersionID
        case geometryVersions
        case activeGeometryVersionID
        case contractVersions
        case activeContractVersionID
        case lineReferenceVersions
        case activeLineReferenceVersionID
        case lineDocumentVersions
        case activeLineDocumentVersionID
        case sources
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        versions = try values.decode([NetworkVersion].self, forKey: .versions)
        activeVersionID = try values.decodeIfPresent(String.self, forKey: .activeVersionID)
        geometryVersions = try values.decodeIfPresent([NetworkGeometryVersion].self, forKey: .geometryVersions) ?? []
        activeGeometryVersionID = try values.decodeIfPresent(String.self, forKey: .activeGeometryVersionID)
        contractVersions = try values.decodeIfPresent([NetworkContractVersion].self, forKey: .contractVersions) ?? []
        activeContractVersionID = try values.decodeIfPresent(String.self, forKey: .activeContractVersionID)
        lineReferenceVersions = try values.decodeIfPresent([NetworkLineReferenceVersion].self, forKey: .lineReferenceVersions) ?? []
        activeLineReferenceVersionID = try values.decodeIfPresent(String.self, forKey: .activeLineReferenceVersionID)
        lineDocumentVersions = try values.decodeIfPresent([NetworkLineDocumentVersion].self, forKey: .lineDocumentVersions) ?? []
        activeLineDocumentVersionID = try values.decodeIfPresent(String.self, forKey: .activeLineDocumentVersionID)
        let decodedSources = try values.decode([NetworkDataSource].self, forKey: .sources)
        let knownSourceIDs = Set(Self.initial.sources.map(\.id))
        sources = Self.initial.sources.map { defaultSource in
            guard let previous = decodedSources.first(where: { $0.id == defaultSource.id }) else {
                return defaultSource
            }
            var migrated = defaultSource
            migrated.state = previous.state
            return migrated
        } + decodedSources.filter { !knownSourceIDs.contains($0.id) }
    }
}
