import Foundation

enum PassengerValidationType: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case navigoSubscription
    case singleTicket
    case reducedFare
    case freeTravel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .navigoSubscription: "Navigo / abonnement"
        case .singleTicket: "Ticket unitaire"
        case .reducedFare: "Tarif réduit"
        case .freeTravel: "Gratuité"
        }
    }
}

struct PassengerValidationBreakdown: Codable, Hashable, Sendable {
    let boardedCount: Int
    private let navigoSubscriptionCount: Int
    private let singleTicketCount: Int
    private let reducedFareCount: Int
    private let freeTravelCount: Int

    init(
        boardedCount: Int,
        navigoSubscriptionCount: Int,
        singleTicketCount: Int,
        reducedFareCount: Int,
        freeTravelCount: Int
    ) {
        self.boardedCount = max(0, boardedCount)
        var remaining = self.boardedCount
        self.navigoSubscriptionCount = min(remaining, max(0, navigoSubscriptionCount))
        remaining -= self.navigoSubscriptionCount
        self.singleTicketCount = min(remaining, max(0, singleTicketCount))
        remaining -= self.singleTicketCount
        self.reducedFareCount = min(remaining, max(0, reducedFareCount))
        remaining -= self.reducedFareCount
        self.freeTravelCount = min(remaining, max(0, freeTravelCount))
    }

    var validatedCount: Int {
        PassengerValidationType.allCases.reduce(0) { $0 + validationCount(for: $1) }
    }

    var validationRate: Double? {
        guard boardedCount > 0 else { return nil }
        return Double(validatedCount) / Double(boardedCount)
    }

    var unvalidatedCount: Int {
        max(0, boardedCount - validatedCount)
    }

    func validationCount(for type: PassengerValidationType) -> Int {
        switch type {
        case .navigoSubscription: navigoSubscriptionCount
        case .singleTicket: singleTicketCount
        case .reducedFare: reducedFareCount
        case .freeTravel: freeTravelCount
        }
    }
}

enum PassengerValidationRules {
    static let validationRateBasisPoints = 9_000
    static let navigoShareBasisPoints = 7_000
    static let singleTicketShareBasisPoints = 2_200
    static let reducedFareShareBasisPoints = 600
    static let freeTravelShareBasisPoints = 200
    static let estimatedRulesLabel = "Estimations de jeu, non calibrées sur des validations réelles"

    private static var titleMixTotalBasisPoints: Int {
        navigoShareBasisPoints
            + singleTicketShareBasisPoints
            + reducedFareShareBasisPoints
            + freeTravelShareBasisPoints
    }

    static func resolve(
        boardedCount: Int,
        tripID: String,
        routeID: String,
        stopID: String,
        stopSequence: Int,
        randomSeed: UInt64
    ) -> PassengerValidationBreakdown {
        let boardings = max(0, boardedCount)
        var countsByType = [PassengerValidationType: Int]()

        for passengerOrdinal in 0..<boardings {
            let validationRoll = stableHash(
                randomSeed: randomSeed,
                tripID: tripID,
                routeID: routeID,
                stopID: stopID,
                stopSequence: stopSequence,
                passengerOrdinal: passengerOrdinal,
                salt: 0x7661_6c69_6461_7465
            ) % 10_000

            guard validationRoll < UInt64(validationRateBasisPoints) else {
                continue
            }

            let titleRoll = Int(stableHash(
                randomSeed: randomSeed,
                tripID: tripID,
                routeID: routeID,
                stopID: stopID,
                stopSequence: stopSequence,
                passengerOrdinal: passengerOrdinal,
                salt: 0x7469_746c_655f_6d69
            ) % UInt64(titleMixTotalBasisPoints))

            let type: PassengerValidationType
            switch titleRoll {
            case 0..<navigoShareBasisPoints:
                type = .navigoSubscription
            case navigoShareBasisPoints..<(navigoShareBasisPoints + singleTicketShareBasisPoints):
                type = .singleTicket
            case (navigoShareBasisPoints + singleTicketShareBasisPoints)..<(
                navigoShareBasisPoints + singleTicketShareBasisPoints + reducedFareShareBasisPoints
            ):
                type = .reducedFare
            default:
                type = .freeTravel
            }
            countsByType[type, default: 0] += 1
        }

        return PassengerValidationBreakdown(
            boardedCount: boardings,
            navigoSubscriptionCount: countsByType[.navigoSubscription, default: 0],
            singleTicketCount: countsByType[.singleTicket, default: 0],
            reducedFareCount: countsByType[.reducedFare, default: 0],
            freeTravelCount: countsByType[.freeTravel, default: 0]
        )
    }

    private static func stableHash(
        randomSeed: UInt64,
        tripID: String,
        routeID: String,
        stopID: String,
        stopSequence: Int,
        passengerOrdinal: Int,
        salt: UInt64
    ) -> UInt64 {
        var hash = randomSeed ^ salt ^ 14_695_981_039_346_656_037
        let key = "\(tripID)|\(routeID)|\(stopID)|\(stopSequence)|\(passengerOrdinal)"
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        hash ^= hash >> 33
        hash &*= 0xff51_afd7_ed55_8ccd
        hash ^= hash >> 33
        hash &*= 0xc4ce_b9fe_1a85_ec53
        hash ^= hash >> 33
        return hash
    }
}

enum PassengerLoadStatus: String, Codable, Hashable, Identifiable, Sendable {
    case normal
    case high
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Charge normale"
        case .high: "Bus très chargé"
        case .full: "Bus complet"
        }
    }
}

struct PassengerLoadPresentation: Hashable, Sendable {
    let passengerCount: Int
    let capacity: Int
    let capacityIsEstimated: Bool

    init(passengerCount: Int, capacity: Int, capacityIsEstimated: Bool) {
        self.passengerCount = max(0, passengerCount)
        self.capacity = max(1, capacity)
        self.capacityIsEstimated = capacityIsEstimated
    }

    var occupancyPercent: Int {
        Int((Double(passengerCount) / Double(capacity) * 100).rounded())
    }

    var progressFraction: Double {
        min(1, max(0, Double(passengerCount) / Double(capacity)))
    }

    var status: PassengerLoadStatus {
        if occupancyPercent >= 100 { return .full }
        if occupancyPercent >= 80 { return .high }
        return .normal
    }
}
