import Foundation

struct PassengerAnalyticsFilter: Hashable, Sendable {
    let startAt: Date?
    let endAt: Date?
    let routeID: String?
    let vehicleID: String?

    init(
        startAt: Date? = nil,
        endAt: Date? = nil,
        routeID: String? = nil,
        vehicleID: String? = nil
    ) {
        if let startAt, let endAt, startAt > endAt {
            self.startAt = endAt
            self.endAt = startAt
        } else {
            self.startAt = startAt
            self.endAt = endAt
        }
        self.routeID = Self.normalizedIdentifier(routeID)
        self.vehicleID = Self.normalizedIdentifier(vehicleID)
    }

    func includes(date: Date, routeID candidateRouteID: String, vehicleID candidateVehicleID: String) -> Bool {
        if let startAt, date < startAt { return false }
        if let endAt, date > endAt { return false }
        if let routeID, routeID != candidateRouteID { return false }
        if let vehicleID, vehicleID != candidateVehicleID { return false }
        return true
    }

    private static func normalizedIdentifier(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }
}

enum PassengerAnalyticsGrouping: String, CaseIterable, Identifiable, Sendable {
    case line
    case bus
    case course
    case stop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .line: "Ligne"
        case .bus: "Bus"
        case .course: "Course"
        case .stop: "Arrêt"
        }
    }
}

struct PassengerAccessSatisfaction: Hashable, Sendable {
    let score: Int?
    let boardedArrivals: Int
    let leftBehindArrivals: Int
    let sampleCount: Int

    var observedArrivalCount: Int { boardedArrivals + leftBehindArrivals }
}

struct PassengerComfortSatisfaction: Hashable, Sendable {
    let score: Int?
    let sampleCount: Int
    let estimatedCapacitySampleCount: Int
}

struct PassengerConnectionSatisfaction: Hashable, Sendable {
    let score: Int?
    let attemptedPassengerCount: Int
    let boardedPassengerCount: Int
    let missedPassengerCount: Int
    let pendingGroupCount: Int
    let pendingPassengerCount: Int
}

struct PassengerSatisfactionSummary: Hashable, Sendable {
    let access: PassengerAccessSatisfaction
    let comfort: PassengerComfortSatisfaction
    let connections: PassengerConnectionSatisfaction

    var coveredComponentCount: Int {
        [access.score, comfort.score, connections.score].compactMap { $0 }.count
    }

    var score: Int? {
        let scores = [access.score, comfort.score, connections.score].compactMap { $0 }
        guard !scores.isEmpty else { return nil }
        return Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
    }
}

struct PassengerAnalyticsTotals: Hashable, Sendable {
    private(set) var boardings = 0
    private(set) var validationDataBoardings = 0
    private(set) var validations = 0
    private(set) var unvalidatedBoardings = 0
    private(set) var navigoSubscriptionCount = 0
    private(set) var singleTicketCount = 0
    private(set) var reducedFareCount = 0
    private(set) var freeTravelCount = 0
    private(set) var maximumOccupancyPercent: Int?
    private(set) var redirectedPassengerCount = 0
    private(set) var leftBehindPassengerCount = 0
    private(set) var displacedPassengerCount = 0
    private(set) var satisfactionAccessBoardedArrivals = 0
    private(set) var satisfactionAccessLeftBehindArrivals = 0
    private(set) var satisfactionAccessSampleCount = 0
    private(set) var satisfactionComfortPointTotal = 0
    private(set) var satisfactionComfortSampleCount = 0
    private(set) var satisfactionEstimatedCapacitySampleCount = 0
    private(set) var satisfactionConnectionAttemptCount = 0
    private(set) var satisfactionConnectionBoardedCount = 0
    private(set) var satisfactionConnectionMissedCount = 0
    private(set) var satisfactionPendingConnectionGroupCount = 0
    private(set) var satisfactionPendingConnectionPassengerCount = 0

    var validationRate: Double? {
        guard validationDataBoardings > 0 else { return nil }
        return Double(validations) / Double(validationDataBoardings)
    }

    var satisfaction: PassengerSatisfactionSummary {
        let accessDenominator = satisfactionAccessBoardedArrivals + satisfactionAccessLeftBehindArrivals
        let access = PassengerAccessSatisfaction(
            score: Self.percentage(
                numerator: satisfactionAccessBoardedArrivals,
                denominator: accessDenominator
            ),
            boardedArrivals: satisfactionAccessBoardedArrivals,
            leftBehindArrivals: satisfactionAccessLeftBehindArrivals,
            sampleCount: satisfactionAccessSampleCount
        )
        let comfort = PassengerComfortSatisfaction(
            score: satisfactionComfortSampleCount > 0
                ? Int((Double(satisfactionComfortPointTotal) / Double(satisfactionComfortSampleCount)).rounded())
                : nil,
            sampleCount: satisfactionComfortSampleCount,
            estimatedCapacitySampleCount: satisfactionEstimatedCapacitySampleCount
        )
        let connections = PassengerConnectionSatisfaction(
            score: Self.percentage(
                numerator: satisfactionConnectionBoardedCount,
                denominator: satisfactionConnectionAttemptCount
            ),
            attemptedPassengerCount: satisfactionConnectionAttemptCount,
            boardedPassengerCount: satisfactionConnectionBoardedCount,
            missedPassengerCount: satisfactionConnectionMissedCount,
            pendingGroupCount: satisfactionPendingConnectionGroupCount,
            pendingPassengerCount: satisfactionPendingConnectionPassengerCount
        )
        return PassengerSatisfactionSummary(access: access, comfort: comfort, connections: connections)
    }

    func validationCount(for type: PassengerValidationType) -> Int {
        switch type {
        case .navigoSubscription: navigoSubscriptionCount
        case .singleTicket: singleTicketCount
        case .reducedFare: reducedFareCount
        case .freeTravel: freeTravelCount
        }
    }

    fileprivate mutating func include(_ exchange: PassengerStopExchange) {
        boardings += max(0, exchange.boardedCount)
        if let breakdown = exchange.validationBreakdown,
           breakdown.boardedCount == max(0, exchange.boardedCount) {
            validationDataBoardings += breakdown.boardedCount
            validations += breakdown.validatedCount
            unvalidatedBoardings += breakdown.unvalidatedCount
            navigoSubscriptionCount += breakdown.validationCount(for: .navigoSubscription)
            singleTicketCount += breakdown.validationCount(for: .singleTicket)
            reducedFareCount += breakdown.validationCount(for: .reducedFare)
            freeTravelCount += breakdown.validationCount(for: .freeTravel)
        }

        let occupancyPercent = PassengerLoadPresentation(
            passengerCount: exchange.onboardAfterExchange,
            capacity: exchange.capacity,
            capacityIsEstimated: exchange.capacityIsEstimated
        ).occupancyPercent
        maximumOccupancyPercent = max(maximumOccupancyPercent ?? 0, occupancyPercent)
        redirectedPassengerCount += max(0, exchange.redirectedPassengerCount ?? 0)
        leftBehindPassengerCount += max(0, exchange.newlyLeftBehindCount ?? exchange.leftBehindCount)

        if exchange.accessBoardingSampleEligible == true,
           let boardedArrivals = exchange.newlyBoardedArrivalsCount,
           let leftBehindArrivals = exchange.newlyLeftBehindCount {
            satisfactionAccessBoardedArrivals += max(0, boardedArrivals)
            satisfactionAccessLeftBehindArrivals += max(0, leftBehindArrivals)
            satisfactionAccessSampleCount += 1
        }

        if exchange.stopWasClosed != true,
           (exchange.onboardAfterExchange > 0 || exchange.boardedCount > 0) {
            let occupancy = PassengerLoadPresentation(
                passengerCount: exchange.onboardAfterExchange,
                capacity: exchange.capacity,
                capacityIsEstimated: exchange.capacityIsEstimated
            ).occupancyPercent
            satisfactionComfortPointTotal += occupancy >= 100 ? 0 : (occupancy >= 80 ? 50 : 100)
            satisfactionComfortSampleCount += 1
            if exchange.capacityIsEstimated {
                satisfactionEstimatedCapacitySampleCount += 1
            }
        }

        if let attempts = exchange.connectingTripAttemptCount,
           let boarded = exchange.connectingTripBoardedCount {
            let safeAttempts = max(0, attempts)
            let safeBoarded = min(safeAttempts, max(0, boarded))
            satisfactionConnectionAttemptCount += safeAttempts
            satisfactionConnectionBoardedCount += safeBoarded
            satisfactionConnectionMissedCount += safeAttempts - safeBoarded
        }
    }

    fileprivate mutating func includePendingConnection(_ transfer: PassengerTransferQueueEntry) {
        guard transfer.intendedTripID != nil, transfer.passengerCount > 0 else { return }
        satisfactionPendingConnectionGroupCount += 1
        satisfactionPendingConnectionPassengerCount += transfer.passengerCount
    }

    fileprivate mutating func includeDisplaced(_ passengerCount: Int) {
        displacedPassengerCount += max(0, passengerCount)
    }

    fileprivate mutating func includeRedirected(_ passengerCount: Int) {
        redirectedPassengerCount += max(0, passengerCount)
    }

    private static func percentage(numerator: Int, denominator: Int) -> Int? {
        guard denominator > 0 else { return nil }
        let boundedNumerator = min(denominator, max(0, numerator))
        return Int((Double(boundedNumerator) / Double(denominator) * 100).rounded())
    }
}

struct PassengerAnalyticsRow: Hashable, Identifiable, Sendable {
    let id: String
    let label: String
    let totals: PassengerAnalyticsTotals
}

struct PassengerAnalyticsSnapshot: Hashable, Sendable {
    let totals: PassengerAnalyticsTotals
    let rows: [PassengerAnalyticsRow]

    var boardings: Int { totals.boardings }
    var validationDataBoardings: Int { totals.validationDataBoardings }
    var validations: Int { totals.validations }
    var unvalidatedBoardings: Int { totals.unvalidatedBoardings }
    var validationRate: Double? { totals.validationRate }
    var maximumOccupancyPercent: Int? { totals.maximumOccupancyPercent }
    var redirectedPassengerCount: Int { totals.redirectedPassengerCount }
    var leftBehindPassengerCount: Int { totals.leftBehindPassengerCount }
    var displacedPassengerCount: Int { totals.displacedPassengerCount }
    var satisfaction: PassengerSatisfactionSummary { totals.satisfaction }

    func validationCount(for type: PassengerValidationType) -> Int {
        totals.validationCount(for: type)
    }
}

enum PassengerAnalytics {
    static func snapshot(
        exchanges: [PassengerStopExchange],
        incidents: [VehicleIncident] = [],
        events: [SimulationEvent] = [],
        pendingTransfers: [PassengerTransferQueueEntry] = [],
        filter: PassengerAnalyticsFilter = PassengerAnalyticsFilter(),
        grouping: PassengerAnalyticsGrouping
    ) -> PassengerAnalyticsSnapshot {
        var totals = PassengerAnalyticsTotals()
        var buckets: [String: Bucket] = [:]

        for exchange in exchanges where filter.includes(
            date: exchange.occurredAt,
            routeID: exchange.routeID,
            vehicleID: exchange.vehicleID
        ) {
            totals.include(exchange)
            let group = groupIdentity(
                grouping: grouping,
                routeID: exchange.routeID,
                vehicleID: exchange.vehicleID,
                tripID: exchange.tripID,
                stopID: exchange.stopID,
                stopName: exchange.stopName,
                occurredAt: exchange.occurredAt
            )
            var bucket = buckets[group.id] ?? Bucket(label: group.label)
            bucket.totals.include(exchange)
            buckets[group.id] = bucket
        }

        for incident in incidents where filter.includes(
            date: incident.occurredAt,
            routeID: incident.routeID,
            vehicleID: incident.vehicleID
        ) {
            totals.includeDisplaced(incident.displacedPassengerCount)
            let group = groupIdentity(
                grouping: grouping,
                routeID: incident.routeID,
                vehicleID: incident.vehicleID,
                tripID: incident.tripID,
                stopID: incident.stopID,
                stopName: incident.stopName,
                occurredAt: incident.occurredAt
            )
            var bucket = buckets[group.id] ?? Bucket(label: group.label)
            bucket.totals.includeDisplaced(incident.displacedPassengerCount)
            buckets[group.id] = bucket
        }

        for event in events {
            let disruption: (routeID: String, vehicleID: String, tripID: String, stopID: String, stopName: String, displaced: Int, redirected: Int)?
            switch event.kind {
            case let .busServiceCompletedAtClosedStop(tripID, vehicleID, routeID, stopID, stopName, _, _, strandedPassengerCount):
                disruption = (routeID, vehicleID, tripID, stopID, stopName, max(0, strandedPassengerCount), 0)
            case let .busServiceCompletedAtClosedStopWithPassengerRedirect(tripID, vehicleID, routeID, stopID, stopName, _, _, passengerCount, _, _):
                disruption = (routeID, vehicleID, tripID, stopID, stopName, 0, max(0, passengerCount))
            default:
                disruption = nil
            }
            guard let disruption,
                  filter.includes(
                      date: event.simulatedAt,
                      routeID: disruption.routeID,
                      vehicleID: disruption.vehicleID
                  ) else { continue }

            totals.includeDisplaced(disruption.displaced)
            totals.includeRedirected(disruption.redirected)
            let group = groupIdentity(
                grouping: grouping,
                routeID: disruption.routeID,
                vehicleID: disruption.vehicleID,
                tripID: disruption.tripID,
                stopID: disruption.stopID,
                stopName: disruption.stopName,
                occurredAt: event.simulatedAt
            )
            var bucket = buckets[group.id] ?? Bucket(label: group.label)
            bucket.totals.includeDisplaced(disruption.displaced)
            bucket.totals.includeRedirected(disruption.redirected)
            buckets[group.id] = bucket
        }

        for transfer in pendingTransfers {
            guard let targetTripID = transfer.intendedTripID,
                  transfer.passengerCount > 0,
                  filter.vehicleID == nil || transfer.targetVehicleID == filter.vehicleID,
                  filter.includes(
                      date: transfer.readyAt,
                      routeID: transfer.targetRouteID,
                      vehicleID: transfer.targetVehicleID ?? "non attribué"
                  ) else { continue }
            totals.includePendingConnection(transfer)
            let group = groupIdentity(
                grouping: grouping,
                routeID: transfer.targetRouteID,
                vehicleID: transfer.targetVehicleID ?? "non attribué",
                tripID: targetTripID,
                stopID: transfer.stopID,
                stopName: "Arrêt \(transfer.stopID)",
                occurredAt: transfer.readyAt
            )
            var bucket = buckets[group.id] ?? Bucket(label: group.label)
            bucket.totals.includePendingConnection(transfer)
            buckets[group.id] = bucket
        }

        let rows = buckets.map { id, bucket in
            PassengerAnalyticsRow(id: id, label: bucket.label, totals: bucket.totals)
        }.sorted {
            let comparison = $0.label.localizedStandardCompare($1.label)
            return comparison == .orderedSame ? $0.id < $1.id : comparison == .orderedAscending
        }
        return PassengerAnalyticsSnapshot(totals: totals, rows: rows)
    }

    private static func groupIdentity(
        grouping: PassengerAnalyticsGrouping,
        routeID: String,
        vehicleID: String,
        tripID: String,
        stopID: String,
        stopName: String,
        occurredAt: Date
    ) -> (id: String, label: String) {
        switch grouping {
        case .line:
            return ("line|\(routeID)", "Ligne \(routeID)")
        case .bus:
            return ("bus|\(vehicleID)", "Bus \(vehicleID)")
        case .course:
            let dateKey = GTFSServiceDate.key(for: occurredAt, timeZone: GTFSServiceDate.parisTimeZone) ?? 0
            return ("course|\(routeID)|\(dateKey)|\(tripID)", "Ligne \(routeID) · \(dateKey) · course \(tripID)")
        case .stop:
            return ("stop|\(routeID)|\(stopID)", "\(stopName) · ligne \(routeID)")
        }
    }

    private struct Bucket {
        let label: String
        var totals = PassengerAnalyticsTotals()
    }
}
