import Foundation

enum NetworkCoverageReferenceStatus: Hashable {
    case unavailable
    case absent
    case unique
    case ambiguous
}

enum NetworkCoverageDocumentStatus: Hashable {
    case unavailable
    case blockedByReference
    case none
    case available
}

enum NetworkCoverageVersionStatus: Hashable {
    case unavailable
    case activeVersions
    case differentVersions
}

struct NetworkCoverageAssignment: Hashable, Identifiable {
    let assignment: DepotLineAssignment
    let depotName: String
    let contractName: String?
    let versionStatus: NetworkCoverageVersionStatus

    var id: String { assignment.id }
}

struct NetworkCoverageAuditEntry: Hashable, Identifiable {
    let route: GTFSRouteSummary
    let isActiveOnDate: Bool?
    let referenceStatus: NetworkCoverageReferenceStatus
    let referenceMatchCount: Int
    let reference: NetworkLineReference?
    let documentStatus: NetworkCoverageDocumentStatus
    let documents: [NetworkLineDocument]
    let assignments: [NetworkCoverageAssignment]

    var id: String { route.routeID }
}

enum NetworkCoverageIDFMRouteStatus: Hashable {
    case unavailable
    case absent
    case unique
    case ambiguous
}

enum NetworkCoverageIDFMServiceStatus: Hashable {
    case active
    case upcoming
}

enum NetworkCoverageIDFMServiceActivityStatus: Hashable {
    case departuresPresent
    case noCourses
    case notEvaluable
}

struct NetworkCoverageIDFMEntry: Hashable, Identifiable {
    let reference: NetworkLineReference
    let serviceStatus: NetworkCoverageIDFMServiceStatus
    let routeStatus: NetworkCoverageIDFMRouteStatus
    let matchingRoutes: [GTFSRouteSummary]
    let serviceActivityStatus: NetworkCoverageIDFMServiceActivityStatus

    var id: String { reference.id }
    var routeMatchCount: Int { matchingRoutes.count }
}

struct NetworkCoverageIDFMAudit {
    let referencesAvailable: Bool
    let routesAvailable: Bool
    let entries: [NetworkCoverageIDFMEntry]
    let activeGTFSRoutesWithoutEligibleIDFMReference: [GTFSRouteSummary]?
    let unknownDateReferenceCount: Int?
    let notYetValidReferenceCount: Int?
    let excludedOutsideStatusScopeCount: Int?
}

enum NetworkCoverageAudit {
    static func buildIDFMToGTFS(
        references: [NetworkLineReference]?,
        routes: [GTFSRouteSummary]?,
        activeRouteIDs: Set<String>?,
        canConfirmNoCourses: Bool,
        selectedDate: Date
    ) -> NetworkCoverageIDFMAudit {
        guard let references else {
            return NetworkCoverageIDFMAudit(
                referencesAvailable: false,
                routesAvailable: routes != nil,
                entries: [],
                activeGTFSRoutesWithoutEligibleIDFMReference: nil,
                unknownDateReferenceCount: nil,
                notYetValidReferenceCount: nil,
                excludedOutsideStatusScopeCount: nil
            )
        }

        guard let selectedDateKey = GTFSServiceDate.key(
            for: GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: selectedDate),
            timeZone: GTFSServiceDate.parisTimeZone
        ) else {
            return NetworkCoverageIDFMAudit(
                referencesAvailable: true,
                routesAvailable: routes != nil,
                entries: [],
                activeGTFSRoutesWithoutEligibleIDFMReference: nil,
                unknownDateReferenceCount: nil,
                notYetValidReferenceCount: nil,
                excludedOutsideStatusScopeCount: nil
            )
        }

        let busReferences = references.filter { normalizedValue($0.transportMode) == "bus" }
        let statusReferences: [(reference: NetworkLineReference, serviceStatus: NetworkCoverageIDFMServiceStatus)] = busReferences.compactMap { reference in
            switch normalizedValue(reference.status) {
            case "active": (reference, .active)
            case "prochainement active": (reference, .upcoming)
            default: nil
            }
        }
        var eligibleReferences: [(reference: NetworkLineReference, serviceStatus: NetworkCoverageIDFMServiceStatus)] = []
        var unknownDateReferenceCount = 0
        var notYetValidReferenceCount = 0

        for candidate in statusReferences {
            switch dateEligibility(of: candidate.reference, on: selectedDateKey) {
            case .active:
                eligibleReferences.append(candidate)
            case .inactive:
                if let validFromKey = idfmDateKey(candidate.reference.validFrom), validFromKey > selectedDateKey {
                    notYetValidReferenceCount += 1
                }
            case .unknown:
                unknownDateReferenceCount += 1
            }
        }

        let routeGroups = Dictionary(grouping: routes ?? []) {
            LineReferenceMatcher.canonicalIdentifier($0.routeID)
        }

        let entries = eligibleReferences.compactMap { candidate -> NetworkCoverageIDFMEntry? in
            let reference = candidate.reference
            let canonicalID = LineReferenceMatcher.canonicalIdentifier(reference.idLine)
            guard !canonicalID.isEmpty else { return nil }

            guard routes != nil else {
                return NetworkCoverageIDFMEntry(
                    reference: reference,
                    serviceStatus: candidate.serviceStatus,
                    routeStatus: .unavailable,
                    matchingRoutes: [],
                    serviceActivityStatus: .notEvaluable
                )
            }

            let matches = (routeGroups[canonicalID] ?? []).sorted {
                let nameOrder = $0.displayName.localizedStandardCompare($1.displayName)
                if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
                return $0.routeID < $1.routeID
            }
            let status: NetworkCoverageIDFMRouteStatus
            switch matches.count {
            case 0: status = .absent
            case 1: status = .unique
            default: status = .ambiguous
            }
            let serviceActivityStatus: NetworkCoverageIDFMServiceActivityStatus
            if status == .unique, let activeRouteIDs, let route = matches.first {
                if activeRouteIDs.contains(route.routeID) {
                    serviceActivityStatus = .departuresPresent
                } else {
                    serviceActivityStatus = canConfirmNoCourses ? .noCourses : .notEvaluable
                }
            } else {
                serviceActivityStatus = .notEvaluable
            }
            return NetworkCoverageIDFMEntry(
                reference: reference,
                serviceStatus: candidate.serviceStatus,
                routeStatus: status,
                matchingRoutes: matches,
                serviceActivityStatus: serviceActivityStatus
            )
        }.sorted { lhs, rhs in
            if lhs.serviceStatus != rhs.serviceStatus {
                return lhs.serviceStatus == .active
            }
            let nameOrder = lhs.reference.displayName.localizedStandardCompare(rhs.reference.displayName)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            let idOrder = LineReferenceMatcher.canonicalIdentifier(lhs.reference.idLine)
                .localizedStandardCompare(LineReferenceMatcher.canonicalIdentifier(rhs.reference.idLine))
            if idOrder != .orderedSame { return idOrder == .orderedAscending }
            return lhs.reference.id < rhs.reference.id
        }

        let activeGTFSRoutesWithoutEligibleIDFMReference: [GTFSRouteSummary]?
        if let routes, let activeRouteIDs {
            let eligibleIDLineIDs = Set(eligibleReferences.compactMap { candidate -> String? in
                let identifier = LineReferenceMatcher.canonicalIdentifier(candidate.reference.idLine)
                return identifier.isEmpty ? nil : identifier
            })
            activeGTFSRoutesWithoutEligibleIDFMReference = routes
                .filter { route in
                    activeRouteIDs.contains(route.routeID)
                        && !eligibleIDLineIDs.contains(LineReferenceMatcher.canonicalIdentifier(route.routeID))
                }
                .sorted { lhs, rhs in
                    let nameOrder = lhs.displayName.localizedStandardCompare(rhs.displayName)
                    if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
                    return lhs.routeID < rhs.routeID
                }
        } else {
            activeGTFSRoutesWithoutEligibleIDFMReference = nil
        }

        return NetworkCoverageIDFMAudit(
            referencesAvailable: true,
            routesAvailable: routes != nil,
            entries: entries,
            activeGTFSRoutesWithoutEligibleIDFMReference: activeGTFSRoutesWithoutEligibleIDFMReference,
            unknownDateReferenceCount: unknownDateReferenceCount,
            notYetValidReferenceCount: notYetValidReferenceCount,
            excludedOutsideStatusScopeCount: references.count - statusReferences.count
        )
    }

    static func build(
        routes: [GTFSRouteSummary],
        activeRouteIDs: Set<String>?,
        references: [NetworkLineReference]?,
        documents: [NetworkLineDocument]?,
        assignments: [DepotLineAssignment],
        contracts: [NetworkContractFeature],
        scenarioID: String,
        scenarioContractID: String,
        depots: [DepotReference],
        activeGTFSVersionID: String?,
        activeContractVersionID: String?
    ) -> [NetworkCoverageAuditEntry] {
        let referenceGroups = Dictionary(grouping: references ?? []) {
            LineReferenceMatcher.canonicalIdentifier($0.idLine)
        }
        let scenarioAssignments = assignments.filter {
            $0.scenarioID == scenarioID && $0.contractID == scenarioContractID
        }
        let assignmentsByRoute = Dictionary(grouping: scenarioAssignments, by: \.routeID)
        let depotNames = Dictionary(uniqueKeysWithValues: depots.map { ($0.id, $0.name) })
        var contractNames: [String: String] = [:]
        for contract in contracts {
            guard let contractID = contract.contractID, contractNames[contractID] == nil else { continue }
            contractNames[contractID] = contract.displayName
        }

        return routes.map { route in
            let matchingReferences = referenceGroups[LineReferenceMatcher.canonicalIdentifier(route.routeID)] ?? []
            let referenceStatus: NetworkCoverageReferenceStatus
            let uniqueReference: NetworkLineReference?
            if references == nil {
                referenceStatus = .unavailable
                uniqueReference = nil
            } else if matchingReferences.isEmpty {
                referenceStatus = .absent
                uniqueReference = nil
            } else if matchingReferences.count == 1 {
                referenceStatus = .unique
                uniqueReference = matchingReferences[0]
            } else {
                referenceStatus = .ambiguous
                uniqueReference = nil
            }

            let linkedDocuments: [NetworkLineDocument]
            let documentStatus: NetworkCoverageDocumentStatus
            if uniqueReference == nil {
                linkedDocuments = []
                documentStatus = referenceStatus == .unavailable ? .unavailable : .blockedByReference
            } else if let uniqueReference, let documents {
                let referenceID = LineReferenceMatcher.canonicalIdentifier(uniqueReference.idLine)
                linkedDocuments = documents.filter {
                    LineReferenceMatcher.canonicalIdentifier($0.idLine) == referenceID
                }.sorted {
                    if $0.documentType != $1.documentType { return $0.documentType < $1.documentType }
                    return $0.documentName.localizedStandardCompare($1.documentName) == .orderedAscending
                }
                documentStatus = linkedDocuments.isEmpty ? .none : .available
            } else {
                linkedDocuments = []
                documentStatus = .unavailable
            }

            let routeAssignments: [NetworkCoverageAssignment] = (assignmentsByRoute[route.routeID] ?? []).map { assignment in
                let versionStatus: NetworkCoverageVersionStatus
                if let activeGTFSVersionID, let activeContractVersionID {
                    versionStatus = assignment.gtfsVersionID == activeGTFSVersionID
                        && assignment.contractVersionID == activeContractVersionID
                        ? .activeVersions
                        : .differentVersions
                } else {
                    versionStatus = .unavailable
                }
                return NetworkCoverageAssignment(
                    assignment: assignment,
                    depotName: depotNames[assignment.depotID] ?? assignment.depotID,
                    contractName: contractNames[assignment.contractID],
                    versionStatus: versionStatus
                )
            }.sorted {
                if $0.depotName != $1.depotName {
                    return $0.depotName.localizedStandardCompare($1.depotName) == .orderedAscending
                }
                if $0.versionStatus != $1.versionStatus {
                    return $0.versionStatus == .activeVersions
                }
                let lhsDate = $0.assignment.evidenceDateIsVerified == true ? ($0.assignment.evidenceDate ?? .distantPast) : .distantPast
                let rhsDate = $1.assignment.evidenceDateIsVerified == true ? ($1.assignment.evidenceDate ?? .distantPast) : .distantPast
                return lhsDate > rhsDate
            }

            return NetworkCoverageAuditEntry(
                route: route,
                isActiveOnDate: activeRouteIDs.map { $0.contains(route.routeID) },
                referenceStatus: referenceStatus,
                referenceMatchCount: matchingReferences.count,
                reference: uniqueReference,
                documentStatus: documentStatus,
                documents: linkedDocuments,
                assignments: routeAssignments
            )
        }.sorted { lhs, rhs in
            if lhs.isActiveOnDate != rhs.isActiveOnDate {
                if lhs.isActiveOnDate == true { return true }
                if rhs.isActiveOnDate == true { return false }
            }
            let nameOrder = lhs.route.displayName.localizedStandardCompare(rhs.route.displayName)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return lhs.route.routeID < rhs.route.routeID
        }
    }

    private enum DateEligibility {
        case active
        case inactive
        case unknown
    }

    private static func dateEligibility(of reference: NetworkLineReference, on selectedDateKey: Int) -> DateEligibility {
        guard let validFromKey = idfmDateKey(reference.validFrom) else { return .unknown }
        guard validFromKey <= selectedDateKey else { return .inactive }

        let validTo = reference.validTo.trimmingCharacters(in: .whitespacesAndNewlines)
        // IDFM commonly leaves valid_todate empty for lines without a scheduled end date.
        guard !validTo.isEmpty else { return .active }
        guard let validToKey = idfmDateKey(validTo), validToKey >= validFromKey else { return .unknown }
        return selectedDateKey <= validToKey ? .active : .inactive
    }

    private static func idfmDateKey(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.split(separator: "-", omittingEmptySubsequences: false)
        guard components.count == 3,
              components[0].count == 4,
              components[1].count == 2,
              components[2].count == 2,
              components.allSatisfy({ $0.allSatisfy(\.isNumber) }) else { return nil }
        let compactDate = components.joined()
        guard let date = GTFSServiceDate.date(from: compactDate) else { return nil }
        return GTFSServiceDate.key(for: date, timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
    }

    private static func normalizedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

enum RegionalCoverageDateStatus: String, Codable, Hashable, Sendable {
    case validOnServiceDate
    case outsideValidity
    case unknown
}

enum RegionalCoverageRouteMatchStatus: String, Codable, Hashable, Sendable {
    case unavailable
    case missing
    case unique
    case multipleVariants
}

enum RegionalCoverageActivityStatus: String, Codable, Hashable, Sendable {
    case unavailable
    case outsideGTFSValidity
    case gtfsValidityUnknown
    case calendarUnavailable
    case departuresPresent
    case partialDepartureCoverage
    case activeTripsWithoutDepartures
    case noScheduledCourses
    case frequencyExpansionNotEvaluable
}

enum RegionalCoverageGeometryStatus: String, Codable, Hashable, Sendable {
    case unavailable
    case exactID
    case uniqueShortName
    case ambiguousShortName
    case absent
}

enum RegionalCoverageDocumentsStatus: String, Codable, Hashable, Sendable {
    case unavailable
    case noLinks
    case linksAvailable
}

enum RegionalCoverageTripShapeStatus: String, Codable, Hashable, Sendable {
    case noReference
    case available
    case invalid
    case unavailable
}

enum RegionalCoverageDocumentValidity: String, Codable, Hashable, Sendable {
    case validOnServiceDate
    case outsideValidity
    case unknown
}

struct RegionalCoverageDocumentLink: Codable, Hashable, Sendable {
    let id: String
    let name: String
    let type: String
    let url: String
    let validityRaw: String?
    let validity: RegionalCoverageDocumentValidity
}

struct RegionalCoverageShapeCoverage: Codable, Hashable, Sendable {
    let tripsWithShapeReference: Int
    let tripsWithoutShapeReference: Int
    let tripsWithAvailableShape: Int
    let tripsWithInvalidShape: Int
    let tripsWithUnavailableShape: Int
}

struct RegionalCoverageTripShapeIssue: Codable, Hashable, Sendable {
    let tripID: String
    let serviceID: String
    let departureSeconds: Int?
    let shapeID: String?
    let status: RegionalCoverageTripShapeStatus
}

struct RegionalCoverageRouteVariant: Codable, Hashable, Sendable {
    let routeID: String
    let shortName: String
    let longName: String
    let activityStatus: RegionalCoverageActivityStatus
    let activeTripTemplateCount: Int?
    let activeDepartureCount: Int?
    let activeTripsWithoutDepartureCount: Int?
    let shapeCoverage: RegionalCoverageShapeCoverage?
    let tripShapeIssues: [RegionalCoverageTripShapeIssue]
}

struct RegionalCoverageGeometry: Codable, Hashable, Sendable {
    let status: RegionalCoverageGeometryStatus
    let featureIDs: [String]
    let featureCount: Int
    let pathCount: Int
}

struct RegionalCoverageLineRecord: Codable, Hashable, Sendable {
    let sourceRecordID: String
    let idLine: String
    let name: String
    let shortName: String
    let status: String
    let dateStatus: RegionalCoverageDateStatus
    let validFrom: String
    let validTo: String
    let operatorRef: String
    let operatorName: String
    let networkName: String
    let transportSubmode: String
    let routeMatchStatus: RegionalCoverageRouteMatchStatus
    let routeVariants: [RegionalCoverageRouteVariant]
    let activityStatus: RegionalCoverageActivityStatus
    let commercialGeometry: RegionalCoverageGeometry
    let plans: [RegionalCoverageDocumentLink]
    let timetables: [RegionalCoverageDocumentLink]
    let otherDocuments: [RegionalCoverageDocumentLink]
    let documentsStatus: RegionalCoverageDocumentsStatus
    let malformedDocumentCount: Int
    let reasons: [String]
}

struct RegionalCoverageGTFSMetadata: Codable, Hashable, Sendable {
    let validFrom: String?
    let validThrough: String?
    let containsFrequenciesFile: Bool?
    let busRouteCount: Int?
    let busTripCount: Int?
    let tripScheduleCount: Int?
    let busStopCount: Int?
    let feedStopRecordCount: Int?
    let serviceCalendarCount: Int?
    let activeTripTemplateCount: Int?
    let activeDepartureCount: Int?
    let activeTripsWithoutDepartureCount: Int?
    let activeRouteCount: Int?
    let activeServiceCalendarCount: Int?
}

struct RegionalCoverageMatrixSummary: Codable, Hashable, Sendable {
    let candidateBusRecordCount: Int
    let eligibleOnServiceDateCount: Int
    let outsideValidityCount: Int
    let unknownDateValidityCount: Int
    let uniqueGTFSLineCount: Int
    let multipleGTFSVariantLineCount: Int
    let missingGTFSLineCount: Int
    let exactCommercialGeometryLineCount: Int
    let shortNameCommercialGeometryLineCount: Int
    let ambiguousCommercialGeometryLineCount: Int
    let missingCommercialGeometryLineCount: Int
    let linesWithPlanLinkCount: Int
    let linesWithTimetableLinkCount: Int
    let malformedDocumentRecordCount: Int
    let sourceRecordsOutsideBusActiveStatusCount: Int
    let activeGTFSRoutesWithoutEligibleIDFMReferenceCount: Int?
}

struct RegionalCoverageMatrix: Codable, Hashable, Sendable {
    let serviceDate: String
    let lineReferencesAvailable: Bool
    let gtfsAvailable: Bool
    let commercialGeometriesAvailable: Bool
    let lineDocumentsAvailable: Bool
    let gtfs: RegionalCoverageGTFSMetadata
    let summary: RegionalCoverageMatrixSummary
    let malformedDocumentReasons: [String: Int]
    let lines: [RegionalCoverageLineRecord]
}

enum RegionalCoverageMatrixBuilder {
    static func build(
        serviceDate: Date,
        references: [NetworkLineReference]?,
        inspection: GTFSFeedInspection?,
        documents: LineDocumentCSVParseResult?,
        geometries: [NetworkRouteGeometry]?
    ) -> RegionalCoverageMatrix {
        let dateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone)
        let serviceDateText = isoDate(serviceDate)
        let routes = inspection?.busRoutes
        let activeServiceIDs: Set<String>?
        if let inspection, let dateKey, !inspection.serviceCalendars.isEmpty {
            activeServiceIDs = Set(inspection.serviceCalendars.lazy
                .filter { $0.activeDates.contains(dateKey) }
                .map(\.serviceID))
        } else {
            activeServiceIDs = nil
        }

        let activeDepartures = inspection.flatMap { feed -> [GTFSServiceTripDeparture]? in
            guard let activeServiceIDs else { return nil }
            return feed.busTripDepartures.filter { activeServiceIDs.contains($0.serviceID) }
        }
        let activeSchedules = inspection.flatMap { feed -> [GTFSServiceTripSchedule]? in
            guard let activeServiceIDs else { return nil }
            return feed.busTripSchedules.filter { activeServiceIDs.contains($0.serviceID) }
        }
        let activeRouteIDs = activeDepartures.map { Set($0.map(\.routeID)) }
        let sourceReferences = references ?? []
        let candidates = sourceReferences.filter { reference in
            normalized(reference.transportMode) == "bus"
                && ["active", "prochainement active"].contains(normalized(reference.status))
        }
        let sourceReferencesByCanonicalID = Dictionary(grouping: candidates) {
            LineReferenceMatcher.canonicalIdentifier($0.idLine)
        }
        let routesByCanonicalID = Dictionary(grouping: routes ?? []) {
            LineReferenceMatcher.canonicalIdentifier($0.routeID)
        }
        let routesByShortName = Dictionary(grouping: (routes ?? []).filter { !$0.shortName.isEmpty }) {
            $0.shortName.lowercased()
        }
        let geometriesByCanonicalID = Dictionary(grouping: geometries ?? []) {
            LineReferenceMatcher.canonicalIdentifier($0.lineID)
        }
        let documentIssuesByCanonicalID = Dictionary(grouping: documents?.issues ?? []) {
            LineReferenceMatcher.canonicalIdentifier($0.idLine ?? "")
        }
        var shapeIDsByTripID: [String: String] = [:]
        for shapeReference in inspection?.busTripShapes.references ?? [] {
            shapeIDsByTripID[shapeReference.tripID] = shapeReference.shapeID
        }
        let availableShapeIDs = Set(inspection?.busTripShapes.shapes.map(\.shapeID) ?? [])
        let invalidShapeIDs = Set(inspection?.quality.invalidShapeIDs ?? [])
        let selectedDateIsWithinGTFSValidity = inspection.flatMap { feed -> Bool? in
            guard let dateKey,
                  let validFrom = feed.validFrom,
                  let validThrough = feed.validThrough,
                  let validFromKey = GTFSServiceDate.key(for: validFrom, timeZone: GTFSServiceDate.parisTimeZone),
                  let validThroughKey = GTFSServiceDate.key(for: validThrough, timeZone: GTFSServiceDate.parisTimeZone) else {
                return nil
            }
            return (validFromKey...validThroughKey).contains(dateKey)
        }
        let hasFrequencyFile = inspection?.quality.containsFrequenciesFile

        let networkAudit = NetworkCoverageAudit.buildIDFMToGTFS(
            references: references,
            routes: routes,
            activeRouteIDs: activeRouteIDs,
            canConfirmNoCourses: hasFrequencyFile == false,
            selectedDate: serviceDate
        )
        let eligibleByID = Dictionary(grouping: networkAudit.entries, by: \.reference.id)

        let lines = candidates.map { reference -> RegionalCoverageLineRecord in
            let canonicalID = LineReferenceMatcher.canonicalIdentifier(reference.idLine)
            let matchRoutes = routesByCanonicalID[canonicalID, default: []].sorted(by: routeOrder)
            let routeMatchStatus: RegionalCoverageRouteMatchStatus
            if routes == nil {
                routeMatchStatus = .unavailable
            } else {
                switch matchRoutes.count {
                case 0: routeMatchStatus = .missing
                case 1: routeMatchStatus = .unique
                default: routeMatchStatus = .multipleVariants
                }
            }

            let dateStatus: RegionalCoverageDateStatus
            switch reference.isActive(on: serviceDate) {
            case .some(true): dateStatus = .validOnServiceDate
            case .some(false): dateStatus = .outsideValidity
            case .none: dateStatus = .unknown
            }

            let variants = matchRoutes.map { route in
                routeVariant(
                    route,
                    activeDepartures: activeDepartures,
                    activeSchedules: activeSchedules,
                    shapeIDsByTripID: shapeIDsByTripID,
                    availableShapeIDs: availableShapeIDs,
                    invalidShapeIDs: invalidShapeIDs,
                    selectedDateIsWithinGTFSValidity: selectedDateIsWithinGTFSValidity,
                    hasFrequencyFile: hasFrequencyFile
                )
            }
            let activityStatus = lineActivityStatus(
                variants: variants,
                routeMatchStatus: routeMatchStatus,
                selectedDateIsWithinGTFSValidity: selectedDateIsWithinGTFSValidity,
                activeServiceIDs: activeServiceIDs,
                hasFrequencyFile: hasFrequencyFile,
                gtfsAvailable: inspection != nil
            )
            let geometry = commercialGeometry(
                for: reference,
                routeVariants: matchRoutes,
                allRoutes: routes ?? [],
                geometries: geometries,
                geometriesByCanonicalID: geometriesByCanonicalID,
                sourceReferencesByCanonicalID: sourceReferencesByCanonicalID,
                routesByShortName: routesByShortName
            )
            let linkedDocuments = documents.map {
                LineDocumentStore.documents(fromCatalog: $0.documents, for: reference.idLine)
            }
            let documentLinks = (linkedDocuments ?? []).map { document in
                documentLink(document, serviceDate: serviceDate)
            }
            let plans = documentLinks.filter { normalized($0.type) == "plan" }.sorted(by: documentOrder)
            let timetables = documentLinks.filter {
                ["horaire", "fiche horaire"].contains(normalized($0.type))
            }.sorted(by: documentOrder)
            let otherDocuments = documentLinks.filter {
                normalized($0.type) != "plan"
                    && !["horaire", "fiche horaire"].contains(normalized($0.type))
            }.sorted(by: documentOrder)
            let malformedDocumentCount = documentIssuesByCanonicalID[canonicalID, default: []].count
            let documentStatus: RegionalCoverageDocumentsStatus
            if documents == nil {
                documentStatus = .unavailable
            } else {
                documentStatus = documentLinks.isEmpty ? .noLinks : .linksAvailable
            }

            var reasons: [String] = []
            if dateStatus == .outsideValidity { reasons.append("idfm_reference_outside_validity_on_service_date") }
            if dateStatus == .unknown { reasons.append("idfm_reference_validity_unknown") }
            if routeMatchStatus == .missing { reasons.append("no_gtfs_route_matches_id_line") }
            if routeMatchStatus == .multipleVariants { reasons.append("multiple_gtfs_route_variants_share_id_line") }
            if routeMatchStatus == .unavailable { reasons.append("gtfs_routes_unavailable") }
            if activityStatus == .outsideGTFSValidity { reasons.append("service_date_outside_gtfs_validity") }
            if activityStatus == .gtfsValidityUnknown { reasons.append("gtfs_validity_range_unknown") }
            if activityStatus == .calendarUnavailable { reasons.append("gtfs_service_calendar_unavailable") }
            if activityStatus == .frequencyExpansionNotEvaluable { reasons.append("frequencies_file_not_expanded") }
            if activityStatus == .partialDepartureCoverage { reasons.append("some_active_gtfs_trips_have_no_departure_rows") }
            if activityStatus == .activeTripsWithoutDepartures { reasons.append("active_gtfs_trips_without_departure_rows") }
            if activityStatus == .noScheduledCourses { reasons.append("no_gtfs_departures_on_service_date") }
            if geometry.status == .absent { reasons.append("no_commercial_geometry_match") }
            if geometry.status == .ambiguousShortName { reasons.append("commercial_geometry_short_name_ambiguous") }
            if geometry.status == .unavailable { reasons.append("commercial_geometry_source_unavailable") }
            if plans.isEmpty { reasons.append("no_plan_link") }
            if timetables.isEmpty { reasons.append("no_timetable_link") }
            if documentStatus == .unavailable { reasons.append("line_document_source_unavailable") }
            if malformedDocumentCount > 0 { reasons.append("malformed_line_document_records_for_id_line") }
            if sourceReferencesByCanonicalID[canonicalID, default: []].count > 1 {
                reasons.append("duplicate_active_idfm_source_rows_for_id_line")
            }
            if dateStatus == .validOnServiceDate && eligibleByID[reference.id] == nil {
                reasons.append("network_coverage_audit_did_not_produce_active_entry")
            }

            return RegionalCoverageLineRecord(
                sourceRecordID: reference.id,
                idLine: reference.idLine,
                name: reference.nameLine,
                shortName: reference.shortNameLine,
                status: reference.status,
                dateStatus: dateStatus,
                validFrom: reference.validFrom,
                validTo: reference.validTo,
                operatorRef: reference.operatorRef,
                operatorName: reference.operatorName,
                networkName: reference.networkName,
                transportSubmode: reference.transportSubmode,
                routeMatchStatus: routeMatchStatus,
                routeVariants: variants,
                activityStatus: activityStatus,
                commercialGeometry: geometry,
                plans: plans,
                timetables: timetables,
                otherDocuments: otherDocuments,
                documentsStatus: documentStatus,
                malformedDocumentCount: malformedDocumentCount,
                reasons: reasons.sorted()
            )
        }.sorted(by: lineOrder)

        var malformedDocumentReasons: [String: Int] = [:]
        for issue in documents?.issues ?? [] {
            malformedDocumentReasons[issue.reason, default: 0] += 1
        }
        let frequenciesPresent = hasFrequencyFile == true
        let activeTripIDs = Set(activeSchedules?.map(\.tripID) ?? [])
        let activeDepartureTripIDs = Set(activeDepartures?.map(\.tripID) ?? [])
        let allActiveDepartureCount = frequenciesPresent ? nil : activeDepartures?.count
        let activeTripsWithoutDepartureCount: Int?
        if frequenciesPresent || activeSchedules == nil || activeDepartures == nil {
            activeTripsWithoutDepartureCount = nil
        } else {
            activeTripsWithoutDepartureCount = activeTripIDs.subtracting(activeDepartureTripIDs).count
        }
        let gtfs = RegionalCoverageGTFSMetadata(
            validFrom: inspection?.validFrom.map(isoDate),
            validThrough: inspection?.validThrough.map(isoDate),
            containsFrequenciesFile: hasFrequencyFile,
            busRouteCount: inspection?.busRouteCount,
            busTripCount: inspection?.quality.busTripCount,
            tripScheduleCount: inspection?.quality.tripScheduleCount,
            busStopCount: inspection?.busStopCount,
            feedStopRecordCount: inspection?.feedStopCount,
            serviceCalendarCount: inspection?.serviceCalendars.count,
            activeTripTemplateCount: activeSchedules == nil ? nil : activeTripIDs.count,
            activeDepartureCount: allActiveDepartureCount,
            activeTripsWithoutDepartureCount: activeTripsWithoutDepartureCount,
            activeRouteCount: activeSchedules == nil ? nil : Set(activeSchedules?.map(\.routeID) ?? []).count,
            activeServiceCalendarCount: inspection == nil ? nil : activeServiceIDs?.count
        )
        let dateEligibleLines = lines.filter { $0.dateStatus == .validOnServiceDate }
        let summary = RegionalCoverageMatrixSummary(
            candidateBusRecordCount: candidates.count,
            eligibleOnServiceDateCount: dateEligibleLines.count,
            outsideValidityCount: lines.filter { $0.dateStatus == .outsideValidity }.count,
            unknownDateValidityCount: lines.filter { $0.dateStatus == .unknown }.count,
            uniqueGTFSLineCount: lines.filter { $0.routeMatchStatus == .unique }.count,
            multipleGTFSVariantLineCount: lines.filter { $0.routeMatchStatus == .multipleVariants }.count,
            missingGTFSLineCount: lines.filter { $0.routeMatchStatus == .missing }.count,
            exactCommercialGeometryLineCount: lines.filter { $0.commercialGeometry.status == .exactID }.count,
            shortNameCommercialGeometryLineCount: lines.filter { $0.commercialGeometry.status == .uniqueShortName }.count,
            ambiguousCommercialGeometryLineCount: lines.filter { $0.commercialGeometry.status == .ambiguousShortName }.count,
            missingCommercialGeometryLineCount: lines.filter { $0.commercialGeometry.status == .absent }.count,
            linesWithPlanLinkCount: lines.filter { !$0.plans.isEmpty }.count,
            linesWithTimetableLinkCount: lines.filter { !$0.timetables.isEmpty }.count,
            malformedDocumentRecordCount: documents?.issues.count ?? 0,
            sourceRecordsOutsideBusActiveStatusCount: sourceReferences.count - candidates.count,
            activeGTFSRoutesWithoutEligibleIDFMReferenceCount: networkAudit.activeGTFSRoutesWithoutEligibleIDFMReference?.count
        )

        return RegionalCoverageMatrix(
            serviceDate: serviceDateText,
            lineReferencesAvailable: references != nil,
            gtfsAvailable: inspection != nil,
            commercialGeometriesAvailable: geometries != nil,
            lineDocumentsAvailable: documents != nil,
            gtfs: gtfs,
            summary: summary,
            malformedDocumentReasons: malformedDocumentReasons,
            lines: lines
        )
    }

    private static func routeVariant(
        _ route: GTFSRouteSummary,
        activeDepartures: [GTFSServiceTripDeparture]?,
        activeSchedules: [GTFSServiceTripSchedule]?,
        shapeIDsByTripID: [String: String],
        availableShapeIDs: Set<String>,
        invalidShapeIDs: Set<String>,
        selectedDateIsWithinGTFSValidity: Bool?,
        hasFrequencyFile: Bool?
    ) -> RegionalCoverageRouteVariant {
        guard let selectedDateIsWithinGTFSValidity else {
            return RegionalCoverageRouteVariant(
                routeID: route.routeID,
                shortName: route.shortName,
                longName: route.longName,
                activityStatus: .gtfsValidityUnknown,
                activeTripTemplateCount: nil,
                activeDepartureCount: nil,
                activeTripsWithoutDepartureCount: nil,
                shapeCoverage: nil,
                tripShapeIssues: []
            )
        }
        guard selectedDateIsWithinGTFSValidity else {
            return RegionalCoverageRouteVariant(
                routeID: route.routeID,
                shortName: route.shortName,
                longName: route.longName,
                activityStatus: .outsideGTFSValidity,
                activeTripTemplateCount: nil,
                activeDepartureCount: nil,
                activeTripsWithoutDepartureCount: nil,
                shapeCoverage: nil,
                tripShapeIssues: []
            )
        }
        guard let activeDepartures, let activeSchedules else {
            return RegionalCoverageRouteVariant(
                routeID: route.routeID,
                shortName: route.shortName,
                longName: route.longName,
                activityStatus: .calendarUnavailable,
                activeTripTemplateCount: nil,
                activeDepartureCount: nil,
                activeTripsWithoutDepartureCount: nil,
                shapeCoverage: nil,
                tripShapeIssues: []
            )
        }

        let routeDepartures = activeDepartures.filter { $0.routeID == route.routeID }
        let routeSchedules = activeSchedules.filter { $0.routeID == route.routeID }
        let activeTripIDs = Set(routeSchedules.map(\.tripID))
        var departureByTripID: [String: GTFSServiceTripDeparture] = [:]
        for departure in routeDepartures {
            departureByTripID[departure.tripID] = departure
        }
        var noShapeCount = 0
        var shapeReferenceCount = 0
        var availableShapeCount = 0
        var invalidShapeCount = 0
        var unavailableShapeCount = 0
        var tripShapeIssues: [RegionalCoverageTripShapeIssue] = []
        for schedule in routeSchedules.sorted(by: { $0.tripID < $1.tripID }) {
            let shapeID = schedule.shapeID ?? shapeIDsByTripID[schedule.tripID]
            let shapeStatus: RegionalCoverageTripShapeStatus
            guard let shapeID else {
                noShapeCount += 1
                shapeStatus = .noReference
                tripShapeIssues.append(RegionalCoverageTripShapeIssue(
                    tripID: schedule.tripID,
                    serviceID: schedule.serviceID,
                    departureSeconds: departureByTripID[schedule.tripID]?.departureSeconds,
                    shapeID: nil,
                    status: shapeStatus
                ))
                continue
            }
            shapeReferenceCount += 1
            if availableShapeIDs.contains(shapeID) {
                availableShapeCount += 1
                shapeStatus = .available
            } else if invalidShapeIDs.contains(shapeID) {
                invalidShapeCount += 1
                shapeStatus = .invalid
            } else {
                unavailableShapeCount += 1
                shapeStatus = .unavailable
            }
            if shapeStatus != .available {
                tripShapeIssues.append(RegionalCoverageTripShapeIssue(
                    tripID: schedule.tripID,
                    serviceID: schedule.serviceID,
                    departureSeconds: departureByTripID[schedule.tripID]?.departureSeconds,
                    shapeID: shapeID,
                    status: shapeStatus
                ))
            }
        }
        let activityStatus: RegionalCoverageActivityStatus
        let tripsWithoutDepartureCount = hasFrequencyFile == true
            ? nil
            : activeTripIDs.subtracting(Set(routeDepartures.map(\.tripID))).count
        if hasFrequencyFile == true {
            activityStatus = .frequencyExpansionNotEvaluable
        } else if (tripsWithoutDepartureCount ?? 0) > 0, !routeDepartures.isEmpty {
            activityStatus = .partialDepartureCoverage
        } else if !routeDepartures.isEmpty {
            activityStatus = .departuresPresent
        } else if !activeTripIDs.isEmpty {
            activityStatus = .activeTripsWithoutDepartures
        } else {
            activityStatus = .noScheduledCourses
        }
        let shapeCoverage = RegionalCoverageShapeCoverage(
            tripsWithShapeReference: shapeReferenceCount,
            tripsWithoutShapeReference: noShapeCount,
            tripsWithAvailableShape: availableShapeCount,
            tripsWithInvalidShape: invalidShapeCount,
            tripsWithUnavailableShape: unavailableShapeCount
        )
        return RegionalCoverageRouteVariant(
            routeID: route.routeID,
            shortName: route.shortName,
            longName: route.longName,
            activityStatus: activityStatus,
            activeTripTemplateCount: activeTripIDs.count,
            activeDepartureCount: hasFrequencyFile == true ? nil : routeDepartures.count,
            activeTripsWithoutDepartureCount: tripsWithoutDepartureCount,
            shapeCoverage: shapeCoverage,
            tripShapeIssues: tripShapeIssues
        )
    }

    private static func lineActivityStatus(
        variants: [RegionalCoverageRouteVariant],
        routeMatchStatus: RegionalCoverageRouteMatchStatus,
        selectedDateIsWithinGTFSValidity: Bool?,
        activeServiceIDs: Set<String>?,
        hasFrequencyFile: Bool?,
        gtfsAvailable: Bool
    ) -> RegionalCoverageActivityStatus {
        guard gtfsAvailable, routeMatchStatus != .unavailable else { return .unavailable }
        guard let selectedDateIsWithinGTFSValidity else { return .gtfsValidityUnknown }
        guard selectedDateIsWithinGTFSValidity else { return .outsideGTFSValidity }
        guard activeServiceIDs != nil else { return .calendarUnavailable }
        guard !variants.isEmpty else { return .unavailable }
        if hasFrequencyFile == true { return .frequencyExpansionNotEvaluable }
        if variants.contains(where: { ($0.activeDepartureCount ?? 0) > 0 }) {
            if variants.contains(where: { ($0.activeTripsWithoutDepartureCount ?? 0) > 0 }) {
                return .partialDepartureCoverage
            }
            return .departuresPresent
        }
        if variants.contains(where: { ($0.activeTripTemplateCount ?? 0) > 0 }) {
            return .activeTripsWithoutDepartures
        }
        return .noScheduledCourses
    }

    private static func commercialGeometry(
        for reference: NetworkLineReference,
        routeVariants: [GTFSRouteSummary],
        allRoutes: [GTFSRouteSummary],
        geometries: [NetworkRouteGeometry]?,
        geometriesByCanonicalID: [String: [NetworkRouteGeometry]],
        sourceReferencesByCanonicalID: [String: [NetworkLineReference]],
        routesByShortName: [String: [GTFSRouteSummary]]
    ) -> RegionalCoverageGeometry {
        guard let geometries else {
            return RegionalCoverageGeometry(status: .unavailable, featureIDs: [], featureCount: 0, pathCount: 0)
        }
        let canonicalID = LineReferenceMatcher.canonicalIdentifier(reference.idLine)
        var matches = geometriesByCanonicalID[canonicalID, default: []]
        if matches.isEmpty {
            for route in routeVariants {
                matches += geometriesByCanonicalID[LineReferenceMatcher.canonicalIdentifier(route.routeID), default: []]
            }
        }
        var status: RegionalCoverageGeometryStatus
        if !matches.isEmpty {
            status = .exactID
        } else {
            let shortName = reference.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let shortNameKey = shortName.lowercased()
            let nameMatches = geometries.filter {
                !$0.shortName.isEmpty && $0.shortName.localizedCaseInsensitiveCompare(shortName) == .orderedSame
            }
            let geometryLineIDs = Set(nameMatches.map { LineReferenceMatcher.canonicalIdentifier($0.lineID) })
            let sourceLineIDs = Set((sourceReferencesByCanonicalID.values.flatMap { $0 }).filter {
                !$0.shortNameLine.isEmpty && $0.shortNameLine.localizedCaseInsensitiveCompare(shortName) == .orderedSame
            }.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) })
            let routeNameMatches = routesByShortName[shortNameKey, default: []]
            let matcherMatches = routeVariants.flatMap { route in
                RouteGeometryMatcher.matches(route: route, among: allRoutes, geometries: geometries)
            }
            if !matcherMatches.isEmpty {
                matches = matcherMatches
                status = .uniqueShortName
            } else if !nameMatches.isEmpty,
                      geometryLineIDs.count == 1,
                      sourceLineIDs.count == 1,
                      (routeNameMatches.isEmpty || routeNameMatches.count == 1) {
                matches = nameMatches
                status = .uniqueShortName
            } else if !nameMatches.isEmpty {
                status = .ambiguousShortName
            } else {
                status = .absent
            }
        }
        matches = Dictionary(grouping: matches, by: \.id).compactMap { $0.value.first }
            .sorted { $0.id < $1.id }
        if matches.isEmpty && status != .ambiguousShortName { status = .absent }
        return RegionalCoverageGeometry(
            status: status,
            featureIDs: matches.map(\.id),
            featureCount: matches.count,
            pathCount: matches.reduce(0) { $0 + $1.paths.count }
        )
    }

    private static func documentLink(
        _ document: NetworkLineDocument,
        serviceDate: Date
    ) -> RegionalCoverageDocumentLink {
        let validityRaw = attribute(named: "date_validite", in: document.attributes)
        let validity = documentValidity(validityRaw, serviceDate: serviceDate)
        return RegionalCoverageDocumentLink(
            id: document.id,
            name: document.documentName,
            type: document.documentType,
            url: document.documentURL,
            validityRaw: validityRaw,
            validity: validity
        )
    }

    private static func documentValidity(_ raw: String?, serviceDate: Date) -> RegionalCoverageDocumentValidity {
        guard let raw else { return .unknown }
        let components = raw.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2,
              let start = idfmDate(components[0]),
              let end = idfmDate(components[1]),
              let dateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone),
              start <= end else { return .unknown }
        return (start...end).contains(dateKey) ? .validOnServiceDate : .outsideValidity
    }

    private static func idfmDate(_ value: Substring) -> Int? {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let date = GTFSServiceDate.date(from: parts.joined()) else { return nil }
        return GTFSServiceDate.key(for: date, timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
    }

    private static func attribute(named name: String, in attributes: [String: String]) -> String? {
        let target = normalized(name)
        guard let key = attributes.keys.first(where: { normalized($0) == target }) else { return nil }
        let value = attributes[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func isoDate(_ date: Date) -> String {
        let components = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
            .dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return "unknown" }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func routeOrder(_ lhs: GTFSRouteSummary, _ rhs: GTFSRouteSummary) -> Bool {
        if lhs.shortName != rhs.shortName { return lhs.shortName.localizedStandardCompare(rhs.shortName) == .orderedAscending }
        if lhs.longName != rhs.longName { return lhs.longName.localizedStandardCompare(rhs.longName) == .orderedAscending }
        return lhs.routeID < rhs.routeID
    }

    private static func lineOrder(_ lhs: RegionalCoverageLineRecord, _ rhs: RegionalCoverageLineRecord) -> Bool {
        let nameOrder = lhs.shortName.localizedStandardCompare(rhs.shortName)
        if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
        let idOrder = LineReferenceMatcher.canonicalIdentifier(lhs.idLine)
            .localizedStandardCompare(LineReferenceMatcher.canonicalIdentifier(rhs.idLine))
        if idOrder != .orderedSame { return idOrder == .orderedAscending }
        return lhs.sourceRecordID < rhs.sourceRecordID
    }

    private static func documentOrder(_ lhs: RegionalCoverageDocumentLink, _ rhs: RegionalCoverageDocumentLink) -> Bool {
        let nameOrder = lhs.name.localizedStandardCompare(rhs.name)
        if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
        return lhs.url < rhs.url
    }
}
