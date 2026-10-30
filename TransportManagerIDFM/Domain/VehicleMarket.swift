Warning: truncated output (original token count: 35127)
Total output lines: 2483

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
    let newOfferAvailableFromYear: Int?
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
    let technicalVariants: [VehicleTechnicalVariant]?
    let additionalEvidenceTitle: String?
    let additionalEvidenceURL: String?
    let estimateEvidenceTitle: String
    let estimateEvidenceURL: String
    let marketAvailabilityNote: String?

    var displayName: String { "\(manufacturer) \(commercialName)" }

}

struct VehicleTechnicalVariant: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let lengthMeters: Double?
    let widthMeters: Double?
    let heightMeters: Double?
    let batteryCapacityKWh: Int?
    let maximumPowerKilowatts: Int?
    let maximumCapacity: Int?
    let seatedCapacity: Int?
    let rangeKilometers: Int?
    let fuelTankCapacitiesLiters: [Int]?
    let turningRadiusBetweenWallsMeters: Double?
    let turningRadiusBetweenCurbsMeters: Double?
    let applicabilityNote: String
    let evidenceTitle: String
    let evidenceURL: String

    init(
        id: String,
        title: String,
        lengthMeters: Double?,
        widthMeters: Double?,
        heightMeters: Double?,
        batteryCapacityKWh: Int?,
        maximumPowerKilowatts: Int?,
        maximumCapacity: Int?,
        seatedCapacity: Int?,
        rangeKilometers: Int?,
        fuelTankCapacitiesLiters: [Int]? = nil,
        turningRadiusBetweenWallsMeters: Double? = nil,
        turningRadiusBetweenCurbsMeters: Double? = nil,
        applicabilityNote: String,
        evidenceTitle: String,
        evidenceURL: String
    ) {
        self.id = id
        self.title = title
        self.lengthMeters = lengthMeters
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
        self.batteryCapacityKWh = batteryCapacityKWh
        self.maximumPowerKilowatts = maximumPowerKilowatts
        self.maximumCapacity = maximumCapacity
        self.seatedCapacity = seatedCapacity
        self.rangeKilometers = rangeKilometers
        self.fuelTankCapacitiesLiters = fuelTankCapacitiesLiters
        self.turningRadiusBetweenWallsMeters = turningRadiusBetweenWallsMeters
        self.turningRadiusBetweenCurbsMeters = turningRadiusBetweenCurbsMeters
        self.applicabilityNote = applicabilityNote
        self.evidenceTitle = evidenceTitle
        self.evidenceURL = evidenceURL
    }

    var specificationSummary: String {
        var specifications: [String] = []
        if let lengthMeters { specifications.append(lengthMeters.formatted(.number.precision(.fractionLength(2))) + " m") }
        if let widthMeters { specifications.append(widthMeters.formatted(.number.precision(.fractionLength(2))) + " m de large") }
        if let heightMeters { specifications.append(heightMeters.formatted(.number.precision(.fractionLength(2))) + " m de haut") }
        if let maximumCapacity { specifications.append("jusqu’à " + String(maximumCapacity) + " voyageurs") }
        if let seatedCapacity { specifications.append(String(seatedCapacity) + " places assises") }
        if let batteryCapacityKWh { specifications.append("batterie jusqu’à " + String(batteryCapacityKWh) + " kWh") }
        if let maximumPowerKilowatts { specifications.append(String(maximumPowerKilowatts) + " kW") }
        if let rangeKilometers { specifications.append("autonomie jusqu’à " + String(rangeKilometers) + " km") }
        if let fuelTankCapacitiesLiters, !fuelTankCapacitiesLiters.isEmpty {
            let capacities = fuelTankCapacitiesLiters.map { $0.formatted() }.joined(separator: ", ")
            specifications.append("réservoir au choix : " + capacities + " L")
        }
        if let turningRadiusBetweenWallsMeters {
            specifications.append("rayon de giration entre murs : " + turningRadiusBetweenWallsMeters.formatted(.number.precision(.fractionLength(2))) + " m")
        }
        if let turningRadiusBetweenCurbsMeters {
            specifications.append("rayon de giration entre trottoirs : " + turningRadiusBetweenCurbsMeters.formatted(.number.precision(.fractionLength(2))) + " m")
        }
        return specifications.joined(separator: " · ")
    }
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
    var plannedStartAt: Date
    var plannedEndAt: Date
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
    static let referenceYea…20127 tokens truncated…echnicalTitle: "CATP · MAN Lion’s City 18C GNV, accord-cadre 2023–2032, lot 7",
            technicalURL: "https://www.catp.fr/wp-content/uploads/2024/03/FP-MAN-autobus-GNV-18m.pdf",
            technicalDataNote: "La fiche CATP donne 18,060 × 2,55 × 3,34 m, 41 places assises, 173 voyageurs maximum, 235 kW et des réservoirs de 1 690 à 1 875 L. Elle indique la compatibilité bioGNV. La rampe UFR électrique et les quatre portes figurent parmi les options possibles ; elles ne sont pas posées comme équipement de base. Cette référence d’achat ne prouve pas une exploitation en Île-de-France.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "man-lions-city-18c-gnv-catp-2024-lot7",
                    title: "CATP · Lion’s City 18C GNV · lot 7 (2024)",
                    lengthMeters: 18.060,
                    widthMeters: 2.55,
                    heightMeters: 3.34,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 235,
                    maximumCapacity: 173,
                    seatedCapacity: 41,
                    rangeKilometers: nil,
                    fuelTankCapacitiesLiters: [1_690, 1_875],
                    turningRadiusBetweenWallsMeters: 12.50,
                    turningRadiusBetweenCurbsMeters: 11.1195,
                    applicabilityNote: "Données de la fiche d’achat CATP. La rampe UFR électrique et les quatre portes sont listées comme options possibles, pas comme équipement garanti. Aucun exemplaire francilien n’est identifié par cette source.",
                    evidenceTitle: "CATP · fiche MAN Lion’s City 18C GNV, accord-cadre 2023–2032, lot 7",
                    evidenceURL: "https://www.catp.fr/wp-content/uploads/2024/03/FP-MAN-autobus-GNV-18m.pdf"
                )
            ],
            fleetTitle: "CATP · référence d’achat MAN · aucune preuve de flotte IDFM",
            fleetURL: "https://www.catp.fr/bus_et_cars/autobus-gnv-man-articule-18m",
            marketAvailabilityNote: "La CATP référence le Lion’s City 18C GNV dans son accord-cadre 2023–2032, lot 7. Les sources consultées n’attestent pas son exploitation en Île-de-France ni un prix d’achat individuel ; aucune offre d’achat n’est simulée."
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
            referencePrice: 445_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 554 500 € HT pour un autobus électrique standard 12 m à charge lente ; le jeu applique le facteur de gabarit midibus 0,8 et arrondit à 445 000 € en base 2024. La version GX 137 C ou L n’est pas identifiée ; ce n’est ni un prix Heuliez individuel ni une offre de vente.",
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
            referencePrice: 245_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 310 300 € HT pour un autobus GNV standard 12 m ; le jeu ajuste au gabarit publié du GX 137 C (9,52 m), soit environ 245 000 € en base 2024 après arrondi. Ce calcul n’est ni un prix individuel du GX 137 C ni une offre de vente.",
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
            referencePrice: 280_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 310 300 € HT pour un autobus GNV standard 12 m ; le jeu ajuste au gabarit publié du GX 137 L (10,735 m), soit environ 280 000 € en base 2024 après arrondi. Ce calcul n’est ni un prix individuel du GX 137 L ni une offre de vente.",
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
            referencePrice: 554_500,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère de jeu à faible confiance : la CATP donne 554 500 € HT comme coût moyen d’acquisition d’un autobus électrique standard 12 m à charge lente en 2024. Il sert de comparable de catégorie, pas de prix historique ou individuel de l’Aptis ni d’offre de vente.",
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
            referencePrice: 554_500,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère de jeu à faible confiance : l’essai IDFM décrit un bus électrique standard de 12 m sans identifier sa version Ebusco ; la base est le coût moyen CATP 2024 d’un autobus électrique standard 12 m à charge lente, 554 500 € HT. Ce n’est pas un prix Ebusco individuel ni une offre de vente.",
            technicalTitle: "Ebusco · brochure française de la gamme 2.2 · 2020",
            technicalURL: "https://www.ebusco.com/wp-content/uploads/Ebusco-2.2-Brochure-2020-FR-Online.pdf",
            technicalDataNote: "La brochure constructeur 2.2 présente deux configurations standard de 12 m : accès surbaissé à 2 portes ou plancher surbaissé à 2/3 portes. Les valeurs ci-dessous appartiennent à cette gamme 2.2 et ne permettent pas d’identifier le sous-modèle du bus de l’essai R’Bus 2015.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "ebusco-22-12m-range-2020",
                    title: "Ebusco 2.2 · standard 12 m · brochure 2020",
                    lengthMeters: 12,
                    widthMeters: 2.55,
                    heightMeters: 3.35,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 270,
                    maximumCapacity: 90,
                    seatedCapacity: 41,
                    rangeKilometers: nil,
                    applicabilityNote: "La fiche donne 90 voyageurs, jusqu’à 41 places assises et 270 kW de puissance de crête. Les packs batterie sont au choix, 363 ou 423 kWh. Ces caractéristiques sont celles de l’Ebusco 2.2 de la brochure et ne sont pas attribuées à l’essai R’Bus de 2015, dont le sous-modèle n’est pas publié.",
                    evidenceTitle: "Ebusco · brochure française 2.2 · 2020",
                    evidenceURL: "https://www.ebusco.com/wp-content/uploads/Ebusco-2.2-Brochure-2020-FR-Online.pdf"
                )
            ],
            fleetTitle: "Île-de-France Mobilités · essai réel Ebusco sur la ligne 1 R’Bus",
            fleetURL: "https://www.iledefrance-mobilites.fr/actualites/davantage-de-bus-en-faveur-de-la-transition-energetique-en-ile-de-france",
            marketAvailabilityNote: "Référence historique d’un essai Transdev sur R’Bus à partir du 22 décembre 2015. La source ne précise pas le modèle Ebusco, la batterie, une autonomie chiffrée, la disponibilité actuelle, un prix individuel ni une compatibilité avec les COB Bords de Marne ; aucune offre d’achat n’est proposée."
        ),
        model(
            id: "volvo-7900-l-hybrid-idf",
            manufacturer: "Volvo Buses",
            commercialName: "7900 L Hybrid",
            vehicleClass: .midibus,
            length: 10.64,
            doubleDoors: 2,
            wheelchairSpaces: 1,
            energy: .dieselHybrid,
            maxCapacity: nil,
            seatedCapacity: 48,
            firstYear: 2016,
            lastYear: 2026,
            regionalEvidenceYear: 2026,
            regionalEvidenceLabel: "Exemplaire francilien n° 169031 / 203015 · mis en service en 2016",
            referencePrice: nil,
            technicalTitle: "Volvo Buses · Rescue sheet Volvo 7900 Hybrid, 10.6 m · 2022",
            technicalURL: "https://www.volvobuses.com/content/dam/volvo-buses/markets/master/why-volvo/safety-first/rescue-sheets/rs-b5lh-100-2-english.pdf",
            technicalDataNote: "La fiche Volvo confirme la carrosserie basse de 10,6 m à deux portes et un début de production en 2012. La fiche secondaire de l’exemplaire francilien n° 169031 / 203015 donne 48 assises, un emplacement UFR et un groupe hybride Volvo D5K-240 / I-SAM de 110 kW. Cette implantation et cette motorisation décrivent cet exemplaire, pas nécessairement chaque 7900 L Hybrid.",
            fleetTitle: "TC Infos · Volvo 7900 L Hybrid n° 169031 / 203015 · relevé du 2 août 2026",
            fleetURL: "https://tc-infos.fr/vehicule/50665",
            marketAvailabilityNote: "TC Infos documente cet exemplaire dans plusieurs réseaux franciliens de 2016 à 2026. La fiche de secours Volvo décrit la variante courte de 10,6 m, sans donner de prix ni de capacité voyageurs. Le relevé secondaire de 48 assises et un emplacement UFR est conservé pour cet exemplaire uniquement. Aucune disponibilité à l’achat, aucun prix individuel ni rattachement à Bords de Marne n’est établi ; aucune offre n’est simulée."
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
            guard vehicleYear <= gameYear else { return nil }
            guard let vehicleModel = models.first(where: { $0.id == modelID }),
                  let newPrice = estimatedNewPrice(for: vehicleModel, gameYear: gameYear) else { return nil }
            let age = max(1, gameYear - vehicleYear)
            let ageRetention = max(0.13, 0.82 - Double(age) * 0.045)
            let conditionFactor = 0.68 + Double(condition) / 312
            let odometerFactor = odometerValueFactor(forKilometers: odometer)
            let estimate = roundedToNearestFiveThousand(
                Int(Double(newPrice) * ageRetention * conditionFactor * odometerFactor)
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
           isAvailableAsNew(urbanway, in: gameYear),
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
           isAvailableAsNew(electric, in: gameYear),
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
        if let manHybridGNV = models.first(where: { $0.id == "man-lions-city-12c-gnv-hybrid" }),
           isAvailableAsNew(manHybridGNV, in: gameYear),
           let newPrice = estimatedNewPrice(for: manHybridGNV, gameYear: gameYear) {
            results.append(makeOffer(
                model: manHybridGNV,
                condition: .new,
                vehicleYear: gameYear,
                odometer: 0,
                conditionPercent: 100,
                askingPrice: newPrice,
                gameYear: gameYear,
                stock: 1,
                deliveryDays: 90
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

    private static func isAvailableAsNew(_ model: VehicleMarketModel, in gameYear: Int) -> Bool {
        guard model.marketAvailabilityNote == nil,
              let availableFromYear = model.newOfferAvailableFromYear else { return false }
        return availableFromYear <= gameYear
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

    private static func odometerValueFactor(forKilometers kilometers: Int) -> Double {
        max(odometerValueFactorFloor, 1 - Double(max(0, kilometers)) / kilometersPerFullValueFactor)
    }

    static func estimatedNewPrice(for model: VehicleMarketModel, gameYear: Int) -> Int? {
        guard let referencePrice = model.estimatedNewPriceReference else { return nil }
        let yearsSinceReference = gameYear - (model.priceReferenceYear ?? referenceYear)
        let gamePriceIndex = pow(1 + annualPriceIndexRate, Double(yearsSinceReference))
        return roundedToNearestFiveThousand(Int((Double(referencePrice) * gamePriceIndex).rounded()))
    }

    static func estimatedNewPriceRange(for model: VehicleMarketModel, gameYear: Int) -> ClosedRange<Int>? {
        guard let estimate = estimatedNewPrice(for: model, gameYear: gameYear) else { return nil }
        let low = roundedToNearestFiveThousand(Int((Double(estimate) * 0.88).rounded()))
        let high = roundedToNearestFiveThousand(Int((Double(estimate) * 1.12).rounded()))
        return low...high
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
        newOfferAvailableFromYear: Int? = nil,
        regionalEvidenceLabel: String? = nil,
        rangeKilometers: Int? = nil,
        rangeEvidenceNote: String? = nil,
        referencePrice: Int?,
        priceReferenceYear: Int? = nil,
        priceEstimateNote: String? = nil,
        technicalTitle: String? = nil,
        technicalURL: String? = nil,
        technicalDataNote: String? = nil,
        technicalVariants: [VehicleTechnicalVariant]? = nil,
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
            newOfferAvailableFromYear: newOfferAvailableFromYear,
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
            technicalVariants: technicalVariants,
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
                    ? " Le prix d’occasion applique des coefficients de jeu pour l’âge et l’état, ainsi qu’un facteur kilométrique max(15 %, 1 − km/1 200 000 km), également utilisé pour estimer la revente."
                    : ""
                return "\(basis) Indexation de jeu de \(annualIndexPercent) %/an à la hausse ou à la baisse depuis l’année de référence jusqu’en \(gameYear) ; fourchette indicative de ±12 %.\(usedPriceRule)"
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
