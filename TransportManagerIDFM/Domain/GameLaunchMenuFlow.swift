import Foundation

struct SavedCareerSummary: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let scenarioID: String
    let depotID: String
    let createdAt: Date
    let updatedAt: Date
    let simulatedAt: Date
    let cashBalance: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case scenarioID
        case depotID
        case createdAt
        case updatedAt
        case simulatedAt
        case cashBalance
    }

    init(
        id: String,
        scenarioID: String,
        depotID: String,
        createdAt: Date,
        updatedAt: Date,
        simulatedAt: Date,
        cashBalance: Int?
    ) {
        self.id = id
        self.scenarioID = scenarioID
        self.depotID = depotID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.simulatedAt = simulatedAt
        self.cashBalance = cashBalance
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        scenarioID = try values.decode(String.self, forKey: .scenarioID)
        depotID = try values.decode(String.self, forKey: .depotID)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
        simulatedAt = try values.decode(Date.self, forKey: .simulatedAt)
        cashBalance = try values.decodeIfPresent(Int.self, forKey: .cashBalance)
    }
}

struct ImportedCareerIdentity: Equatable, Sendable {
    let id: String
    let sourceID: String
    let wasCopied: Bool
}

struct CareerImportResult: Equatable, Sendable {
    let importedID: String
    let sourceID: String
    let createdCopy: Bool
}

enum GameLaunchMenuAction: Hashable, Sendable {
    case continueCareer
    case newCareer
    case chooseScenario
    case importCareer
    case options
}

enum GameLaunchMenuDestination: Equatable, Sendable {
    case welcome
    case resumeCareer
    case careerSetup
    case scenarioPicker
    case importPicker
    case options
}

enum GameLaunchMenuFlow {
    static func destination(
        for action: GameLaunchMenuAction,
        hasActiveCareer: Bool
    ) -> GameLaunchMenuDestination {
        switch action {
        case .continueCareer:
            hasActiveCareer ? .resumeCareer : .welcome
        case .newCareer:
            .careerSetup
        case .chooseScenario:
            .scenarioPicker
        case .importCareer:
            .importPicker
        case .options:
            .options
        }
    }

    static func newestFirst(_ careers: [SavedCareerSummary]) -> [SavedCareerSummary] {
        careers.sorted {
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.id.localizedStandardCompare($1.id) == .orderedAscending
        }
    }

    static func importIdentity(
        sourceID: String,
        existingIDs: Set<String>,
        makeCopyID: () -> String = { UUID().uuidString }
    ) -> ImportedCareerIdentity {
        guard existingIDs.contains(sourceID) else {
            return ImportedCareerIdentity(id: sourceID, sourceID: sourceID, wasCopied: false)
        }

        var copyID = makeCopyID()
        while existingIDs.contains(copyID) || copyID == sourceID {
            copyID = makeCopyID()
        }
        return ImportedCareerIdentity(id: copyID, sourceID: sourceID, wasCopied: true)
    }
}
