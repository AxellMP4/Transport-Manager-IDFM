import Foundation

struct CareerAchievement: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let achievedAt: Date
    let points: Int
}

struct CareerProgressionState: Codable, Hashable, Sendable {
    var achievements: [CareerAchievement] = []
}

enum CareerProgressionRank: Int, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case newOperator = 1
    case networkInService = 2
    case confirmedManager = 3
    case regionalReference = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .newOperator: "Nouvel exploitant"
        case .networkInService: "Réseau en service"
        case .confirmedManager: "Gestionnaire confirmé"
        case .regionalReference: "Référence régionale"
        }
    }

    var minimumPoints: Int {
        switch self {
        case .newOperator: 0
        case .networkInService: 40
        case .confirmedManager: 120
        case .regionalReference: 220
        }
    }

    static func rank(for points: Int) -> CareerProgressionRank {
        allCases.last(where: { points >= $0.minimumPoints }) ?? .newOperator
    }
}

struct CareerMilestoneProgress: Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let criterion: String
    let points: Int
    let requiredRank: CareerProgressionRank
    let currentValue: Int
    let targetValue: Int
    let isAvailable: Bool
    let achievedAt: Date?

    var isEarned: Bool { achievedAt != nil }

    var criterionIsSatisfied: Bool { currentValue >= targetValue }

    var progress: Double {
        guard targetValue > 0 else { return 1 }
        return min(1, max(0, Double(currentValue) / Double(targetValue)))
    }
}

struct CareerProgressionSnapshot: Hashable, Sendable {
    let rank: CareerProgressionRank
    let totalPoints: Int
    let nextRank: CareerProgressionRank?
    let pointsTowardNextRank: Int
    let pointsNeededForNextRank: Int
    let progressToNextRank: Double
    let milestones: [CareerMilestoneProgress]
    let history: [CareerAchievement]
}

private struct CareerMilestoneDefinition: Hashable, Sendable {
    let id: String
    let title: String
    let criterion: String
    let points: Int
    let requiredRank: CareerProgressionRank
    let targetValue: Int
}

enum CareerProgressionCatalog {
    private static let definitions: [CareerMilestoneDefinition] = [
        CareerMilestoneDefinition(
            id: "first-bus-delivered",
            title: "Premier bus reçu",
            criterion: "Recevoir un bus acheté au marché.",
            points: 10,
            requiredRank: .newOperator,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "first-machinist-hired",
            title: "Première recrue",
            criterion: "Enregistrer un machiniste dans l’équipe.",
            points: 10,
            requiredRank: .newOperator,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "first-trip-completed",
            title: "Première course terminée",
            criterion: "Terminer une course réelle jusqu’à son terminus.",
            points: 20,
            requiredRank: .newOperator,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "first-daily-report",
            title: "Premier bilan quotidien",
            criterion: "Enregistrer un bilan de journée.",
            points: 20,
            requiredRank: .newOperator,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "ten-trips-completed",
            title: "Dix courses terminées",
            criterion: "Terminer dix courses réelles.",
            points: 25,
            requiredRank: .networkInService,
            targetValue: 10
        ),
        CareerMilestoneDefinition(
            id: "seven-daily-reports",
            title: "Sept bilans quotidiens",
            criterion: "Enregistrer sept bilans quotidiens.",
            points: 30,
            requiredRank: .networkInService,
            targetValue: 7
        ),
        CareerMilestoneDefinition(
            id: "twenty-five-trips-completed",
            title: "Vingt-cinq courses terminées",
            criterion: "Terminer vingt-cinq courses réelles.",
            points: 35,
            requiredRank: .networkInService,
            targetValue: 25
        ),
        CareerMilestoneDefinition(
            id: "first-breakdown-repaired",
            title: "Première panne réparée",
            criterion: "Terminer la réparation d’une panne de véhicule.",
            points: 20,
            requiredRank: .confirmedManager,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "first-investment-completed",
            title: "Premier investissement achevé",
            criterion: "Achever une extension d’atelier ou une installation énergétique.",
            points: 20,
            requiredRank: .confirmedManager,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "high-production-day",
            title: "Journée de production tenue",
            criterion: "Enregistrer au moins 98 % de courses terminées sur une journée.",
            points: 25,
            requiredRank: .confirmedManager,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "first-invoice-paid",
            title: "Première facture réglée",
            criterion: "Régler une facture de jeu enregistrée dans la carrière.",
            points: 15,
            requiredRank: .confirmedManager,
            targetValue: 1
        ),
        CareerMilestoneDefinition(
            id: "fifty-trips-completed",
            title: "Cinquante courses terminées",
            criterion: "Terminer cinquante courses réelles.",
            points: 50,
            requiredRank: .confirmedManager,
            targetValue: 50
        )
    ]

    static func reconcile(session: inout SimulationSession) {
        var state = session.careerProgression ?? CareerProgressionState()
        var achievementsByID: [String: CareerAchievement] = [:]
        for achievement in state.achievements {
            guard let definition = definitions.first(where: { $0.id == achievement.id }) else { continue }
            let normalized = CareerAchievement(
                id: definition.id,
                achievedAt: achievement.achievedAt,
                points: definition.points
            )
            if achievementsByID[normalized.id]?.achievedAt ?? .distantFuture > normalized.achievedAt {
                achievementsByID[normalized.id] = normalized
            } else if achievementsByID[normalized.id] == nil {
                achievementsByID[normalized.id] = normalized
            }
        }

        let evidence = evidenceDates(for: session)
        for definition in definitions {
            guard achievementsByID[definition.id] == nil,
                  let achievedAt = evidence[definition.id] else { continue }
            let pointsEarnedSoFar = achievementsByID.values.reduce(into: 0) { $0 += $1.points }
            guard CareerProgressionRank.rank(for: pointsEarnedSoFar).rawValue >= definition.requiredRank.rawValue else {
                continue
            }
            achievementsByID[definition.id] = CareerAchievement(
                id: definition.id,
                achievedAt: achievedAt,
                points: definition.points
            )
        }

        state.achievements = achievementsByID.values.sorted {
            if $0.achievedAt != $1.achievedAt { return $0.achievedAt < $1.achievedAt }
            return $0.id < $1.id
        }
        session.careerProgression = state
    }

    static func snapshot(for session: SimulationSession) -> CareerProgressionSnapshot {
        let achievements = session.careerProgression?.achievements ?? []
        let achievementsByID = Dictionary(achievements.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let points = achievements.reduce(into: 0) { $0 += max(0, $1.points) }
        let rank = CareerProgressionRank.rank(for: points)
        let nextRank = CareerProgressionRank.allCases.first(where: { $0.minimumPoints > points })
        let pointsTowardNextRank = nextRank == nil ? 0 : max(0, points - rank.minimumPoints)
        let pointsNeededForNextRank = nextRank.map { $0.minimumPoints - rank.minimumPoints } ?? 0
        let progressToNextRank: Double
        if nextRank != nil, pointsNeededForNextRank > 0 {
            progressToNextRank = min(1, Double(pointsTowardNextRank) / Double(pointsNeededForNextRank))
        } else {
            progressToNextRank = 1
        }
        let evidence = evidenceDates(for: session)
        let milestones = definitions.map { definition in
            let achievedAt = achievementsByID[definition.id]?.achievedAt
            let currentValue = achievedAt == nil ? (evidence[definition.id] == nil ? 0 : definition.targetValue) : definition.targetValue
            return CareerMilestoneProgress(
                id: definition.id,
                title: definition.title,
                criterion: definition.criterion,
                points: definition.points,
                requiredRank: definition.requiredRank,
                currentValue: currentValue,
                targetValue: definition.targetValue,
                isAvailable: rank.rawValue >= definition.requiredRank.rawValue,
                achievedAt: achievedAt
            )
        }
        let history = achievements.sorted {
            if $0.achievedAt != $1.achievedAt { return $0.achievedAt > $1.achievedAt }
            return $0.id < $1.id
        }
        return CareerProgressionSnapshot(
            rank: rank,
            totalPoints: points,
            nextRank: nextRank,
            pointsTowardNextRank: pointsTowardNextRank,
            pointsNeededForNextRank: pointsNeededForNextRank,
            progressToNextRank: progressToNextRank,
            milestones: milestones,
            history: history
        )
    }

    private static func evidenceDates(for session: SimulationSession) -> [String: Date] {
        let history = session.eventHistory.filter { $0.simulatedAt <= session.simulatedAt }
        let deliveredBusDate = history.compactMap { event -> Date? in
            guard case .vehicleDelivered = event.kind else { return nil }
            return event.simulatedAt
        }.min() ?? (session.ownedBuses ?? [])
            .filter { $0.status != .inDelivery }
            .map(\.deliveryAt)
            .min()

        let machinistDate = (session.machinists ?? []).map(\.hiredAt).min()
        let tripDates = history.compactMap { event -> Date? in
            switch event.kind {
            case .busServiceCompleted,
                 .busServiceCompletedAtClosedStop,
                 .busServiceCompletedAtClosedStopWithPassengerRedirect,
                 .serviceCompleted:
                return event.simulatedAt
            default:
                return nil
            }
        }.sorted()

        let reports = (session.dailyOperationsReports ?? []).sorted { $0.dateKey < $1.dateKey }
        let reportDates = reports.map { reportDate(for: $0, history: history) }
        let repairedAt = history.compactMap { event -> Date? in
            guard case .vehicleRepairCompleted = event.kind else { return nil }
            return event.simulatedAt
        }.min()
        let investmentDates = history.compactMap { event -> Date? in
            switch event.kind {
            case .workshopExpansionCompleted, .depotEnergyInfrastructureCompleted:
                return event.simulatedAt
            default:
                return nil
            }
        } + (session.depotEnergyInfrastructureProjects ?? []).compactMap(\.completedAt)
        let firstInvestmentDate = investmentDates.min()
        let highProductionDate = reports.first(where: { productionRate(for: $0) >= 0.98 })
            .map { reportDate(for: $0, history: history) }
        let paidInvoiceDate = (session.invoices ?? []).compactMap(\.paidAt).min()

        var result: [String: Date] = [:]
        if let deliveredBusDate { result["first-bus-delivered"] = deliveredBusDate }
        if let machinistDate { result["first-machinist-hired"] = machinistDate }
        if let firstTrip = tripDates.first { result["first-trip-completed"] = firstTrip }
        if let firstReport = reportDates.first { result["first-daily-report"] = firstReport }
        if tripDates.count >= 10 { result["ten-trips-completed"] = tripDates[9] }
        if reportDates.count >= 7 { result["seven-daily-reports"] = reportDates[6] }
        if tripDates.count >= 25 { result["twenty-five-trips-completed"] = tripDates[24] }
        if let repairedAt { result["first-breakdown-repaired"] = repairedAt }
        if let firstInvestmentDate { result["first-investment-completed"] = firstInvestmentDate }
        if let highProductionDate { result["high-production-day"] = highProductionDate }
        if let paidInvoiceDate { result["first-invoice-paid"] = paidInvoiceDate }
        if tripDates.count >= 50 { result["fifty-trips-completed"] = tripDates[49] }
        return result
    }

    private static func reportDate(for report: DailyOperationsReport, history: [SimulationEvent]) -> Date {
        if let settlementDate = history.compactMap({ event -> Date? in
            guard case let .dailySettlement(dateKey) = event.kind,
                  dateKey == report.dateKey else { return nil }
            return event.simulatedAt
        }).min() {
            return settlementDate
        }
        let year = report.dateKey / 10_000
        let month = (report.dateKey / 100) % 100
        let day = report.dateKey % 100
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).date(from: components)
            ?? .distantPast
    }

    private static func productionRate(for report: DailyOperationsReport) -> Double {
        if let contractCompletionRate = report.contractCompletionRate {
            return contractCompletionRate
        }
        let denominator = max(
            report.servedDepartureCount + report.missedDepartureCount,
            report.completedTripCount
        )
        guard denominator > 0 else { return 0 }
        return min(1, Double(report.completedTripCount) / Double(denominator))
    }
}
