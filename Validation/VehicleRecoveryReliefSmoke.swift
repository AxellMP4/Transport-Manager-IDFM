import Foundation

@main
struct VehicleRecoveryReliefSmoke {
    static func main() throws {
        freeDepotTeamDoesNotOfferRelief()
        busyDepotTeamOffersEarlierReliefWithGameEstimate()
        noFeasibleReliefIsReportedDeterministically()
        try oldTowPlansDecodeWithoutReliefFields()
        print("PASS: recovery relief availability, ETAs, costs, and legacy tow-plan decoding are deterministic")
    }

    private static func freeDepotTeamDoesNotOfferRelief() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let plan = towPlan(calculatedAt: now)
        let assessment = VehicleRecoveryRules.reliefAssessment(
            from: plan,
            simulatedAt: now,
            depotTeamAvailableAt: now,
            reliefAvailableAt: now
        )

        precondition(assessment == .notNeeded)
    }

    private static func busyDepotTeamOffersEarlierReliefWithGameEstimate() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let depotAvailableAt = now.addingTimeInterval(2 * 60 * 60)
        let plan = towPlan(calculatedAt: now)

        guard case let .available(reliefPlan) = VehicleRecoveryRules.reliefAssessment(
            from: plan,
            simulatedAt: now,
            depotTeamAvailableAt: depotAvailableAt,
            reliefAvailableAt: now
        ) else {
            preconditionFailure("A busy depot team with a long wait should offer the faster simulated relief option.")
        }

        let expectedDispatchAt = now.addingTimeInterval(VehicleRecoveryRules.reliefCalloutWait)
        precondition(reliefPlan.recoveryProvider == .simulatedRelief)
        precondition(reliefPlan.recoveryTeamID == VehicleRecoveryRules.reliefTeamID(for: plan.depotID))
        precondition(reliefPlan.recoveryTeamName == VehicleRecoveryRules.reliefTeamName)
        precondition(reliefPlan.recoveryProviderSurchargeEuro == VehicleRecoveryRules.reliefSurchargeEuro)
        precondition(reliefPlan.dispatchStartsAt == expectedDispatchAt)
        precondition(reliefPlan.expectedRecoveryTeamArrivalAt == expectedDispatchAt.addingTimeInterval(900))
        precondition(reliefPlan.expectedDepotArrivalAt == expectedDispatchAt.addingTimeInterval(900 + VehicleRecoveryRules.towHookupDuration + 1_200))
        precondition(reliefPlan.expectedRecoveryTeamArrivalAt! < depotAvailableAt.addingTimeInterval(900))

        let cost = VehicleRepairResponse.towToDepot.cost(
            for: .major,
            towDistanceMeters: reliefPlan.totalServiceDistanceMeters
        ) + (reliefPlan.recoveryProviderSurchargeEuro ?? 0)
        precondition(cost == VehicleRepairResponse.towToDepot.cost(for: .major, towDistanceMeters: plan.totalServiceDistanceMeters) + VehicleRecoveryRules.reliefSurchargeEuro)
    }

    private static func noFeasibleReliefIsReportedDeterministically() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let plan = towPlan(calculatedAt: now)
        let shortTeamWait = now.addingTimeInterval(10 * 60)

        let assessment = VehicleRecoveryRules.reliefAssessment(
            from: plan,
            simulatedAt: now,
            depotTeamAvailableAt: shortTeamWait,
            reliefAvailableAt: now
        )
        guard case let .depotTeamArrivesFirst(reliefEarliestDispatchAt) = assessment else {
            preconditionFailure("The depot team should be the faster option when it is free before relief dispatch.")
        }
        precondition(reliefEarliestDispatchAt == now.addingTimeInterval(VehicleRecoveryRules.reliefCalloutWait))

        var outOfCoveragePlan = plan
        outOfCoveragePlan.dispatchRouteDistanceMeters = VehicleRecoveryRules.reliefMaximumDispatchDistanceMeters + 1
        precondition(VehicleRecoveryRules.reliefAssessment(
            from: outOfCoveragePlan,
            simulatedAt: now,
            depotTeamAvailableAt: now.addingTimeInterval(2 * 60 * 60),
            reliefAvailableAt: now
        ) == .outsideEstimatedCoverage)
    }

    private static func oldTowPlansDecodeWithoutReliefFields() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let plan = towPlan(calculatedAt: now)
        var encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(plan)) as! [String: Any]
        encoded.removeValue(forKey: "recoveryProvider")
        encoded.removeValue(forKey: "recoveryProviderSurchargeEuro")

        let decoded = try JSONDecoder().decode(VehicleTowPlan.self, from: JSONSerialization.data(withJSONObject: encoded))
        precondition(decoded.recoveryProvider == nil)
        precondition(decoded.recoveryProviderSurchargeEuro == nil)
        precondition(decoded.recoveryTeamID == plan.recoveryTeamID)
        precondition(decoded.dispatchStartsAt == plan.dispatchStartsAt)
    }

    private static func towPlan(calculatedAt: Date) -> VehicleTowPlan {
        VehicleTowPlan(
            depotID: "depot-test",
            depotName: "Dépôt de test",
            resolvedDepotAddress: "10 rue du dépôt, 94000 Créteil",
            routeDistanceMeters: 12_000,
            expectedTravelSeconds: 1_200,
            destination: BusMovementCoordinate(latitude: 48.80, longitude: 2.40),
            routeCoordinates: [
                BusMovementCoordinate(latitude: 48.82, longitude: 2.40),
                BusMovementCoordinate(latitude: 48.80, longitude: 2.40)
            ],
            calculatedAt: calculatedAt,
            routingSourceTitle: "Route simulée du smoke",
            recoveryTeamID: VehicleRecoveryRules.teamID(for: "depot-test"),
            recoveryTeamName: VehicleRecoveryRules.teamName(for: "Dépôt de test"),
            recoveryProvider: .depotTeam,
            recoveryProviderSurchargeEuro: 0,
            dispatchStartsAt: calculatedAt,
            dispatchRouteDistanceMeters: 8_000,
            dispatchExpectedTravelSeconds: 900,
            dispatchRouteCoordinates: [
                BusMovementCoordinate(latitude: 48.80, longitude: 2.40),
                BusMovementCoordinate(latitude: 48.82, longitude: 2.40)
            ]
        )
    }
}
