import Foundation

struct GTFSDepartureIntervalSummary: Equatable, Sendable {
    let departureCount: Int
    let intervalCount: Int
    let medianIntervalSeconds: TimeInterval?
    let maximumIntervalSeconds: TimeInterval?

    init(departures: [Date]) {
        let orderedDepartures = departures.sorted()
        let intervals = zip(orderedDepartures, orderedDepartures.dropFirst())
            .map { earlier, later in later.timeIntervalSince(earlier) }
        let orderedIntervals = intervals.sorted()

        departureCount = orderedDepartures.count
        intervalCount = intervals.count
        maximumIntervalSeconds = orderedIntervals.last

        if orderedIntervals.isEmpty {
            medianIntervalSeconds = nil
        } else if orderedIntervals.count.isMultiple(of: 2) {
            let middle = orderedIntervals.count / 2
            medianIntervalSeconds = (orderedIntervals[middle - 1] + orderedIntervals[middle]) / 2
        } else {
            medianIntervalSeconds = orderedIntervals[orderedIntervals.count / 2]
        }
    }
}
