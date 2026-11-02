import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("ÉCHEC : \(message)\n", stderr)
        exit(1)
    }
}

private let expected: [(CareerDifficulty, Int, Double, String)] = [
    (.accompanied, 1_250_000, 0.5, "reduced"),
    (.standard, 1_000_000, 1.0, "standard"),
    (.demanding, 800_000, 2.0, "increased")
]

@main
private struct CareerDifficultySmoke {
    static func main() throws {
        for (difficulty, capital, risk, frequency) in expected {
            expect(difficulty.initialCapitalBeforeStock == capital, "capital initial \(difficulty.rawValue)")
            expect(difficulty.incidentRiskMultiplier == risk, "multiplicateur de risque \(difficulty.rawValue)")
            expect(difficulty.breakdownFrequencyRawValue == frequency, "fréquence de panne \(difficulty.rawValue)")
            expect(difficulty.trafficDisruptionFrequencyRawValue == frequency, "fréquence routière \(difficulty.rawValue)")
            expect(difficulty.startingCashBalance(afterStockCostEuro: 42_750) == capital - 42_750, "débit unique du stock \(difficulty.rawValue)")

            let encoded = try JSONEncoder().encode(difficulty)
            let decoded = try JSONDecoder().decode(CareerDifficulty.self, from: encoded)
            expect(decoded == difficulty, "aller-retour JSON \(difficulty.rawValue)")
        }

        expect(CareerDifficulty(rawValue: "standard") == .standard, "profil historique par défaut")
        print("PASS : 3 profils, capitaux avant stock, fréquences, solde et codage JSON.")
    }
}
