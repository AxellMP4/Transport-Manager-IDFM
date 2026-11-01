import Foundation

@main
struct RecoveryTeamMaintenanceSmoke {
    @MainActor
    static func main() throws {
        try completedInternalTowWearsTheTeam()
        try maintenanceBlocksAndRestoresTheTeamOnce()
        try occupiedTeamCannotEnterMaintenance()
        teamWearIsProjectedBeforeTheNextDispatch()
        maintenanceInProgressCanOfferSimulatedRelief()
        try legacySessionDefaultsRecoveryState()
        print("PASS: recovery team wear, maintenance costs, availability, completion, and legacy decoding are deterministic")
    }

    @MainActor
    private static func completedInternalTowWearsTheTeam() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let plan = towPlan(at: now)
        precondition(VehicleRecoveryRules.conditionLossAfterTow(distanceMeters: plan.totalServiceDistanceMeters) == 7)
        var incident = incident(at: now, plan: plan)
        incident.busTowStartedAt = now
        let completion = plan.expectedDepotArrivalAt!
        var session = session(at: now)
        session.vehicleIncidents = [incident]
        session.pendingEvents = [SimulationEvent(
            sequence: 0,
            simulatedAt: completion,
            kind: .vehicleTowArrived(incidentID: incident.id)
        )]
        session.nextEventSequence = 1
        session.ownedBuses = [PurchasedBus(
            id: incident.vehicleID,
            modelID: "iveco-urbanway-12-gnv",
            offerID: "offer-test",
            depotID: plan.depotID,
            acquiredAt: now,
            modelYear: 2025,
            odometerKilometers: 0,
            conditionPercent: 100,
            purchasePrice: 0,
            deliveryAt: now,
            status: .beingTowed
        )]

        let engine = SimulationEngine(initialSession: session)
        precondition(engine.advanceToNextEvent())
        let updatedSession = engine.session!
        precondition(updatedSession.recoveryTeamConditionPercent(depotID: plan.depotID)
            == 100 - VehicleRecoveryRules.conditionLossAfterTow(distanceMeters: plan.totalServiceDistanceMeters))
        precondition(updatedSession.recoveryTeamConditionPercent(depotID: "other-depot") == 100)
    }

    @MainActor
    private static func maintenanceBlocksAndRestoresTheTeamOnce() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let depotID = "depot-test"
        var session = session(at: now)
        session.cashBalance = 5_000
        session.ledgerEntries = []
        session.recoveryTeamConditionPercentByDepot = [depotID: 40]
        let engine = SimulationEngine(initialSession: session)

        try engine.scheduleRecoveryTeamMaintenance(depotID: depotID)
        let started = engine.session!
        let completionAt = now.addingTimeInterval(VehicleRecoveryRules.teamMaintenanceDuration)
        precondition(started.cashBalance == 5_000)
        precondition(started.ledgerEntries?.count == 1)
        guard let maintenanceEntry = started.ledgerEntries?.first else {
            preconditionFailure("Maintenance must create one ledger entry.")
        }
        precondition(maintenanceEntry.amount == -VehicleRecoveryRules.teamMaintenanceCostEuro)
        precondition(started.recoveryTeamMaintenanceCompletionDate(depotID: depotID) == completionAt)
        precondition(!started.isRecoveryTeamDispatchEligible(depotID: depotID))
        do {
            try engine.scheduleRecoveryTeamMaintenance(depotID: depotID)
            preconditionFailure("An active maintenance order must not create a second charge.")
        } catch SimulationEngineError.recoveryTeamAlreadyInMaintenance {
            precondition(engine.session?.ledgerEntries?.count == 1)
        }

        precondition(engine.advanceToNextEvent())
        let completed = engine.session!
        precondition(completed.simulatedAt == completionAt)
        precondition(completed.recoveryTeamConditionPercent(depotID: depotID) == 100)
        precondition(completed.recoveryTeamMaintenanceCompletionDate(depotID: depotID) == nil)
        precondition(completed.isRecoveryTeamDispatchEligible(depotID: depotID))
        do {
            try engine.scheduleRecoveryTeamMaintenance(depotID: depotID)
            preconditionFailure("A team at full condition must not be charged for unnecessary maintenance.")
        } catch SimulationEngineError.recoveryTeamMaintenanceNotRequired {
            precondition(engine.session?.ledgerEntries?.count == 1)
            precondition(engine.session?.cashBalance == 5_000)
        }
    }

    @MainActor
    private static func occupiedTeamCannotEnterMaintenance() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let plan = towPlan(at: now)
        var session = session(at: now)
        session.cashBalance = 5_000
        session.ledgerEntries = []
        session.recoveryTeamConditionPercentByDepot = [plan.depotID: 60]
        session.vehicleIncidents = [incident(at: now, plan: plan)]
        let engine = SimulationEngine(initialSession: session)

        do {
            try engine.scheduleRecoveryTeamMaintenance(depotID: plan.depotID)
            preconditionFailure("A recovery team committed to an active tow must remain unavailable for maintenance.")
        } catch SimulationEngineError.recoveryTeamBusy {
            precondition(engine.session?.ledgerEntries?.isEmpty == true)
            precondition(engine.session?.cashBalance == 5_000)
        }
    }

    private static func maintenanceInProgressCanOfferSimulatedRelief() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let depotID = "depot-test"
        let plan = towPlan(at: now)
        var session = session(at: now)
        session.recoveryTeamConditionPercentByDepot = [depotID: 10]
        session.recoveryTeamMaintenanceCompletesAtByDepot = [
            depotID: now.addingTimeInterval(2 * 60 * 60)
        ]

        guard case let .available(reliefPlan) = VehicleRecoveryRules.reliefAssessment(
            from: plan,
            simulatedAt: now,
            depotTeamAvailableAt: session.recoveryTeamAvailabilityForReliefAssessment(depotID: depotID),
            reliefAvailableAt: session.nextRecoveryReliefAvailableAt(depotID: depotID)
        ) else {
            preconditionFailure("A team in maintenance must allow an earlier simulated relief assessment.")
        }
        precondition(reliefPlan.recoveryProvider == .simulatedRelief)
        precondition(reliefPlan.dispatchStartsAt == now.addingTimeInterval(VehicleRecoveryRules.reliefCalloutWait))
    }

    private static func teamWearIsProjectedBeforeTheNextDispatch() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let depotID = "depot-test"
        let plan = towPlan(at: now)
        var session = session(at: now)
        session.recoveryTeamConditionPercentByDepot = [depotID: 30]
        session.vehicleIncidents = [incident(at: now, plan: plan)]
        let dispatchAt = session.nextRecoveryTeamAvailableAt(depotID: depotID)

        precondition(session.projectedRecoveryTeamConditionPercent(depotID: depotID, at: dispatchAt) == 23)
        precondition(!session.canDispatchRecoveryTeam(depotID: depotID, at: dispatchAt))
        precondition(session.recoveryTeamAvailabilityForReliefAssessment(depotID: depotID) == .distantFuture)
    }

    private static func legacySessionDefaultsRecoveryState() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let encoded = try JSONEncoder().encode(session(at: now))
        var object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        object.removeValue(forKey: "recoveryTeamConditionPercentByDepot")
        object.removeValue(forKey: "recoveryTeamMaintenanceCompletesAtByDepot")
        let decoded = try JSONDecoder().decode(
            SimulationSession.self,
            from: JSONSerialization.data(withJSONObject: object)
        )
        precondition(decoded.recoveryTeamConditionPercent(depotID: "depot-test") == 100)
        precondition(decoded.recoveryTeamMaintenanceCompletionDate(depotID: "depot-test") == nil)
        precondition(decoded.isRecoveryTeamDispatchEligible(depotID: "depot-test"))
    }

    private static func session(at date: Date) -> SimulationSession {
        SimulationSession(
            id: "session-recovery-maintenance",
            scenarioID: "scenario-test",
            depotID: "depot-test",
            networkVersions: SimulationDataVersions(
                gtfsID: "gtfs-test",
                routeGeometryID: "geometry-test",
                contractID: "contract-test",
                lineReferenceID: "references-test"
            ),
            randomSeed: 7,
            createdAt: date,
            updatedAt: date,
            simulatedAt: date,
            speed: .paused,
            resumeSpeed: .x1,
            nextEventSequence: 0,
            pendingEvents: [],
            eventHistory: []
        )
    }

    private static func incident(at date: Date, plan: VehicleTowPlan) -> VehicleIncident {
        var incident = VehicleIncident(
            id: "incident-test",
            vehicleID: "bus-test",
            vehicleModelName: "Bus de test",
            tripID: "trip-test",
            routeID: "route-test",
            stopID: "stop-test",
            stopName: "Arrêt de test",
            latitude: 48.8,
            longitude: 2.4,
            occurredAt: date,
            severity: .minor,
            repairCompletedAt: date.addingTimeInterval(6 * 60 * 60),
            repairCostEuro: 500,
            displacedPassengerCount: 0,
            repairResponse: .towToDepot,
            towPlan: plan
        )
        incident.busTowStartedAt = date
        return incident
    }

    private static func towPlan(at date: Date) -> VehicleTowPlan {
        VehicleTowPlan(
            depotID: "depot-test",
            depotName: "Dépôt de test",
            resolvedDepotAddress: "10 rue du dépôt, 94000 Créteil",
            routeDistanceMeters: 24_000,
            expectedTravelSeconds: 1_800,
            destination: BusMovementCoordinate(latitude: 48.80, longitude: 2.40),
            routeCoordinates: [
                BusMovementCoordinate(latitude: 48.82, longitude: 2.40),
                BusMovementCoordinate(latitude: 48.80, longitude: 2.40)
            ],
            calculatedAt: date,
            routingSourceTitle: "Route simulée du smoke",
            recoveryTeamID: VehicleRecoveryRules.teamID(for: "depot-test"),
            recoveryTeamName: VehicleRecoveryRules.teamName(for: "Dépôt de test"),
            recoveryProvider: .depotTeam,
            recoveryProviderSurchargeEuro: 0,
            dispatchStartsAt: date,
            dispatchRouteDistanceMeters: 8_000,
            dispatchExpectedTravelSeconds: 900,
            dispatchRouteCoordinates: [
                BusMovementCoordinate(latitude: 48.80, longitude: 2.40),
                BusMovementCoordinate(latitude: 48.82, longitude: 2.40)
            ]
        )
    }
}
