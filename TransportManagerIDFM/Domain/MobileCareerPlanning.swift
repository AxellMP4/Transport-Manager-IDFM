import Foundation

struct MobileCareerLineChoice: Hashable, Sendable {
    let id: String
    let label: String
    let evidenceStatus: DepotLineEvidenceStatus
    let routeIDs: [String]
}

enum MobileCareerLineSelection {
    static func routeIDs(from choices: [MobileCareerLineChoice], selectedLineIDs: Set<String>) -> Set<String> {
        Set(choices.lazy
            .filter { choice in
                choice.evidenceStatus == .confirmed
                    || (choice.evidenceStatus != .planned && selectedLineIDs.contains(choice.id))
            }
            .flatMap(\.routeIDs))
    }
}
