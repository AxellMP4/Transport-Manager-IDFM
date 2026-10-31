import Foundation

@main
struct PassengerValidationSmoke {
    static func main() {
        validatesBoardersWithAnEstimatedTitleMix()
        validationOutcomesRepeatForTheSameTripAndStop()
        repeatedStopVisitsUseDistinctRandomStreams()
        zeroBoardersHaveNoValidationRate()
        loadPresentationClampsItsGaugeAndFlagsFullVehicles()
        print("PASS: passenger validation rules and load presentation")
    }

    private static func validatesBoardersWithAnEstimatedTitleMix() {
        let result = PassengerValidationRules.resolve(
            boardedCount: 10_000,
            tripID: "trip-42",
            routeID: "route-113",
            stopID: "stop-10",
            stopSequence: 10,
            randomSeed: 42
        )

        precondition(result.boardedCount == 10_000)
        precondition(result.validatedCount + result.unvalidatedCount == 10_000)
        precondition(result.validationRate != nil)
        precondition((0.89...0.91).contains(result.validationRate!))

        let titleTotal = PassengerValidationType.allCases.reduce(0) { total, type in
            total + result.validationCount(for: type)
        }
        precondition(titleTotal == result.validatedCount)
        precondition(PassengerValidationType.allCases.allSatisfy { result.validationCount(for: $0) > 0 })

        let validated = Double(result.validatedCount)
        precondition((0.68...0.72).contains(Double(result.validationCount(for: .navigoSubscription)) / validated))
        precondition((0.20...0.24).contains(Double(result.validationCount(for: .singleTicket)) / validated))
        precondition((0.04...0.08).contains(Double(result.validationCount(for: .reducedFare)) / validated))
        precondition((0.00...0.04).contains(Double(result.validationCount(for: .freeTravel)) / validated))
    }

    private static func validationOutcomesRepeatForTheSameTripAndStop() {
        let first = PassengerValidationRules.resolve(
            boardedCount: 500,
            tripID: "trip-42",
            routeID: "route-113",
            stopID: "stop-10",
            stopSequence: 10,
            randomSeed: 42
        )
        let replay = PassengerValidationRules.resolve(
            boardedCount: 500,
            tripID: "trip-42",
            routeID: "route-113",
            stopID: "stop-10",
            stopSequence: 10,
            randomSeed: 42
        )

        precondition(first == replay)
    }

    private static func repeatedStopVisitsUseDistinctRandomStreams() {
        let firstVisit = PassengerValidationRules.resolve(
            boardedCount: 10_000,
            tripID: "trip-loop",
            routeID: "route-1",
            stopID: "same-stop",
            stopSequence: 2,
            randomSeed: 7
        )
        let secondVisit = PassengerValidationRules.resolve(
            boardedCount: 10_000,
            tripID: "trip-loop",
            routeID: "route-1",
            stopID: "same-stop",
            stopSequence: 9,
            randomSeed: 7
        )

        precondition(firstVisit != secondVisit)
    }

    private static func zeroBoardersHaveNoValidationRate() {
        let result = PassengerValidationRules.resolve(
            boardedCount: 0,
            tripID: "trip-empty",
            routeID: "route-1",
            stopID: "stop-1",
            stopSequence: 1,
            randomSeed: 1
        )

        precondition(result.boardedCount == 0)
        precondition(result.validatedCount == 0)
        precondition(result.unvalidatedCount == 0)
        precondition(result.validationRate == nil)
    }

    private static func loadPresentationClampsItsGaugeAndFlagsFullVehicles() {
        let empty = PassengerLoadPresentation(passengerCount: 0, capacity: 100, capacityIsEstimated: false)
        precondition(empty.occupancyPercent == 0)
        precondition(empty.progressFraction == 0)
        precondition(empty.status == .normal)

        let high = PassengerLoadPresentation(passengerCount: 80, capacity: 100, capacityIsEstimated: true)
        precondition(high.occupancyPercent == 80)
        precondition(high.status == .high)
        precondition(high.capacityIsEstimated)

        let full = PassengerLoadPresentation(passengerCount: 100, capacity: 100, capacityIsEstimated: false)
        precondition(full.occupancyPercent == 100)
        precondition(full.progressFraction == 1)
        precondition(full.status == .full)

        let overCapacity = PassengerLoadPresentation(passengerCount: 126, capacity: 100, capacityIsEstimated: false)
        precondition(overCapacity.occupancyPercent == 126)
        precondition(overCapacity.progressFraction == 1)
        precondition(overCapacity.status == .full)
    }
}
