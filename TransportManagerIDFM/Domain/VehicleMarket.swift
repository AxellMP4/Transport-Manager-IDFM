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
    private static let odometerValueFactorFloor = 0.15
    private static let kilometersPerFullValueFactor = 1_200_000.0

    static func preventiveMaintenanceCost(for conditionPercent: Int) -> Int {
        let conditionGap = 100 - max(0, min(100, conditionPercent))
        return preventiveMaintenanceBaseCostEuro + conditionGap * preventiveMaintenanceCostPerConditionPointEuro
    }

    static func estimatedResaleValue(for bus: PurchasedBus, at date: Date) -> Int {
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let currentYear = calendar.component(.year, from: date)
        let ageYears = max(0, currentYear - bus.modelYear)
        let ageFactor = max(0.12, 1 - Double(ageYears) * 0.06)
        let distanceFactor = odometerValueFactor(forKilometers: bus.odometerKilometers)
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
            technicalDataNote: "La fiche Irisbus de 2010 décrit la gamme Citelis 12 Diesel. Un exemplaire régional précis, n° 918604, est aussi documenté par une source secondaire ; ces données ne caractérisent pas tous les bus de cette gamme.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "citelis-12-diesel-irisbus-range-2010",
                    title: "Gamme constructeur Citelis 12 Diesel · décembre 2010",
                    lengthMeters: 11.99,
                    widthMeters: 2.5,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 213,
                    maximumCapacity: nil,
                    seatedCapacity: nil,
                    rangeKilometers: nil,
                    applicabilityNote: "Cursor 8 de 180 ou 213 kW (245 ou 290 ch), émissions Euro V ou EEV et 2 ou 3 portes selon version. La brochure indique 20 à 37 places assises selon l’aménagement. Elle ne permet pas d’identifier la motorisation ni l’homologation de chaque Citelis régional observé.",
                    evidenceTitle: "Irisbus IVECO · fiche technique Citelis 12 m Diesel (12/2010)",
                    evidenceURL: "https://www.tplitalia.it/produttori/Irisbus-IvecoBus/Irisbus-Citelis-12m-pubIRUS11011008-12-2010.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "citelis-12-bords-de-marne-918604-2012",
                    title: "Exemplaire Bords de Marne n° 918604 · 2012",
                    lengthMeters: 11.99,
                    widthMeters: nil,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 180,
                    maximumCapacity: nil,
                    seatedCapacity: 30,
                    rangeKilometers: nil,
                    applicabilityNote: "TC Infos décrit ce véhicule comme EEV, Cursor 8 F2B de 245 ch, 2 portes, 30 assises, 72 debout et 1 emplacement UFR. Il est affecté à Bords de Marne jusqu’en octobre 2025 puis à Neuilly-Plaisance depuis novembre 2025. Relevé secondaire mis à jour le 7 mars 2026, limité à ce numéro de parc.",
                    evidenceTitle: "TC Infos · fiche individuelle Irisbus Citelis 12 n° 918604",
                    evidenceURL: "https://tc-infos.fr/vehicule/10847"
                )
            ],
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
            technicalDataNote: "La brochure Irisbus de 2009 documente la gamme Citelis 18 Diesel. Une fiche secondaire détaille aussi l’exemplaire régional n° 921667, sans caractériser tous les véhicules de cette série.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "citelis-18-diesel-irisbus-range-2009",
                    title: "Gamme constructeur Citelis 18 Diesel · décembre 2009",
                    lengthMeters: 17.9,
                    widthMeters: 2.5,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 280,
                    maximumCapacity: nil,
                    seatedCapacity: nil,
                    rangeKilometers: nil,
                    applicabilityNote: "Cursor 8 de 213 ou 280 kW (290 ou 380 ch), 3 ou 4 portes et 31 à 49 places assises selon la version et l’homologation. Ces valeurs décrivent la gamme constructeur et ne confirment pas la configuration exacte des véhicules de Bords de Marne.",
                    evidenceTitle: "Irisbus IVECO · catalogue de gamme Citelis 10,5, 12 et 18 m (12/2009)",
                    evidenceURL: "https://www.tplitalia.it/produttori/Irisbus-IvecoBus/Irisbus-Citelis-catalogo-pubIRUC011009008-12-2009.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "citelis-18-bords-de-marne-921667-2013",
                    title: "Exemplaire Bords de Marne n° 921667 · 2013",
                    lengthMeters: 17.8,
                    widthMeters: nil,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 280,
                    maximumCapacity: nil,
                    seatedCapacity: 44,
                    rangeKilometers: nil,
                    applicabilityNote: "TC Infos décrit ce véhicule comme Euro V, Cursor 8 F2B de 381 ch, 3 portes, 44 assises, 104 debout et 1 emplacement UFR. Il est listé à Frères-Lumière depuis février 2026 après des périodes à Bords de Marne et au dépôt d’appui Championnet. Relevé secondaire mis à jour le 9 mars 2026, limité à ce numéro de parc.",
                    evidenceTitle: "TC Infos · fiche individuelle Irisbus Citelis 18 n° 921667",
                    evidenceURL: "https://tc-infos.fr/vehicule/10801"
                )
            ],
            fleetURL: "https://tc-infos.fr/reseau/1452/parc-bus-cars/page2"
        ),
        model(
            id: "heuliez-gx127-diesel",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 127",
            vehicleClass: .midibus,
            length: nil,
            width: 2.33,
            energy: .diesel,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2025,
            regionalEvidenceLabel: "Parc Bords de Marne · relevé secondaire",
            referencePrice: 235_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 293 400 € HT pour un autobus diesel standard 12 m ; le jeu applique un facteur de gabarit midibus de 0,8, soit environ 235 000 € en base 2024. Ce calcul n’est ni un prix historique ou individuel du GX 127 ni une offre de vente.",
            technicalTitle: "Heuliez Bus · descriptif technique GX 127 (mai 2010)",
            technicalURL: "https://wikibus.blob.core.windows.net/sources2561/Heuliez%20GX%20127%20Descriptif%20technique.pdf",
            technicalDataNote: "Le descriptif constructeur couvre plusieurs implantations : deux ou trois portes, deux longueurs et plusieurs hauteurs selon configuration, avec des aménagements différents. Les 9 GX 127 recensés dans le parc Bords de Marne par TC Infos ne sont pas qualifiés individuellement par la fiche constructeur. Aucun prix individuel ni état de marché n’est établi.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "heuliez-gx127-two-door-16-seat-2010",
                    title: "Gamme constructeur · 2 portes · implantation 16 assises (2010)",
                    lengthMeters: 9.42,
                    widthMeters: 2.33,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 160,
                    maximumCapacity: nil,
                    seatedCapacity: 16,
                    rangeKilometers: nil,
                    applicabilityNote: "Heuliez donne 16 assises + conducteur + 1 espace UFR + 55 debout. La hauteur constructeur varie de 2,885 à 3,265 m selon équipement ; la capacité totale n’est pas ramenée à un chiffre unique. Cette implantation n’est pas attribuée aux véhicules du dépôt.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 127, version France (mai 2010)",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2561/Heuliez%20GX%20127%20Descriptif%20technique.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx127-two-door-12-seat-2010",
                    title: "Gamme constructeur · 2 portes · implantation 12 assises (2010)",
                    lengthMeters: 9.42,
                    widthMeters: 2.33,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 160,
                    maximumCapacity: nil,
                    seatedCapacity: 12,
                    rangeKilometers: nil,
                    applicabilityNote: "Heuliez donne 12 assises + conducteur + 1 espace UFR + 58 debout. La hauteur constructeur varie de 2,885 à 3,265 m selon équipement ; la capacité totale n’est pas ramenée à un chiffre unique. Cette implantation n’est pas attribuée aux véhicules du dépôt.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 127, version France (mai 2010)",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2561/Heuliez%20GX%20127%20Descriptif%20technique.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx127-three-door-18-seat-2010",
                    title: "Gamme constructeur · 3 portes · implantation 18 assises (2010)",
                    lengthMeters: 9.495,
                    widthMeters: 2.33,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 194,
                    maximumCapacity: nil,
                    seatedCapacity: 18,
                    rangeKilometers: nil,
                    applicabilityNote: "Heuliez donne 18 assises + conducteur + 1 espace UFR + 49 debout. La hauteur constructeur varie de 2,885 à 3,265 m selon équipement ; la capacité totale n’est pas ramenée à un chiffre unique. Cette implantation n’est pas attribuée aux véhicules du dépôt.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 127, version France (mai 2010)",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2561/Heuliez%20GX%20127%20Descriptif%20technique.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx127-three-door-19-seat-2010",
                    title: "Gamme constructeur · 3 portes · implantation 19 assises (2010)",
                    lengthMeters: 9.495,
                    widthMeters: 2.33,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 194,
                    maximumCapacity: nil,
                    seatedCapacity: 19,
                    rangeKilometers: nil,
                    applicabilityNote: "Heuliez donne 19 assises + conducteur + 1 espace UFR + 46 debout. La hauteur constructeur varie de 2,885 à 3,265 m selon équipement ; la capacité totale n’est pas ramenée à un chiffre unique. Cette implantation n’est pas attribuée aux véhicules du dépôt.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 127, version France (mai 2010)",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2561/Heuliez%20GX%20127%20Descriptif%20technique.pdf"
                )
            ],
            fleetTitle: "Parc Bords de Marne · 9 GX 127 recensés par TC Infos (source secondaire)",
            fleetURL: "https://tc-infos.fr/reseau/1452/parc-bus-cars/page2",
            marketAvailabilityNote: "Le relevé secondaire du parc Bords de Marne recense 9 GX 127, dont les configurations individuelles ne sont pas toutes établies. Le modèle apparaît au catalogue régional comme référence historique ; faute de prix, d’état et d’offre actuelle documentés, aucune offre d’achat n’est simulée."
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
            technicalURL: "https://www.ivecobus.com/worldwide/-/media/IvecoBus/International/Urbanway-2024.pdf?rev=8202872493f84cfbb93a4a54402f4f74",
            technicalDataNote: "La version full-hybrid observée en Île-de-France en 2015 n’est pas caractérisée par cette fiche. Voir ci-dessous la fiche CATP de la génération mild-hybrid 2023, distincte ; ses données ne sont pas appliquées aux offres d’occasion de 2015.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "urbanway-12-diesel-mild-hybrid-2023",
                    title: "Version mild-hybrid Diesel Euro VI/E · fiche CATP 2024 / accord-cadre 2023–2032",
                    lengthMeters: 12.09,
                    widthMeters: 2.50,
                    heightMeters: 3.165,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 228,
                    maximumCapacity: 105,
                    seatedCapacity: 28,
                    rangeKilometers: nil,
                    applicabilityNote: "Ces valeurs décrivent la version mild-hybrid de l’accord-cadre, pas la version full-hybrid de 2015 recensée dans le parc. Le moteur thermique Cursor 9 développe 228 kW ; l’assistance 48 V est donnée pour 25 kW en continu / 35 kW en pointe, avec une batterie de 1 kWh. Cette batterie d’assistance n’est pas la capacité de traction électrique du modèle de jeu.",
                    evidenceTitle: "CATP · Urbanway mild-hybrid 12 m, fiche de l’accord-cadre 2023–2032",
                    evidenceURL: "https://www.catp.fr/wp-content/uploads/2024/04/FP-IVECO-autobus-Diesel-Mild-Hybride-12m.pdf"
                )
            ]
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
            newOfferAvailableFromYear: 2020,
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
            newOfferAvailableFromYear: 2017,
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
            id: "iveco-urbanway-18-gnv",
            manufacturer: "Iveco Bus",
            commercialName: "Urbanway 18 GNV",
            vehicleClass: .articulated,
            length: 18,
            width: 2.50,
            height: 3.30,
            energy: .gnv,
            maximumPowerKilowatts: 265,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2024,
            regionalEvidenceLabel: "Paris-Saclay · Urbanway 18 GNV n° 2470",
            referencePrice: 403_390,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu 2024 : le repère CATP d’un autobus GNV standard 12 m est de 310 300 € HT ; une majoration de gabarit articulé de 30 % donne 403 390 €. La CATP ne publie pas le prix de l’Urbanway 18 ; cette base indicative n’est ni un prix individuel ni une offre commerciale.",
            technicalTitle: "CATP · fiche Autobus GNV articulé 18 m IVECO France Urbanway · accord-cadre 2023–32",
            technicalURL: "https://www.catp.fr/wp-content/uploads/2024/04/FP-IVECO-autobus-GNV-18m.pdf",
            technicalDataNote: "La fiche CATP publie un moteur de 265 kW, 43 places assises et une capacité maximale de 172 voyageurs pour la configuration de son accord-cadre, ainsi que les dimensions ci-dessus. La fiche secondaire du n° 2470 documente un autre aménagement : 37 places assises et 121 debout. Ces capacités restent des configurations distinctes et ne sont pas appliquées aux véhicules de Bords de Marne.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "iveco-urbanway-18-gnv-catp-2023-32",
                    title: "Fiche CATP · configuration de l’accord-cadre 2023–32",
                    lengthMeters: 18,
                    widthMeters: 2.50,
                    heightMeters: 3.30,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 265,
                    maximumCapacity: 172,
                    seatedCapacity: 43,
                    rangeKilometers: nil,
                    fuelTankCapacitiesLiters: [1_280, 1_610, 1_940],
                    turningRadiusBetweenWallsMeters: 11.405,
                    turningRadiusBetweenCurbsMeters: 9.891,
                    applicabilityNote: "Fiche de l’offre CATP IVECO France Urbanway GNV articulé 18 m : capacité maximale annoncée de 172 voyageurs, dont 43 places assises, moteur de 265 kW et réservoirs de 1 280, 1 610 ou 1 940 L. La fiche ne donne pas de prix ; elle n’établit ni disponibilité à la vente pour cette partie ni rattachement à un dépôt Bords de Marne.",
                    evidenceTitle: "CATP · Autobus GNV articulé 18 m IVECO France Urbanway",
                    evidenceURL: "https://www.catp.fr/wp-content/uploads/2024/04/FP-IVECO-autobus-GNV-18m.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "iveco-urbanway-18-gnv-paris-saclay-2470",
                    title: "Configuration observée · Paris-Saclay n° 2470",
                    lengthMeters: 18,
                    widthMeters: nil,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: 158,
                    seatedCapacity: 37,
                    rangeKilometers: nil,
                    applicabilityNote: "La fiche secondaire du n° 2470 indique 37 places assises, 121 debout, un emplacement UFR et quatre portes. Le véhicule est recensé sur le réseau Paris-Saclay à partir de décembre 2024. Cette configuration ne décrit que cet exemplaire et ne prouve aucune affectation à Bords de Marne.",
                    evidenceTitle: "TC Infos · fiche individuelle Urbanway 18 GNV n° 2470",
                    evidenceURL: "https://tc-infos.fr/vehicule/73566"
                )
            ],
            fleetTitle: "TC Infos · Urbanway 18 GNV n° 2470 · réseau Paris-Saclay",
            fleetURL: "https://tc-infos.fr/vehicule/73566",
            marketAvailabilityNote: "La fiche technique CATP de l’Urbanway articulé 18 m ne publie pas de prix. Le catalogue affiche seulement un repère de jeu obtenu en majorant de 30 % le prix CATP d’un autobus GNV standard 12 m ; ce calcul ne confirme ni le prix du modèle ni sa disponibilité à la vente. La présence du n° 2470 sur Paris-Saclay ne documente pas une affectation à Bords de Marne ; aucune offre n’est créée."
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
            rangeEvidenceNote: "La publication IDFM de 2015 annonce jusqu’à 180 km sans recharge intermédiaire pour la version alors testée. La fiche Bluebus actuelle annonce jusqu’à 320 km ; la configuration des véhicules d’occasion de 2017 n’est pas identifiée et conserve donc la valeur historique dans la simulation.",
            referencePrice: 554_500,
            priceReferenceYear: 2022,
            priceEstimateNote: "Repère de l’étude CATP 2024 : autobus électrique à batterie 12 m à charge lente, options comprises, 554 500 € HT (474 500 € véhicule de base et 80 000 € d’options moyennes), montant indiqué comme équivalent à février 2022. La CATP n’en fait pas un devis Bluebus.",
            technicalTitle: "IDFM · STIF en ligne n°8 (2015) — bus standard 12 m, autonomie annoncée jusqu’à 180 km",
            technicalURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/26c22c53-53fa-4e38-8a28-558408a359b1_stif_en_ligne_no8.pdf",
            technicalDataNote: "La fiche constructeur actuelle décrit une configuration plus récente, affichée séparément ci-dessous. Elle n’est pas utilisée pour recalculer l’autonomie ou la batterie du Bluebus d’occasion de 2017, dont la version exacte n’est pas établie.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "bluebus-12m-current-manufacturer-specification",
                    title: "Fiche constructeur actuelle du Bluebus 12 m · consultée en 2026",
                    lengthMeters: 12.068,
                    widthMeters: 2.915,
                    heightMeters: 3.291,
                    batteryCapacityKWh: 441,
                    maximumPowerKilowatts: 160,
                    maximumCapacity: 109,
                    seatedCapacity: nil,
                    rangeKilometers: 320,
                    applicabilityNote: "La largeur comprend les rétroviseurs. La capacité batterie et l’autonomie sont des maxima annoncés par Bluebus ; l’autonomie est mesurée sur cycles SORT. Ces caractéristiques de la fiche actuelle ne sont pas attribuées aux véhicules IDFM vus en 2015 ni à l’offre d’occasion 2017, faute d’identification de leur configuration.",
                    evidenceTitle: "Bluebus · fiche officielle du modèle 12 m",
                    evidenceURL: "https://www.bluebus.fr/bluebus-12-m"
                )
            ],
            fleetTitle: "RATP · Rapport d’activité 2016 — commande de 23 Bluebus de 12 m pour la ligne 341",
            fleetURL: "https://www.ratp.fr/mediateur/sites/default/files/2017-06/raddratp2016fr_0.pdf"
        ),
        model(
            // Keep this identifier for saved careers; the sourced manufacturer is Van Hool.
            id: "hess-tzen4-biarticulated-electric",
            manufacturer: "Van Hool",
            commercialName: "Bi-articulé électrique TZen 4 · 24 m",
            vehicleClass: .articulated,
            length: 24,
            energy: .electric,
            maxCapacity: 140,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2026,
            referencePrice: 885_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 554 500 € HT pour un autobus électrique standard 12 m à charge lente. Le jeu ajoute 30 % par tranche de 6 m au-delà de 12 m (facteur 1,6 pour 24 m), puis arrondit à 885 000 € en base 2024. Ce n’est ni un prix unitaire IDFM, ni une ventilation du forfait de reprise TZen 4, ni une offre commerciale.",
            technicalTitle: "IDFM · présentation des bus TZen 4 et TZen 5",
            technicalURL: "https://www.iledefrance-mobilites.fr/actualites/t-zen-4-t-zen-5-bus-24-metres-100-pourcent-electriques-ile-de-france",
            technicalDataNote: "IDFM décrit un autobus bi-articulé de 24 m, électrique, rechargeable par contact au sol, pouvant transporter 140 passagers, et indique avoir retenu le groupement Van Hool / Kiepe Electric / Alstom pour sa conception et sa fabrication. Les sources consultées ne donnent ni capacité de batterie, ni places assises, ni prix unitaire. La lettre IDFM de novembre 2024 précise que Van Hool avait livré 5 des 30 bus avant sa faillite et que HESS avait reçu le contrat pour achever les 25 restants ; HESS est donc documenté comme partenaire de reprise de fabrication.",
            additionalEvidenceTitle: "IDFM · délibération n° 20241211-267, marché n° 2024-070",
            additionalEvidenceURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/Z2Kq5JbqstJ98og7_RAA160-1-D%C3%A9lib%C3%A9rations.pdf",
            fleetTitle: "IDFM · lettre n° 13 : 5 bus livrés, HESS chargé des 25 restants",
            fleetURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/Z0bkO5bqstJ97zrk_Tzen4_LIR_n%C2%B013_BD.pdf",
            marketAvailabilityNote: "Le marché IDFM n° 2024-070 porte, pour le TZen 4, sur la reprise de fabrication du matériel roulant électrique et des systèmes de charge associés ; il est forfaitaire, de 11 510 400 € HT sur 24 mois. Ce montant couvre un lot de reprise et les systèmes associés, pas un prix unitaire de bus. L’offre reste absente faute de prix individuel ou de disponibilité commerciale documentés ; aucune compatibilité avec un dépôt ou une ligne Bords de Marne n’est déduite."
        ),
        model(
            id: "bbdm-project-24m-electric-biarticulated",
            manufacturer: "Configuration projet",
            commercialName: "Bus Bords de Marne · bi-articulé électrique 24 m",
            vehicleClass: .articulated,
            length: 24,
            energy: .electric,
            maxCapacity: 145,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2026,
            regionalEvidenceLabel: "Projet IDFM · mise en service visée vers 2030",
            referencePrice: nil,
            technicalTitle: "IDFM · principes d’aménagement du Bus Bords de Marne",
            technicalURL: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/principes-amenagement-fonctionnement-bbdm",
            technicalDataNote: "La page IDFM actuelle prévoit pour le projet des bus bi-articulés électriques de 24 m et une capacité d’environ 145 voyageurs. La FAQ IDFM du 22 février 2024 annonçait environ 150 personnes. Ce sont deux estimations de projet, pas une configuration finale publiée. Le constructeur, la capacité de batterie, la puissance, les places assises et le prix individuel restent inconnus.",
            additionalEvidenceTitle: "IDFM · FAQ matériel roulant et futur COB · 22 février 2024",
            additionalEvidenceURL: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/questions/materiel-roulant-cob",
            fleetTitle: "IDFM · projet Bus Bords de Marne, horizon 2030",
            fleetURL: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne",
            marketAvailabilityNote: "Référence de projet, distincte du bi-articulé TZen 4 : IDFM ne publie pas le constructeur ni la configuration finale du matériel Bords de Marne. Aucun prix unitaire, disponibilité commerciale ou véhicule déjà en service n’est attesté ; aucune offre d’achat n’est créée. Le futur COB reste un projet et ses équipements/capacités opérationnels ne sont pas connus."
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
            referencePrice: 403_390,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 310 300 € HT pour un autobus GNV standard 12 m ; le jeu applique sa majoration de gabarit articulé de 30 %, soit 403 390 € en base 2024. Ce calcul n’est ni un prix individuel d’Urbino 18 ni une offre commerciale.",
            technicalTitle: "IDFM · Dossier d’enquête Sénia–Orly (2022) — dimensions et capacité de la ligne 393",
            technicalURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/bb8667f9-2153-49f0-9132-92fcc994166b_2.pdf",
            fleetTitle: "IDFM · parc de la ligne 393, renouvelé au GNV entre 2017 et 2020",
            fleetURL: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/bb8667f9-2153-49f0-9132-92fcc994166b_2.pdf",
            marketAvailabilityNote: "Référence de la ligne 393 en Île-de-France ; aucune présence à Bords de Marne, compatibilité avec ses COB ni aucun prix individuel ne sont documentés. Aucune offre d’achat n’est proposée."
        ),
        model(
            id: "heuliez-gx437-hybrid",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 437 Hybrid",
            vehicleClass: .articulated,
            length: 17.96,
            width: 2.55,
            height: 3.246,
            energy: .dieselHybrid,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2020,
            regionalEvidenceLabel: "Parc RATP · GX 437 Hybrid n° 924417",
            referencePrice: 430_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 293 400 € HT pour un autobus diesel standard 12 m. Le jeu ajoute 12,5 % pour la motorisation full-hybrid puis 30 % pour le gabarit articulé et arrondit le résultat à 430 000 € en base 2024. La CATP ne publie pas de prix full-hybrid articulé ; ce n’est ni un prix individuel GX 437 ni une offre de vente.",
            technicalTitle: "Heuliez Bus · descriptif technique GX 437 H (juin 2020)",
            technicalURL: "https://www.heuliezbus.com/fr/vue/produits/bus/GX-HYBRIDE/FT_GX437_HYB_NG.pdf",
            technicalDataNote: "La fiche constructeur donne 17,960 × 2,550 m et 3,246 m de haut en charge, avec plusieurs implantations. Deux plans indiquent 38 ou 40 assises, conducteur et espace UFR compris, dont 4 places PMR ; la capacité totale voyageurs n'est pas fixée ici. La fiche individuelle secondaire du n° 924417 décrit une autre configuration précise. Ces données ne prouvent aucune affectation à Bords de Marne.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "heuliez-gx437-hybrid-38-seats-2020",
                    title: "Gamme constructeur · implantation 38 assises (2020)",
                    lengthMeters: 17.96,
                    widthMeters: 2.55,
                    heightMeters: 3.246,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 38,
                    rangeKilometers: nil,
                    applicabilityNote: "Le constructeur indique 38 places assises + conducteur + espace UFR, dont 4 places PMR. Le document ne donne pas de capacité totale unique ; cette implantation n'est pas attribuée au véhicule 924417 ni à Bords de Marne.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 437 H · juin 2020",
                    evidenceURL: "https://www.heuliezbus.com/fr/vue/produits/bus/GX-HYBRIDE/FT_GX437_HYB_NG.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx437-hybrid-40-seats-2020",
                    title: "Gamme constructeur · implantation 40 assises (2020)",
                    lengthMeters: 17.96,
                    widthMeters: 2.55,
                    heightMeters: 3.246,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 40,
                    rangeKilometers: nil,
                    applicabilityNote: "Le constructeur indique 40 places assises + conducteur + espace UFR, dont 4 places PMR. Le document ne donne pas de capacité totale unique ; cette implantation n'est pas attribuée au véhicule 924417 ni à Bords de Marne.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 437 H · juin 2020",
                    evidenceURL: "https://www.heuliezbus.com/fr/vue/produits/bus/GX-HYBRIDE/FT_GX437_HYB_NG.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx437-hybrid-ratp-924417-2020",
                    title: "Configuration observée · RATP n° 924417 (2020)",
                    lengthMeters: 17.96,
                    widthMeters: 2.55,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 34,
                    rangeKilometers: nil,
                    applicabilityNote: "TC Infos documente pour le seul n° 924417 quatre portes, 34 assises, 119 debout et 2 espaces UFR, ainsi qu'un Iveco Tector 7 E28 de 286 ch et le système BAE Systems Hybri’Drive de 200 kW. Ces caractéristiques secondaires ne décrivent pas toutes les variantes constructeur ni les autres véhicules.",
                    evidenceTitle: "TC Infos · fiche individuelle Heuliez GX 437 Hybrid n° 924417",
                    evidenceURL: "https://tc-infos.fr/vehicule/7183"
                )
            ],
            fleetTitle: "TC Infos · GX 437 Hybrid n° 924417 · parc RATP puis Transdev Ourcq",
            fleetURL: "https://tc-infos.fr/vehicule/7183",
            marketAvailabilityNote: "La fiche secondaire suit un véhicule RATP de 2020 puis son transfert à Transdev Ourcq ; elle ne prouve pas sa disponibilité à la vente ni une présence à Bords de Marne. Le catalogue ne dispose pas d'un repère CATP identifié pour un articulé diesel-hybride de 18 m ; aucun prix individuel ni offre d'achat n'est simulé."
        ),
        model(
            id: "heuliez-gx437-electric",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 437 Elec · articulé 18 m",
            vehicleClass: .articulated,
            length: 17.96,
            width: 2.55,
            height: 3.24,
            energy: .electric,
            batteryCapacityKWh: 485,
            maximumPowerKilowatts: 550,
            maxCapacity: 155,
            seatedCapacity: 40,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: nil,
            regionalEvidenceLabel: "Référence CATP · accord-cadre AC 2024-02 · fiche publiée en 2025",
            referencePrice: 720_850,
            priceReferenceYear: 2022,
            priceEstimateNote: "Estimation de jeu : la CATP donne 554 500 € HT comme coût moyen d’acquisition d’un autobus électrique standard 12 m à charge lente, options moyennes comprises, valeur équivalente à février 2022. La majoration forfaitaire de 30 % retenue par le jeu pour le gabarit articulé donne une base de 720 850 €. La fiche du GX 437 Elec ne publie pas de prix ; ce calcul n’est ni un prix individuel ni une offre commerciale.",
            technicalTitle: "CATP · autobus électrique 18 m à charge lente · accord-cadre AC 2024-02",
            technicalURL: "https://www.catp.fr/wp-content/uploads/2025/05/Autobus-standard-18m-electrique-charge-lente-Fiche-vehicule-CATP-2024-02.pdf",
            technicalDataNote: "La fiche CATP donne une configuration de base à 485 kWh avec des options à 347, 416, 555 ou 624 kWh, et 330 kW continus / 550 kW en pointe. Les 40 assises et les 155 voyageurs (+ conducteur) correspondent à la version trois portes de la fiche. Ces données ne décrivent pas un véhicule d’Île-de-France ou de Bords de Marne.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "heuliez-gx437-electric-catp-ac-2024-02",
                    title: "CATP · recharge lente · accord-cadre AC 2024-02 · 3 portes",
                    lengthMeters: 17.96,
                    widthMeters: 2.55,
                    heightMeters: 3.24,
                    batteryCapacityKWh: 485,
                    maximumPowerKilowatts: 550,
                    maximumCapacity: 155,
                    seatedCapacity: 40,
                    rangeKilometers: nil,
                    applicabilityNote: "Configuration de base de la fiche CATP : batterie 485 kWh (options 347, 416, 555 ou 624 kWh), puissance 330 kW continus / 550 kW en pointe et capacité de 155 voyageurs + conducteur en trois portes. La fiche ne donne pas d’autonomie chiffrée, de prix ni d’affectation à un réseau francilien ou à un COB.",
                    evidenceTitle: "CATP · fiche véhicule autobus 18 m électrique charge lente · AC 2024-02",
                    evidenceURL: "https://www.catp.fr/wp-content/uploads/2025/05/Autobus-standard-18m-electrique-charge-lente-Fiche-vehicule-CATP-2024-02.pdf"
                )
            ],
            fleetTitle: "CATP · fiche véhicule Heuliez GX 437 Elec · AC 2024-02",
            fleetURL: "https://www.catp.fr/wp-content/uploads/2025/05/Autobus-standard-18m-electrique-charge-lente-Fiche-vehicule-CATP-2024-02.pdf",
            marketAvailabilityNote: "Référence du catalogue CATP 2025 sous l’accord-cadre AC 2024-02, distincte du GX 437 Hybrid. La fiche ne publie pas de prix et n’établit pas que l’accord-cadre est encore actif en 2026 ; le montant affiché est un repère de jeu calculé depuis une catégorie 12 m, pas un prix du GX 437 Elec. Aucune présence en Île-de-France, disponibilité à l’achat, affectation à Bords de Marne ou compatibilité avec ses dépôts n’est établie ; aucune offre n’est créée."
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
            referencePrice: 403_390,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 310 300 € HT pour un autobus GNV standard 12 m ; le jeu applique sa majoration de gabarit articulé de 30 %, soit 403 390 € en base 2024. Ce calcul n’est ni un prix individuel Scania ni une offre commerciale.",
            technicalTitle: "Scania · brochure Citywide LF en français",
            technicalURL: "https://www.scania.com/content/dam/www/market/ch/products/buses-and-coaches/pdfs/citywide-lf/Scania-Citywide-LF-FR.pdf",
            technicalDataNote: "La brochure constructeur documente les variantes de gamme GNV ; la variante ci-dessous en reprend les plages sans choisir un moteur ou un réservoir pour les bus RATP. L’annonce de livraison Scania précise que les 101 véhicules RATP sont identiques, articulés de 18 m et équipés de portes type métro, sans publier leur capacité voyageurs ni leur configuration mécanique détaillée.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "scania-citywide-lf-gaz-articule-range-2021",
                    title: "Gamme Citywide LF GNV · brochure constructeur française",
                    lengthMeters: nil,
                    widthMeters: 2.55,
                    heightMeters: 3.17,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: nil,
                    rangeKilometers: nil,
                    applicabilityNote: "La brochure décrit des articulés de 18,0 à 18,7 m, des moteurs gaz de 9 litres de 206 ou 250 kW et 1 260 à 1 875 litres de gaz utilisables selon configuration. Ce sont des plages de la gamme, pas les spécifications attribuées aux 101 véhicules RATP ; leur capacité voyageurs et leur choix exact de moteur et de réservoir restent inconnus.",
                    evidenceTitle: "Scania · brochure Citywide LF, version française",
                    evidenceURL: "https://www.scania.com/content/dam/www/market/ch/products/buses-and-coaches/pdfs/citywide-lf/Scania-Citywide-LF-FR.pdf"
                )
            ],
            fleetTitle: "Scania France · 101 Citywide GNV de 18 m livrés à la RATP",
            fleetURL: "https://www.scania.com/fr/fr/home/about-scania/newsroom/news/2022/2/101-citywide-gaz-livres-scania-france-ratp.html",
            marketAvailabilityNote: "Scania documente 101 autobus articulés Citywide GNV de 18 m livrés à la RATP entre 2018 et 2021, tête de série comprise. La source ne donne ni capacité voyageurs ni prix individuel ; elle n’atteste pas de présence à Bords de Marne, de compatibilité avec ses dépôts ou de disponibilité actuelle à l’achat. Aucune offre n’est simulée."
        ),
        model(
            id: "mercedes-citaro-standard-ratp-2002",
            manufacturer: "Mercedes-Benz",
            commercialName: "Citaro standard · série RATP 2002",
            vehicleClass: .standard,
            length: nil,
            energy: .diesel,
            maxCapacity: 95,
            seatedCapacity: nil,
            firstYear: 2002,
            lastYear: nil,
            regionalEvidenceYear: 2002,
            regionalEvidenceLabel: "70 Citaro commandés par la RATP · premiers en service en mai 2002",
            referencePrice: 293_400,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère de jeu à faible confiance : la CATP donne 293 400 € HT comme coût moyen d’acquisition d’un autobus diesel Euro VI standard 12 m en 2024. Il sert de comparable de catégorie neuf, pas de prix historique du Citaro 2002 ni de prix individuel.",
            technicalTitle: "RATP · ELL n° 121 (juin–juillet 2002), parc bus",
            technicalURL: "https://ratp.histolab.fr/uploads/r/null/e/6/c/e6c6b448b61c270f05331518da8113b6f91ae2638bb14eed5570a3cd630b9fc5/FRAHRATP_PER002_200206_n121.pdf",
            technicalDataNote: "La revue RATP de 2002 indique une capacité de 95 voyageurs et décrit la série comme climatisée, à plancher surbaissé et accessible aux personnes à mobilité réduite. Elle ne précise pas les places assises, les dimensions ni la configuration de chaque autobus. Une autre revue RATP documente un moteur OM 906 de 279 ch pour le Citaro présenté à la RATP ; cette puissance ne caractérise pas un numéro de parc individuel.",
            additionalEvidenceTitle: "RATP · Savoir-Faire n° 41 (2002), Citaro présenté pour la RATP",
            additionalEvidenceURL: "https://ratp.histolab.fr/uploads/r/null/2/2/e/22e255996bb3e05fe662e63d963a6812a2abc071ce73432c43cff868e0a12d06/FRAHRATP_PER004_2002_T1_n41.pdf",
            fleetTitle: "RATP · ELL n° 126 (décembre 2002), Citaro sur les lignes 297 et 299",
            fleetURL: "https://ratp.histolab.fr/uploads/r/null/f/f/2/ff24e13ddb05a518756388322d0c416ad4c08ad50880d2edce6ad8bb99149426/FRAHRATP_PER002_200212_n126.pdf",
            marketAvailabilityNote: "Les archives RATP attestent la série de 70 véhicules et sa mise en service historique en Île-de-France. Elles ne documentent ni le prix actuel ou historique d’achat, ni une disponibilité d’occasion, ni un rattachement à Bords de Marne ; aucune offre n’est créée."
        ),
        model(
            id: "mercedes-citaro-g-articulated-ratp-2014",
            manufacturer: "Mercedes-Benz",
            commercialName: "Citaro G articulé · livraisons RATP dès 2014",
            vehicleClass: .articulated,
            length: nil,
            energy: .diesel,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: 2014,
            lastYear: nil,
            regionalEvidenceYear: 2014,
            regionalEvidenceLabel: "75 exemplaires annoncés en livraison à la RATP dès le T4 2014",
            referencePrice: 380_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : le comparable CATP d’un diesel standard 12 m vaut 293 400 € HT ; le jeu applique une majoration de gabarit articulé de 30 % (381 420 €), arrondie à 380 000 € en base 2024. Ce n’est ni un prix historique du Citaro G ni un prix d’occasion observé.",
            technicalTitle: "Mercedes-Benz Buses · fiche technique Citaro",
            technicalURL: "https://www.mercedes-benz-bus.com/int/en/models/citaro/facts-citaro.pdf",
            technicalDataNote: "Bus & Car rapporte que les livraisons des 75 Citaro G à la RATP ont commencé au dernier trimestre 2014, notamment au dépôt d’Aubervilliers, et décrit le Citaro G essayé comme diesel. Une fiche secondaire documente un seul exemplaire RATP, le n° 5413, mis en service en novembre 2014 ; ses données sont isolées dans une variante distincte. La fiche constructeur décrit le Citaro G actuellement commercialisé et reste séparée des véhicules historiques. Ces références ne caractérisent pas l’ensemble des 75 livraisons ; le prix individuel et la disponibilité d’occasion ne sont pas établis.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "mercedes-citaro-g-c2-ratp-5413-2014",
                    title: "Exemplaire RATP n° 5413 · Citaro G C2 (2014)",
                    lengthMeters: 18.13,
                    widthMeters: nil,
                    heightMeters: nil,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 33,
                    rangeKilometers: nil,
                    applicabilityNote: "Fiche secondaire de l’exemplaire mis en service en novembre 2014 (n° 5413, puis 242124/144138), avec 33 places assises et un moteur diesel OM470 de 360 ch, norme Euro VI et quatre portes. Elle indique aussi 126 places debout et deux emplacements UFR ; aucun total de capacité n’est repris ici. Son historique de dépôts cite Aubervilliers puis Thiais, sans rattachement à Bords de Marne. Ces caractéristiques ne sont pas généralisées aux autres Citaro G RATP.",
                    evidenceTitle: "TC Infos · fiche individuelle Citaro G C2 n° 5413 / 242124 / 144138 · relevé du 8 avril 2026",
                    evidenceURL: "https://tc-infos.fr/vehicule/5602"
                ),
                VehicleTechnicalVariant(
                    id: "mercedes-citaro-g-current-facts-2026",
                    title: "Fiche constructeur actuelle · Citaro G · consultée en 2026",
                    lengthMeters: 18.125,
                    widthMeters: 2.55,
                    heightMeters: 3.095,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: 163,
                    seatedCapacity: 42,
                    rangeKilometers: nil,
                    applicabilityNote: "Données de la fiche actuelle pour le Citaro G : elles décrivent des configurations de produit contemporaines et ne prouvent pas les dimensions ou l’aménagement exacts des véhicules livrés à la RATP en 2014–2015.",
                    evidenceTitle: "Mercedes-Benz Buses · Citaro · caractéristiques techniques",
                    evidenceURL: "https://www.mercedes-benz-bus.com/int/en/models/citaro/facts-citaro.pdf"
                )
            ],
            fleetTitle: "Bus & Car · livraison des Citaro G à la RATP à partir du T4 2014",
            fleetURL: "https://www.busetcar.com/bibliotheque-numerique/bus-et-car/968/technologie/le-citaro-joue-la-maxi-capacite-efficace-614126.php",
            marketAvailabilityNote: "L’article de 2015 documente le début des livraisons au réseau RATP et un premier dépôt à Aubervilliers. Il n’atteste pas d’affectation à Bords de Marne, de disponibilité actuelle à la vente ou d’un prix d’occasion vérifiable ; aucune offre n’est simulée."
        ),
        model(
            id: "mercedes-ecitaro-12m-catp-2024",
            manufacturer: "Mercedes-Benz",
            commercialName: "eCitaro électrique 12 m",
            vehicleClass: .standard,
            length: 12.135,
            width: 2.55,
            height: 3.48,
            energy: .electric,
            batteryCapacityKWh: 588,
            maximumPowerKilowatts: 240,
            maxCapacity: 90,
            seatedCapacity: 24,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2024,
            regionalEvidenceLabel: "Référence d’achat CATP · accord-cadre 2023–2027, lot 1 · flotte IDFM non attestée",
            referencePrice: 554_500,
            priceReferenceYear: 2024,
            priceEstimateNote: "Comparable de catégorie CATP 2024 : autobus électrique standard 12 m à charge lente, 554 500 € HT options moyennes comprises. Ce montant n’est pas le prix Mercedes-Benz de l’eCitaro et n’est pas une offre individuelle.",
            technicalTitle: "CATP · eCitaro électrique standard 12 m · accord-cadre 2023–2027, lot 1",
            technicalURL: "https://www.catp.fr/wp-content/uploads/2024/06/FP-MERCEDES-autobus-electrique-12m.pdf",
            technicalDataNote: "La fiche CATP de 2024 décrit la configuration de l’accord-cadre 2023–2027 : batterie NMC3 jusqu’à 588 kWh, 2 × 120 kW, 24 places assises et 90 voyageurs maximum. La gamme Mercedes-Benz actuelle décrit séparément des batteries NMC4 jusqu’à 666 kWh et une autonomie annoncée jusqu’à 600 km. La capacité actuelle de 88 voyageurs publiée par le constructeur n’est pas attribuée à la variante du marché CATP.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "mercedes-ecitaro-12m-catp-2023-27",
                    title: "CATP · NMC3 · accord-cadre 2023–2027 (2024)",
                    lengthMeters: 12.135,
                    widthMeters: 2.55,
                    heightMeters: 3.48,
                    batteryCapacityKWh: 588,
                    maximumPowerKilowatts: 240,
                    maximumCapacity: 90,
                    seatedCapacity: 24,
                    rangeKilometers: nil,
                    applicabilityNote: "Fiche produit CATP de l’accord-cadre 2023–2027, lot 1. Deux moteurs de 120 kW (240 kW cumulés), batterie NMC3 jusqu’à 588 kWh. La rampe UFR électrique et les autres aménagements cités figurent parmi les options possibles; aucune configuration IDFM précise n’est attestée.",
                    evidenceTitle: "CATP · fiche eCitaro 12 m, accord-cadre 2023–2027",
                    evidenceURL: "https://www.catp.fr/wp-content/uploads/2024/06/FP-MERCEDES-autobus-electrique-12m.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "mercedes-ecitaro-12m-nmc4-current",
                    title: "Gamme constructeur actuelle · NMC4 (consultée en 2026)",
                    lengthMeters: nil,
                    widthMeters: nil,
                    heightMeters: nil,
                    batteryCapacityKWh: 666,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: 88,
                    seatedCapacity: nil,
                    rangeKilometers: 600,
                    applicabilityNote: "La page constructeur actuelle annonce jusqu’à 666 kWh NMC4 et 600 km pour l’eCitaro non articulé. Ce sont des maxima de gamme actuels; ils ne remplacent pas la configuration de l’accord-cadre CATP 2023–2027 et ne décrivent aucun autobus IDFM identifié.",
                    evidenceTitle: "Mercedes-Benz Buses · gamme eCitaro, consultée en 2026",
                    evidenceURL: "https://www.mercedes-benz-bus.com/fr/fr/models/ecitaro.html"
                )
            ],
            fleetTitle: "CATP · référence d’achat Mercedes-Benz · exploitation IDFM non attestée",
            fleetURL: "https://www.catp.fr/bus_et_cars/autobus-standard-electrique-charge-lente-man-truck-bus-lions-city-12e-2",
            marketAvailabilityNote: "La CATP référence l’eCitaro 12 m à charge lente dans l’accord-cadre 2023–2027. Les sources consultées n’attestent aucune présence IDFM, affectation aux COB Bords de Marne, compatibilité avec leurs équipements ou offre actuelle à l’achat. Le comparable CATP de catégorie ne constitue pas un prix Mercedes-Benz individuel ; aucune offre n’est simulée."
        ),
        model(
            id: "heuliez-gx427-hybrid",
            manufacturer: "Heuliez Bus",
            commercialName: "GX 427 HYB · articulé diesel-hybride",
            vehicleClass: .articulated,
            length: 17.95,
            width: 2.55,
            height: 3.30,
            energy: .dieselHybrid,
            maxCapacity: nil,
            seatedCapacity: nil,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2014,
            regionalEvidenceLabel: "CNH rapporte 16 hybrides articulés livrés à la RATP · modèle non précisé",
            referencePrice: 430_000,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la CATP donne 293 400 € HT pour un autobus diesel standard 12 m. Le jeu ajoute 12,5 % pour le full-hybrid puis 30 % pour le gabarit articulé, et arrondit à 430 000 € en base 2024. La CATP ne publie pas de prix full-hybrid articulé ; ce n’est ni un prix individuel GX 427 ni une offre de vente.",
            technicalTitle: "Heuliez Bus · descriptif technique GX 427 HYB · version France, juin 2010",
            technicalURL: "https://wikibus.blob.core.windows.net/sources2568/Heuliez%20GX%20427%20HYB%20Descriptif%20technique.pdf",
            technicalDataNote: "Le descriptif constructeur donne 17,950 × 2,550 × 3,300 m en charge, un PTAC de 30 000 kg et un moteur diesel EEV Iveco Tector de 5,9 dm³ / 220 kW. L’architecture hybride en série associe une génératrice de 200 kW à un moteur électrique de traction de 160 kW continus (200 kW en crête) ; ces puissances décrivent des composants distincts et ne se cumulent pas en une puissance totale du bus. La fiche présente deux implantations à 3 portes (36 ou 47 places assises; 99 ou 113 debout) et deux à 4 portes (34 ou 35 assises; 120 ou 110 debout). Le nombre de places debout est indicatif et peut varier selon l’équipement. Aucune capacité totale générique ni configuration précise pour la RATP n’est déduite.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "heuliez-gx427-hybrid-3door-36-seat-2010",
                    title: "Heuliez · 3 portes · implantation 36 places assises (2010)",
                    lengthMeters: 17.95,
                    widthMeters: 2.55,
                    heightMeters: 3.30,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 36,
                    rangeKilometers: nil,
                    applicabilityNote: "Fiche Heuliez : 36 assises + conducteur, 99 places debout indicatives et un emplacement UFR. Cette implantation de gamme n’est pas attribuée aux véhicules livrés à la RATP.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 427 HYB, juin 2010",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2568/Heuliez%20GX%20427%20HYB%20Descriptif%20technique.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx427-hybrid-3door-47-seat-2010",
                    title: "Heuliez · 3 portes · implantation 47 places assises (2010)",
                    lengthMeters: 17.95,
                    widthMeters: 2.55,
                    heightMeters: 3.30,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 47,
                    rangeKilometers: nil,
                    applicabilityNote: "Fiche Heuliez : 47 assises + conducteur, 113 places debout indicatives et un emplacement UFR. Cette implantation de gamme n’est pas attribuée aux véhicules livrés à la RATP.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 427 HYB, juin 2010",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2568/Heuliez%20GX%20427%20HYB%20Descriptif%20technique.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx427-hybrid-4door-34-seat-2010",
                    title: "Heuliez · 4 portes · implantation 34 places assises (2010)",
                    lengthMeters: 17.95,
                    widthMeters: 2.55,
                    heightMeters: 3.30,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 34,
                    rangeKilometers: nil,
                    applicabilityNote: "Fiche Heuliez : 34 assises + conducteur, 120 places debout indicatives et un emplacement UFR. Cette implantation de gamme n’est pas attribuée aux véhicules livrés à la RATP.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 427 HYB, juin 2010",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2568/Heuliez%20GX%20427%20HYB%20Descriptif%20technique.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "heuliez-gx427-hybrid-4door-35-seat-2010",
                    title: "Heuliez · 4 portes · implantation 35 places assises (2010)",
                    lengthMeters: 17.95,
                    widthMeters: 2.55,
                    heightMeters: 3.30,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 35,
                    rangeKilometers: nil,
                    applicabilityNote: "Fiche Heuliez : 35 assises + conducteur, 110 places debout indicatives et un emplacement UFR. Cette implantation de gamme n’est pas attribuée aux véhicules livrés à la RATP.",
                    evidenceTitle: "Heuliez Bus · descriptif technique GX 427 HYB, juin 2010",
                    evidenceURL: "https://wikibus.blob.core.windows.net/sources2568/Heuliez%20GX%20427%20HYB%20Descriptif%20technique.pdf"
                )
            ],
            fleetTitle: "CNH Industrial · 16 autobus hybrides articulés livrés à la RATP · modèle non précisé",
            fleetURL: "https://media.cnh.com/emea/cnh/cnh-industrial-bus-brand--heuliez-bus--wins-a-major-tender-from-the-paris-public-transport-operator-/s/f5c5e73f-1d8e-47f0-aa59-e163ebc948a0",
            marketAvailabilityNote: "Le communiqué CNH de mai 2014 rapporte 16 autobus hybrides articulés livrés à la RATP, mais ne nomme pas leur modèle ; le même communiqué identifie le GX 427 HYB comme un modèle articulé de 18 m exploité à Dijon. Il ne prouve donc pas que les 16 véhicules RATP étaient des GX 427 HYB. Aucun prix, disponibilité d’occasion ou rattachement à un COB de Bords de Marne n’est documenté ; aucune offre n’est créée."
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
            regionalEvidenceLabel: "100 standards MAN au gaz en cours de livraison à Paris · 2020",
            referencePrice: 310_300,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère de jeu à faible confiance : faute de longueur ou de génération précisée pour le parc RATP, la base retenue est le coût moyen CATP 2024 d’un autobus GNV standard 12 m, 310 300 € HT. Ce n’est ni un prix MAN individuel ni une identification de la version livrée.",
            technicalTitle: "MAN · fiche technique Lion’s City 12 G",
            technicalURL: "https://www.man.eu/content/dam/man/countries/doc/bw-master/bus/datenblaetter/man-lions-city/en/man_lions_city_datenblatt_12-g_EN.pdf",
            technicalDataNote: "La fiche constructeur actuelle du Lion’s City 12 G décrit une variante de gamme. Elle ne précise pas la génération ni la configuration des 100 véhicules au gaz livrés à la RATP en 2020 ; ses dimensions et ses places assises ne leur sont donc pas attribuées.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "man-lions-city-12g-gnv-current-range",
                    title: "MAN · Lion’s City 12 G, fiche de gamme actuelle",
                    lengthMeters: 12.185,
                    widthMeters: 2.55,
                    heightMeters: 3.295,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: nil,
                    maximumCapacity: nil,
                    seatedCapacity: 37,
                    rangeKilometers: nil,
                    applicabilityNote: "La fiche MAN indique un moteur de 206 ou 235 kW, EfficientHybrid disponible en option et jusqu’à 37 places assises. Ces éléments décrivent la fiche actuelle et ne sont pas attribués aux 100 véhicules RATP livrés en 2020.",
                    evidenceTitle: "MAN · fiche technique Lion’s City 12 G",
                    evidenceURL: "https://www.man.eu/content/dam/man/countries/doc/bw-master/bus/datenblaetter/man-lions-city/en/man_lions_city_datenblatt_12-g_EN.pdf"
                )
            ],
            fleetTitle: "MAN Truck & Bus · 100 Lion’s City standards au gaz pour la RATP",
            fleetURL: "https://press.mantruckandbus.com/france/en-route-vers-lavenir-avec-les-autobus-urbains-man-au-gaz/",
            marketAvailabilityNote: "En octobre 2020, MAN indique que la livraison de 100 autobus standards Lion’s City au gaz pour les transports publics parisiens est en cours. Le communiqué ne précise ni génération, ni longueur, ni capacité voyageurs, ni hybridation, ni prix individuel ; il n’atteste pas de présence à Bords de Marne, de compatibilité avec ses dépôts ou de disponibilité actuelle à l’achat. Aucune offre n’est simulée."
        ),
        model(
            id: "man-lions-city-12c-gnv-hybrid",
            manufacturer: "MAN Truck & Bus",
            commercialName: "Lion’s City 12C mild-hybrid GNV",
            vehicleClass: .standard,
            length: 12.185,
            width: 2.55,
            height: 3.34,
            energy: .gnvHybrid,
            maxCapacity: 110,
            seatedCapacity: 27,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceYear: 2025,
            newOfferAvailableFromYear: 2024,
            regionalEvidenceLabel: "Produit référencé par la CATP · exploitation en Île-de-France non attestée",
            referencePrice: 324_600,
            priceReferenceYear: 2024,
            priceEstimateNote: "Repère CATP 2024 : autobus standard mild-hybrid GNV 12 m, options comprises, 324 600 € HT. Ce coût moyen de catégorie sert de base à une estimation de jeu indexée à 2 % par an ; ce n’est ni un prix d’offre MAN ni un prix de contrat individuel.",
            technicalTitle: "CATP · Catalogue Véhicules 2025, Lion’s City 12C mild-hybrid GNV",
            technicalURL: "https://www.catp.fr/wp-content/uploads/2025/07/2025-07-Catalogue-BusCars-1.pdf",
            technicalDataNote: "Le catalogue CATP 2025 donne 12,185 × 2,55 × 3,34 m, 27 places assises et jusqu’à 110 voyageurs. Il cite deux puissances (206 ou 243 kW) et des capacités de réservoir comprises entre 1 014 et 1 690 L selon configuration. Le produit référencé et sa fiche technique ne prouvent pas une mise en service en Île-de-France, une compatibilité avec un dépôt précis ni un prix MAN individuel.",
            technicalVariants: [
                VehicleTechnicalVariant(
                    id: "man-lions-city-12c-gnv-hybrid-206kw-2025",
                    title: "CATP · configuration moteur 206 kW (2025)",
                    lengthMeters: 12.185,
                    widthMeters: 2.55,
                    heightMeters: 3.34,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 206,
                    maximumCapacity: 110,
                    seatedCapacity: 27,
                    rangeKilometers: nil,
                    applicabilityNote: "Mild-hybrid GNV. Le catalogue CATP associe cette variante à un réservoir de 1 014 à 1 690 L selon configuration. Ces caractéristiques sont celles de la fiche d’achat publique, pas d’un autobus francilien identifié.",
                    evidenceTitle: "CATP · Catalogue Véhicules 2025, p. 33–34",
                    evidenceURL: "https://www.catp.fr/wp-content/uploads/2025/07/2025-07-Catalogue-BusCars-1.pdf"
                ),
                VehicleTechnicalVariant(
                    id: "man-lions-city-12c-gnv-hybrid-243kw-2025",
                    title: "CATP · configuration moteur 243 kW (2025)",
                    lengthMeters: 12.185,
                    widthMeters: 2.55,
                    heightMeters: 3.34,
                    batteryCapacityKWh: nil,
                    maximumPowerKilowatts: 243,
                    maximumCapacity: 110,
                    seatedCapacity: 27,
                    rangeKilometers: nil,
                    applicabilityNote: "Mild-hybrid GNV. Le catalogue CATP associe cette variante à un réservoir de 1 014 à 1 690 L selon configuration. Ces caractéristiques sont celles de la fiche d’achat publique, pas d’un autobus francilien identifié.",
                    evidenceTitle: "CATP · Catalogue Véhicules 2025, p. 33–34",
                    evidenceURL: "https://www.catp.fr/wp-content/uploads/2025/07/2025-07-Catalogue-BusCars-1.pdf"
                )
            ],
            additionalEvidenceTitle: "CATP · Étude comparative des motorisations 2024 · coût moyen mild-hybrid GNV",
            additionalEvidenceURL: "https://www.agir-transport.org/wp-content/uploads/2024/07/Etude-comparative-des-differentes-motorisations-de-bus-2024.pdf",
            fleetTitle: "CATP · Catalogue Véhicules 2025 · référence d’achat, pas preuve de flotte",
            fleetURL: "https://www.catp.fr/wp-content/uploads/2025/07/2025-07-Catalogue-BusCars-1.pdf"
        ),
        model(
            id: "man-lions-city-18c-gnv-catp-2024",
            manufacturer: "MAN Truck & Bus",
            commercialName: "Lion’s City 18C GNV",
            vehicleClass: .articulated,
            length: 18.060,
            width: 2.55,
            height: 3.34,
            energy: .gnv,
            maximumPowerKilowatts: 235,
            maxCapacity: 173,
            seatedCapacity: 41,
            firstYear: nil,
            lastYear: nil,
            regionalEvidenceLabel: "Référence d’achat CATP · exploitation en Île-de-France non attestée",
            referencePrice: 403_390,
            priceReferenceYear: 2024,
            priceEstimateNote: "Estimation de jeu à faible confiance : la fiche CATP ne publie pas de prix individuel pour le Lion’s City 18C GNV. La base est le coût moyen CATP 2024 d’un autobus GNV standard de 12 m, 310 300 € HT, augmenté du facteur de gabarit articulé de jeu de 30 %. Ce n’est ni un prix MAN ni une offre d’achat.",
            technicalTitle: "CATP · MAN Lion’s City 18C GNV, accord-cadre 2023–2032, lot 7",
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
