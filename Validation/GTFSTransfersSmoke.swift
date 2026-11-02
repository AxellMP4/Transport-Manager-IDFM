import Foundation

@main
@MainActor
struct GTFSTransfersSmoke {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            fatalError("Usage: GTFSTransfersSmoke <transfers.zip> <without-transfers.zip>")
        }

        let withTransfersCatalog = try NetworkVersionStore.importGTFS(
            from: URL(fileURLWithPath: CommandLine.arguments[1])
        )
        guard let withTransfersVersionID = withTransfersCatalog.activeVersionID else {
            fatalError("The transfer fixture should create a GTFS version.")
        }
        let legacyCatalog = try NetworkVersionStore.importGTFS(
            from: URL(fileURLWithPath: CommandLine.arguments[2])
        )
        guard let legacyVersionID = legacyCatalog.activeVersionID else {
            fatalError("The legacy fixture should create a GTFS version.")
        }

        typeTwoMinimumTimeAndMissedTransferRetention(versionID: withTransfersVersionID)
        transferRulesAreDirectional(versionID: withTransfersVersionID)
        specificRulesSupplantGenericRules(versionID: withTransfersVersionID)
        typeThreeForbidsTransfer(versionID: withTransfersVersionID)
        parentStationsApplyToChildStops(versionID: withTransfersVersionID)
        recommendedAndTimedTransfersUseTheirSemantics(versionID: withTransfersVersionID)
        try timedTransfersHoldTheTargetSchedule(versionID: withTransfersVersionID)
        unprovenLinkedTripsAreNotExecuted(versionID: withTransfersVersionID)
        typeFourInSeatPassengersStayOnTheLinkedVehicle(versionID: withTransfersVersionID)
        try malformedTransferRowsAreIgnored(archiveURL: URL(fileURLWithPath: CommandLine.arguments[1]))
        feedsWithoutTransfersKeepTheLegacyFallback(versionID: legacyVersionID)
        oldTransferJSONStillDecodes()

        print("PASS: imported GTFS transfer rules, directional station transfers, missed-transfer queues, fallback and legacy JSON")
    }

    private static func typeTwoMinimumTimeAndMissedTransferRetention(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_000_000)
        let source = demand(
            tripID: "TRIP-FROM",
            routeID: "R1",
            stopID: "FROM",
            at: start
        )
        let earlyTarget = demand(
            tripID: "TRIP-TO-EARLY",
            routeID: "R2",
            stopID: "TO",
            at: start.addingTimeInterval(60)
        )
        let earlyEvent = event(sequence: 11, demand: earlyTarget)
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [earlyEvent]

        let sourceEvent = event(sequence: 10, demand: source)
        guard let resolvedSource = SimulationEngine.resolvePassengerDemand(sourceEvent, in: session),
              case let .passengersExchanged(sourceExchange) = resolvedSource.kind else {
            preconditionFailure("A type-2 rule should create a transfer toward the distinct target stop.")
        }
        precondition(sourceExchange.estimatedTransferPassengerCount == 2)
        precondition(sourceExchange.connectingTripID == "TRIP-TO-EARLY")
        precondition(sourceExchange.connectingTripAttemptCount == 0)
        precondition(sourceExchange.connectingTripBoardedCount == 0)
        precondition(sourceExchange.transferReadyAt == start.addingTimeInterval(120))
        precondition(sourceExchange.connectingStopID == "TO")

        SimulationEngine.applyVehicleEvent(resolvedSource, to: &session)
        SimulationEngine.applyVehicleEvent(resolvedSource, to: &session)
        precondition(session.passengerTransferQueueEntries?.count == 1, "Replaying an exchange must not duplicate its transfer queue entry.")
        precondition(session.passengerTransferQueueEntries?.first?.targetVehicleID == earlyTarget.vehicleID)
        precondition(session.passengerQueuesByRouteStopKey?["R2|TO"] == 2, "Transferred passengers belong to the target stop queue.")

        guard let resolvedEarlyTarget = SimulationEngine.resolvePassengerDemand(earlyEvent, in: session),
              case let .passengersExchanged(earlyExchange) = resolvedEarlyTarget.kind else {
            preconditionFailure("The early target trip should resolve with the transfer still waiting.")
        }
        precondition(earlyExchange.connectingTripAttemptCount == 2)
        precondition(earlyExchange.connectingTripBoardedCount == 0)
        precondition(earlyExchange.missedConnectionCount == 2)
        SimulationEngine.applyVehicleEvent(resolvedEarlyTarget, to: &session)
        precondition(session.passengerQueuesByRouteStopKey?["R2|TO"] == 2, "A missed transfer stays at the distinct target stop.")

        let laterTarget = demand(
            tripID: "TRIP-TO-LATER",
            routeID: "R2",
            stopID: "TO",
            at: start.addingTimeInterval(600)
        )
        guard let resolvedLaterTarget = SimulationEngine.resolvePassengerDemand(
            event(sequence: 12, demand: laterTarget),
            in: session
        ), case let .passengersExchanged(laterExchange) = resolvedLaterTarget.kind else {
            preconditionFailure("The retained transfer should be available to the later target trip.")
        }
        precondition(laterExchange.connectingTripAttemptCount == 0)
        precondition(laterExchange.connectingTripBoardedCount == 0)
        precondition(laterExchange.estimatedTransferBoardedCount == 2)
        SimulationEngine.applyVehicleEvent(resolvedLaterTarget, to: &session)
        precondition(session.passengerQueuesByRouteStopKey?["R2|TO"] == 0)
        precondition(session.passengerTransferQueueEntries?.isEmpty == true)
    }

    private static func transferRulesAreDirectional(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_010_000)
        let reverseSource = demand(tripID: "TRIP-TO", routeID: "R2", stopID: "TO", at: start)
        let reverseTarget = demand(
            tripID: "TRIP-FROM-REVERSE",
            routeID: "R1",
            stopID: "FROM",
            at: start.addingTimeInterval(600)
        )
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [event(sequence: 21, demand: reverseTarget)]
        guard let resolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 20, demand: reverseSource),
            in: session
        ), case let .passengersExchanged(exchange) = resolved.kind else {
            preconditionFailure("Passenger demand should resolve.")
        }
        precondition(exchange.connectingTripID == nil, "A FROM→TO transfer rule must not create the reverse TO→FROM transfer.")
    }

    private static func specificRulesSupplantGenericRules(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_020_000)
        let source = demand(tripID: "TRIP-SPEC-FROM", routeID: "R4", stopID: "SPEC_FROM", at: start)
        let target = demand(
            tripID: "TRIP-SPEC-TO",
            routeID: "R5",
            stopID: "SPEC_TO",
            at: start.addingTimeInterval(90)
        )
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [event(sequence: 31, demand: target)]
        guard let resolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 30, demand: source),
            in: session
        ), case let .passengersExchanged(exchange) = resolved.kind else {
            preconditionFailure("Passenger demand should resolve.")
        }
        precondition(exchange.connectingTripID == target.tripID, "The route-specific type-2 row must override the generic type-3 prohibition.")
        precondition(exchange.transferReadyAt == start.addingTimeInterval(45))
    }

    private static func typeThreeForbidsTransfer(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_030_000)
        let source = demand(tripID: "TRIP-FROM", routeID: "R1", stopID: "BAN_FROM", at: start)
        let target = demand(
            tripID: "TRIP-BAN-TO",
            routeID: "R3",
            stopID: "BAN_TO",
            at: start.addingTimeInterval(600)
        )
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [event(sequence: 41, demand: target)]
        guard let resolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 40, demand: source),
            in: session
        ), case let .passengersExchanged(exchange) = resolved.kind else {
            preconditionFailure("Passenger demand should resolve.")
        }
        precondition(exchange.connectingTripID == nil, "A matching type-3 row blocks the transfer.")
    }

    private static func parentStationsApplyToChildStops(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_040_000)
        let source = demand(
            tripID: "TRIP-PARENT-FROM",
            routeID: "R6",
            stopID: "PARENT_CHILD_FROM",
            at: start
        )
        let target = demand(
            tripID: "TRIP-PARENT-TO",
            routeID: "R7",
            stopID: "PARENT_CHILD_TO",
            at: start.addingTimeInterval(120)
        )
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [event(sequence: 51, demand: target)]
        guard let resolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 50, demand: source),
            in: session
        ), case let .passengersExchanged(exchange) = resolved.kind else {
            preconditionFailure("A station-level transfer should apply to its child stops.")
        }
        precondition(exchange.connectingTripID == target.tripID)
        precondition(exchange.transferReadyAt == start.addingTimeInterval(90))
    }

    private static func unprovenLinkedTripsAreNotExecuted(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_050_000)
        let source = demand(tripID: "TRIP-LINK4-FROM", routeID: "R8", stopID: "LINK4_FROM", at: start)
        let target = demand(
            tripID: "TRIP-LINK4-TO",
            routeID: "R9",
            stopID: "LINK4_TO",
            at: start.addingTimeInterval(120),
            vehicleID: source.vehicleID
        )
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [event(sequence: 61, demand: target)]
        guard let resolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 60, demand: source),
            in: session
        ), case let .passengersExchanged(exchange) = resolved.kind else {
            preconditionFailure("Passenger demand should resolve.")
        }
        precondition(exchange.connectingTripID == nil, "Matching vehicle IDs alone do not prove sequential same-bus linked-trip operation.")

        let sourceTypeFive = demand(
            tripID: "TRIP-LINK5-FROM",
            routeID: "R10",
            stopID: "LINK5_FROM",
            at: start,
            isTerminal: true
        )
        let targetTypeFive = demand(
            tripID: "TRIP-LINK5-TO",
            routeID: "R11",
            stopID: "LINK5_TO",
            at: start.addingTimeInterval(120),
            vehicleID: sourceTypeFive.vehicleID,
            isFirstStop: true
        )
        let interveningTypeFive = demand(
            tripID: "TRIP-INTERVENING",
            routeID: "R12",
            stopID: "LINK5_TO",
            at: start.addingTimeInterval(60),
            vehicleID: sourceTypeFive.vehicleID
        )
        var interveningSession = makeSession(at: start, gtfsVersionID: versionID)
        interveningSession.pendingEvents = [
            event(sequence: 63, demand: interveningTypeFive),
            event(sequence: 64, demand: targetTypeFive)
        ]
        guard let resolvedWithIntervening = SimulationEngine.resolvePassengerDemand(
            event(sequence: 62, demand: sourceTypeFive),
            in: interveningSession
        ), case let .passengersExchanged(interveningExchange) = resolvedWithIntervening.kind else {
            preconditionFailure("Passenger demand should resolve.")
        }
        precondition(interveningExchange.connectingTripID == nil, "Type 5 must not imply consecutive linked trips if another trip is assigned to the same vehicle in between.")

        var typeFiveSession = makeSession(at: start, gtfsVersionID: versionID)
        typeFiveSession.pendingEvents = [event(sequence: 65, demand: targetTypeFive)]
        guard let resolvedTypeFive = SimulationEngine.resolvePassengerDemand(
            event(sequence: 62, demand: sourceTypeFive),
            in: typeFiveSession
        ), case let .passengersExchanged(typeFiveExchange) = resolvedTypeFive.kind else {
            preconditionFailure("Passenger demand should resolve.")
        }
        precondition(typeFiveExchange.connectingTripID == targetTypeFive.tripID, "A verified type-5 link is modeled as an alight-and-reboard transfer.")
        precondition(typeFiveExchange.transferReadyAt == start.addingTimeInterval(300))
    }

    private static func typeFourInSeatPassengersStayOnTheLinkedVehicle(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_070_000)
        let source = demand(
            tripID: "TRIP-LINK4-FROM",
            routeID: "R8",
            stopID: "LINK4_END",
            at: start,
            isTerminal: true
        )
        let target = demand(
            tripID: "TRIP-LINK4-TO",
            routeID: "R9",
            stopID: "LINK4_TO",
            at: start.addingTimeInterval(31 * 60),
            isFirstStop: true
        )
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [event(sequence: 81, demand: target)]
        guard let resolvedSource = SimulationEngine.resolvePassengerDemand(
            event(sequence: 80, demand: source),
            in: session
        ), case let .passengersExchanged(sourceExchange) = resolvedSource.kind else {
            preconditionFailure("A proven GTFS type-4 link should resolve at the source terminus.")
        }

        precondition(sourceExchange.alightedCount == 16, "The estimated in-seat passengers must not be recorded as alighting.")
        precondition(sourceExchange.onboardAfterExchange == 4, "GTFS type-4 passengers should remain aboard the linked vehicle.")
        precondition(sourceExchange.inSeatTransferPassengerCount == 4)
        precondition(sourceExchange.inSeatTransferTripID == target.tripID)
        SimulationEngine.applyVehicleEvent(resolvedSource, to: &session)
        precondition(session.ownedBuses?.first?.onboardPassengerCount == 4)
        precondition(session.passengerTransferQueueEntries?.isEmpty == true, "In-seat transfers do not enter the platform transfer queue.")

        guard let resolvedTarget = SimulationEngine.resolvePassengerDemand(
            event(sequence: 81, demand: target),
            in: session
        ), case let .passengersExchanged(targetExchange) = resolvedTarget.kind else {
            preconditionFailure("The linked target course should resolve with the existing onboard riders.")
        }
        precondition(targetExchange.boardedCount == 0, "In-seat passengers must not be counted as newly boarding at the target course.")
        precondition(targetExchange.onboardAfterExchange == 4)
        SimulationEngine.applyVehicleEvent(resolvedTarget, to: &session)
        precondition(session.ownedBuses?.first?.onboardPassengerCount == 4)

        let differentVehicleTarget = demand(
            tripID: "TRIP-LINK4-TO",
            routeID: "R9",
            stopID: "LINK4_TO",
            at: start.addingTimeInterval(120),
            vehicleID: "bus-2",
            isFirstStop: true
        )
        var differentVehicleSession = makeSession(at: start, gtfsVersionID: versionID)
        differentVehicleSession.pendingEvents = [event(sequence: 83, demand: differentVehicleTarget)]
        guard let differentVehicleSource = SimulationEngine.resolvePassengerDemand(
            event(sequence: 82, demand: source),
            in: differentVehicleSession
        ), case let .passengersExchanged(differentVehicleExchange) = differentVehicleSource.kind else {
            preconditionFailure("The source course should resolve when a linked target uses another vehicle.")
        }
        precondition(differentVehicleExchange.inSeatTransferPassengerCount == nil)
        precondition(differentVehicleExchange.onboardAfterExchange == 0, "A different vehicle cannot inherit the source passengers.")

        let interveningDemand = demand(
            tripID: "TRIP-LINK4-INTERVENING",
            routeID: "R12",
            stopID: "LINK4_TO",
            at: start.addingTimeInterval(60)
        )
        var interveningSession = makeSession(at: start, gtfsVersionID: versionID)
        interveningSession.pendingEvents = [
            event(sequence: 85, demand: interveningDemand),
            event(sequence: 86, demand: target)
        ]
        guard let interveningSource = SimulationEngine.resolvePassengerDemand(
            event(sequence: 84, demand: source),
            in: interveningSession
        ), case let .passengersExchanged(interveningExchange) = interveningSource.kind else {
            preconditionFailure("The source course should resolve when another trip is scheduled between linked trips.")
        }
        precondition(interveningExchange.inSeatTransferPassengerCount == nil)
        precondition(interveningExchange.onboardAfterExchange == 0, "An intervening trip prevents the linked-course in-seat transfer.")
    }

    private static func recommendedAndTimedTransfersUseTheirSemantics(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_055_000)
        let recommendedSource = demand(tripID: "TRIP-ZERO-FROM", routeID: "R12", stopID: "ZERO_FROM", at: start)
        let recommendedTarget = demand(
            tripID: "TRIP-ZERO-TO",
            routeID: "R13",
            stopID: "ZERO_TO",
            at: start.addingTimeInterval(600)
        )
        var recommendedSession = makeSession(at: start, gtfsVersionID: versionID)
        recommendedSession.pendingEvents = [event(sequence: 65, demand: recommendedTarget)]
        guard let recommendedResolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 64, demand: recommendedSource),
            in: recommendedSession
        ), case let .passengersExchanged(recommendedExchange) = recommendedResolved.kind else {
            preconditionFailure("Type 0 should allow a recommended transfer point.")
        }
        precondition(recommendedExchange.transferReadyAt == start.addingTimeInterval(300))

        let timedSource = demand(tripID: "TRIP-TIMED-FROM", routeID: "R14", stopID: "TIMED_FROM", at: start)
        let timedTarget = demand(
            tripID: "TRIP-TIMED-TO",
            routeID: "R15",
            stopID: "TIMED_TO",
            at: start.addingTimeInterval(30)
        )
        var timedSession = makeSession(at: start, gtfsVersionID: versionID)
        timedSession.pendingEvents = [event(sequence: 67, demand: timedTarget)]
        guard let timedResolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 66, demand: timedSource),
            in: timedSession
        ), case let .passengersExchanged(timedExchange) = timedResolved.kind else {
            preconditionFailure("Type 1 should allow a timed transfer before the scheduled target departure.")
        }
        precondition(timedExchange.transferReadyAt == start.addingTimeInterval(60))
    }

    private static func timedTransfersHoldTheTargetSchedule(versionID: String) throws {
        let start = Date(timeIntervalSince1970: 1_798_055_000)
        var incomingDemand = demand(
            tripID: "TRIP-TIMED-FROM",
            routeID: "R14",
            stopID: "TIMED_FROM",
            at: start
        )
        incomingDemand.departureAt = start.addingTimeInterval(120)
        let incomingEvent = SimulationEvent(
            sequence: 80,
            simulatedAt: incomingDemand.departureAt!,
            kind: .passengerDemand(incomingDemand)
        )
        let targetVisits = [
            ScheduledTripStopVisit(
                stopID: "TIMED_TO",
                stopName: "Timed to",
                stopSequence: 1,
                latitude: 48.878,
                longitude: 2.328,
                scheduledAt: start,
                departureAt: start.addingTimeInterval(30),
                movementToNext: [
                    BusMovementCoordinate(latitude: 48.878, longitude: 2.328),
                    BusMovementCoordinate(latitude: 48.879, longitude: 2.329)
                ],
                movementGeometrySource: .stopCoordinateEstimate
            ),
            ScheduledTripStopVisit(
                stopID: "TIMED_DEST_END",
                stopName: "Timed destination end",
                stopSequence: 2,
                latitude: 48.879,
                longitude: 2.329,
                scheduledAt: start.addingTimeInterval(600),
                departureAt: nil,
                movementToNext: nil,
                movementGeometrySource: nil
            )
        ]
        guard let transferRules = try NetworkVersionStore.loadTransferRuleIndex(forGTFSVersionID: versionID) else {
            preconditionFailure("The timed-transfer fixture should load its transfer index.")
        }
        let plan = PassengerConnectionRules.applyingTimedTransferHolds(
            to: targetVisits,
            targetTripID: "TRIP-TIMED-TO",
            targetRouteID: "R15",
            pendingEvents: [incomingEvent],
            transferRuleIndex: transferRules
        )
        precondition(plan.holds.count == 1)
        precondition(plan.holds[0].sourceTripIDs == ["TRIP-TIMED-FROM"])
        precondition(plan.holds[0].heldDepartureAt == start.addingTimeInterval(180))
        precondition(plan.visits[0].scheduledAt == start, "Holding at a stop must preserve its arrival time.")
        precondition(plan.visits[0].departureAt == start.addingTimeInterval(180))
        precondition(plan.visits[1].scheduledAt == start.addingTimeInterval(750))

        var targetSession = makeSession(at: start, gtfsVersionID: versionID)
        targetSession.ownedBuses?[0].currentStopID = "TIMED_TO"
        targetSession.operatedRouteIDs = (targetSession.operatedRouteIDs ?? []) + ["R15"]
        targetSession.machinists = [Machinist(
            id: "driver-timed-transfer",
            employeeNumber: 15,
            qualification: .standard,
            hiredAt: start,
            depotID: "depot-1"
        )]
        targetSession.pendingEvents = [
            SimulationEvent(
                sequence: 90,
                simulatedAt: start,
                kind: .scheduledServiceDeparture(
                    tripID: "TRIP-TIMED-TO",
                    routeID: "R15",
                    serviceDateKey: 20261102
                )
            ),
            incomingEvent
        ]
        let engine = SimulationEngine(initialSession: targetSession)
        try engine.dispatchScheduledDeparture(
            eventSequence: 90,
            vehicleID: "bus-1",
            machinistID: "driver-timed-transfer",
            stopVisits: targetVisits
        )
        let dispatchedEvents = engine.session?.pendingEvents ?? []
        let dispatchedFirstStopDemand = dispatchedEvents.compactMap { event -> PassengerStopDemand? in
            guard case let .passengerDemand(demand) = event.kind,
                  demand.tripID == "TRIP-TIMED-TO",
                  demand.stopSequence == 1 else { return nil }
            return demand
        }.first
        precondition(dispatchedFirstStopDemand?.departureAt == start.addingTimeInterval(180))
        precondition(dispatchedEvents.contains {
            if case let .busMovementStarted(_, leg) = $0.kind {
                return leg.startsAt == start.addingTimeInterval(180)
            }
            return false
        }, "The target bus must remain at the stop until the timed transfer is ready.")
        guard case let .timedTransferHeld(heldTripID, heldRouteID, _, sourceTripIDs, delaySeconds)? =
                engine.session?.eventHistory.last?.kind else {
            preconditionFailure("The dispatch history should report the timed-transfer hold.")
        }
        precondition(heldTripID == "TRIP-TIMED-TO")
        precondition(heldRouteID == "R15")
        precondition(sourceTripIDs == ["TRIP-TIMED-FROM"])
        precondition(delaySeconds == 150)

        var retimedSession = engine.session!
        let retimedSourceDeparture = start.addingTimeInterval(420)
        guard let incomingEventIndex = retimedSession.pendingEvents.firstIndex(where: { event in
            guard case let .passengerDemand(demand) = event.kind else { return false }
            return demand.tripID == "TRIP-TIMED-FROM"
        }), case var .passengerDemand(retimedIncomingDemand) = retimedSession.pendingEvents[incomingEventIndex].kind else {
            preconditionFailure("The incoming course should remain scheduled after target assignment.")
        }
        retimedIncomingDemand.departureAt = retimedSourceDeparture
        retimedSession.pendingEvents[incomingEventIndex] = SimulationEvent(
            sequence: retimedSession.pendingEvents[incomingEventIndex].sequence,
            simulatedAt: retimedSourceDeparture,
            kind: .passengerDemand(retimedIncomingDemand)
        )
        precondition(SimulationEngine.replanActiveDispatchedTrips(in: &retimedSession))

        guard let retimedTargetDemand = retimedSession.pendingEvents.compactMap({ event -> PassengerStopDemand? in
            guard case let .passengerDemand(demand) = event.kind,
                  demand.tripID == "TRIP-TIMED-TO",
                  demand.stopSequence == 1 else { return nil }
            return demand
        }).first else {
            preconditionFailure("The target course's pending demand should survive timetable replanning.")
        }
        precondition(retimedTargetDemand.departureAt == start.addingTimeInterval(480))
        precondition(retimedSession.pendingEvents.contains {
            if case let .busMovementStarted(_, leg) = $0.kind {
                return leg.startsAt == start.addingTimeInterval(480)
            }
            return false
        }, "A later incoming-course departure must move the target bus's first trip leg.")
        guard let retimedTargetPlan = retimedSession.dispatchedTripRoutePlans?.first(where: {
            $0.tripID == "TRIP-TIMED-TO"
        }) else {
            preconditionFailure("The target course should retain its execution plan after replanning.")
        }
        precondition(retimedTargetPlan.stopVisits.last?.scheduledAt == start.addingTimeInterval(1_050))
        let retimedTargetAssignment = retimedSession.machinistServiceAssignments?.first(where: {
            $0.id == retimedTargetPlan.tripKey
        })
        precondition(retimedTargetAssignment?.plannedEndAt == start.addingTimeInterval(1_050))
        precondition(retimedSession.ownedBuses?.first?.reservedUntil == start.addingTimeInterval(1_050))
        guard case let .timedTransferHeld(_, _, _, _, incrementalDelay)? = retimedSession.eventHistory.last?.kind else {
            preconditionFailure("Replanning should record the additional timed-transfer hold.")
        }
        precondition(incrementalDelay == 300)

        let noTimedRulePlan = PassengerConnectionRules.applyingTimedTransferHolds(
            to: targetVisits,
            targetTripID: "TRIP-TIMED-TO",
            targetRouteID: "R15",
            pendingEvents: [event(sequence: 81, demand: demand(
                tripID: "TRIP-FROM",
                routeID: "R1",
                stopID: "FROM",
                at: start.addingTimeInterval(120)
            ))],
            transferRuleIndex: transferRules
        )
        precondition(noTimedRulePlan.holds.isEmpty, "A type-2 transfer must not hold the target service.")
    }

    private static func feedsWithoutTransfersKeepTheLegacyFallback(versionID: String) {
        let start = Date(timeIntervalSince1970: 1_798_060_000)
        let source = demand(tripID: "TRIP-FROM", routeID: "R1", stopID: "FROM", at: start)
        let target = demand(
            tripID: "TRIP-TO",
            routeID: "R2",
            stopID: "FROM",
            at: start.addingTimeInterval(600)
        )
        var session = makeSession(at: start, gtfsVersionID: versionID)
        session.pendingEvents = [event(sequence: 71, demand: target)]
        guard let resolved = SimulationEngine.resolvePassengerDemand(
            event(sequence: 70, demand: source),
            in: session
        ), case let .passengersExchanged(exchange) = resolved.kind else {
            preconditionFailure("A feed without transfers.txt should retain the existing same-stop fallback.")
        }
        precondition(exchange.connectingTripID == target.tripID)
        precondition(exchange.transferReadyAt == start.addingTimeInterval(300))
    }

    private static func oldTransferJSONStillDecodes() {
        let legacyExchangeJSON = #"{"tripID":"old-trip","vehicleID":"old-bus","routeID":"old-route","stopID":"old-stop","stopName":"Ancien arrêt","occurredAt":1798000000,"boardedCount":1,"alightedCount":1,"leftBehindCount":0,"onboardAfterExchange":0,"capacity":40,"capacityIsEstimated":true,"estimatedArrivalsCount":1,"waitingBeforeCount":0,"waitingAfterCount":0,"newlyLeftBehindCount":0,"connectingTripID":"old-target"}"#
        let exchange = try! JSONDecoder().decode(PassengerStopExchange.self, from: Data(legacyExchangeJSON.utf8))
        precondition(exchange.connectingStopID == nil)
        precondition(exchange.inSeatTransferTripID == nil)
        precondition(exchange.inSeatTransferPassengerCount == nil)
        precondition(exchange.tripID == "old-trip")

        let legacyQueueJSON = #"{"sourceTripID":"old-source","targetRouteID":"old-route","intendedTripID":"old-target","stopID":"old-stop","passengerCount":1,"readyAt":1798000300}"#
        let entry = try! JSONDecoder().decode(PassengerTransferQueueEntry.self, from: Data(legacyQueueJSON.utf8))
        precondition(entry.targetVehicleID == nil)
        precondition(entry.lastMissedTripID == nil)
        precondition(entry.sourceEventSequence == nil)
        precondition(entry.passengerCount == 1)
    }

    private static func malformedTransferRowsAreIgnored(archiveURL: URL) throws {
        guard let index = try GTFSFeedInspector.inspect(archiveURL).transferRuleIndex else {
            preconditionFailure("The transfer fixture should return an indexed rules table.")
        }
        precondition(index.rule(
            fromStopID: "NO_MIN_FROM",
            toStopID: "NO_MIN_TO",
            fromRouteID: "R1",
            toRouteID: "R2",
            fromTripID: "TRIP-FROM",
            toTripID: "TRIP-TO"
        ) == nil, "Type 2 without min_transfer_time must be ignored during import.")
        precondition(index.rule(
            fromStopID: "UNLISTED_FROM",
            toStopID: "UNLISTED_TO",
            fromRouteID: "R1",
            toRouteID: "R2",
            fromTripID: "TRIP-FROM",
            toTripID: "TRIP-TO"
        ) == nil, "A row without stop endpoints must not become a global rule.")
        precondition(index.rule(
            fromStopID: "UNLISTED_FROM",
            toStopID: "UNLISTED_TO",
            fromRouteID: "R10",
            toRouteID: "R11",
            fromTripID: "TRIP-LINK5-FROM",
            toTripID: "TRIP-LINK5-TO"
        )?.transferType == 5, "GTFS allows linked-trip rules without stop IDs when the trip pair is explicit.")
    }

    private static func demand(
        tripID: String,
        routeID: String,
        stopID: String,
        at date: Date,
        vehicleID: String = "bus-1",
        isTerminal: Bool = false,
        isFirstStop: Bool = false
    ) -> PassengerStopDemand {
        PassengerStopDemand(
            tripID: tripID,
            vehicleID: vehicleID,
            routeID: routeID,
            stopID: stopID,
            stopName: stopID,
            occurredAt: date,
            estimatedArrivalsCount: 0,
            alightingShare: isFirstStop ? 0 : 0.5,
            isTerminal: isTerminal,
            isFirstStop: isFirstStop,
            capacity: 40,
            capacityIsEstimated: true,
            stopSequence: 1
        )
    }

    private static func event(sequence: UInt64, demand: PassengerStopDemand) -> SimulationEvent {
        SimulationEvent(sequence: sequence, simulatedAt: demand.occurredAt, kind: .passengerDemand(demand))
    }

    private static func makeSession(at date: Date, gtfsVersionID: String) -> SimulationSession {
        let bus = PurchasedBus(
            id: "bus-1",
            modelID: "iveco-urbanway-12-gnv",
            offerID: "offer-1",
            depotID: "depot-1",
            acquiredAt: date,
            modelYear: 2024,
            odometerKilometers: 0,
            conditionPercent: 100,
            purchasePrice: 0,
            deliveryAt: date,
            status: .atStop,
            currentStopID: "FROM",
            onboardPassengerCount: 20
        )
        return SimulationSession(
            id: "session-transfer-smoke",
            scenarioID: "scenario-1",
            depotID: "depot-1",
            networkVersions: SimulationDataVersions(
                gtfsID: gtfsVersionID,
                routeGeometryID: "geometry-1",
                contractID: "contract-1",
                lineReferenceID: "line-1"
            ),
            randomSeed: 42,
            createdAt: date,
            updatedAt: date,
            simulatedAt: date,
            speed: .paused,
            resumeSpeed: .x1,
            nextEventSequence: 100,
            pendingEvents: [],
            eventHistory: [],
            timetableHorizonEnd: nil,
            operatedRouteIDs: ["R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9"],
            assignmentRecordIDs: [],
            cashBalance: 0,
            ownedBuses: [bus],
            machinists: [],
            machinistServiceAssignments: [],
            machinistDutyBlocks: [],
            machinistAbsences: [],
            machinistTrainings: [],
            machinistBreaks: [],
            machinistPayrollRecords: [],
            workshopPartsStock: [],
            workshopPartOrders: [],
            marketOffers: [],
            purchasedOfferQuantities: [:],
            ledgerEntries: [],
            tripDistanceRecords: [],
            dailyOperationsReports: [],
            passengerExchangeRecords: [],
            passengerQueuesByRouteStopKey: [:],
            passengerQueueUpdatedAtByRouteStopKey: [:],
            vehicleIncidents: [],
            vehicleMaintenanceRecords: []
        )
    }
}
