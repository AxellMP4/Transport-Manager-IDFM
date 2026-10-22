import Foundation

enum BusEnergy: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case diesel
    case dieselHybrid
    case gnv
    case gnvHybrid
    case electric

    var id: String { rawValue }

    var title: String {
        switch self {
        case .diesel: "Diesel"
        case .dieselHybrid: "Hybride diesel"
        case .gnv: "GNV"
        case .gnvHybrid: "GNV mild-hybrid"
        case .electric: "Électrique à batterie"
        }
    }

    var requiresDepotEquipment: String {
        switch self {
        case .diesel, .dieselHybrid: "Ravitaillement diesel"
        case .gnv, .gnvHybrid: "Station GNV"
        case .electric: "Recharge électrique et puissance disponible au dépôt"
        }
    }

    var systemImageName: String {
        self == .electric ? "bolt.fill" : "fuelpump"
    }

    var depotInfrastructure: DepotEnergyInfrastructureKind {
        switch self {
        case .diesel, .dieselHybrid:
            .dieselFueling
        case .gnv, .gnvHybrid:
            .biomethaneFueling
        case .electric:
            .electricCharging
        }
    }
}

enum DepotEnergyInfrastructureKind: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case dieselFueling
    case biomethaneFueling
    case electricCharging

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dieselFueling: "Ravitaillement diesel"
        case .biomethaneFueling: "Ravitaillement biométhane / GNV"
        case .electricCharging: "Recharge électrique"
        }
    }

    var installationCostEuro: Int? {
        switch self {
        case .dieselFueling: nil
        case .biomethaneFueling: 350_000
        case .electricCharging: 60_000
        }
    }

    var installationDuration: TimeInterval {
        switch self {
        case .dieselFueling: 0
        case .biomethaneFueling: 7 * 24 * 60 * 60
        case .electricCharging: 3 * 24 * 60 * 60
        }
    }

    var installationEstimateNote: String {
        switch self {
        case .dieselFueling:
            "Équipement initial de scénario, règle de jeu non attestée pour le site."
        case .biomethaneFueling:
            "Coût et délai provisoires de jeu ; aucun devis d’installation propre à ce dépôt n’est documenté."
        case .electricCharging:
            "Coût et délai provisoires de jeu pour une borne ; aucun devis ni capacité de raccordement propre à ce dépôt n’est documenté."
        }
    }

    var canBeInstalledByPlayer: Bool {
        installationCostEuro != nil
    }
}

enum BusVehicleClass: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case standard
    case midibus
    case articulated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "Standard"
        case .midibus: "Gabarit réduit"
        case .articulated: "Articulé"
        }
    }
}

enum BusOfferCondition: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case new
    case used

    var id: String { rawValue }
    var title: String { self == .new ? "Neuf" : "Occasion" }
}

enum MachinistQualification: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case standard
    case articulated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "Bus standard et gabarit réduit"
        case .articulated: "Bus standard, gabarit réduit et articulé"
        }
    }

    var estimatedLoadedCostPerServiceHourEuro: Int {
        switch self {
        case .standard: 24
        case .articulated: 26
        }
    }

    func canDrive(_ vehicleClass: BusVehicleClass) -> Bool {
        self == .articulated || vehicleClass != .articulated
    }
}

enum MachinistWorkRules {
    static let minimumRestBetweenDutyBlocks: TimeInterval = 11 * 60 * 60
    static let minimumRestHours = Int(minimumRestBetweenDutyBlocks / 3_600)
    static let maximumGapWithinServiceBlock: TimeInterval = 2 * 60 * 60
    static let maximumServiceBlockDuration: TimeInterval = 10 * 60 * 60
    static let scheduledBreakDuration: TimeInterval = 30 * 60
    static let scheduledBreakDurationMinutes = Int(scheduledBreakDuration / 60)
    static let articulatedTrainingDuration: TimeInterval = 8 * 60 * 60
    static let articulatedTrainingDurationHours = 8
}

enum VehicleEstimateConfidence: String, Codable, Hashable, Sendable {
    case low
    case medium

    var title: String { self == .low ? "Faible" : "Moyenne" }
}

struct VehicleMarketModel: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let manufacturer: String
    let commercialName: String
    let vehicleClass: BusVehicleClass
    let lengthMeters: Double?
    let widthMeters: Double?
    let heightMeters: Double?
    let doubleDoorCount: Int?
    let wheelchairSpaces: Int?
    let energy: BusEnergy
    let batteryCapacityKWh: Int?
    let maximumPowerKilowatts: Int?
    let maximumCapacity: Int?
    let seatedCapacity: Int?
    let firstObservedInScenarioYear: Int?
    let lastObservedInScenarioYear: Int?
    let regionalEvidenceYear: Int?
    let regionalEvidenceLabel: String?
    let rangeKilometers: Int?
    let rangeEvidenceNote: String?
    let estimatedNewPriceReference: Int?
    let priceReferenceYear: Int?
    let priceEstimateNote: String?
    let fleetEvidenceTitle: String
    let fleetEvidenceURL: String
    let technicalEvidenceTitle: String?
    let technicalEvidenceURL: String?
    let technicalDataNote: String?
    let additionalEvidenceTitle: String?
    let additionalEvidenceURL: String?
    let estimateEvidenceTitle: String
    let estimateEvidenceURL: String
    let marketAvailabilityNote: String?

    var displayName: String { "\(manufacturer) \(commercialName)" }

}

struct VehicleEnergyEstimate: Hashable, Sendable {
    let quantityPer100Kilometers: Double
    let unit: String
    let pricePerUnitEuro: Double

    var estimatedCostPer100KilometersEuro: Double {
        quantityPer100Kilometers * pricePerUnitEuro
    }

    var assumptionDescription: String {
        "\(quantityPer100Kilometers.formatted(.number.precision(.fractionLength(0...1)))) \(unit)/100 km × \(pricePerUnitEuro.formatted(.currency(code: "EUR").precision(.fractionLength(2))))/\(unit)"
    }
}

struct VehicleOwnershipCostEstimate: Hashable, Sendable {
    let horizonKilometers: Int
    let horizonYears: Int
    let acquisitionCostEuro: Int
    let energyCostEuro: Int
    let maintenanceCostEuro: Int
    let maintenanceKitsCostEuro: Int
    let estimatedResaleValueEuro: Int

    var netOwnershipCostEuro: Int {
        acquisitionCostEuro + energyCostEuro + maintenanceCostEuro + maintenanceKitsCostEuro - estimatedResaleValueEuro
    }
}

struct VehicleMarketOffer: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let modelID: String
    let condition: BusOfferCondition
    let vehicleYear: Int
    let odometerKilometers: Int
    let conditionPercent: Int
    let estimatedPriceLow: Int
    let estimatedPriceHigh: Int
    let askingPrice: Int
    let estimateConfidence: VehicleEstimateConfidence
    let deliveryDays: Int
    let initialStock: Int
    let priceBasis: String
}

struct PurchasedBus: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let modelID: String
    let offerID: String
    var depotID: String
    let acquiredAt: Date
    let modelYear: Int
    var odometerKilometers: Int
    var conditionPercent: Int
    let purchasePrice: Int
    let deliveryAt: Date
    var status: PurchasedBusStatus
    var currentStopID: String? = nil
    var currentStopName: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var currentTripID: String? = nil
    var reservedTripKey: String? = nil
    var reservedUntil: Date? = nil
    var activeMovementLeg: ScheduledBusMovementLeg? = nil
    var distanceTravelledMeters: Double? = nil
    var lastPreventiveMaintenanceDistanceMeters: Double? = nil
    var energyConsumedUnits: Double? = nil
    var onboardPassengerCount: Int? = nil
    var passengersBoardedCount: Int? = nil
    var passengersLeftBehindCount: Int? = nil
    var coquilleNumber: String? = nil
    var batteryCapacityKWh: Double? = nil
    var batteryChargeKWh: Double? = nil
    var batteryCapacityIsEstimated: Bool? = nil
    var rechargePlanID: String? = nil

    var canBeSold: Bool {
        (status == .atDepot || status == .atStop)
            && currentTripID == nil
            && reservedTripKey == nil
            && reservedUntil == nil
            && activeMovementLeg == nil
            && rechargePlanID == nil
    }
}

enum PurchasedBusStatus: String, Codable, Hashable, Sendable {
    case inDelivery
    case assigned
    case inService
    case atDepot
    case atStop
    case waitingForWorkshop
    case inMaintenance
    case beingTowed
    case deadheadingToService
    case returningToDepot
    case outOfService

    var title: String {
        switch self {
        case .inDelivery: "En livraison"
        case .assigned: "Course affectée"
        case .inService: "En ligne"
        case .atDepot: "Au dépôt"
        case .atStop: "Au terminus"
        case .waitingForWorkshop: "En attente d’une baie d’atelier"
        case .inMaintenance: "En entretien"
        case .beingTowed: "Remorqué vers le dépôt"
        case .deadheadingToService: "Acheminement à vide vers le premier arrêt"
        case .returningToDepot: "Retour à vide vers le dépôt"
        case .outOfService: "Hors service"
        }
    }
}

enum VehicleWorkshopRules {
    static let initialRepairBayCount = 1
    static let maximumRepairBayCount = 2
    static let expansionCostEuro = 150_000
    static let expansionConstructionDuration: TimeInterval = 7 * 24 * 60 * 60
}

enum VehicleWorkshopPart: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case preventiveMaintenance
    case minorRepair
    case majorRepair
    case immobilizingRepair

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preventiveMaintenance: "Kit d’entretien préventif"
        case .minorRepair: "Kit de réparation mineure"
        case .majorRepair: "Kit de réparation importante"
        case .immobilizingRepair: "Kit de réparation immobilisante"
        }
    }

    var purchasePriceEuro: Int {
        switch self {
        case .preventiveMaintenance: 350
        case .minorRepair: 450
        case .majorRepair: 1_600
        case .immobilizingRepair: 4_200
        }
    }

    var gameDeliveryDuration: TimeInterval {
        switch self {
        case .preventiveMaintenance: 12 * 60 * 60
        case .minorRepair: 4 * 60 * 60
        case .majorRepair: 12 * 60 * 60
        case .immobilizingRepair: 24 * 60 * 60
        }
    }

    static func repairKit(for severity: VehicleIncidentSeverity) -> VehicleWorkshopPart {
        switch severity {
        case .minor: .minorRepair
        case .major: .majorRepair
        case .immobilizing: .immobilizingRepair
        }
    }
}

struct VehicleWorkshopPartStock: Codable, Hashable, Identifiable, Sendable {
    let part: VehicleWorkshopPart
    var quantity: Int
    var vehicleModelID: String? = nil
    var depotID: String? = nil

    var id: String { "\(depotID ?? "legacy-depot")|\(vehicleModelID ?? "legacy")|\(part.id)" }
}

struct VehicleWorkshopPartOrder: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let part: VehicleWorkshopPart
    var vehicleModelID: String? = nil
    let quantity: Int
    let orderedAt: Date
    let deliveryAt: Date
    var depotID: String? = nil
    var reservedQuantity: Int = 0
    var deliveredAt: Date? = nil

    var pending: Bool { deliveredAt == nil }
    var unreservedQuantity: Int { max(0, quantity - reservedQuantity) }
}

enum VehicleWorkshopPartCatalog {
    static let initialQuantities: [VehicleWorkshopPart: Int] = [
        .preventiveMaintenance: 2,
        .minorRepair: 1,
        .majorRepair: 1,
        .immobilizingRepair: 1
    ]

    static func initialStock(forDepotID depotID: String? = nil) -> [VehicleWorkshopPartStock] {
        VehicleMarketCatalog.models.filter { $0.marketAvailabilityNote == nil }.flatMap { model in
            VehicleWorkshopPart.allCases.map { part in
                VehicleWorkshopPartStock(
                    part: part,
                    quantity: initialQuantities[part, default: 0],
                    vehicleModelID: model.id,
                    depotID: depotID
                )
            }
        }
    }

    static var initialStockCostEuro: Int {
        initialStock(forDepotID: nil).reduce(into: 0) { total, stock in
            total += stock.quantity * stock.part.purchasePriceEuro
        }
    }
}

struct Machinist: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let employeeNumber: Int
    var qualification: MachinistQualification
    let hiredAt: Date
    var depotID: String? = nil

    var displayName: String { String(format: "Machiniste %03d", employeeNumber) }
    var estimatedLoadedCostPerServiceHourEuro: Int { qualification.estimatedLoadedCostPerServiceHourEuro }
}

struct MachinistTrainingRecord: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let machinistID: String
    let sourceQualification: MachinistQualification
    let targetQualification: MachinistQualification
    let startsAt: Date
    let endsAt: Date
    let estimatedLaborCostEuro: Int
    let recordedAt: Date
    var completedAt: Date? = nil
    var cancelledAt: Date? = nil

    var isPending: Bool { completedAt == nil && cancelledAt == nil }

    func statusTitle(at simulatedAt: Date) -> String {
        if cancelledAt != nil { return "Annulée" }
        if completedAt != nil { return "Terminée" }
        return startsAt <= simulatedAt ? "En formation" : "Prévue"
    }
}

struct MachinistServiceAssignment: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var machinistID: String
    var dutyBlockID: String? = nil
    let vehicleID: String
    var vehicleModelID: String? = nil
    let tripID: String
    let routeID: String
    let serviceDateKey: Int
    let plannedStartAt: Date
    let plannedEndAt: Date
    var actualEndAt: Date? = nil
    var laborCostEuro: Int? = nil
}

struct MachinistAssignmentCorrection: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let dutyBlockID: String
    let previousMachinistID: String
    let correctedMachinistID: String
    let recordedAt: Date
    let reason: String
}

struct MachinistReliefPlan: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let eventSequence: UInt64
    let outgoingAssignmentID: String
    let incomingAssignmentID: String
    let stopID: String
    let stopSequence: Int
    var cancelledAt: Date? = nil
    var transferPlan: MachinistTransferPlan? = nil
}

struct MachinistReliefStop: Hashable, Identifiable, Sendable {
    let eventSequence: UInt64
    let stopID: String
    let stopName: String
    let stopSequence: Int
    let scheduledAt: Date
    let coordinate: BusMovementCoordinate

    var id: UInt64 { eventSequence }
}

struct MachinistTransferRequest: Hashable, Sendable {
    let machinistID: String
    let originName: String
    let originAddress: String?
    let originCoordinate: BusMovementCoordinate?
    let earliestDepartureAt: Date
    let stop: MachinistReliefStop
}

struct MachinistTransferPlan: Codable, Hashable, Sendable {
    let machinistID: String
    let stopEventSequence: UInt64
    let stopID: String
    let originName: String
    let departureAt: Date
    let expectedArrivalAt: Date
    let expectedTravelSeconds: TimeInterval
    let routingSourceTitle: String
}

struct MachinistDutyBlock: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var machinistID: String
    var plannedStartAt: Date
    var plannedEndAt: Date
    var actualEndAt: Date? = nil
    var laborCostEuro: Int? = nil
    var lastSettledAt: Date? = nil
}

struct MachinistDepotReturnStaffing: Hashable, Sendable {
    let machinist: Machinist
    let estimatedLaborCostEuro: Int
}

struct MachinistBreak: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var machinistID: String
    let dutyBlockID: String
    let startsAt: Date
    let endsAt: Date
    let recordedAt: Date
    var startedAt: Date? = nil
    var completedAt: Date? = nil
    var cancelledAt: Date? = nil

    var isPending: Bool { completedAt == nil && cancelledAt == nil }

    func statusTitle(at simulatedAt: Date) -> String {
        if cancelledAt != nil { return "Annulée" }
        if completedAt != nil { return "Terminée" }
        return startsAt <= simulatedAt ? "En pause" : "Prévue"
    }
}

struct MachinistBreakWindow: Hashable, Identifiable, Sendable {
    let id: String
    let dutyBlockID: String
    let startsAt: Date
    let endsAt: Date
    let nextCourseStartsAt: Date
}

enum MachinistAbsenceType: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case paidLeave
    case medicalLeave
    case unpaidLeave

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paidLeave: "Congé rémunéré"
        case .medicalLeave: "Arrêt maladie simulé"
        case .unpaidLeave: "Absence non rémunérée"
        }
    }

    var estimatedPayFactor: Double {
        switch self {
        case .paidLeave: 1
        case .medicalLeave: 0.5
        case .unpaidLeave: 0
        }
    }
}

struct MachinistAbsence: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let machinistID: String
    let startsAt: Date
    let endsAt: Date
    let reason: String
    let recordedAt: Date
    var absenceType: MachinistAbsenceType? = nil
    var estimatedPaidHours: Double? = nil
    var estimatedPayrollCostEuro: Int? = nil
    var settledAt: Date? = nil

    func statusTitle(at simulatedAt: Date) -> String {
        if let settledAt { return "Terminée · clôturée \(settledAt.formatted(date: .abbreviated, time: .shortened))" }
        if startsAt > simulatedAt { return "Prévue" }
        if endsAt > simulatedAt { return "En cours" }
        if absenceType == nil { return "Terminée · ancienne absence" }
        return "Terminée · règlement en attente"
    }
}

enum MachinistPayrollKind: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case service
    case incidentWaiting
    case training
    case paidLeave
    case medicalLeave
    case unpaidLeave

    var id: String { rawValue }

    var title: String {
        switch self {
        case .service: "Service et battements"
        case .incidentWaiting: "Attente après panne"
        case .training: "Formation"
        case .paidLeave: "Congé rémunéré"
        case .medicalLeave: "Arrêt maladie simulé"
        case .unpaidLeave: "Absence non rémunérée"
        }
    }

    init(absenceType: MachinistAbsenceType) {
        switch absenceType {
        case .paidLeave: self = .paidLeave
        case .medicalLeave: self = .medicalLeave
        case .unpaidLeave: self = .unpaidLeave
        }
    }
}

struct MachinistPayrollRecord: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var machinistID: String
    let occurredAt: Date
    let kind: MachinistPayrollKind
    let workHours: Double
    let amountEuro: Int
    var details: String
}

struct SimulationLedgerEntry: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let occurredAt: Date
    let category: String
    let description: String
    let amount: Int
    var nature: SimulationLedgerNature? = nil
    var cashDeltaEuro: Int? = nil
    var depotID: String? = nil

    var cashMovementEuro: Int { cashDeltaEuro ?? amount }
}

enum SimulationLedgerNature: String, Codable, Hashable, Sendable {
    case operating
    case financing
    case settlement
}

enum SimulationInvoiceDirection: String, Codable, Hashable, Sendable {
    case receivable
    case payable

    var cashSign: Int {
        switch self {
        case .receivable: 1
        case .payable: -1
        }
    }
}

struct SimulationInvoiceLineItem: Codable, Hashable, Identifiable, Sendable {
    let ledgerEntryID: String
    let category: String
    let description: String
    let amountEuro: Int

    var id: String { ledgerEntryID }
}

struct SimulationInvoice: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let counterparty: String
    let direction: SimulationInvoiceDirection
    let issuedAt: Date
    let dueAt: Date
    let lineItems: [SimulationInvoiceLineItem]
    var paidAt: Date? = nil

    var signedAmountEuro: Int {
        lineItems.reduce(into: 0) { $0 += $1.amountEuro }
    }

    var totalEuro: Int {
        let amount = signedAmountEuro
        return amount < 0 ? -amount : amount
    }

    var cashDeltaEuro: Int { direction.cashSign * totalEuro }
    var isPaid: Bool { paidAt != nil }
}

enum SimulationInvoiceRules {
    static let settlementDelayCalendarDays = 30

    static func dueDate(for issuedAt: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        return calendar.date(byAdding: .day, value: settlementDelayCalendarDays, to: issuedAt)
            ?? issuedAt.addingTimeInterval(TimeInterval(settlementDelayCalendarDays * 24 * 60 * 60))
    }
}

struct SimulationLoanInstallment: Codable, Hashable, Identifiable, Sendable {
    let number: Int
    let dueAt: Date
    let principalEuro: Int
    let interestEuro: Int
    var paidAt: Date? = nil

    var totalEuro: Int { principalEuro + interestEuro }
    var id: Int { number }
}

struct SimulationLoan: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let issuedAt: Date
    let principalEuro: Int
    let annualInterestRateBasisPoints: Int
    let termMonths: Int
    var installments: [SimulationLoanInstallment]

    var outstandingPrincipalEuro: Int {
        installments.filter { $0.paidAt == nil }.reduce(0) { $0 + $1.principalEuro }
    }

    var paidInstallmentCount: Int {
        installments.filter { $0.paidAt != nil }.count
    }

    var totalInterestEuro: Int {
        installments.reduce(0) { $0 + $1.interestEuro }
    }

    var nextInstallment: SimulationLoanInstallment? {
        installments.first { $0.paidAt == nil }
    }
}

enum SimulationLoanRules {
    static let annualInterestRateBasisPoints = 600
    static let minimumPrincipalEuro = 25_000
    static let principalIncrementEuro = 25_000
    static let termOptionsMonths = [12, 24, 36, 48]
    static let maximumOutstandingPrincipalEuro = 500_000

    static func supportsPrincipal(_ principalEuro: Int) -> Bool {
        principalEuro >= minimumPrincipalEuro
            && principalEuro <= maximumOutstandingPrincipalEuro
            && principalEuro.isMultiple(of: principalIncrementEuro)
    }

    static func regularInstallmentEuro(principalEuro: Int, termMonths: Int) -> Int? {
        guard supportsPrincipal(principalEuro), termOptionsMonths.contains(termMonths) else { return nil }
        let monthlyRate = Double(annualInterestRateBasisPoints) / 10_000 / 12
        return Int((Double(principalEuro) * monthlyRate / (1 - pow(1 + monthlyRate, Double(-termMonths)))).rounded())
    }

    static func loan(
        id: String,
        principalEuro: Int,
        termMonths: Int,
        issuedAt: Date
    ) -> SimulationLoan? {
        guard supportsPrincipal(principalEuro),
              termOptionsMonths.contains(termMonths),
              principalEuro > 0 else { return nil }

        guard let regularPayment = regularInstallmentEuro(principalEuro: principalEuro, termMonths: termMonths) else {
            return nil
        }
        let monthlyRate = Double(annualInterestRateBasisPoints) / 10_000 / 12
        var remainingPrincipal = principalEuro
        var installments: [SimulationLoanInstallment] = []

        for number in 1...termMonths {
            guard let dueAt = monthlyDueDate(from: issuedAt, monthOffset: number) else { return nil }
            let interest = Int((Double(remainingPrincipal) * monthlyRate).rounded())
            let principalPayment = number == termMonths
                ? remainingPrincipal
                : min(remainingPrincipal, max(1, regularPayment - interest))
            installments.append(SimulationLoanInstallment(
                number: number,
                dueAt: dueAt,
                principalEuro: principalPayment,
                interestEuro: interest
            ))
            remainingPrincipal -= principalPayment
        }

        guard remainingPrincipal == 0 else { return nil }
        return SimulationLoan(
            id: id,
            issuedAt: issuedAt,
            principalEuro: principalEuro,
            annualInterestRateBasisPoints: annualInterestRateBasisPoints,
            termMonths: termMonths,
            installments: installments
        )
    }

    private static func monthlyDueDate(from date: Date, monthOffset: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        let source = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard let sourceYear = source.year,
              let sourceMonth = source.month,
              let sourceDay = source.day,
              let firstOfSourceMonth = calendar.date(from: DateComponents(year: sourceYear, month: sourceMonth, day: 1)),
              let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: firstOfSourceMonth),
              let targetRange = calendar.range(of: .day, in: .month, for: targetMonth) else { return nil }

        var target = calendar.dateComponents([.year, .month], from: targetMonth)
        target.day = min(sourceDay, targetRange.count)
        target.hour = source.hour
        target.minute = source.minute
        target.second = source.second
        return calendar.date(from: target)
    }
}

enum VehicleMarketCatalog {
    static let referenceYear = 2026
    static let annualPriceIndexRate = 0.02
    static let initialCareerCapital = 1_000_000
    static let estimatedServiceRevenuePerVehicleKilometerEuro = ContractEconomicsRules.contributionPerVehicleKilometerEuro
    static let conditionWearIntervalKilometers = 10_000
    static let conditionWearPercentPerInterval = 1
    static let ownershipCostHorizonKilometers = 100_000
    static let ownershipCostHorizonYears = 5
    static let preventiveMaintenanceDuration: TimeInterval = 4 * 60 * 60
    static let preventiveMaintenanceBaseCostEuro = 450
    static let preventiveMaintenanceCostPerConditionPointEuro = 90

    static func preventiveMaintenanceCost(for conditionPercent: Int) -> Int {
        let conditionGap = 100 - max(0, min(100, conditionPercent))
        return preventiveMaintenanceBaseCostEuro + conditionGap * preventiveMaintenanceCostPerConditionPointEuro
    }

    static func estimatedResaleValue(for bus: PurchasedBus, at date: Date) -> Int {
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let currentYear = calendar.component(.year, from: date)
        let ageYears = max(0, currentYear - bus.modelYear)
        let ageFactor = max(0.12, 1 - Double(ageYears) * 0.06)
        let distanceFactor = max(0.15, 1 - Double(max(0, bus.odometerKilometers)) / 1_200_000)
        let condition = Double(max(0, min(100, bus.conditionPercent))) / 100
        let conditionFactor = 0.30 + condition * 0.70
        let saleFactor = 0.88
        let modeledValue = Int((Double(max(0, bus.purchasePrice)) * ageFactor * distanceFactor * conditionFactor * saleFactor).rounded())
        return min(max(0, bus.purchasePrice), max(1_000, modeledValue))
    }

    static func ownershipCostEstimate(
        for offer: VehicleMarketOffer,
        model: VehicleMarketModel,
        startingAt date: Date
    ) -> VehicleOwnershipCostEstimate {
        let horizonKilometers = ownershipCostHorizonKilometers
        let energy = energyEstimate(for: model)
        let energyCost = Int((energy.estimatedCostPer100KilometersEuro * Double(horizonKilometers) / 100).rounded())
        let wearIntervals = horizonKilometers / conditionWearIntervalKilometers
        let conditionAfterOneInterval = max(0, 100 - conditionWearPercentPerInterval)
        let scheduledMaintenanceCost = wearIntervals * preventiveMaintenanceCost(for: conditionAfterOneInterval)
        let initialRestorationCost = offer.conditionPercent < 100
            ? preventiveMaintenanceCost(for: offer.conditionPercent)
            : 0
        let maintenanceInterventions = wearIntervals + (offer.conditionPercent < 100 ? 1 : 0)
        let maintenanceKitsCost = maintenanceInterventions * VehicleWorkshopPart.preventiveMaintenance.purchasePriceEuro

        let projectedBus = PurchasedBus(
            id: "ownership-cost-projection",
            modelID: model.id,
            offerID: offer.id,
            depotID: "ownership-cost-projection",
            acquiredAt: date,
            modelYear: offer.vehicleYear,
            odometerKilometers: max(0, offer.odometerKilometers) + horizonKilometers,
            conditionPercent: 100,
            purchasePrice: offer.askingPrice,
            deliveryAt: date,
            status: .atDepot
        )
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let resaleDate = calendar.date(byAdding: .year, value: ownershipCostHorizonYears, to: date) ?? date
        let resaleValue = estimatedResaleValue(for: projectedBus, at: resaleDate)

        return VehicleOwnershipCostEstimate(
            horizonKilometers: horizonKilometers,
            horizonYears: ownershipCostHorizonYears,
            acquisitionCostEuro: offer.askingPrice,
            energyCostEuro: energyCost,
            maintenanceCostEuro: initialRestorationCost + scheduledMaintenanceCost,
            maintenanceKitsCostEuro: maintenanceKitsCost,
            estimatedResaleValueEuro: resaleValue
        )
    }

    static let models: [VehicleMarketModel] = [
        model(
            id: "irisbus-citelis-12-diesel",
            manufacturer: "Irisbus",
            commercialName: "Citelis 12",
            vehicleClass: .standard,
            length: nil,
            energy: .diesel,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: 2010,
            lastYear: 2013,
            referencePrice: 293_400,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère CATP 2024 : autobus standard diesel Euro VI step E de 12 m, options comprises, 293 400 € HT. Utilisé comme comparable de prix neuf pour ce modèle retiré, pas comme prix historique du Citelis ni comme prix individuel.",
            fleetURL: "https://tc-infos.fr/reseau/1452/parc-bus-cars/page1"
        ),
        model(
            id: "irisbus-citelis-18-diesel",
            manufacturer: "Irisbus",
            commercialName: "Citelis 18",
            vehicleClass: .articulated,
            length: nil,
            energy: .diesel,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: 2013,
            lastYear: 2013,
            referencePrice: 380_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu 2024 : repère CATP diesel standard 12 m de 293 400 € HT, majoré de 30 % par règle de gabarit articulé et arrondi. La CATP ne publie pas ici de prix Citelis 18 ; ce n’est ni un prix historique ni un prix individuel.",
            fleetURL: "https://tc-infos.fr/reseau/1452/parc-bus-cars/page2"
        ),
        model(
            id: "heuliez-gx337-hybrid",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 337 Hybrid",
            vehicleClass: .standard,
            length: 12.05,
            width: 2.55,
            height: 3.246,
            energy: .dieselHybrid,
            maximumPowerKilowatts: 210,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: 2015,
            lastYear: 2015,
            regionalEvidenceYear: 2016,
            regionalEvidenceLabel: "Référence de modèle IDFM · 2016",
            referencePrice: 330_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu 2024 : repère CATP diesel standard 12 m de 293 400 € HT, majoré de 12,5 % par règle de jeu. L’étude CATP n’évalue pas les autobus full-hybrides et ne publie pas de tarif GX 337 Hybrid ; ce montant n’est pas un prix individuel.",
            technicalTitle: "Heuliez Bus · fiche technique GX 337 Hybrid (juin 2020)",
            technicalURL: "https://www.heuliezbus.com/fr/vue/produits/bus/GX-HYBRIDE/FT_GX337_HYB_NG.pdf",
            technicalDataNote: "La fiche donne 210 kW pour le moteur thermique. Elle décrit deux implantations de 24 ou 27 places assises, avec UFR et conducteur ; la capacité totale dépend de l’aménagement et n’est pas publiée comme valeur unique.",
            additionalEvidenceTitle: "IDFM · Référence régionale Transdev GX 337 Hybrid (2016)",
            additionalEvidenceURL: "https://www.iledefrance-mobilites.fr/en/actualites/davantage-de-bus-en-faveur-de-la-transition-energetique-en-ile-de-france",
            fleetTitle: "Parc Bords de Marne · TC Infos (source secondaire, consultée en 2026)",
            fleetURL: "https://tc-infos.fr/reseau/1452/parc-bus-cars/page1"
        ),
        model(
            id: "iveco-urbanway-12-hybrid",
            manufacturer: "Iveco Bus",
            commercialName: "Urbanway 12 Hybrid",
            vehicleClass: .standard,
            length: 12.09,
            energy: .dieselHybrid,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: 2015,
            lastYear: 2015,
            referencePrice: 300_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère CATP 2024 : autobus mild-hybride diesel standard 12 m, options comprises, environ 299 500 € HT (219 500 € hors options et 80 000 € d’options moyennes). La génération hybride de cette offre n’est pas établie comme mild-hybrid ; le repère sert uniquement à l’estimation de jeu, pas de prix Urbanway individuel.",
            technicalTitle: "Urbanway Hybrid 12/18 m — fiche constructeur",
            technicalURL: "https://www.ivecobus.com/worldwide/-/media/IvecoBus/International/Urbanway-2024.pdf?rev=8202872493f84cfbb93a4a54402f4f74"
        ),
        model(
            id: "heuliez-gx337e-electric",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 337e",
            vehicleClass: .standard,
            length: 12.05,
            energy: .electric,
            batteryCapacityKWh: 346,
            maximumPowerKilowatts: 310,
            maxCapacity: 102,
            seatedCapacity: 27,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2021,
            referencePrice: 554_500,
            priceReferenceYear: 2022,
            priceEstimateNote: "Repère de l’étude CATP 2024 : autobus électrique à batterie 12 m à charge lente, options comprises, 554 500 € HT (474 500 € véhicule de base et 80 000 € d’options moyennes), montant indiqué comme équivalent à février 2022. La CATP n’en fait pas un devis GX 337e.",
            technicalTitle: "CATP · fiche GX 337 Elec, accord-cadre 2023–2027",
            technicalURL: "https://www.catp.fr/wp-content/uploads/2024/06/FP-IVECO-autobus-electrique-12m.pdf",
            technicalDataNote: "La fiche CATP 2024 indique 185 kW en continu et 310 kW en pointe, avec une batterie de 346 kWh pour l’offre de l’accord-cadre 2023–2027. La fiche Heuliez d’août 2020 décrit une version antérieure avec d’autres capacités de batterie ; la configuration des bus régionaux concernés n’est pas établie ici.",
            additionalEvidenceTitle: "Heuliez Bus · fiche GX 337 ELEC, version France (août 2020)",
            additionalEvidenceURL: "https://www.heuliezbus.com/fr/vue/produits/bus/GX-ELEC/FT_GX337_ELEC.pdf",
            fleetTitle: "IDFM · Green Bond 2022 — 68 GX 337e achetés pour Argenteuil et Vélizy",
            fleetURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/cd8ae5a4-12be-4749-880b-8c6e1877d6f4_Greenbond_IDFM_vnumerique_062022.pdf"
        ),
        model(
            id: "heuliez-gx337-gnv",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 337 GNV",
            vehicleClass: .standard,
            length: 12.07,
            width: 2.55,
            height: 3.30,
            energy: .gnv,
            maximumPowerKilowatts: 213,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: 2020,
            lastYear: 2021,
            referencePrice: 310_300,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère CATP 2024 : autobus GNV Euro VI step E standard 12 m, options comprises, 310 300 € HT (230 300 € hors options et 80 000 € d’options moyennes). Ce repère de catégorie n’est pas un prix individuel du GX 337 GNV.",
            technicalTitle: "Heuliez Bus · fiche technique GX 337 GNV (septembre 2017)",
            technicalURL: "https://www.heuliezbus.com/fr/vue/produits/bus/GX-GNV/FT_GX337_GNV.pdf",
            technicalDataNote: "La fiche donne 213 kW pour le moteur GNV et deux implantations de 24 ou 27 places assises, avec UFR et conducteur ; la capacité totale dépend de l’aménagement et n’est pas publiée comme valeur unique.",
            fleetURL: "https://tc-infos.fr/reseau/1452/parc-bus-cars/page1"
        ),
        model(
            id: "iveco-urbanway-12-gnv",
            manufacturer: "Iveco Bus",
            commercialName: "Urbanway 12 GNV",
            vehicleClass: .standard,
            length: 12.09,
            energy: .gnv,
            maximumPowerKilowatts: 228,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: 2024,
            lastYear: nil,
            referencePrice: 310_300,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère CATP 2024 : autobus GNV Euro VI step E standard 12 m, options comprises, 310 300 € HT (230 300 € hors options et 80 000 € d’options moyennes). Ce repère de catégorie n’est pas un prix individuel de l’Urbanway.",
            technicalTitle: "IVECO Bus · fiche technique Urbanway 12 m GNV (2023)",
            technicalURL: "https://www.ivecobus.com/ame-fr/-/media/IvecoBus/France/pdf/schede-tecniche/urbanway/FT-UBW-12m-GNC-GSR-001-2023.pdf?rev=-1",
            technicalDataNote: "Fiche constructeur : moteur Cursor 9 GNV de 228 kW. Les implantations décrites offrent 24 ou 29 places assises, avec des variantes d’environ 20 à 36 sièges ; la fiche ne publie pas une capacité totale voyageurs unique. La capacité de simulation reste estimée.",
            additionalEvidenceTitle: "CATP · Catalogue Bus/Car 2024",
            additionalEvidenceURL: "https://www.catp.fr/wp-content/uploads/2024/06/2024-06-Catalogue-BusCars.pdf",
            fleetTitle: "IDFM/RATP · communiqué du 26 mars 2021 — série de 49 Urbanway GNV commandés",
            fleetURL: "https://www.gart.org/wp-content/uploads/2021/03/CP-ILE-DE-FRANCE-MOBILITES-ET-LA-RATP-ANTICIPENT-LES-BESOINS-VOYAGEURS-GRACE-AU-BUS-INNOVATIONS-.pdf"
        ),
        model(
            id: "bluebus-12m-electric",
            manufacturer: "Bluebus",
            commercialName: "12 m",
            vehicleClass: .standard,
            length: 12,
            energy: .electric,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2016,
            rangeKilometers: 180,
            rangeEvidenceNote: "Jusqu’à 180 km sans recharge intermédiaire selon la publication IDFM de 2015 ; une recharge au terminus peut augmenter l’autonomie.",
            referencePrice: 554_500,
            priceReferenceYear: 2022,
            priceEstimateNote: "Repère de l’étude CATP 2024 : autobus électrique à batterie 12 m à charge lente, options comprises, 554 500 € HT (474 500 € véhicule de base et 80 000 € d’options moyennes), montant indiqué comme équivalent à février 2022. La CATP n’en fait pas un devis Bluebus.",
            technicalTitle: "IDFM · STIF en ligne n°8 (2015) — bus standard 12 m, autonomie annoncée jusqu’à 180 km",
            technicalURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/26c22c53-53fa-4e38-8a28-558408a359b1_stif_en_ligne_no8.pdf",
            fleetTitle: "RATP · Rapport d’activité 2016 — commande de 23 Bluebus de 12 m pour la ligne 341",
            fleetURL: "https://www.ratp.fr/mediateur/sites/default/files/2017-06/raddratp2016fr_0.pdf"
        ),
        model(
            id: "hess-tzen4-biarticulated-electric",
            manufacturer: "HESS",
            commercialName: "Bi-articulé TZen 4 · 24 m",
            vehicleClass: .articulated,
            length: 24,
            energy: .electric,
            maxCapacity: 140,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2026,
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            technicalTitle: "Île-de-France Mobilités · mise en service du TZen 4 et caractéristiques des bus",
            technicalURL: "https://presse.iledefrance-mobilites.fr/mise-en-service-du-tzen-4-la-nouvelle-ligne-de-bus-100-electrique-et-en-site-propre-dile-de-france/?lang=fr",
            fleetTitle: "Île-de-France Mobilités · 30 bus bi-articulés HESS affectés au TZen 4",
            fleetURL: "https://presse.iledefrance-mobilites.fr/mise-en-service-du-tzen-4-la-nouvelle-ligne-de-bus-100-electrique-et-en-site-propre-dile-de-france/?lang=fr",
            marketAvailabilityNote: "Modèle conçu pour le TZen 4 : recharge statique au sol (SRS) aux terminus en moins de 5 min. Aucune compatibilité avec un dépôt ou une ligne Bords de Marne ni aucun prix individuel ne sont documentés ; aucune offre d’achat n’est proposée."
        ),
        model(
            id: "solaris-urbino-18-iv-cng",
            manufacturer: "Solaris",
            commercialName: "Urbino 18 IV GNV",
            vehicleClass: .articulated,
            length: 18,
            width: 2.55,
            height: 3.25,
            doubleDoors: 4,
            wheelchairSpaces: 2,
            energy: .gnv,
            maxCapacity: 109,
            seatedCapacity: 36,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2022,
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            technicalTitle: "IDFM · Dossier d’enquête Sénia–Orly (2022) — dimensions et capacité de la ligne 393",
            technicalURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/bb8667f9-2153-49f0-9132-92fcc994166b_2.pdf",
            fleetTitle: "IDFM · parc de la ligne 393, renouvelé au GNV entre 2017 et 2020",
            fleetURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/bb8667f9-2153-49f0-9132-92fcc994166b_2.pdf",
            marketAvailabilityNote: "Référence de la ligne 393 en Île-de-France ; aucune présence à Bords de Marne, compatibilité avec ses COB ni aucun prix individuel ne sont documentés. Aucune offre d’achat n’est proposée."
        ),
        model(
            id: "scania-citywide-18-gnv-ratp",
            manufacturer: "Scania",
            commercialName: "Citywide articulé GNV · 18 m",
            vehicleClass: .articulated,
            length: 18,
            energy: .gnv,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2021,
            regionalEvidenceLabel: "101 autobus GNV de 18 m livrés à la RATP · 2018–2021",
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            fleetTitle: "Scania France · 101 Citywide GNV de 18 m livrés à la RATP",
            fleetURL: "https://www.scania.com/fr/fr/home/about-scania/newsroom/news/2022/2/101-citywide-gaz-livres-scania-france-ratp.html",
            marketAvailabilityNote: "Scania documente 101 autobus articulés Citywide GNV de 18 m livrés à la RATP entre 2018 et 2021, tête de série comprise. La source ne donne ni capacité voyageurs ni prix individuel ; elle n’atteste pas de présence à Bords de Marne, de compatibilité avec ses dépôts ou de disponibilité actuelle à l’achat. Aucune offre n’est simulée."
        ),
        model(
            id: "man-lions-city-standard-gnv-paris",
            manufacturer: "MAN",
            commercialName: "Lion’s City standard GNV · version non précisée",
            vehicleClass: .standard,
            length: nil,
            energy: .gnv,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2020,
            regionalEvidenceLabel: "100 standards MAN au gaz livrés à Paris · 2020",
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            fleetTitle: "MAN Truck & Bus · 100 Lion’s City standards au gaz pour la RATP",
            fleetURL: "https://press.mantruckandbus.com/france/en-route-vers-lavenir-avec-les-autobus-urbains-man-au-gaz/",
            marketAvailabilityNote: "MAN indique que 100 autobus standards Lion’s City au gaz ont été livrés pour les transports publics parisiens. Le communiqué ne précise ni génération, ni longueur, ni capacité voyageurs, ni hybridation, ni prix individuel ; il n’atteste pas de présence à Bords de Marne, de compatibilité avec ses dépôts ou de disponibilité actuelle à l’achat. Aucune offre n’est simulée."
        ),
        model(
            id: "heuliez-gx137-electric",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 137 ELEC",
            vehicleClass: .midibus,
            length: nil,
            energy: .electric,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2025,
            regionalEvidenceLabel: "Qualification prévue · 2025",
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            technicalTitle: "CATP · Catalogue véhicules 2025 — GX 137 C et GX 137 L, variantes distinctes",
            technicalURL: "https://www.catp.fr/wp-content/uploads/2025/07/2025-07-Catalogue-BusCars-1.pdf",
            fleetTitle: "Île-de-France Mobilités · Contrat bus 2025–2026 — GX 137 électrique identifié pour qualification RATP",
            fleetURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/aTFjzHNYClf9nz_6_ContratBUS2025-2026_vsigne%CC%81eLP.pdf",
            marketAvailabilityNote: "Le contrat IDFM 2025–2026 identifie une tête de série GX 137 électrique à qualifier pour la RATP au second semestre 2025. Cette source décrit une qualification prévue, pas une mise en service attestée. Elle ne précise pas la version courte ou longue : longueur, capacité, batterie, affectation locale, compatibilité avec les COB et prix individuel restent inconnus. Aucune offre n’est simulée."
        ),
        model(
            id: "heuliez-gx137-c-gnv",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 137 C GNV",
            vehicleClass: .midibus,
            length: 9.52,
            width: 2.335,
            height: 3.253,
            wheelchairSpaces: 1,
            energy: .gnv,
            maximumPowerKilowatts: 206,
            maxCapacity: 62,
            seatedCapacity: 16,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2022,
            regionalEvidenceLabel: "Convention IDFM · livraisons prévues 2024–2027",
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            technicalTitle: "IVECO Bus · fiche technique GX 137 C GNV (2023)",
            technicalURL: "https://www.ivecobus.com/france/-/media/IvecoBus/France/pdf/schede-tecniche/GX/FT-GX137C-GNC-001-2023.pdf?rev=-1",
            additionalEvidenceTitle: "IVECO Bus · GX 137 CNG identifié pour la commande IDFM (2025)",
            additionalEvidenceURL: "https://www.ivecobus.com/de/Press/Press-Release-Pages/2025/g-way",
            fleetTitle: "IDFM · convention CATP pour jusqu’à 700 midibus GNV (2022)",
            fleetURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/c85573c8-2923-4d5d-87c5-fbc9b6e78e90_RAA_144-1.pdf",
            marketAvailabilityNote: "Fiche constructeur : 9,52 × 2,335 × 3,253 m, 16 places assises et jusqu’à 62 voyageurs selon configuration, avec un emplacement UFR/poussette. Moteur Tector 7 GNV Euro VI Step E-2, 280 ch (206 kW) et 1 000 Nm ; compatibilité biométhane annoncée par IVECO. IDFM a approuvé une convention CATP couvrant jusqu’à 700 midibus GNV pour des livraisons prévues entre 2024 et 2027 ; IVECO relie cette commande au GX 137 CNG. Cela ne confirme ni les quantités livrées de cette version ni sa mise en service. Aucune affectation Bords de Marne, compatibilité de dépôt ou prix individuel n’est documenté ; aucune offre n’est simulée."
        ),
        model(
            id: "heuliez-gx137-l-gnv",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 137 L GNV",
            vehicleClass: .midibus,
            length: 10.735,
            width: 2.335,
            height: 3.253,
            wheelchairSpaces: 1,
            energy: .gnv,
            maximumPowerKilowatts: 206,
            maxCapacity: 84,
            seatedCapacity: 17,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2022,
            regionalEvidenceLabel: "Convention IDFM · livraisons prévues 2024–2027",
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            technicalTitle: "IVECO Bus · fiche technique GX 137 L GNV (2023)",
            technicalURL: "https://www.ivecobus.com/france/-/media/IvecoBus/France/pdf/schede-tecniche/GX/FT-GX137L-GNC-001-2023.pdf?rev=-1",
            additionalEvidenceTitle: "IVECO Bus · GX 137 CNG identifié pour la commande IDFM (2025)",
            additionalEvidenceURL: "https://www.ivecobus.com/de/Press/Press-Release-Pages/2025/g-way",
            fleetTitle: "IDFM · convention CATP pour jusqu’à 700 midibus GNV (2022)",
            fleetURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/c85573c8-2923-4d5d-87c5-fbc9b6e78e90_RAA_144-1.pdf",
            marketAvailabilityNote: "Fiche constructeur : 10,735 × 2,335 × 3,253 m, 17 places assises et jusqu’à 84 voyageurs selon configuration, avec un emplacement UFR/poussette. Moteur Tector 7 GNV Euro VI Step E-2, 280 ch (206 kW) et 1 000 Nm ; compatibilité biométhane annoncée par IVECO. IDFM a approuvé une convention CATP couvrant jusqu’à 700 midibus GNV pour des livraisons prévues entre 2024 et 2027 ; IVECO relie cette commande au GX 137 CNG. Cela ne confirme ni les quantités livrées de cette version ni sa mise en service. Aucune affectation Bords de Marne, compatibilité de dépôt ou prix individuel n’est documenté ; aucune offre n’est simulée."
        ),
        model(
            id: "alstom-aptis-electric",
            manufacturer: "Alstom",
            commercialName: "Aptis",
            vehicleClass: .standard,
            length: 12,
            energy: .electric,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2017,
            regionalEvidenceLabel: "Service commercial d’essai · 2017",
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            technicalTitle: "Alstom · Aptis 12 m sélectionné dans le marché de bus électriques IDFM/RATP",
            technicalURL: "https://www.alstom.com/sites/alstom.com/files/2019/05/20/20190520%20PR%20Aptis%20EN_0.pdf",
            fleetTitle: "Île-de-France Mobilités · essai Aptis sur la ligne 23 de Versailles–Vélizy",
            fleetURL: "https://www.iledefrance-mobilites.fr/actualites/ile-de-france-mobilites-et-keolis-vont-tester-le-nouveau-bus-electrique-alstom-ntl-sur-le-reseau-de-versailles-velizy",
            marketAvailabilityNote: "IDFM documente une mise en service commerciale d’essai sur la ligne 23 pendant un an à partir de septembre 2017 ; Alstom indique aussi la sélection d’Aptis dans un marché de bus électriques IDFM/RATP en 2019. Cette référence historique ne confirme pas une disponibilité actuelle à l’achat ni une affectation à Bords de Marne. Capacité, batterie, prix individuel et compatibilité locale ne sont pas documentés ; aucune offre n’est simulée."
        ),
        model(
            id: "ebusco-electric-standard-2015",
            manufacturer: "Ebusco",
            commercialName: "Autobus électrique 12 m · essai R’Bus (version non précisée)",
            vehicleClass: .standard,
            length: 12,
            energy: .electric,
            maxCapacity: 95,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2015,
            regionalEvidenceLabel: "Essai sur la ligne 1 R’Bus · depuis le 22 décembre 2015",
            rangeEvidenceNote: "IDFM indique une autonomie suffisante pour un service quotidien sans recharge, sans publier de valeur chiffrée.",
            referencePrice: nil,
            priceReferenceYear: nil,
            priceEstimateNote: nil,
            fleetTitle: "Île-de-France Mobilités · essai réel Ebusco sur la ligne 1 R’Bus",
            fleetURL: "https://www.iledefrance-mobilites.fr/actualites/davantage-de-bus-en-faveur-de-la-transition-energetique-en-ile-de-france",
            marketAvailabilityNote: "Référence historique d’un essai Transdev sur R’Bus à partir du 22 décembre 2015. La source ne précise pas le modèle Ebusco, la batterie, une autonomie chiffrée, la disponibilité actuelle, un prix individuel ni une compatibilité avec les COB Bords de Marne ; aucune offre d’achat n’est proposée."
        )
    ]

    static func offers(for gameYear: Int) -> [VehicleMarketOffer] {
        let usedStock: [(String, Int, Int, Int)] = [
            ("irisbus-citelis-12-diesel", 2012, 310_000, 42),
            ("irisbus-citelis-18-diesel", 2013, 325_000, 38),
            ("heuliez-gx337-hybrid", 2015, 210_000, 49),
            ("iveco-urbanway-12-hybrid", 2015, 195_000, 52),
            ("heuliez-gx337-gnv", 2021, 112_000, 71),
            ("iveco-urbanway-12-gnv", 2024, 42_000, 88),
            ("heuliez-gx337e-electric", 2022, 92_000, 74),
            ("bluebus-12m-electric", 2017, 265_000, 48)
        ]
        var results: [VehicleMarketOffer] = usedStock.compactMap { item -> VehicleMarketOffer? in
            let (modelID, vehicleYear, odometer, condition) = item
            guard let vehicleModel = models.first(where: { $0.id == modelID }),
                  let newPrice = estimatedNewPrice(for: vehicleModel, gameYear: gameYear) else { return nil }
            let age = max(1, gameYear - vehicleYear)
            let ageRetention = max(0.13, 0.82 - Double(age) * 0.045)
            let conditionFactor = 0.68 + Double(condition) / 312
            let estimate = roundedToNearestFiveThousand(
                Int(Double(newPrice) * ageRetention * conditionFactor)
            )
            return makeOffer(
                model: vehicleModel,
                condition: .used,
                vehicleYear: vehicleYear,
                odometer: odometer,
                conditionPercent: condition,
                askingPrice: estimate,
                gameYear: gameYear,
                stock: 1,
                deliveryDays: 2
            )
        }

        if let urbanway = models.first(where: { $0.id == "iveco-urbanway-12-gnv" }),
           let newPrice = estimatedNewPrice(for: urbanway, gameYear: gameYear) {
            results.append(makeOffer(
                model: urbanway,
                condition: .new,
                vehicleYear: gameYear,
                odometer: 0,
                conditionPercent: 100,
                askingPrice: newPrice,
                gameYear: gameYear,
                stock: 2,
                deliveryDays: 90
            ))
        }
        if let electric = models.first(where: { $0.id == "heuliez-gx337e-electric" }),
           let newPrice = estimatedNewPrice(for: electric, gameYear: gameYear) {
            results.append(makeOffer(
                model: electric,
                condition: .new,
                vehicleYear: gameYear,
                odometer: 0,
                conditionPercent: 100,
                askingPrice: newPrice,
                gameYear: gameYear,
                stock: 1,
                deliveryDays: 120
            ))
        }
        return results.sorted {
            if $0.condition != $1.condition { return $0.condition == .used }
            return $0.modelID < $1.modelID
        }
    }

    static func model(id: String) -> VehicleMarketModel? {
        models.first { $0.id == id }
    }

    static var marketableModels: [VehicleMarketModel] {
        models.filter { $0.marketAvailabilityNote == nil }
    }

    static func energyEstimate(for model: VehicleMarketModel) -> VehicleEnergyEstimate {
        let base: VehicleEnergyEstimate
        switch model.energy {
        case .diesel:
            base = VehicleEnergyEstimate(quantityPer100Kilometers: 38, unit: "L", pricePerUnitEuro: 1.75)
        case .dieselHybrid:
            base = VehicleEnergyEstimate(quantityPer100Kilometers: 32, unit: "L", pricePerUnitEuro: 1.75)
        case .gnv:
            base = VehicleEnergyEstimate(quantityPer100Kilometers: 38, unit: "kg", pricePerUnitEuro: 1.50)
        case .gnvHybrid:
            base = VehicleEnergyEstimate(quantityPer100Kilometers: 35, unit: "kg", pricePerUnitEuro: 1.50)
        case .electric:
            base = VehicleEnergyEstimate(quantityPer100Kilometers: 125, unit: "kWh", pricePerUnitEuro: 0.25)
        }
        let vehicleClassFactor: Double
        switch model.vehicleClass {
        case .standard: vehicleClassFactor = 1
        case .midibus: vehicleClassFactor = 0.8
        case .articulated: vehicleClassFactor = 1.25
        }
        guard vehicleClassFactor != 1 else { return base }
        return VehicleEnergyEstimate(
            quantityPer100Kilometers: base.quantityPer100Kilometers * vehicleClassFactor,
            unit: base.unit,
            pricePerUnitEuro: base.pricePerUnitEuro
        )
    }

    /// Capacity to initialize tracked gameplay batteries. Published capacities remain exact;
    /// Bluebus has no capacity figure in this catalog, so its 180 km range is converted using
    /// this game's electric consumption estimate and is explicitly marked as an estimate.
    static func gameplayBatteryCapacity(for model: VehicleMarketModel) -> (kWh: Double, isEstimated: Bool)? {
        guard model.energy == .electric else { return nil }
        if let capacity = model.batteryCapacityKWh { return (Double(capacity), false) }
        guard model.manufacturer == "Bluebus", let range = model.rangeKilometers else { return nil }
        return (Double(range) * energyEstimate(for: model).quantityPer100Kilometers / 100, true)
    }

    static func passengerCapacity(for model: VehicleMarketModel) -> Int {
        if let maximumCapacity = model.maximumCapacity { return maximumCapacity }
        return switch model.vehicleClass {
        case .standard: 85
        case .midibus: 60
        case .articulated: 120
        }
    }

    static func usesEstimatedPassengerCapacity(for model: VehicleMarketModel) -> Bool {
        model.maximumCapacity == nil
    }

    static func estimatedNewPrice(for model: VehicleMarketModel, gameYear: Int) -> Int? {
        guard let referencePrice = model.estimatedNewPriceReference else { return nil }
        let yearsSinceReference = max(0, gameYear - (model.priceReferenceYear ?? referenceYear))
        let gamePriceIndex = pow(1 + annualPriceIndexRate, Double(yearsSinceReference))
        return roundedToNearestFiveThousand(Int((Double(referencePrice) * gamePriceIndex).rounded()))
    }

    private static func model(
        id: String,
        manufacturer: String,
        commercialName: String,
        vehicleClass: BusVehicleClass,
        length: Double?,
        width: Double? = nil,
        height: Double? = nil,
        doubleDoors: Int? = nil,
        wheelchairSpaces: Int? = nil,
        energy: BusEnergy,
        batteryCapacityKWh: Int? = nil,
        maximumPowerKilowatts: Int? = nil,
        maxCapacity: Int?,
        seatedCapacity: Int?,
        firstYear: Int?,
        lastYear: Int?,
        regionalEvidenceYear: Int? = nil,
        regionalEvidenceLabel: String? = nil,
        rangeKilometers: Int? = nil,
        rangeEvidenceNote: String? = nil,
        referencePrice: Int?,
        priceReferenceYear: Int? = nil,
        priceEstimateNote: String? = nil,
        technicalTitle: String? = nil,
        technicalURL: String? = nil,
        technicalDataNote: String? = nil,
        additionalEvidenceTitle: String? = nil,
        additionalEvidenceURL: String? = nil,
        fleetTitle: String? = nil,
        fleetURL: String = "https://tc-infos.fr/reseau/1452/parc-bus-cars/page1",
        marketAvailabilityNote: String? = nil
    ) -> VehicleMarketModel {
        VehicleMarketModel(
            id: id,
            manufacturer: manufacturer,
            commercialName: commercialName,
            vehicleClass: vehicleClass,
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height,
            doubleDoorCount: doubleDoors,
            wheelchairSpaces: wheelchairSpaces,
            energy: energy,
            batteryCapacityKWh: batteryCapacityKWh,
            maximumPowerKilowatts: maximumPowerKilowatts,
            maximumCapacity: maxCapacity,
            seatedCapacity: seatedCapacity,
            firstObservedInScenarioYear: firstYear,
            lastObservedInScenarioYear: lastYear,
            regionalEvidenceYear: regionalEvidenceYear,
            regionalEvidenceLabel: regionalEvidenceLabel,
            rangeKilometers: rangeKilometers,
            rangeEvidenceNote: rangeEvidenceNote,
            estimatedNewPriceReference: referencePrice,
            priceReferenceYear: referencePrice == nil ? nil : (priceReferenceYear ?? referenceYear),
            priceEstimateNote: priceEstimateNote,
            fleetEvidenceTitle: fleetTitle ?? "Parc Bords de Marne — TC Infos (consulté en 2026)",
            fleetEvidenceURL: fleetURL,
            technicalEvidenceTitle: technicalTitle,
            technicalEvidenceURL: technicalURL,
            technicalDataNote: technicalDataNote,
            additionalEvidenceTitle: additionalEvidenceTitle,
            additionalEvidenceURL: additionalEvidenceURL,
            estimateEvidenceTitle: "Étude comparative des motorisations de bus 2024 — CATP",
            estimateEvidenceURL: "https://www.agir-transport.org/wp-content/uploads/2024/07/Etude-comparative-des-differentes-motorisations-de-bus-2024.pdf",
            marketAvailabilityNote: marketAvailabilityNote
        )
    }

    private static func makeOffer(
        model: VehicleMarketModel,
        condition: BusOfferCondition,
        vehicleYear: Int,
        odometer: Int,
        conditionPercent: Int,
        askingPrice: Int,
        gameYear: Int,
        stock: Int,
        deliveryDays: Int
    ) -> VehicleMarketOffer {
        let low = roundedToNearestFiveThousand(Int(Double(askingPrice) * 0.88))
        let high = roundedToNearestFiveThousand(Int(Double(askingPrice) * 1.12))
        return VehicleMarketOffer(
            id: "\(model.id)-\(condition.rawValue)-\(vehicleYear)-\(gameYear)",
            modelID: model.id,
            condition: condition,
            vehicleYear: vehicleYear,
            odometerKilometers: odometer,
            conditionPercent: conditionPercent,
            estimatedPriceLow: low,
            estimatedPriceHigh: high,
            askingPrice: askingPrice,
            estimateConfidence: .low,
            deliveryDays: deliveryDays,
            initialStock: stock,
            priceBasis: {
                let basis = model.priceEstimateNote
                    ?? "Estimation de jeu en euros \(gameYear), modulée selon la motorisation, l’âge et l’état. Fourchette indicative, sans prix officiel individuel."
                let annualIndexPercent = Int((annualPriceIndexRate * 100).rounded())
                let usedPriceRule = condition == .used
                    ? " Le prix d’occasion est modulé par l’âge, le kilométrage et l’état selon des coefficients de jeu."
                    : ""
                return "\(basis) Indexation de jeu de \(annualIndexPercent) %/an jusqu’en \(gameYear) ; fourchette indicative de ±12 %.\(usedPriceRule)"
            }()
        )
    }

    private static func roundedToNearestFiveThousand(_ value: Int) -> Int {
        max(5_000, ((value + 2_500) / 5_000) * 5_000)
    }
}

enum ContractEconomicsRules {
    static let contributionPerVehicleKilometerEuro = 5.50
    static let productionBonusThreshold = 0.98
    static let productionMalusThreshold = 0.94
    static let productionBonusRate = 0.03
    static let productionMalusRate = 0.05

    static func productionAdjustmentEuro(contributionEuro: Int, completionRate: Double) -> Int {
        guard contributionEuro > 0, completionRate.isFinite else { return 0 }
        if completionRate >= productionBonusThreshold {
            return Int((Double(contributionEuro) * productionBonusRate).rounded())
        }
        if completionRate < productionMalusThreshold {
            return -Int((Double(contributionEuro) * productionMalusRate).rounded())
        }
        return 0
    }
}
