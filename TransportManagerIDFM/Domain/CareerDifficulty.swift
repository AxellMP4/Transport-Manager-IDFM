import Foundation

enum CareerDifficulty: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case accompanied
    case standard
    case demanding

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accompanied: "Accompagnée"
        case .standard: "Standard"
        case .demanding: "Exigeante"
        }
    }

    var initialCapitalBeforeStock: Int {
        switch self {
        case .accompanied: 1_250_000
        case .standard: 1_000_000
        case .demanding: 800_000
        }
    }

    var incidentRiskMultiplier: Double {
        switch self {
        case .accompanied: 0.5
        case .standard: 1
        case .demanding: 2
        }
    }

    var breakdownFrequencyRawValue: String {
        switch self {
        case .accompanied: "reduced"
        case .standard: "standard"
        case .demanding: "increased"
        }
    }

    var trafficDisruptionFrequencyRawValue: String { breakdownFrequencyRawValue }

    var formattedInitialCapital: String {
        initialCapitalBeforeStock.formatted(
            .currency(code: "EUR").locale(Locale(identifier: "fr_FR"))
        )
    }

    var riskMultiplierLabel: String {
        switch self {
        case .accompanied: "×0,5"
        case .standard: "×1"
        case .demanding: "×2"
        }
    }

    var explanation: String {
        "\(formattedInitialCapital) avant le stock de départ · risques de panne et de circulation \(riskMultiplierLabel) · règle de jeu."
    }

    func startingCashBalance(afterStockCostEuro stockCostEuro: Int) -> Int {
        initialCapitalBeforeStock - stockCostEuro
    }
}
