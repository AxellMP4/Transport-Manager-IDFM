import Foundation

@main
struct GTFSDepartureIntervalSmoke {
    static func main() {
        summarizesSortedDeparturesAndLongGaps()
        calculatesEvenMedian()
        handlesSingleAndMissingDepartures()
        preservesSimultaneousDepartures()
        print("PASS: GTFS departure interval summaries cover median, longest gap, and sparse schedules")
    }

    private static func summarizesSortedDeparturesAndLongGaps() {
        let summary = GTFSDepartureIntervalSummary(departures: [
            date(15 * 3_600 + 35 * 60),
            date(9 * 3_600 + 40 * 60),
            date(13 * 3_600 + 5 * 60),
            date(12 * 3_600 + 35 * 60)
        ])

        precondition(summary.departureCount == 4)
        precondition(summary.intervalCount == 3)
        precondition(summary.medianIntervalSeconds == 150 * 60)
        precondition(summary.maximumIntervalSeconds == 175 * 60)
    }

    private static func calculatesEvenMedian() {
        let summary = GTFSDepartureIntervalSummary(departures: [0, 10, 70, 100, 180].map(date))

        precondition(summary.intervalCount == 4)
        precondition(summary.medianIntervalSeconds == 45)
        precondition(summary.maximumIntervalSeconds == 80)
    }

    private static func handlesSingleAndMissingDepartures() {
        let oneDeparture = GTFSDepartureIntervalSummary(departures: [date(10_800)])
        precondition(oneDeparture.departureCount == 1)
        precondition(oneDeparture.intervalCount == 0)
        precondition(oneDeparture.medianIntervalSeconds == nil)
        precondition(oneDeparture.maximumIntervalSeconds == nil)

        let noDepartures = GTFSDepartureIntervalSummary(departures: [])
        precondition(noDepartures.departureCount == 0)
        precondition(noDepartures.medianIntervalSeconds == nil)
        precondition(noDepartures.maximumIntervalSeconds == nil)
    }

    private static func preservesSimultaneousDepartures() {
        let summary = GTFSDepartureIntervalSummary(departures: [date(10_800), date(10_800)])
        precondition(summary.intervalCount == 1)
        precondition(summary.medianIntervalSeconds == 0)
        precondition(summary.maximumIntervalSeconds == 0)
    }

    private static func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }
}
