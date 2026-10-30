import Foundation

@main
@MainActor
struct RouteDetourExecutionSmoke {
    static func main() {
        futureDetoursShiftOnlyUpcomingVisits()
        passedSegmentsAreNotRewritten()
        dispatchedTripEventsAndReservationsAreUpdated()
        detourDelayPropagatesToFollowingAssignedTrip()
        detourReservationConflictIsAtomic()
        legacySessionsDecodeWithoutTripPlans()
        print("PASS: dispatched route detours update future events and reservations atomically")
    }

    private static func futureDetoursShiftOnlyUpcomingVisits() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let visits = routeVisits(startingAt: start)
        let detour = routeDetour(
            id: "future-detour",
            from: visits[1],
            to: visits[2],
            startsAt: start.addingTimeInterval(60),
            endsAt: start.addingTimeInterval(3_600),
            additionalTravelSeconds: 300
        )

        let result = RouteDetourSchedulePlanner.applying(
            detours: [detour],
            to: visits,
            alreadyAppliedDetourIDs: []
        )

        precondition(result.appliedDetourIDs == [detour.id])
        precondition(result.visits[1].scheduledAt == visits[1].scheduledAt)
        precondition(result.visits[2].scheduledAt == visits[2].scheduledAt.addingTimeInterval(300))
        precondition(result.visits[3].scheduledAt == visits[3].scheduledAt.addingTimeInterval(300))
        precondition(result.visits[1].movementGeometrySource == .temporaryRouteDetour)
        precondition(result.visits[1].movementToNext == detour.replacementCoordinates)
    }

    private static func passedSegmentsAreNotRewritten() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let visits = routeVisits(startingAt: start)
        let detour = routeDetour(
            id: "late-detour",
            from: visits[0],
            to: visits[1],
            startsAt: start.addingTimeInterval(90),
            endsAt: start.addingTimeInterval(3_600),
            additionalTravelSeconds: 300
        )

        let result = RouteDetourSchedulePlanner.applying(
            detours: [detour],
            to: visits,
            alreadyAppliedDetourIDs: []
        )

        precondition(result.appliedDetourIDs.isEmpty)
        precondition(result.visits == visits)
    }

    private static func routeVisits(startingAt start: Date) -> [ScheduledTripStopVisit] {
        (0..<4).map { index in
            let sequence = (index + 1) * 10
            let coordinate = BusMovementCoordinate(latitude: 48.80 + Double(index) * 0.01, longitude: 2.30)
            return ScheduledTripStopVisit(
                stopID: "stop-\(sequence)",
                stopName: "Arrêt \(sequence)",
                stopSequence: sequence,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                scheduledAt: start.addingTimeInterval(Double(index) * 600),
                departureAt: index < 3 ? start.addingTimeInterval(Double(index) * 600 + 60) : nil,
                movementToNext: index < 3 ? [coordinate, BusMovementCoordinate(latitude: coordinate.latitude + 0.005, longitude: coordinate.longitude)] : nil,
                movementGeometrySource: .gtfsShape
            )
        }
    }

    private static func routeDetour(
        id: String,
        from: ScheduledTripStopVisit,
        to: ScheduledTripStopVisit,
        startsAt: Date,
        endsAt: Date,
        additionalTravelSeconds: TimeInterval
    ) -> SimulatedRouteDetour {
        SimulatedRouteDetour(
            id: id,
            routeID: "line-1",
            fromStopID: from.stopID,
            fromStopName: from.stopName,
            fromStopSequence: from.stopSequence,
            toStopID: to.stopID,
            toStopName: to.stopName,
            toStopSequence: to.stopSequence,
            startsAt: startsAt,
            scheduledEndAt: endsAt,
            replacementCoordinates: [
                BusMovementCoordinate(latitude: from.latitude, longitude: from.longitude),
                BusMovementCoordinate(latitude: 48.85, longitude: 2.40),
                BusMovementCoordinate(latitude: to.latitude, longitude: to.longitude)
            ],
            additionalTravelSeconds: additionalTravelSeconds
        )
    }

    private static func dispatchedTripEventsAndReservationsAreUpdated() {
        var session = sessionWithDispatchedTrip()
        let originalHistory = session.eventHistory
        precondition(SimulationEngine.replanActiveDispatchedTrips(in: &session))
        let plan = session.dispatchedTripRoutePlans![0]
        let bySequence = Dictionary(uniqueKeysWithValues: session.pendingEvents.map { ($0.sequence, $0) })
        let originalStops = routeVisits(startingAt: plan.stopVisits[0].scheduledAt)

        precondition(plan.stopVisits[2].scheduledAt == originalStops[2].scheduledAt.addingTimeInterval(300))
        precondition(plan.stopVisits[3].scheduledAt == originalStops[3].scheduledAt.addingTimeInterval(300))
        precondition(session.machinistServiceAssignments?.first?.plannedEndAt == originalStops[3].scheduledAt.addingTimeInterval(300))
        precondition(session.ownedBuses?.first?.reservedUntil == originalStops[3].scheduledAt.addingTimeInterval(300))
        guard let downstreamStop = bySequence[plan.stopEventSequencesByStopSequence[30]!] else {
            preconditionFailure("The downstream stop event should remain pending.")
        }
        precondition(downstreamStop.simulatedAt == originalStops[2].scheduledAt.addingTimeInterval(300))
        guard let downstreamDemand = bySequence[plan.demandEventSequencesByStopSequence[30]!] else {
            preconditionFailure("The downstream passenger demand should remain pending.")
        }
        guard case let .passengerDemand(demand) = downstreamDemand.kind else {
            preconditionFailure("The passenger demand should remain a demand event.")
        }
        precondition(demand.occurredAt == originalStops[2].scheduledAt.addingTimeInterval(300))
        guard let detourMovement = bySequence[plan.movementEventSequencesByFromStopSequence[20]!] else {
            preconditionFailure("The affected movement event should remain pending.")
        }
        guard case let .busMovementStarted(_, movementLeg) = detourMovement.kind else {
            preconditionFailure("The affected movement should retain its scheduled movement event.")
        }
        precondition(movementLeg.geometrySource == .temporaryRouteDetour)
        precondition(movementLeg.coordinates == session.routeDetours![0].replacementCoordinates)
        guard let completion = bySequence[plan.completionEventSequence!] else {
            preconditionFailure("The service completion should remain pending.")
        }
        precondition(completion.simulatedAt == originalStops[3].scheduledAt.addingTimeInterval(300))
        precondition(Array(session.eventHistory.prefix(originalHistory.count)) == originalHistory)
        guard case let .routeDetourReplanned(_, _, addedDelaySeconds, addedDistanceMeters) = session.eventHistory.last!.kind else {
            preconditionFailure("The event log should explain the affected course delay and distance.")
        }
        precondition(addedDelaySeconds == 300)
        precondition(addedDistanceMeters > 0)

        let updatedEnd = session.machinistServiceAssignments![0].plannedEndAt
        precondition(SimulationEngine.replanActiveDispatchedTrips(in: &session))
        precondition(session.machinistServiceAssignments![0].plannedEndAt == updatedEnd)
    }

    private static func detourReservationConflictIsAtomic() {
        var session = sessionWithDispatchedTrip()
        let originalEnd = session.machinistServiceAssignments![0].plannedEndAt
        session.machinistServiceAssignments?.append(MachinistServiceAssignment(
            id: "following-trip",
            machinistID: "machinist-1",
            vehicleID: "bus-2",
            tripID: "following-trip",
            routeID: "line-1",
            serviceDateKey: 20261025,
            plannedStartAt: originalEnd.addingTimeInterval(60),
            plannedEndAt: originalEnd.addingTimeInterval(900)
        ))
        let unchanged = session

        precondition(!SimulationEngine.replanActiveDispatchedTrips(in: &session))
        precondition(session == unchanged, "A rejected detour must not partially change the saved simulation state.")
    }

    private static func detourDelayPropagatesToFollowingAssignedTrip() {
        var session = sessionWithDispatchedTrip()
        let firstPlan = session.dispatchedTripRoutePlans![0]
        let firstEnd = firstPlan.stopVisits.last!.scheduledAt
        let followingStart = firstEnd.addingTimeInterval(60)
        let followingVisits = routeVisits(startingAt: followingStart)
        let followingKey = "trip-2|line-1|20261025"
        let followingCompletionSequence: UInt64 = 240
        let thirdStart = followingVisits.last!.scheduledAt.addingTimeInterval(60)
        let thirdVisits = routeVisits(startingAt: thirdStart)
        let thirdKey = "trip-3|line-1|20261025"
        let thirdCompletionSequence: UInt64 = 340
        session.dispatchedTripRoutePlans?.append(DispatchedTripRoutePlan(
            tripKey: followingKey,
            tripID: "trip-2",
            routeID: "line-1",
            serviceDateKey: 20261025,
            vehicleID: "bus-1",
            machinistID: "machinist-1",
            passengerCapacity: 85,
            capacityIsEstimated: true,
            stopVisits: followingVisits,
            appliedDetourIDs: [],
            stopEventSequencesByStopSequence: [:],
            demandEventSequencesByStopSequence: [:],
            movementEventSequencesByFromStopSequence: [:],
            completionEventSequence: followingCompletionSequence
        ))
        session.dispatchedTripRoutePlans?.append(DispatchedTripRoutePlan(
            tripKey: thirdKey,
            tripID: "trip-3",
            routeID: "line-1",
            serviceDateKey: 20261025,
            vehicleID: "bus-1",
            machinistID: "machinist-1",
            passengerCapacity: 85,
            capacityIsEstimated: true,
            stopVisits: thirdVisits,
            appliedDetourIDs: [],
            stopEventSequencesByStopSequence: [:],
            demandEventSequencesByStopSequence: [:],
            movementEventSequencesByFromStopSequence: [:],
            completionEventSequence: thirdCompletionSequence
        ))
        let followingEnd = followingVisits.last!.scheduledAt
        let thirdEnd = thirdVisits.last!.scheduledAt
        session.machinistServiceAssignments?.append(MachinistServiceAssignment(
            id: followingKey,
            machinistID: "machinist-1",
            dutyBlockID: "block-1",
            vehicleID: "bus-1",
            vehicleModelID: "unknown-model",
            tripID: "trip-2",
            routeID: "line-1",
            serviceDateKey: 20261025,
            plannedStartAt: followingStart,
            plannedEndAt: followingEnd
        ))
        session.machinistServiceAssignments?.append(MachinistServiceAssignment(
            id: thirdKey,
            machinistID: "machinist-1",
            dutyBlockID: "block-1",
            vehicleID: "bus-1",
            vehicleModelID: "unknown-model",
            tripID: "trip-3",
            routeID: "line-1",
            serviceDateKey: 20261025,
            plannedStartAt: thirdStart,
            plannedEndAt: thirdEnd
        ))
        session.machinistDutyBlocks?[0].plannedEndAt = thirdEnd
        session.ownedBuses?[0].reservedUntil = thirdEnd
        session.pendingEvents.append(SimulationEvent(
            sequence: followingCompletionSequence,
            simulatedAt: followingEnd,
            kind: .busServiceCompleted(
                tripID: "trip-2",
                vehicleID: "bus-1",
                stopID: followingVisits.last!.stopID,
                stopName: followingVisits.last!.stopName,
                latitude: followingVisits.last!.latitude,
                longitude: followingVisits.last!.longitude
            )
        ))
        session.pendingEvents.append(SimulationEvent(
            sequence: thirdCompletionSequence,
            simulatedAt: thirdEnd,
            kind: .busServiceCompleted(
                tripID: "trip-3",
                vehicleID: "bus-1",
                stopID: thirdVisits.last!.stopID,
                stopName: thirdVisits.last!.stopName,
                latitude: thirdVisits.last!.latitude,
                longitude: thirdVisits.last!.longitude
            )
        ))
        let expectedShift: TimeInterval = 300

        precondition(SimulationEngine.replanActiveDispatchedTrips(in: &session))

        let updatedFollowing = session.dispatchedTripRoutePlans!.first { $0.tripKey == followingKey }!
        let updatedThird = session.dispatchedTripRoutePlans!.first { $0.tripKey == thirdKey }!
        let updatedAssignment = session.machinistServiceAssignments!.first { $0.id == followingKey }!
        let updatedThirdAssignment = session.machinistServiceAssignments!.first { $0.id == thirdKey }!
        precondition(updatedFollowing.stopVisits[0].scheduledAt == followingStart.addingTimeInterval(expectedShift))
        precondition(updatedFollowing.stopVisits.last!.scheduledAt == followingEnd.addingTimeInterval(expectedShift))
        precondition(updatedAssignment.plannedStartAt == followingStart.addingTimeInterval(expectedShift))
        precondition(updatedAssignment.plannedEndAt == followingEnd.addingTimeInterval(expectedShift))
        precondition(updatedThird.stopVisits[0].scheduledAt == thirdStart.addingTimeInterval(expectedShift))
        precondition(updatedThird.stopVisits.last!.scheduledAt == thirdEnd.addingTimeInterval(expectedShift))
        precondition(updatedThirdAssignment.plannedStartAt == thirdStart.addingTimeInterval(expectedShift))
        precondition(updatedThirdAssignment.plannedEndAt == thirdEnd.addingTimeInterval(expectedShift))
        let completion = session.pendingEvents.first { $0.sequence == followingCompletionSequence }!
        precondition(completion.simulatedAt == followingEnd.addingTimeInterval(expectedShift))
        let thirdCompletion = session.pendingEvents.first { $0.sequence == thirdCompletionSequence }!
        precondition(thirdCompletion.simulatedAt == thirdEnd.addingTimeInterval(expectedShift))
        precondition(session.machinistDutyBlocks![0].plannedEndAt == thirdEnd.addingTimeInterval(expectedShift))
        precondition(session.ownedBuses![0].reservedUntil == thirdEnd.addingTimeInterval(expectedShift))
        let propagatedTrips = session.eventHistory.compactMap { event -> String? in
            guard case let .followingServiceDelayed(_, toTripID, _, delaySeconds) = event.kind,
                  delaySeconds == expectedShift else { return nil }
            return toTripID
        }
        precondition(propagatedTrips == ["trip-2", "trip-3"])
    }

    private static func legacySessionsDecodeWithoutTripPlans() {
        let session = sessionWithDispatchedTrip()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try! encoder.encode(session)
        var object = try! JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        object.removeValue(forKey: "dispatchedTripRoutePlans")
        let legacyJSON = try! JSONSerialization.data(withJSONObject: object)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try! decoder.decode(SimulationSession.self, from: legacyJSON)
        precondition(decoded.dispatchedTripRoutePlans == nil)
    }

    private static func sessionWithDispatchedTrip() -> SimulationSession {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let visits = routeVisits(startingAt: start)
        let detour = routeDetour(
            id: "future-detour",
            from: visits[1],
            to: visits[2],
            startsAt: start.addingTimeInterval(600),
            endsAt: start.addingTimeInterval(1_200),
            additionalTravelSeconds: 300
        )
        let tripKey = "trip-1|line-1|20261025"
        let stopSequences: [Int: UInt64] = [20: 100, 30: 101, 40: 102]
        let demandSequences: [Int: UInt64] = [10: 110, 20: 111, 30: 112, 40: 113]
        let movementSequences: [Int: UInt64] = [10: 120, 20: 121, 30: 122]
        let plan = DispatchedTripRoutePlan(
            tripKey: tripKey,
            tripID: "trip-1",
            routeID: "line-1",
            serviceDateKey: 20261025,
            vehicleID: "bus-1",
            machinistID: "machinist-1",
            passengerCapacity: 85,
            capacityIsEstimated: true,
            stopVisits: visits,
            appliedDetourIDs: [],
            stopEventSequencesByStopSequence: stopSequences,
            demandEventSequencesByStopSequence: demandSequences,
            movementEventSequencesByFromStopSequence: movementSequences,
            completionEventSequence: 130
        )
        var events: [SimulationEvent] = []
        for visit in visits.dropFirst() {
            events.append(SimulationEvent(
                sequence: stopSequences[visit.stopSequence]!,
                simulatedAt: visit.scheduledAt,
                kind: .busAtStop(
                    tripID: "trip-1",
                    vehicleID: "bus-1",
                    stopID: visit.stopID,
                    stopName: visit.stopName,
                    stopSequence: visit.stopSequence,
                    latitude: visit.latitude,
                    longitude: visit.longitude
                )
            ))
        }
        for visit in visits {
            let demand = PassengerStopDemand(
                tripID: "trip-1",
                vehicleID: "bus-1",
                routeID: "line-1",
                stopID: visit.stopID,
                stopName: visit.stopName,
                occurredAt: visit.scheduledAt,
                estimatedArrivalsCount: 10,
                alightingShare: 0.2,
                isTerminal: visit.stopSequence == 40,
                capacity: 85,
                capacityIsEstimated: true
            )
            events.append(SimulationEvent(
                sequence: demandSequences[visit.stopSequence]!,
                simulatedAt: visit.scheduledAt,
                kind: .passengerDemand(demand)
            ))
        }
        for index in visits.indices.dropLast() {
            let startVisit = visits[index]
            let endVisit = visits[index + 1]
            let leg = ScheduledBusMovementLeg(
                startsAt: startVisit.departureAt!,
                endsAt: endVisit.scheduledAt,
                coordinates: startVisit.movementToNext!,
                geometrySource: startVisit.movementGeometrySource
            )
            events.append(SimulationEvent(
                sequence: movementSequences[startVisit.stopSequence]!,
                simulatedAt: leg.startsAt,
                kind: .busMovementStarted(vehicleID: "bus-1", leg: leg)
            ))
        }
        let last = visits.last!
        events.append(SimulationEvent(
            sequence: 130,
            simulatedAt: last.scheduledAt,
            kind: .busServiceCompleted(
                tripID: "trip-1",
                vehicleID: "bus-1",
                stopID: last.stopID,
                stopName: last.stopName,
                latitude: last.latitude,
                longitude: last.longitude
            )
        ))
        events.sort {
            if $0.simulatedAt != $1.simulatedAt { return $0.simulatedAt < $1.simulatedAt }
            return $0.sequence < $1.sequence
        }
        events.removeAll { $0.sequence == demandSequences[10] || $0.sequence == movementSequences[10] }

        var bus = PurchasedBus(
            id: "bus-1",
            modelID: "unknown-model",
            offerID: "offer",
            depotID: "depot-1",
            acquiredAt: start,
            modelYear: 2024,
            odometerKilometers: 0,
            conditionPercent: 100,
            purchasePrice: 0,
            deliveryAt: start,
            status: .assigned
        )
        bus.reservedTripKey = tripKey
        bus.reservedUntil = last.scheduledAt
        let assignment = MachinistServiceAssignment(
            id: tripKey,
            machinistID: "machinist-1",
            dutyBlockID: "block-1",
            vehicleID: "bus-1",
            vehicleModelID: "unknown-model",
            tripID: "trip-1",
            routeID: "line-1",
            serviceDateKey: 20261025,
            plannedStartAt: start,
            plannedEndAt: last.scheduledAt
        )
        let block = MachinistDutyBlock(
            id: "block-1",
            machinistID: "machinist-1",
            plannedStartAt: start,
            plannedEndAt: last.scheduledAt
        )
        var session = SimulationSession(
            id: "session-1",
            scenarioID: "scenario-1",
            depotID: "depot-1",
            networkVersions: SimulationDataVersions(
                gtfsID: "gtfs",
                routeGeometryID: "geometry",
                contractID: "contracts",
                lineReferenceID: "references"
            ),
            randomSeed: 123,
            createdAt: start,
            updatedAt: start,
            simulatedAt: start.addingTimeInterval(300),
            speed: .paused,
            resumeSpeed: .x1,
            nextEventSequence: 200,
            pendingEvents: events,
            eventHistory: [SimulationEvent(
                sequence: 1,
                simulatedAt: start.addingTimeInterval(-600),
                kind: .dailySettlement(dateKey: 20261024)
            )]
        )
        session.routeDetours = [detour]
        session.dispatchedTripRoutePlans = [plan]
        session.ownedBuses = [bus]
        session.machinists = [Machinist(
            id: "machinist-1",
            employeeNumber: 1,
            qualification: .standard,
            hiredAt: start,
            depotID: "depot-1"
        )]
        session.machinistServiceAssignments = [assignment]
        session.machinistDutyBlocks = [block]
        return session
    }
}
