import Foundation

@main
struct PassengerAnalyticsSmoke {
    static func main() {
        aggregatesBoardingsValidationTitlesAndPeakOccupancy()
        appliesInclusiveDateRouteAndVehicleFilters()
        groupsWithSummedDenominators()
        attributesDisruptionEffectsWithoutChangingBoardingTotals()
        satisfactionUsesOnlyMeasuredAccessAndConnectionSamples()
        print("PASS: passenger analytics and estimated satisfaction preserve partial coverage")
    }

    private static func aggregatesBoardingsValidationTitlesAndPeakOccupancy() {
        let exchanges = fixtureExchanges()
        let snapshot = PassengerAnalytics.snapshot(
            exchanges: exchanges,
            grouping: .line
        )

        precondition(snapshot.boardings == 160)
        precondition(snapshot.validationDataBoardings == 110)
        precondition(snapshot.validations == 105)
        precondition(snapshot.unvalidatedBoardings == 5)
        precondition(snapshot.validationRate == 105.0 / 110.0)
        precondition(snapshot.validationCount(for: .navigoSubscription) == 78)
        precondition(snapshot.validationCount(for: .singleTicket) == 20)
        precondition(snapshot.validationCount(for: .reducedFare) == 5)
        precondition(snapshot.validationCount(for: .freeTravel) == 2)
        precondition(snapshot.maximumOccupancyPercent == 100)
    }

    private static func appliesInclusiveDateRouteAndVehicleFilters() {
        let exchanges = fixtureExchanges()
        let boundaryFilter = PassengerAnalyticsFilter(
            startAt: fixtureDate(0),
            endAt: fixtureDate(3_600)
        )
        let atDateBoundary = PassengerAnalytics.snapshot(
            exchanges: exchanges,
            filter: boundaryFilter,
            grouping: .line
        )
        precondition(atDateBoundary.boardings == 110)

        let routeFiltered = PassengerAnalytics.snapshot(
            exchanges: exchanges,
            filter: PassengerAnalyticsFilter(routeID: "route-2"),
            grouping: .line
        )
        precondition(routeFiltered.boardings == 50)
        precondition(routeFiltered.validationDataBoardings == 0)
        precondition(routeFiltered.validationRate == nil)

        let vehicleFiltered = PassengerAnalytics.snapshot(
            exchanges: exchanges,
            filter: PassengerAnalyticsFilter(vehicleID: "bus-2"),
            grouping: .bus
        )
        precondition(vehicleFiltered.boardings == 100)
        precondition(vehicleFiltered.validations == 95)

        let reversedDates = PassengerAnalyticsFilter(
            startAt: fixtureDate(3_600),
            endAt: fixtureDate(0)
        )
        precondition(reversedDates.startAt == fixtureDate(0))
        precondition(reversedDates.endAt == fixtureDate(3_600))
    }

    private static func groupsWithSummedDenominators() {
        let exchanges = fixtureExchanges()
        let lines = PassengerAnalytics.snapshot(exchanges: exchanges, grouping: .line)
        let routeOne = lines.rows.first { $0.label.contains("route-1") }
        precondition(routeOne?.totals.boardings == 110)
        precondition(routeOne?.totals.validations == 105)
        precondition(routeOne?.totals.validationRate == 105.0 / 110.0)

        let courses = PassengerAnalytics.snapshot(exchanges: exchanges, grouping: .course)
        let courseRows = courses.rows.filter { $0.totals.validationDataBoardings > 0 }
        let unweightedCourseAverage = courseRows.compactMap(\.totals.validationRate).reduce(0, +)
            / Double(courseRows.count)
        precondition(abs(unweightedCourseAverage - (105.0 / 110.0)) > 0.01)
    }

    private static func attributesDisruptionEffectsWithoutChangingBoardingTotals() {
        let events = [
            SimulationEvent(
                sequence: 80,
                simulatedAt: fixtureDate(3_600),
                kind: .busServiceCompletedAtClosedStop(
                    tripID: "trip-3",
                    vehicleID: "bus-1",
                    routeID: "route-2",
                    stopID: "stop-c",
                    stopName: "Terminus fermé",
                    latitude: 48.8,
                    longitude: 2.4,
                    strandedPassengerCount: 5
                )
            ),
            SimulationEvent(
                sequence: 81,
                simulatedAt: fixtureDate(3_600),
                kind: .busServiceCompletedAtClosedStopWithPassengerRedirect(
                    tripID: "trip-2",
                    vehicleID: "bus-2",
                    routeID: "route-1",
                    stopID: "stop-b",
                    stopName: "Terminus bis",
                    latitude: 48.8,
                    longitude: 2.4,
                    passengerCount: 6,
                    replacementStopID: "stop-replacement",
                    replacementStopName: "Arrêt provisoire"
                )
            )
        ]
        let snapshot = PassengerAnalytics.snapshot(
            exchanges: fixtureExchanges(),
            incidents: [fixtureIncident(displacedPassengerCount: 3)],
            events: events,
            grouping: .line
        )

        precondition(snapshot.boardings == 160)
        precondition(snapshot.validationDataBoardings == 110)
        precondition(snapshot.validations == 105)
        precondition(snapshot.redirectedPassengerCount == 10)
        precondition(snapshot.leftBehindPassengerCount == 2)
        precondition(snapshot.displacedPassengerCount == 8)
    }

    private static func satisfactionUsesOnlyMeasuredAccessAndConnectionSamples() {
        var first = makeExchange(
            tripID: "trip-1",
            routeID: "route-1",
            vehicleID: "bus-1",
            stopID: "stop-a",
            stopName: "Arrêt A",
            at: fixtureDate(0),
            boarded: 3,
            onboard: 8,
            capacity: 10,
            leftBehind: 1,
            redirected: nil,
            breakdown: nil
        )
        first.newlyBoardedArrivalsCount = 3
        first.accessBoardingSampleEligible = true
        first.connectingTripAttemptCount = 4
        first.connectingTripBoardedCount = 3

        var second = makeExchange(
            tripID: "trip-2",
            routeID: "route-1",
            vehicleID: "bus-1",
            stopID: "stop-b",
            stopName: "Arrêt B",
            at: fixtureDate(3_600),
            boarded: 1,
            onboard: 10,
            capacity: 10,
            leftBehind: 0,
            redirected: nil,
            breakdown: nil
        )
        second.newlyBoardedArrivalsCount = 1
        second.accessBoardingSampleEligible = true
        second.connectingTripAttemptCount = 0
        second.connectingTripBoardedCount = 0

        let legacy = makeExchange(
            tripID: "trip-3",
            routeID: "route-2",
            vehicleID: "bus-2",
            stopID: "stop-c",
            stopName: "Arrêt C",
            at: fixtureDate(3_601),
            boarded: 0,
            onboard: 5,
            capacity: 10,
            leftBehind: 0,
            redirected: nil,
            breakdown: nil,
            capacityIsEstimated: true
        )

        var closed = makeExchange(
            tripID: "trip-4",
            routeID: "route-1",
            vehicleID: "bus-1",
            stopID: "stop-closed",
            stopName: "Arrêt fermé",
            at: fixtureDate(3_602),
            boarded: 0,
            onboard: 9,
            capacity: 10,
            leftBehind: 5,
            redirected: nil,
            breakdown: nil
        )
        closed.stopWasClosed = true
        closed.newlyBoardedArrivalsCount = 0
        closed.accessBoardingSampleEligible = false
        closed.connectingTripAttemptCount = 0
        closed.connectingTripBoardedCount = 0

        let pending = PassengerTransferQueueEntry(
            sourceTripID: "source-trip",
            targetRouteID: "route-1",
            targetVehicleID: "bus-1",
            intendedTripID: "target-trip",
            stopID: "stop-b",
            passengerCount: 5,
            readyAt: fixtureDate(3_600)
        )
        let snapshot = PassengerAnalytics.snapshot(
            exchanges: [first, second, legacy, closed],
            pendingTransfers: [pending],
            grouping: .line
        )

        let satisfaction = snapshot.satisfaction
        precondition(satisfaction.score == 68)
        precondition(satisfaction.coveredComponentCount == 3)
        precondition(satisfaction.access.score == 80)
        precondition(satisfaction.access.boardedArrivals == 4)
        precondition(satisfaction.access.leftBehindArrivals == 1)
        precondition(satisfaction.comfort.score == 50)
        precondition(satisfaction.comfort.sampleCount == 3)
        precondition(satisfaction.comfort.estimatedCapacitySampleCount == 1)
        precondition(satisfaction.connections.score == 75)
        precondition(satisfaction.connections.attemptedPassengerCount == 4)
        precondition(satisfaction.connections.boardedPassengerCount == 3)
        precondition(satisfaction.connections.missedPassengerCount == 1)
        precondition(satisfaction.connections.pendingGroupCount == 1)
        precondition(satisfaction.connections.pendingPassengerCount == 5)

        let courseFiltered = PassengerAnalytics.snapshot(
            exchanges: [first, second, legacy, closed],
            pendingTransfers: [pending],
            filter: PassengerAnalyticsFilter(routeID: "route-1", vehicleID: "bus-1"),
            grouping: .course
        )
        precondition(courseFiltered.satisfaction.access.score == 80)
        precondition(courseFiltered.satisfaction.comfort.score == 25)
        precondition(courseFiltered.satisfaction.connections.score == 75)
        precondition(courseFiltered.satisfaction.score == 60)
        let pendingCourse = courseFiltered.rows.first { $0.label.contains("target-trip") }
        precondition(pendingCourse?.totals.satisfaction.connections.pendingGroupCount == 1)
        precondition(pendingCourse?.totals.satisfaction.connections.attemptedPassengerCount == 0)

        let dateFiltered = PassengerAnalytics.snapshot(
            exchanges: [first, second, legacy, closed],
            pendingTransfers: [pending],
            filter: PassengerAnalyticsFilter(
                startAt: fixtureDate(0),
                endAt: fixtureDate(0),
                routeID: "route-1",
                vehicleID: "bus-1"
            ),
            grouping: .course
        )
        precondition(dateFiltered.satisfaction.score == 67)
        precondition(dateFiltered.satisfaction.connections.pendingGroupCount == 0)

        let legacyOnly = PassengerAnalytics.snapshot(exchanges: [legacy], grouping: .line)
        precondition(legacyOnly.satisfaction.score == 100)
        precondition(legacyOnly.satisfaction.coveredComponentCount == 1)
        precondition(legacyOnly.satisfaction.access.score == nil)
        precondition(legacyOnly.satisfaction.connections.score == nil)

        var encoded = try! JSONEncoder().encode(legacy)
        var legacyObject = try! JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        for key in [
            "newlyBoardedArrivalsCount",
            "accessBoardingSampleEligible",
            "connectingTripAttemptCount",
            "connectingTripBoardedCount"
        ] {
            legacyObject.removeValue(forKey: key)
        }
        encoded = try! JSONSerialization.data(withJSONObject: legacyObject)
        let decoded = try! JSONDecoder().decode(PassengerStopExchange.self, from: encoded)
        precondition(decoded.newlyBoardedArrivalsCount == nil)
        precondition(decoded.accessBoardingSampleEligible == nil)
        precondition(decoded.connectingTripAttemptCount == nil)
        precondition(decoded.connectingTripBoardedCount == nil)
    }

    private static func fixtureExchanges() -> [PassengerStopExchange] {
        [
            makeExchange(
                tripID: "trip-1",
                routeID: "route-1",
                vehicleID: "bus-1",
                stopID: "stop-a",
                stopName: "Arrêt A",
                at: fixtureDate(0),
                boarded: 10,
                onboard: 8,
                capacity: 10,
                leftBehind: 2,
                redirected: nil,
                breakdown: PassengerValidationBreakdown(
                    boardedCount: 10,
                    navigoSubscriptionCount: 8,
                    singleTicketCount: 2,
                    reducedFareCount: 0,
                    freeTravelCount: 0
                )
            ),
            makeExchange(
                tripID: "trip-2",
                routeID: "route-1",
                vehicleID: "bus-2",
                stopID: "stop-b",
                stopName: "Arrêt B",
                at: fixtureDate(3_600),
                boarded: 100,
                onboard: 20,
                capacity: 20,
                leftBehind: 0,
                redirected: 4,
                breakdown: PassengerValidationBreakdown(
                    boardedCount: 100,
                    navigoSubscriptionCount: 70,
                    singleTicketCount: 18,
                    reducedFareCount: 5,
                    freeTravelCount: 2
                )
            ),
            makeExchange(
                tripID: "trip-3",
                routeID: "route-2",
                vehicleID: "bus-1",
                stopID: "stop-c",
                stopName: "Arrêt C",
                at: fixtureDate(3_601),
                boarded: 50,
                onboard: 50,
                capacity: 100,
                leftBehind: 0,
                redirected: nil,
                breakdown: nil
            )
        ]
    }

    private static func makeExchange(
        tripID: String,
        routeID: String,
        vehicleID: String,
        stopID: String,
        stopName: String,
        at date: Date,
        boarded: Int,
        onboard: Int,
        capacity: Int,
        leftBehind: Int,
        redirected: Int?,
        breakdown: PassengerValidationBreakdown?,
        capacityIsEstimated: Bool = false
    ) -> PassengerStopExchange {
        PassengerStopExchange(
            tripID: tripID,
            vehicleID: vehicleID,
            routeID: routeID,
            stopID: stopID,
            stopName: stopName,
            occurredAt: date,
            boardedCount: boarded,
            alightedCount: 0,
            leftBehindCount: leftBehind,
            onboardAfterExchange: onboard,
            capacity: capacity,
            capacityIsEstimated: capacityIsEstimated,
            estimatedArrivalsCount: boarded + leftBehind,
            waitingBeforeCount: 0,
            waitingAfterCount: leftBehind,
            newlyLeftBehindCount: leftBehind,
            redirectedPassengerCount: redirected,
            validationBreakdown: breakdown
        )
    }

    private static func fixtureIncident(displacedPassengerCount: Int) -> VehicleIncident {
        VehicleIncident(
            id: "incident-1",
            vehicleID: "bus-1",
            vehicleModelName: "Bus standard",
            tripID: "trip-3",
            routeID: "route-2",
            stopID: "stop-c",
            stopName: "Arrêt C",
            latitude: 48.8,
            longitude: 2.4,
            occurredAt: fixtureDate(3_600),
            severity: .minor,
            repairCompletedAt: fixtureDate(7_200),
            repairCostEuro: 0,
            displacedPassengerCount: displacedPassengerCount,
            resolvedAt: nil
        )
    }

    private static func fixtureDate(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_798_000_000 + offset)
    }
}
