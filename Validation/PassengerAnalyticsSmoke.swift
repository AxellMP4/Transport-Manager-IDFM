import Foundation

@main
struct PassengerAnalyticsSmoke {
    static func main() {
        aggregatesBoardingsValidationTitlesAndPeakOccupancy()
        appliesInclusiveDateRouteAndVehicleFilters()
        groupsWithSummedDenominators()
        attributesDisruptionEffectsWithoutChangingBoardingTotals()
        print("PASS: passenger analytics aggregate validations and disruption effects without double-counting")
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
        breakdown: PassengerValidationBreakdown?
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
            capacityIsEstimated: false,
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
