import Foundation

enum DepotAssignmentEvidenceStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case confirmedByPlayer
    case corroborated
    case needsReview
    case historical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .confirmedByPlayer: "Confirmée par le joueur"
        case .corroborated: "Corroborée par plusieurs sources"
        case .needsReview: "À vérifier"
        case .historical: "Historique"
        }
    }

    var isOperationallyUsable: Bool {
        self == .confirmedByPlayer || self == .corroborated
    }
}

struct DepotLineAssignment: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let scenarioID: String
    let depotID: String
    let routeID: String
    let contractID: String
    let gtfsVersionID: String
    let contractVersionID: String
    let evidenceStatus: DepotAssignmentEvidenceStatus
    let evidenceTitle: String
    let evidenceURL: String
    let additionalEvidenceURLs: [String]
    let evidenceDate: Date?
    let evidenceDateIsVerified: Bool?
    let notes: String
    let recordedAt: Date

    var hasValidEvidence: Bool {
        let title = evidenceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, Self.isWebURL(evidenceURL) else { return false }
        guard additionalEvidenceURLs.allSatisfy(Self.isWebURL) else { return false }
        return evidenceStatus != .corroborated || !additionalEvidenceURLs.isEmpty
    }

    var isOperationallyUsable: Bool {
        evidenceStatus.isOperationallyUsable && evidenceDate != nil && evidenceDateIsVerified == true && hasValidEvidence
    }

    var evidenceDateSummary: String {
        guard evidenceDateIsVerified == true, let evidenceDate else {
            return evidenceDate == nil ? "date de source inconnue" : "date de source à revérifier"
        }
        return evidenceDate.formatted(date: .abbreviated, time: .omitted)
    }

    var scopeKey: String {
        [scenarioID, gtfsVersionID, contractVersionID, contractID, routeID, depotID]
            .joined(separator: "|")
    }

    private static func isWebURL(_ value: String) -> Bool {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let host = components.host, !host.isEmpty else { return false }
        return true
    }
}

struct DepotLineAssignmentPrefill: Hashable, Identifiable, Sendable {
    let depotID: String
    let routeID: String
    let evidenceTitle: String
    let evidenceURL: String
    let additionalEvidenceURLs: [String]
    let evidenceDate: Date?
    let notes: String

    var id: String { "\(depotID)|\(routeID)" }
}

enum DepotAssignmentStore {
    private static let filename = "depot-line-assignments.json"

    static func load() throws -> [DepotLineAssignment] {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DepotLineAssignment].self, from: Data(contentsOf: url))
    }

    static func save(_ assignments: [DepotLineAssignment]) throws {
        let url = try fileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(assignments.sorted {
            if $0.scenarioID != $1.scenarioID { return $0.scenarioID < $1.scenarioID }
            if $0.routeID != $1.routeID { return $0.routeID < $1.routeID }
            if $0.depotID != $1.depotID { return $0.depotID < $1.depotID }
            return $0.id < $1.id
        }).write(to: url, options: .atomic)
    }

    private static func fileURL() throws -> URL {
        try NetworkVersionStore.rootDirectory().appending(path: filename)
    }
}
