import Foundation

@main
@MainActor
struct SpecialTransportSmoke {
    static func main() throws {
        try specialTransportIsReservedEarnedInvoicedAndSettled()
        specialTransportRejectsVehicleAndMachinistConflicts()
        specialTransportMachinistChoicesRespectTraining()
        try specialTransportReopensSettledDutyBlockAndPaysOnlyExtension()
        try pendingSpecialTransportCanBeCancelledAndOldSavesDecode()
        print("PASS: special transport reserves resources and records agreed revenue through settlement")
    }

    private static func specialTransportIsReservedEarnedInvoicedAndSettled() throws {
        let start = Date(timeIntervalSince1970: 1_798_000_000)
        let serviceStartsAt = start.addingTimeInterval(3_600)
        let serviceEndsAt = serviceStartsAt.addingTimeInterval(3_600)
        let engine = try engine(with: makeSession(at: start, busCount: 1, machinistCount: 1))

        let order = try engine.scheduleSpecialTransport(
            clientName: "Association des Rives",
            purpose: "Navette événementielle",
            startsAt: serviceStartsAt,
            durationMinutes: 60,
            plannedDistanceKilometers: 12.5,
            passengerCount: 20,
            vehicleID: "bus-1",
            machinistID: "driver-1",
            quotedAmountEuro: 700
        )

        guard let bookedSession = engine.session,
              let bookedBus = bookedSession.ownedBuses?.first(where: { $0.id == "bus-1" }) else {
            preconditionFailure("A valid order should be saved with its bus.")
        }
        precondition(order.status == .scheduled)
        precondition(bookedSession.specialTransportOrders == [order])
        precondition(bookedBus.reservedTripKey == nil, "A future charter must not freeze the bus outside its time window.")
        precondition(bookedSession.machinistServiceAssignments?.contains(where: {
            $0.tripID == order.id && $0.machinistID == "driver-1"
        }) == true)
        do {
            try engine.sellVehicle(
                vehicleID: bookedBus.id,
                quotedValue: VehicleMarketCatalog.estimatedResaleValue(for: bookedBus, at: start)
            )
            preconditionFailure("A bus with a future special transport must not be sold.")
        } catch SimulationEngineError.vehicleCannotBeSold {
        } catch {
            preconditionFailure("Unexpected sale protection error: \(error)")
        }
        precondition(!((bookedSession.ledgerEntries ?? []).contains {
            $0.category == "Recette transport spécial estimée (jeu)"
        }))

        precondition(engine.advanceToNextEvent())
        guard let activeSession = engine.session,
              let activeOrder = activeSession.specialTransportOrders?.first,
              let activeBus = activeSession.ownedBuses?.first(where: { $0.id == "bus-1" }) else {
            preconditionFailure("The start event should activate the special transport.")
        }
        precondition(activeOrder.status == .inProgress)
        precondition(activeBus.status == .inService)
        precondition(activeBus.currentTripID == order.id)
        precondition(!((activeSession.ledgerEntries ?? []).contains {
            $0.category == "Recette transport spécial estimée (jeu)"
        }))

        precondition(engine.advanceToNextEvent())
        guard let completedSession = engine.session,
              let completedOrder = completedSession.specialTransportOrders?.first,
              let completedBus = completedSession.ownedBuses?.first(where: { $0.id == "bus-1" }) else {
            preconditionFailure("The end event should complete the order and release its bus.")
        }
        precondition(completedOrder.status == .completed)
        precondition(completedOrder.completedAt == serviceEndsAt)
        precondition(completedBus.status == .atDepot)
        precondition(completedBus.currentTripID == nil)
        precondition(completedBus.odometerKilometers == 12)
        precondition(completedSession.tripDistanceRecords?.contains(where: {
            $0.tripID == order.id && $0.distanceMeters == 12_500 && $0.isServiceDistance == true
        }) == true)
        let charterRevenue = completedSession.ledgerEntries?.filter {
            $0.category == "Recette transport spécial estimée (jeu)"
        } ?? []
        precondition(charterRevenue.count == 1)
        precondition(charterRevenue[0].amount == 700)
        precondition(charterRevenue[0].cashDeltaEuro == 0)
        precondition(!(completedSession.ledgerEntries ?? []).contains {
            $0.category == "Contribution contractuelle estimée (jeu)"
        })

        precondition(engine.advanceToNextEvent(), "A daily close should invoice the completed charter.")
        guard let invoicedSession = engine.session,
              let invoice = invoicedSession.invoices?.first(where: { $0.id.hasPrefix("invoice-accessory-") }) else {
            preconditionFailure("The daily close should create an accessory receivable invoice.")
        }
        precondition(invoice.direction == .receivable)
        precondition(invoice.totalEuro == 700)
        precondition(invoice.lineItems.contains(where: {
            $0.category == "Recette transport spécial estimée (jeu)"
        }))
        precondition(invoice.dueAt == SimulationInvoiceRules.dueDate(for: invoice.issuedAt))

        precondition(engine.advanceToNextEvent(), "The receivable should settle on its due date.")
        guard let paidSession = engine.session,
              let paidInvoice = paidSession.invoices?.first(where: { $0.id == invoice.id }) else {
            preconditionFailure("The invoice should remain in the career after settlement.")
        }
        precondition(paidInvoice.isPaid)
        let settlementEntries = (paidSession.ledgerEntries ?? []).filter { $0.nature == .settlement }
        precondition(settlementEntries.contains(where: {
            $0.id == "invoice-settlement-\(invoice.id)" && $0.cashDeltaEuro == 700
        }))
        precondition(paidSession.cashBalance == settlementEntries.reduce(0) { $0 + $1.cashMovementEuro })
    }

    private static func specialTransportRejectsVehicleAndMachinistConflicts() {
        let start = Date(timeIntervalSince1970: 1_798_000_000)
        let engine = try! engine(with: makeSession(at: start, busCount: 2, machinistCount: 2))
        _ = try! engine.scheduleSpecialTransport(
            clientName: "Client A",
            purpose: "Navette",
            startsAt: start.addingTimeInterval(3_600),
            durationMinutes: 60,
            plannedDistanceKilometers: 8,
            passengerCount: 8,
            vehicleID: "bus-1",
            machinistID: "driver-1",
            quotedAmountEuro: 300
        )

        do {
            _ = try engine.scheduleSpecialTransport(
                clientName: "Client B",
                purpose: "Deuxième navette",
                startsAt: start.addingTimeInterval(4_000),
                durationMinutes: 30,
                plannedDistanceKilometers: 4,
                passengerCount: 5,
                vehicleID: "bus-1",
                machinistID: "driver-2",
                quotedAmountEuro: 200
            )
            preconditionFailure("One vehicle must not be booked for overlapping charters.")
        } catch SimulationEngineError.specialTransportVehicleConflict {
        } catch {
            preconditionFailure("Unexpected vehicle conflict error: \(error)")
        }

        do {
            _ = try engine.scheduleSpecialTransport(
                clientName: "Client C",
                purpose: "Troisième navette",
                startsAt: start.addingTimeInterval(4_000),
                durationMinutes: 30,
                plannedDistanceKilometers: 4,
                passengerCount: 5,
                vehicleID: "bus-2",
                machinistID: "driver-1",
                quotedAmountEuro: 200
            )
            preconditionFailure("One machinist must not be booked for overlapping charters.")
        } catch SimulationEngineError.machinistUnavailable {
        } catch {
            preconditionFailure("Unexpected machinist conflict error: \(error)")
        }
    }

    private static func specialTransportMachinistChoicesRespectTraining() {
        let start = Date(timeIntervalSince1970: 1_798_000_000)
        let serviceStartsAt = start.addingTimeInterval(3_600)
        var session = makeSession(at: start, busCount: 1, machinistCount: 1)
        session.machinistTrainings = [MachinistTrainingRecord(
            id: "training-1",
            machinistID: "driver-1",
            sourceQualification: .standard,
            targetQualification: .articulated,
            startsAt: serviceStartsAt,
            endsAt: serviceStartsAt.addingTimeInterval(8 * 3_600),
            estimatedLaborCostEuro: 400,
            recordedAt: start
        )]
        let engine = try! engine(with: session)

        let availableMachinists = engine.availableMachinistsForSpecialTransport(
            vehicleID: "bus-1",
            startsAt: serviceStartsAt,
            durationMinutes: 60
        )

        precondition(
            !availableMachinists.contains(where: { $0.id == "driver-1" }),
            "A machinist whose training overlaps the charter must not appear in its choices."
        )
    }

    private static func specialTransportReopensSettledDutyBlockAndPaysOnlyExtension() throws {
        let firstDutyStart = Date(timeIntervalSince1970: 1_798_000_000)
        let firstDutyEnd = firstDutyStart.addingTimeInterval(3_600)
        let transportStartsAt = firstDutyEnd.addingTimeInterval(3_600)
        let transportEndsAt = transportStartsAt.addingTimeInterval(3_600)
        let sessionStartsAt = firstDutyEnd.addingTimeInterval(1_800)
        var session = makeSession(at: sessionStartsAt, busCount: 1, machinistCount: 1)
        session.machinistServiceAssignments = [MachinistServiceAssignment(
            id: "prior-assignment",
            machinistID: "driver-1",
            dutyBlockID: "settled-block",
            vehicleID: "bus-1",
            vehicleModelID: "iveco-urbanway-12-gnv",
            tripID: "prior-trip",
            routeID: "route-113",
            serviceDateKey: 20261025,
            plannedStartAt: firstDutyStart,
            plannedEndAt: firstDutyEnd,
            actualEndAt: firstDutyEnd
        )]
        session.machinistDutyBlocks = [MachinistDutyBlock(
            id: "settled-block",
            machinistID: "driver-1",
            plannedStartAt: firstDutyStart,
            plannedEndAt: firstDutyEnd,
            actualEndAt: firstDutyEnd,
            laborCostEuro: 24,
            lastSettledAt: firstDutyEnd
        )]
        session.machinistPayrollRecords = [MachinistPayrollRecord(
            id: "machinist-duty-settled-block",
            machinistID: "driver-1",
            occurredAt: firstDutyEnd,
            kind: .service,
            workHours: 1,
            amountEuro: 24,
            details: "service initial · 1 h"
        )]
        let engine = try engine(with: session)

        let cancelledOrder = try engine.scheduleSpecialTransport(
            clientName: "Association des Rives",
            purpose: "Prolongement d’un service",
            startsAt: transportStartsAt,
            durationMinutes: 60,
            plannedDistanceKilometers: 12.5,
            passengerCount: 20,
            vehicleID: "bus-1",
            machinistID: "driver-1",
            quotedAmountEuro: 700
        )

        guard let scheduledSession = engine.session,
              let scheduledBlock = scheduledSession.machinistDutyBlocks?.first(where: { $0.id == "settled-block" }),
              let charterAssignment = scheduledSession.machinistServiceAssignments?.first(where: { $0.tripID == cancelledOrder.id }) else {
            preconditionFailure("A charter joined to a settled block must reopen that block.")
        }
        precondition(charterAssignment.dutyBlockID == scheduledBlock.id)
        precondition(scheduledBlock.actualEndAt == nil)
        precondition(scheduledBlock.plannedEndAt == transportEndsAt)
        precondition(scheduledBlock.laborCostEuro == 24, "Reopening must preserve the amount already settled.")
        precondition(scheduledBlock.lastSettledAt == firstDutyEnd)

        try engine.cancelSpecialTransport(orderID: cancelledOrder.id)
        guard let cancelledSession = engine.session,
              let restoredBlock = cancelledSession.machinistDutyBlocks?.first(where: { $0.id == "settled-block" }) else {
            preconditionFailure("Cancelling a pending extension must restore the prior settled block.")
        }
        precondition(restoredBlock.actualEndAt == firstDutyEnd)
        precondition(restoredBlock.plannedEndAt == firstDutyEnd)
        precondition(restoredBlock.laborCostEuro == 24)
        precondition(restoredBlock.lastSettledAt == firstDutyEnd)
        precondition(!cancelledSession.machinistServiceAssignments!.contains { $0.tripID == cancelledOrder.id })

        let order = try engine.scheduleSpecialTransport(
            clientName: "Association des Rives",
            purpose: "Prolongement d’un service",
            startsAt: transportStartsAt,
            durationMinutes: 60,
            plannedDistanceKilometers: 12.5,
            passengerCount: 20,
            vehicleID: "bus-1",
            machinistID: "driver-1",
            quotedAmountEuro: 700
        )

        precondition(engine.advanceToNextEvent())
        precondition(engine.advanceToNextEvent())
        guard let completedSession = engine.session,
              let completedOrder = completedSession.specialTransportOrders?.first(where: { $0.id == order.id }),
              let settledBlock = completedSession.machinistDutyBlocks?.first(where: { $0.id == "settled-block" }) else {
            preconditionFailure("The completed charter should settle the reopened duty block.")
        }
        precondition(completedOrder.status == .completed)
        precondition(settledBlock.actualEndAt == transportEndsAt)
        precondition(settledBlock.laborCostEuro == 72)
        let payroll = completedSession.machinistPayrollRecords?.filter { $0.machinistID == "driver-1" } ?? []
        precondition(payroll.count == 2, "The extension must add one incremental payroll record.")
        let extensionPayroll = payroll.first { $0.id.hasPrefix("machinist-duty-extension-settled-block-") }
        precondition(extensionPayroll?.workHours == 2)
        precondition(extensionPayroll?.amountEuro == 48)
    }

    private static func pendingSpecialTransportCanBeCancelledAndOldSavesDecode() throws {
        let start = Date(timeIntervalSince1970: 1_798_000_000)
        let engine = try engine(with: makeSession(at: start, busCount: 1, machinistCount: 1))
        let order = try engine.scheduleSpecialTransport(
            clientName: "Client",
            purpose: "Navette annulable",
            startsAt: start.addingTimeInterval(7_200),
            durationMinutes: 45,
            plannedDistanceKilometers: 5,
            passengerCount: 10,
            vehicleID: "bus-1",
            machinistID: "driver-1",
            quotedAmountEuro: 250
        )
        try engine.cancelSpecialTransport(orderID: order.id)

        guard let cancelledSession = engine.session,
              let cancelledOrder = cancelledSession.specialTransportOrders?.first else {
            preconditionFailure("Cancellation should retain a readable order history.")
        }
        precondition(cancelledOrder.status == .cancelled)
        precondition(!cancelledSession.pendingEvents.contains { event in
            switch event.kind {
            case let .specialTransportStarted(orderID), let .specialTransportCompleted(orderID):
                return orderID == order.id
            default:
                return false
            }
        })
        precondition(cancelledSession.machinistServiceAssignments?.contains(where: { $0.tripID == order.id }) == false)

        var legacyObject = try JSONSerialization.jsonObject(with: engine.exportSaveData()) as! [String: Any]
        legacyObject.removeValue(forKey: "specialTransportOrders")
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        let legacyDecoder = JSONDecoder()
        legacyDecoder.dateDecodingStrategy = .iso8601
        let decodedLegacy = try legacyDecoder.decode(SimulationSession.self, from: legacyData)
        precondition(decodedLegacy.specialTransportOrders == nil)
    }

    private static func engine(with session: SimulationSession) throws -> SimulationEngine {
        SimulationEngine(initialSession: session)
    }

    private static func makeSession(
        at date: Date,
        busCount: Int,
        machinistCount: Int
    ) -> SimulationSession {
        let buses = (1...busCount).map { index in
            PurchasedBus(
                id: "bus-\(index)",
                modelID: "iveco-urbanway-12-gnv",
                offerID: "offer-\(index)",
                depotID: "depot-1",
                acquiredAt: date,
                modelYear: 2024,
                odometerKilometers: 0,
                conditionPercent: 100,
                purchasePrice: 0,
                deliveryAt: date,
                status: .atDepot
            )
        }
        let machinists = (1...machinistCount).map { index in
            Machinist(
                id: "driver-\(index)",
                employeeNumber: index,
                qualification: .standard,
                hiredAt: date,
                depotID: "depot-1"
            )
        }
        return SimulationSession(
            id: "session-special-transport",
            scenarioID: "scenario-1",
            depotID: "depot-1",
            networkVersions: SimulationDataVersions(
                gtfsID: "gtfs-1",
                routeGeometryID: "geometry-1",
                contractID: "contract-1",
                lineReferenceID: "lines-1"
            ),
            randomSeed: 42,
            createdAt: date,
            updatedAt: date,
            simulatedAt: date,
            speed: .paused,
            resumeSpeed: .x1,
            nextEventSequence: 1,
            pendingEvents: [],
            eventHistory: [],
            timetableHorizonEnd: nil,
            operatedRouteIDs: ["route-113"],
            assignmentRecordIDs: [],
            cashBalance: 0,
            ownedBuses: buses,
            machinists: machinists,
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
            vehicleMaintenanceRecords: [],
            loans: [],
            invoices: [],
            advertisingCampaigns: [],
            careerProgression: CareerProgressionState()
        )
    }
}
