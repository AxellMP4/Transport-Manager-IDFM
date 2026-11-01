import Foundation

@main
@MainActor
struct PassengerSystemSmoke {
    static func main() throws {
        resolvedExchangesStoreValidationCountsForActualBoardings()
        fullAndTerminalStopsCreateNoValidations()
        try liveSimulationMovesBusThroughValidatedPassengerExchangeAndSave()
        missedTransfersRemainQueuedAfterAnImpossibleConnection()
        transfersReadyDuringConnectionStopDwellCanBoard()
        legacyExchangesDecodeWithoutValidationFields()
        careerJSONRoundTripPreservesValidationBreakdowns()
        print("PASS: passenger exchanges store deterministic validations and remain save-compatible")
    }

    private static func resolvedExchangesStoreValidationCountsForActualBoardings() {
        let at = Date(timeIntervalSince1970: 1_798_000_000)
        let demand = PassengerStopDemand(
            tripID: "trip-42",
            vehicleID: "bus-1",
            routeID: "route-113",
            stopID: "stop-2",
            stopName: "Mairie",
            occurredAt: at,
            estimatedArrivalsCount: 100,
            alightingShare: 0,
            isTerminal: false,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 2
        )
        let event = SimulationEvent(sequence: 20, simulatedAt: at, kind: .passengerDemand(demand))
        let session = makeSession(at: at, onboardPassengerCount: 10, randomSeed: 42)

        guard let resolved = SimulationEngine.resolvePassengerDemand(event, in: session),
              case let .passengersExchanged(exchange) = resolved.kind,
              let breakdown = exchange.validationBreakdown else {
            preconditionFailure("A passenger demand must resolve to an exchange with validation totals.")
        }

        precondition(exchange.stopSequence == 2)
        precondition(exchange.boardedCount == 30)
        precondition(breakdown.boardedCount == exchange.boardedCount)
        precondition(breakdown.validatedCount + breakdown.unvalidatedCount == exchange.boardedCount)
        precondition(PassengerValidationType.allCases.reduce(0) {
            $0 + breakdown.validationCount(for: $1)
        } == breakdown.validatedCount)

        let replay = SimulationEngine.resolvePassengerDemand(event, in: session)
        guard case let .passengersExchanged(replayedExchange)? = replay?.kind else {
            preconditionFailure("The same demand should replay to a passenger exchange.")
        }
        precondition(replayedExchange.validationBreakdown == breakdown)
        precondition(resolved.summary.contains("Validations estimées :"))
        precondition(!resolved.summary.contains("€"))
    }

    private static func fullAndTerminalStopsCreateNoValidations() {
        let at = Date(timeIntervalSince1970: 1_798_000_000)
        let fullBusDemand = PassengerStopDemand(
            tripID: "trip-full",
            vehicleID: "bus-1",
            routeID: "route-113",
            stopID: "stop-2",
            stopName: "Mairie",
            occurredAt: at,
            estimatedArrivalsCount: 40,
            alightingShare: 0,
            isTerminal: false,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 2
        )
        let fullBus = makeSession(at: at, onboardPassengerCount: 40, randomSeed: 42)
        let fullEvent = SimulationEvent(sequence: 21, simulatedAt: at, kind: .passengerDemand(fullBusDemand))
        guard let fullResolved = SimulationEngine.resolvePassengerDemand(fullEvent, in: fullBus),
              case let .passengersExchanged(fullExchange) = fullResolved.kind else {
            preconditionFailure("A full bus demand must resolve to an exchange.")
        }
        precondition(fullExchange.boardedCount == 0)
        precondition(fullExchange.validationBreakdown?.validatedCount == 0)
        precondition(fullExchange.validationBreakdown?.validationRate == nil)

        let closedDemand = PassengerStopDemand(
            tripID: "trip-closed",
            vehicleID: "bus-1",
            routeID: "route-113",
            stopID: "stop-2",
            stopName: "Arrêt fermé",
            occurredAt: at,
            estimatedArrivalsCount: 12,
            alightingShare: 0,
            isTerminal: false,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 2
        )
        var closedStopSession = makeSession(at: at, onboardPassengerCount: 10, randomSeed: 42)
        closedStopSession.stopClosures = [SimulatedStopClosure(
            id: "closure-1",
            stopID: "stop-2",
            stopName: "Arrêt fermé",
            routeIDs: ["route-113"],
            closedAt: at.addingTimeInterval(-60),
            scheduledOpenAt: at.addingTimeInterval(3_600)
        )]
        let closedStopEvent = SimulationEvent(
            sequence: 23,
            simulatedAt: at,
            kind: .passengerDemand(closedDemand)
        )
        guard let closedStopResolved = SimulationEngine.resolvePassengerDemand(closedStopEvent, in: closedStopSession),
              case let .passengersExchanged(closedStopExchange) = closedStopResolved.kind else {
            preconditionFailure("A closed-stop demand must resolve to an exchange.")
        }
        precondition(closedStopExchange.stopWasClosed == true)
        precondition(closedStopExchange.boardedCount == 0)
        precondition(closedStopExchange.validationBreakdown?.validatedCount == 0)
        precondition(closedStopExchange.validationBreakdown?.validationRate == nil)

        let terminalDemand = PassengerStopDemand(
            tripID: "trip-terminal",
            vehicleID: "bus-1",
            routeID: "route-113",
            stopID: "stop-9",
            stopName: "Terminus",
            occurredAt: at,
            estimatedArrivalsCount: 50,
            alightingShare: 0.4,
            isTerminal: true,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 9
        )
        let terminalEvent = SimulationEvent(sequence: 22, simulatedAt: at, kind: .passengerDemand(terminalDemand))
        guard let terminalResolved = SimulationEngine.resolvePassengerDemand(
            terminalEvent,
            in: makeSession(at: at, onboardPassengerCount: 12, randomSeed: 42)
        ), case let .passengersExchanged(terminalExchange) = terminalResolved.kind else {
            preconditionFailure("A terminal demand must resolve to an exchange.")
        }
        precondition(terminalExchange.boardedCount == 0)
        precondition(terminalExchange.alightedCount == 12)
        precondition(terminalExchange.validationBreakdown?.validatedCount == 0)
    }

    private static func liveSimulationMovesBusThroughValidatedPassengerExchangeAndSave() throws {
        let start = Date(timeIntervalSince1970: 1_798_000_000)
        let stopAt = start.addingTimeInterval(60)
        let stopDepartureAt = stopAt.addingTimeInterval(30)
        let finalStopAt = start.addingTimeInterval(120)
        let visits = [
            ScheduledTripStopVisit(
                stopID: "stop-2",
                stopName: "Terminus Ouest",
                stopSequence: 10,
                latitude: 48.800,
                longitude: 2.450,
                scheduledAt: start,
                departureAt: start,
                movementToNext: [
                    BusMovementCoordinate(latitude: 48.800, longitude: 2.450),
                    BusMovementCoordinate(latitude: 48.810, longitude: 2.460)
                ],
                movementGeometrySource: .stopCoordinateEstimate
            ),
            ScheduledTripStopVisit(
                stopID: "stop-3",
                stopName: "Mairie",
                stopSequence: 20,
                latitude: 48.810,
                longitude: 2.460,
                scheduledAt: stopAt,
                departureAt: stopDepartureAt,
                movementToNext: [
                    BusMovementCoordinate(latitude: 48.810, longitude: 2.460),
                    BusMovementCoordinate(latitude: 48.820, longitude: 2.470)
                ],
                movementGeometrySource: .stopCoordinateEstimate
            ),
            ScheduledTripStopVisit(
                stopID: "stop-4",
                stopName: "Terminus Est",
                stopSequence: 30,
                latitude: 48.820,
                longitude: 2.470,
                scheduledAt: finalStopAt,
                departureAt: finalStopAt,
                movementToNext: nil,
                movementGeometrySource: nil
            )
        ]
        var session = makeSession(at: start, onboardPassengerCount: 10, randomSeed: 42)
        session.pendingEvents = [
            SimulationEvent(
                sequence: 30,
                simulatedAt: start,
                kind: .scheduledServiceDeparture(
                    tripID: "trip-live",
                    routeID: "route-113",
                    serviceDateKey: 20261223
                )
            ),
            SimulationEvent(
                sequence: 31,
                simulatedAt: start.addingTimeInterval(30),
                kind: .serviceDeparture(tripID: "mid-segment-position-check")
            )
        ]
        session.nextEventSequence = 32
        session.machinists = [Machinist(
            id: "driver-1",
            employeeNumber: 1,
            qualification: .standard,
            hiredAt: start,
            depotID: "depot-1"
        )]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let engine = SimulationEngine()
        try engine.importSaveData(encoder.encode(session))
        try engine.dispatchScheduledDeparture(
            eventSequence: 30,
            vehicleID: "bus-1",
            machinistID: "driver-1",
            stopVisits: visits
        )
        let generatedDemands = (engine.session?.pendingEvents ?? []).compactMap { event -> PassengerStopDemand? in
            guard case let .passengerDemand(demand) = event.kind else { return nil }
            return demand
        }.sorted { ($0.stopSequence ?? 0) < ($1.stopSequence ?? 0) }
        guard let model = VehicleMarketCatalog.model(id: "iveco-urbanway-12-gnv") else {
            preconditionFailure("The test bus model should exist in the vehicle market.")
        }
        let modelCapacity = VehicleMarketCatalog.passengerCapacity(for: model)
        precondition(generatedDemands.count == visits.count)
        precondition(generatedDemands.map(\.stopSequence) == [10, 20, 30])
        precondition(generatedDemands.allSatisfy { $0.capacity == modelCapacity })
        let intermediateDemandEvent = (engine.session?.pendingEvents ?? []).first { event in
            guard case let .passengerDemand(demand) = event.kind else { return false }
            return demand.stopSequence == 20
        }
        precondition(intermediateDemandEvent?.simulatedAt == stopDepartureAt)

        precondition(engine.advanceToNextEvent())
        guard let firstExchange = engine.session?.passengerExchangeRecords?.first?.exchange,
              let firstValidationBreakdown = firstExchange.validationBreakdown else {
            preconditionFailure("The first dispatched stop should create a passenger exchange.")
        }
        precondition(firstExchange.boardedCount > 0)
        precondition(firstValidationBreakdown.boardedCount == firstExchange.boardedCount)
        precondition(engine.advanceToNextEvent())
        guard let midSegmentBus = engine.session?.ownedBuses?.first(where: { $0.id == "bus-1" }) else {
            preconditionFailure("The live simulation should retain the moving bus.")
        }
        precondition(midSegmentBus.activeMovementLeg?.startsAt == start)
        precondition(abs((midSegmentBus.latitude ?? 0) - 48.805) < 0.000_001)
        precondition(abs((midSegmentBus.longitude ?? 0) - 2.455) < 0.000_001)

        precondition(engine.advanceToNextEvent())
        precondition(engine.session?.simulatedAt == stopAt)
        precondition(engine.session?.passengerExchangeRecords?.count == 1)
        precondition(engine.advanceToNextEvent())
        precondition(engine.session?.simulatedAt == stopDepartureAt)
        guard let liveSession = engine.session,
              let exchange = liveSession.passengerExchangeRecords?.last?.exchange,
              let validations = exchange.validationBreakdown,
              let updatedBus = liveSession.ownedBuses?.first(where: { $0.id == "bus-1" }) else {
            preconditionFailure("The stop event should save a passenger exchange and its validation breakdown.")
        }
        precondition(exchange.tripID == "trip-live")
        precondition(exchange.occurredAt == stopDepartureAt)
        precondition(validations.boardedCount == exchange.boardedCount)
        precondition(validations.validatedCount + validations.unvalidatedCount == exchange.boardedCount)
        precondition(updatedBus.onboardPassengerCount == exchange.onboardAfterExchange)
        precondition(abs((updatedBus.latitude ?? 0) - 48.810) < 0.000_001)

        let analytics = PassengerAnalytics.snapshot(
            exchanges: (liveSession.passengerExchangeRecords ?? []).map(\.exchange),
            grouping: .bus
        )
        let allExchanges = (liveSession.passengerExchangeRecords ?? []).map(\.exchange)
        let totalBoardings = allExchanges.reduce(0) { $0 + $1.boardedCount }
        let totalValidations = allExchanges.compactMap(\.validationBreakdown)
            .reduce(0) { $0 + $1.validatedCount }
        precondition(allExchanges.count == 2)
        precondition(totalBoardings > 0)
        precondition(analytics.boardings == totalBoardings)
        precondition(analytics.validations == totalValidations)
        precondition(analytics.validationRate == Double(totalValidations) / Double(totalBoardings))
        precondition(analytics.rows.count == 1)

        let savedData = try engine.exportSaveData()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(SimulationSession.self, from: savedData)
        precondition(restored.passengerExchangeRecords?.last?.exchange.validationBreakdown == validations)
    }

    private static func missedTransfersRemainQueuedAfterAnImpossibleConnection() {
        let at = Date(timeIntervalSince1970: 1_798_000_000)
        let connectionAt = at.addingTimeInterval(180)
        let sourceDemand = PassengerStopDemand(
            tripID: "source-trip",
            vehicleID: "bus-1",
            routeID: "route-113",
            stopID: "stop-2",
            stopName: "Mairie",
            occurredAt: at,
            estimatedArrivalsCount: 0,
            alightingShare: 0.5,
            isTerminal: false,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 2
        )
        let connectionDemand = PassengerStopDemand(
            tripID: "target-trip-early",
            vehicleID: "bus-1",
            routeID: "route-210",
            stopID: "stop-2",
            stopName: "Mairie",
            occurredAt: connectionAt,
            estimatedArrivalsCount: 0,
            alightingShare: 0,
            isTerminal: false,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 2
        )
        let connectionEvent = SimulationEvent(
            sequence: 41,
            simulatedAt: connectionAt,
            kind: .passengerDemand(connectionDemand)
        )
        var session = makeSession(at: at, onboardPassengerCount: 20, randomSeed: 42)
        session.pendingEvents = [connectionEvent]
        let sourceEvent = SimulationEvent(sequence: 40, simulatedAt: at, kind: .passengerDemand(sourceDemand))

        guard let resolvedSource = SimulationEngine.resolvePassengerDemand(sourceEvent, in: session),
              case let .passengersExchanged(sourceExchange) = resolvedSource.kind else {
            preconditionFailure("Source demand should produce a passenger exchange.")
        }
        precondition(sourceExchange.estimatedTransferPassengerCount == 2)
        precondition(sourceExchange.connectingRouteID == "route-210")
        precondition(sourceExchange.connectingTripID == "target-trip-early")
        precondition(sourceExchange.transferReadyAt == at.addingTimeInterval(300))
        precondition(resolvedSource.summary.contains("en correspondance vers route-210"))
        SimulationEngine.applyVehicleEvent(resolvedSource, to: &session)
        let savedSession = try! JSONDecoder().decode(
            SimulationSession.self,
            from: JSONEncoder().encode(session)
        )
        precondition(savedSession.passengerTransferQueueEntries == session.passengerTransferQueueEntries)
        precondition(savedSession.passengerQueuesByRouteStopKey?["route-210|stop-2"] == 2)
        session = savedSession

        guard let resolvedEarlyConnection = SimulationEngine.resolvePassengerDemand(connectionEvent, in: session),
              case let .passengersExchanged(earlyExchange) = resolvedEarlyConnection.kind else {
            preconditionFailure("The connecting demand should produce a passenger exchange.")
        }
        precondition(earlyExchange.missedConnectionCount == 2)
        precondition(earlyExchange.missedConnectionToTripID == "target-trip-early")
        precondition((earlyExchange.estimatedTransferBoardedCount ?? 0) == 0)
        precondition(earlyExchange.boardedCount == 0)
        precondition(resolvedEarlyConnection.summary.contains("correspondance(s) estimée(s) manquée(s)"))
        SimulationEngine.applyVehicleEvent(resolvedEarlyConnection, to: &session)
        precondition(session.passengerQueuesByRouteStopKey?["route-210|stop-2"] == 2)

        let laterAt = at.addingTimeInterval(15 * 60)
        let laterDemand = PassengerStopDemand(
            tripID: "target-trip-later",
            vehicleID: "bus-1",
            routeID: "route-210",
            stopID: "stop-2",
            stopName: "Mairie",
            occurredAt: laterAt,
            estimatedArrivalsCount: 0,
            alightingShare: 0,
            isTerminal: false,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 2
        )
        let laterEvent = SimulationEvent(sequence: 42, simulatedAt: laterAt, kind: .passengerDemand(laterDemand))
        guard let resolvedLaterConnection = SimulationEngine.resolvePassengerDemand(laterEvent, in: session),
              case let .passengersExchanged(laterExchange) = resolvedLaterConnection.kind else {
            preconditionFailure("A later connection should resolve normally.")
        }
        precondition(laterExchange.estimatedTransferBoardedCount == 2)
        precondition(laterExchange.boardedCount == 2)
        SimulationEngine.applyVehicleEvent(resolvedLaterConnection, to: &session)
        precondition(session.passengerQueuesByRouteStopKey?["route-210|stop-2"] == 0)
        precondition(session.passengerTransferQueueEntries?.isEmpty == true)
    }

    private static func transfersReadyDuringConnectionStopDwellCanBoard() {
        let at = Date(timeIntervalSince1970: 1_798_100_000)
        let sourceDemand = PassengerStopDemand(
            tripID: "source-trip-dwell",
            vehicleID: "bus-1",
            routeID: "route-113",
            stopID: "stop-2",
            stopName: "Mairie",
            occurredAt: at,
            estimatedArrivalsCount: 0,
            alightingShare: 0.5,
            isTerminal: false,
            capacity: 40,
            capacityIsEstimated: false,
            stopSequence: 2
        )
        let connectionArrival = at.addingTimeInterval(180)
        let connectionDeparture = at.addingTimeInterval(360)
        let connectionDemandData = try! JSONSerialization.data(withJSONObject: [
            "tripID": "target-trip-dwell",
            "vehicleID": "bus-1",
            "routeID": "route-210",
            "stopID": "stop-2",
            "stopName": "Mairie",
            "occurredAt": connectionArrival.timeIntervalSinceReferenceDate,
            "departureAt": connectionDeparture.timeIntervalSinceReferenceDate,
            "estimatedArrivalsCount": 0,
            "alightingShare": 0.0,
            "isTerminal": false,
            "capacity": 40,
            "capacityIsEstimated": false,
            "stopSequence": 2
        ])
        let connectionDemand = try! JSONDecoder().decode(PassengerStopDemand.self, from: connectionDemandData)
        let connectionEvent = SimulationEvent(
            sequence: 41,
            simulatedAt: connectionDeparture,
            kind: .passengerDemand(connectionDemand)
        )
        var session = makeSession(at: at, onboardPassengerCount: 20, randomSeed: 42)
        session.pendingEvents = [connectionEvent]
        let sourceEvent = SimulationEvent(sequence: 40, simulatedAt: at, kind: .passengerDemand(sourceDemand))

        guard let resolvedSource = SimulationEngine.resolvePassengerDemand(sourceEvent, in: session) else {
            preconditionFailure("Source demand should resolve before the connection arrives.")
        }
        SimulationEngine.applyVehicleEvent(resolvedSource, to: &session)

        guard let resolvedConnection = SimulationEngine.resolvePassengerDemand(connectionEvent, in: session),
              case let .passengersExchanged(exchange) = resolvedConnection.kind else {
            preconditionFailure("The connection demand should resolve at its stop.")
        }
        precondition(exchange.boardedCount == 2)
        precondition(exchange.estimatedTransferBoardedCount == 2)
        precondition(exchange.missedConnectionCount == nil)
    }

    private static func legacyExchangesDecodeWithoutValidationFields() {
        let legacyJSON = #"{"tripID":"trip-old","vehicleID":"bus-old","routeID":"route-old","stopID":"stop-old","stopName":"Ancien arrêt","occurredAt":1798000000,"boardedCount":3,"alightedCount":1,"leftBehindCount":0,"onboardAfterExchange":2,"capacity":50,"capacityIsEstimated":true,"estimatedArrivalsCount":3,"waitingBeforeCount":0,"waitingAfterCount":0,"newlyLeftBehindCount":0}"#
        let legacyExchange = try! JSONDecoder().decode(PassengerStopExchange.self, from: Data(legacyJSON.utf8))
        precondition(legacyExchange.stopSequence == nil)
        precondition(legacyExchange.validationBreakdown == nil)
        precondition(legacyExchange.estimatedTransferPassengerCount == nil)
        precondition(legacyExchange.missedConnectionCount == nil)
        precondition(legacyExchange.boardedCount == 3)
    }

    private static func careerJSONRoundTripPreservesValidationBreakdowns() {
        let at = Date(timeIntervalSince1970: 1_798_000_000)
        let breakdown = PassengerValidationRules.resolve(
            boardedCount: 30,
            tripID: "trip-42",
            routeID: "route-113",
            stopID: "stop-2",
            stopSequence: 2,
            randomSeed: 42
        )
        let exchange = PassengerStopExchange(
            tripID: "trip-42",
            vehicleID: "bus-1",
            routeID: "route-113",
            stopID: "stop-2",
            stopName: "Mairie",
            occurredAt: at,
            boardedCount: 30,
            alightedCount: 0,
            leftBehindCount: 70,
            onboardAfterExchange: 40,
            capacity: 40,
            capacityIsEstimated: false,
            estimatedArrivalsCount: 100,
            waitingBeforeCount: 0,
            waitingAfterCount: 70,
            newlyLeftBehindCount: 70,
            stopSequence: 2,
            validationBreakdown: breakdown
        )
        let session = makeSession(at: at, onboardPassengerCount: 40, randomSeed: 42, exchange: exchange)
        let data = try! JSONEncoder().encode(session)
        let restored = try! JSONDecoder().decode(SimulationSession.self, from: data)
        precondition(restored.passengerExchangeRecords?.first?.exchange.validationBreakdown == breakdown)
    }

    private static func makeSession(
        at date: Date,
        onboardPassengerCount: Int,
        randomSeed: UInt64,
        exchange: PassengerStopExchange? = nil
    ) -> SimulationSession {
        var bus = PurchasedBus(
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
            currentStopID: "stop-2",
            onboardPassengerCount: onboardPassengerCount
        )
        bus.status = .atStop
        return SimulationSession(
            id: "session-1",
            scenarioID: "scenario-1",
            depotID: "depot-1",
            networkVersions: SimulationDataVersions(
                gtfsID: "gtfs-1",
                routeGeometryID: "geometry-1",
                contractID: "contract-1",
                lineReferenceID: "line-1"
            ),
            randomSeed: randomSeed,
            createdAt: date,
            updatedAt: date,
            simulatedAt: date,
            speed: .paused,
            resumeSpeed: .x1,
            nextEventSequence: 100,
            pendingEvents: [],
            eventHistory: [],
            timetableHorizonEnd: nil,
            operatedRouteIDs: ["route-113"],
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
            passengerExchangeRecords: exchange.map {
                [PassengerExchangeRecord(eventSequence: 22, exchange: $0)]
            } ?? [],
            passengerQueuesByRouteStopKey: [:],
            passengerQueueUpdatedAtByRouteStopKey: [:],
            vehicleIncidents: [],
            vehicleMaintenanceRecords: []
        )
    }
}
