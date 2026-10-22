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
