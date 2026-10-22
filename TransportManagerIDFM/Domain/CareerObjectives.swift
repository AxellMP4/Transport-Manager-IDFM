import Foundation

struct CareerObjective: Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let instruction: String
    let currentCount: Int
    let targetCount: Int

    var isComplete: Bool {
        currentCount >= targetCount
    }

    var progress: Double {
        guard targetCount > 0 else { return 1 }
        return min(1, max(0, Double(currentCount) / Double(targetCount)))
    }
}

enum CareerObjectiveCatalog {
    static func objectives(for session: SimulationSession) -> [CareerObjective] {
        let deliveredBusCount = (session.ownedBuses ?? []).filter { $0.status != .inDelivery }.count
        let machinistCount = (session.machinists ?? []).count
        let completedTripCount = session.eventHistory.reduce(into: 0) { count, event in
            switch event.kind {
            case .busServiceCompleted,
                 .busServiceCompletedAtClosedStop,
                 .busServiceCompletedAtClosedStopWithPassengerRedirect,
                 .serviceCompleted:
                if event.simulatedAt <= session.simulatedAt { count += 1 }
            default:
                break
            }
        }
        let closedDayCount = completedTripCount > 0 ? (session.dailyOperationsReports ?? []).count : 0

        return [
            CareerObjective(
                id: "receive-first-bus",
                title: "Recevoir un premier bus",
                instruction: "Achetez une offre au marché et attendez sa livraison au dépôt.",
                currentCount: deliveredBusCount,
                targetCount: 1
            ),
            CareerObjective(
                id: "hire-first-machinist",
                title: "Recruter un machiniste",
                instruction: "Recrutez un machiniste qualifié depuis le panneau Personnel.",
                currentCount: machinistCount,
                targetCount: 1
            ),
            CareerObjective(
                id: "complete-first-trip",
                title: "Terminer une première course",
                instruction: "Affectez un départ GTFS au bus et au machiniste, puis suivez-le jusqu’au terminus.",
                currentCount: completedTripCount,
                targetCount: 1
            ),
            CareerObjective(
                id: "close-first-day",
                title: "Consulter un premier bilan quotidien",
                instruction: "Après une course terminée, laissez l’horloge atteindre la clôture journalière.",
                currentCount: closedDayCount,
                targetCount: 1
            )
        ]
    }
}
