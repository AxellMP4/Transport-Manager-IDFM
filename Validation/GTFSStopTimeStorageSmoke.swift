import Foundation

@main
struct GTFSStopTimeStorageSmoke {
    static func main() {
        let trips = [
            "trip-1": BusTripReference(
                routeID: "route-1",
                serviceID: "weekday",
                directionID: "0",
                headsign: "Centre-ville",
                shapeID: "shape-1"
            )
        ]
        let collector = BusStopRouteCollector(tripByID: trips)
        collector.consume([
            "trip_id": "trip-1",
            "stop_id": "stop-b",
            "stop_sequence": "2",
            "arrival_time": "08:10:00",
            "departure_time": "08:10:00"
        ])
        collector.consume([
            "trip_id": "trip-1",
            "stop_id": "stop-a",
            "stop_sequence": "1",
            "arrival_time": "08:00:00",
            "departure_time": "08:00:00"
        ])

        guard collector.retainedStopTimeRowCount == 2 else {
            fatalError("The collector should report both parsed rows before transferring them.")
        }
        let schedules = collector.takeTripSchedules()
        guard schedules.count == 1,
              schedules[0].tripID == "trip-1",
              schedules[0].routeID == "route-1",
              schedules[0].serviceID == "weekday",
              schedules[0].stops.map(\.stopID) == ["stop-a", "stop-b"],
              schedules[0].stops.map(\.stopSequence) == [1, 2] else {
            fatalError("Transferring rows must preserve one complete schedule in stop order.")
        }
        guard collector.retainedStopTimeRowCount == 0 else {
            fatalError("The collector must release raw stop-time rows after transferring schedules.")
        }
        let departures = collector.tripDepartures
        guard departures.count == 1,
              departures[0].tripID == "trip-1",
              departures[0].departureSeconds == 28_800 else {
            fatalError("Transferring schedules must preserve the original first-stop departure index.")
        }
        guard collector.takeTripSchedules().isEmpty else {
            fatalError("Transferred stop-time rows must not be emitted a second time.")
        }

        print("PASS: stop-time rows move into ordered schedules without retaining a duplicate buffer")
    }
}
