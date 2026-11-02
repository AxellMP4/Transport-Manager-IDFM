import Foundation

enum MachinistServiceRuleKind: String, Equatable {
    case betweenCourses
    case serviceBlock
    case recoveryRest
}

struct MachinistServiceRuleRow: Equatable, Identifiable {
    let id: MachinistServiceRuleKind
    let title: String
    let limit: String
    let explanation: String
    let symbol: String
}

enum MachinistServiceRuleSummary {
    static func rows(
        maximumGap: TimeInterval,
        maximumServiceBlock: TimeInterval,
        minimumRest: TimeInterval
    ) -> [MachinistServiceRuleRow] {
        [
            MachinistServiceRuleRow(
                id: .betweenCourses,
                title: "Battement entre courses",
                limit: "\(formattedDuration(maximumGap)) max",
                explanation: "Espacement maximal entre deux courses du même bloc.",
                symbol: "arrow.left.and.right"
            ),
            MachinistServiceRuleRow(
                id: .serviceBlock,
                title: "Présence dans un bloc",
                limit: "\(formattedDuration(maximumServiceBlock)) max",
                explanation: "Durée entre la première course et la dernière du bloc.",
                symbol: "clock"
            ),
            MachinistServiceRuleRow(
                id: .recoveryRest,
                title: "Repos avant reprise",
                limit: "\(formattedDuration(minimumRest)) min",
                explanation: "Attendre après un service ou une formation avant une nouvelle affectation.",
                symbol: "moon.zzz"
            )
        ]
    }

    private static func formattedDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int((duration / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            return "\(minutes) min"
        }
        if minutes == 0 {
            return "\(hours) h"
        }
        return "\(hours) h \(minutes) min"
    }
}
