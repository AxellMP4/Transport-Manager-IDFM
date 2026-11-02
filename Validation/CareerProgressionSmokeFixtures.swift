import Foundation

enum CareerProgressionSmokeBusStatus: String, Codable {
    case atDepot
    case inDelivery
}

struct CareerProgressionSmokeBus: Codable {
    let status: CareerProgressionSmokeBusStatus
    let deliveryAt: Date
}

struct CareerProgressionSmokeMachinist: Codable {
    let hiredAt: Date
}

struct CareerProgressionSmokeReport: Codable {
    let dateKey: Int
    let servedDepartureCount: Int
    let missedDepartureCount: Int
    let completedTripCount: Int
    let contractCompletionRate: Double?
}

struct CareerProgressionSmokeEnergyProject: Codable {
    let completedAt: Date?
}

struct CareerProgressionSmokeInvoice: Codable {
    let paidAt: Date?
}

typealias PurchasedBus = CareerProgressionSmokeBus
typealias Machinist = CareerProgressionSmokeMachinist
typealias DailyOperationsReport = CareerProgressionSmokeReport
typealias DepotEnergyInfrastructureProject = CareerProgressionSmokeEnergyProject
typealias SimulationInvoice = CareerProgressionSmokeInvoice

enum CareerProgressionSmokeEventKind: Codable {
    case vehicleDelivered(vehicleID: String)
    case busServiceCompleted(
        tripID: String,
        vehicleID: String,
        stopID: String,
        stopName: String,
        latitude: Double,
        longitude: Double
    )
    case busServiceCompletedAtClosedStop(
        tripID: String,
        vehicleID: String,
        routeID: String,
        stopID: String,
        stopName: String,
        latitude: Double,
        longitude: Double,
        strandedPassengerCount: Int
    )
    case busServiceCompletedAtClosedStopWithPassengerRedirect(
        tripID: String,
        vehicleID: String,
        routeID: String,
        stopID: String,
        stopName: String,
        latitude: Double,
        longitude: Double,
        passengerCount: Int,
        replacementStopID: String,
        replacementStopName: String
    )
    case serviceCompleted(tripID: String)
    case dailySettlement(dateKey: Int)
    case vehicleRepairCompleted(incidentID: String)
    case workshopExpansionCompleted
    case workshopExpansionCompletedAtDepot(depotID: String)
    case depotEnergyInfrastructureCompleted(projectID: String, infrastructure: String)
}

struct CareerProgressionSmokeEvent: Codable {
    let simulatedAt: Date
    let kind: CareerProgressionSmokeEventKind
}

typealias SimulationEventKind = CareerProgressionSmokeEventKind
typealias SimulationEvent = CareerProgressionSmokeEvent

struct SimulationSession: Codable {
    var simulatedAt: Date
    var eventHistory: [CareerProgressionSmokeEvent]
    var pendingEvents: [CareerProgressionSmokeEvent]
    var ownedBuses: [CareerProgressionSmokeBus]?
    var machinists: [CareerProgressionSmokeMachinist]?
    var dailyOperationsReports: [CareerProgressionSmokeReport]?
    var depotEnergyInfrastructureProjects: [CareerProgressionSmokeEnergyProject]?
    var invoices: [CareerProgressionSmokeInvoice]?
    var careerProgression: CareerProgressionState? = nil
}

enum GTFSServiceDate {
    static let parisTimeZone = TimeZone(identifier: "Europe/Paris")!

    static func calendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
