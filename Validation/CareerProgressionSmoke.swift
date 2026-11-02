import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("ÉCHEC : \(message)\n", stderr)
        exit(1)
    }
}

private func parisDate(_ day: Int, hour: Int = 12) -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 1
    components.day = day
    components.hour = hour
    return GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).date(from: components)!
}

private func serviceCompletion(_ tripID: String, at date: Date) -> CareerProgressionSmokeEvent {
    CareerProgressionSmokeEvent(
        simulatedAt: date,
        kind: .busServiceCompleted(
            tripID: tripID,
            vehicleID: "bus-1",
            stopID: "terminus",
            stopName: "Terminus",
            latitude: 48.0,
            longitude: 2.0
        )
    )
}

private func eventDate(for id: String, in session: SimulationSession) -> Date? {
    session.careerProgression?.achievements.first(where: { $0.id == id })?.achievedAt
}

private func reports(_ dates: [Int], rate: Double? = nil, completed: Int = 0, served: Int = 0, missed: Int = 0) -> [CareerProgressionSmokeReport] {
    dates.map {
        CareerProgressionSmokeReport(
            dateKey: $0,
            servedDepartureCount: served,
            missedDepartureCount: missed,
            completedTripCount: completed,
            contractCompletionRate: rate
        )
    }
}

private func rankThreeAchievements(from date: Date) -> CareerProgressionState {
    CareerProgressionState(achievements: [
        CareerAchievement(id: "first-bus-delivered", achievedAt: date, points: 10),
        CareerAchievement(id: "first-machinist-hired", achievedAt: date, points: 10),
        CareerAchievement(id: "first-trip-completed", achievedAt: date, points: 20),
        CareerAchievement(id: "first-daily-report", achievedAt: date, points: 20),
        CareerAchievement(id: "ten-trips-completed", achievedAt: date, points: 25),
        CareerAchievement(id: "seven-daily-reports", achievedAt: date, points: 30),
        CareerAchievement(id: "twenty-five-trips-completed", achievedAt: date, points: 35)
    ])
}

private func productionMilestone(
    report: CareerProgressionSmokeReport,
    at settledAt: Date? = nil
) -> CareerMilestoneProgress {
    var history: [CareerProgressionSmokeEvent] = []
    if let settledAt {
        history.append(CareerProgressionSmokeEvent(
            simulatedAt: settledAt,
            kind: .dailySettlement(dateKey: report.dateKey)
        ))
    }
    var session = SimulationSession(
        simulatedAt: parisDate(31),
        eventHistory: history,
        pendingEvents: [],
        dailyOperationsReports: [report],
        careerProgression: rankThreeAchievements(from: parisDate(1))
    )
    CareerProgressionCatalog.reconcile(session: &session)
    return CareerProgressionCatalog.snapshot(for: session).milestones.first {
        $0.id == "high-production-day"
    }!
}

@main
private struct CareerProgressionSmoke {
    static func main() throws {
        try legacySaveWithoutProgressionRebuildsAchievements()
        pendingEventsDoNotCreateAchievements()
        aLockedMilestoneKeepsItsOriginalEvidenceDateWhenUnlocked()
        productionUsesSavedContractRateOrTheDocumentedFallback()
        print("PASS : migration, exclusion des événements en attente, rang/date d’origine et taux de production.")
    }

    private static func legacySaveWithoutProgressionRebuildsAchievements() throws {
        let deliveryDate = parisDate(1, hour: 8)
        let hireDate = parisDate(2, hour: 9)
        let tripDate = parisDate(3, hour: 10)
        let settlementDate = parisDate(4, hour: 23)
        let reportDateKey = 20260104
        let currentDate = parisDate(5)
        let oldSaveState = CareerProgressionState()
        let encoded = try JSONEncoder().encode(SimulationSession(
            simulatedAt: currentDate,
            eventHistory: [],
            pendingEvents: [],
            careerProgression: oldSaveState
        ))
        var legacyObject = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        legacyObject.removeValue(forKey: "careerProgression")
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        var session = try JSONDecoder().decode(SimulationSession.self, from: legacyData)
        expect(session.careerProgression == nil, "une ancienne sauvegarde sans le champ de progression reste décodable")

        session.eventHistory = [
            CareerProgressionSmokeEvent(simulatedAt: deliveryDate, kind: .vehicleDelivered(vehicleID: "bus-1")),
            serviceCompletion("trip-1", at: tripDate),
            CareerProgressionSmokeEvent(simulatedAt: settlementDate, kind: .dailySettlement(dateKey: reportDateKey))
        ]
        session.machinists = [CareerProgressionSmokeMachinist(hiredAt: hireDate)]
        session.dailyOperationsReports = reports([reportDateKey])
        CareerProgressionCatalog.reconcile(session: &session)

        expect(session.careerProgression?.achievements.count == 4, "les quatre premiers jalons sont reconstruits depuis la sauvegarde historique")
        expect(eventDate(for: "first-bus-delivered", in: session) == deliveryDate, "la livraison garde l’heure de son événement")
        expect(eventDate(for: "first-machinist-hired", in: session) == hireDate, "le recrutement garde sa date enregistrée")
        expect(eventDate(for: "first-trip-completed", in: session) == tripDate, "la fin de course historique est reconstruite")
        expect(eventDate(for: "first-daily-report", in: session) == settlementDate, "le bilan utilise l’heure du règlement historique")
    }

    private static func pendingEventsDoNotCreateAchievements() {
        var session = SimulationSession(
            simulatedAt: parisDate(10),
            eventHistory: [],
            pendingEvents: [
                CareerProgressionSmokeEvent(simulatedAt: parisDate(2), kind: .vehicleDelivered(vehicleID: "bus-1")),
                serviceCompletion("pending-trip", at: parisDate(3)),
                CareerProgressionSmokeEvent(simulatedAt: parisDate(4), kind: .dailySettlement(dateKey: 20260104))
            ]
        )
        CareerProgressionCatalog.reconcile(session: &session)
        let snapshot = CareerProgressionCatalog.snapshot(for: session)
        let pendingOnlyIDs = ["first-bus-delivered", "first-trip-completed", "first-daily-report"]
        expect(pendingOnlyIDs.allSatisfy { id in
            snapshot.milestones.first(where: { $0.id == id })?.isEarned == false
        }, "aucun événement en attente ne valide un jalon")
        expect(snapshot.milestones.first(where: { $0.id == "first-trip-completed" })?.currentValue == 0, "une course en attente ne compte pas dans l’avancement")
    }

    private static func aLockedMilestoneKeepsItsOriginalEvidenceDateWhenUnlocked() {
        let earlyRepairDate = parisDate(1, hour: 8)
        var history = [CareerProgressionSmokeEvent(
            simulatedAt: earlyRepairDate,
            kind: .vehicleRepairCompleted(incidentID: "incident-1")
        )]
        history.append(contentsOf: (1...25).map { day in
            serviceCompletion("trip-\(day)", at: parisDate(min(day + 1, 30)))
        })
        let reportDateKeys = (1...7).map { 20260100 + $0 }
        history.append(contentsOf: reportDateKeys.enumerated().map { index, key in
            CareerProgressionSmokeEvent(
                simulatedAt: parisDate(index + 1, hour: 22),
                kind: .dailySettlement(dateKey: key)
            )
        })
        var session = SimulationSession(
            simulatedAt: parisDate(31),
            eventHistory: history,
            pendingEvents: [],
            dailyOperationsReports: reports(reportDateKeys),
            careerProgression: CareerProgressionState(achievements: [
                CareerAchievement(id: "first-bus-delivered", achievedAt: parisDate(1), points: 10),
                CareerAchievement(id: "first-machinist-hired", achievedAt: parisDate(1), points: 10),
                CareerAchievement(id: "first-trip-completed", achievedAt: parisDate(2), points: 20),
                CareerAchievement(id: "first-daily-report", achievedAt: parisDate(1), points: 20),
                CareerAchievement(id: "ten-trips-completed", achievedAt: parisDate(11), points: 25),
                CareerAchievement(id: "seven-daily-reports", achievedAt: parisDate(7), points: 30)
            ])
        )
        expect(CareerProgressionRank.rank(for: 115).rawValue == 2, "le jalon de panne est encore verrouillé à 115 points")

        CareerProgressionCatalog.reconcile(session: &session)
        let snapshot = CareerProgressionCatalog.snapshot(for: session)
        let repair = snapshot.milestones.first(where: { $0.id == "first-breakdown-repaired" })!
        expect(snapshot.totalPoints == 170, "le jalon des 25 courses débloque le niveau 3 avant le jalon de panne")
        expect(repair.isEarned, "le jalon de panne est attribué quand le rang requis devient admissible")
        expect(repair.achievedAt == earlyRepairDate, "la date de panne d’origine est conservée après déverrouillage")
    }

    private static func productionUsesSavedContractRateOrTheDocumentedFallback() {
        let contractRateOverridesRawCounts = productionMilestone(report: CareerProgressionSmokeReport(
            dateKey: 20260110,
            servedDepartureCount: 50,
            missedDepartureCount: 0,
            completedTripCount: 50,
            contractCompletionRate: 0.97
        ))
        expect(!contractRateOverridesRawCounts.criterionIsSatisfied, "un taux contractuel sauvegardé de 97 % prévaut sur les comptes bruts à 100 %")

        let savedContractThreshold = productionMilestone(report: CareerProgressionSmokeReport(
            dateKey: 20260111,
            servedDepartureCount: 0,
            missedDepartureCount: 0,
            completedTripCount: 0,
            contractCompletionRate: 0.98
        ))
        expect(savedContractThreshold.isEarned, "le taux contractuel sauvegardé de 98 % valide le jalon")

        let fallbackThreshold = productionMilestone(report: CareerProgressionSmokeReport(
            dateKey: 20260112,
            servedDepartureCount: 50,
            missedDepartureCount: 0,
            completedTripCount: 49,
            contractCompletionRate: nil
        ))
        expect(fallbackThreshold.isEarned, "le fallback 49 courses terminées sur 50 départs vaut 98 %")

        let emptyFallback = productionMilestone(report: CareerProgressionSmokeReport(
            dateKey: 20260113,
            servedDepartureCount: 0,
            missedDepartureCount: 0,
            completedTripCount: 0,
            contractCompletionRate: nil
        ))
        expect(!emptyFallback.criterionIsSatisfied, "un dénominateur nul ne produit pas une journée qualifiante")
    }
}
