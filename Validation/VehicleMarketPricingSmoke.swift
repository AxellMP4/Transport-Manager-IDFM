import Foundation

@main
struct VehicleMarketPricingSmoke {
    static func main() {
        guard let urbanway = VehicleMarketCatalog.model(id: "iveco-urbanway-12-gnv") else {
            fatalError("Le modèle Urbanway GNV utilisé par l’offre de référence doit exister.")
        }

        let yearBeforeReference = VehicleMarketCatalog.estimatedNewPrice(for: urbanway, gameYear: 2023)
        let referenceYear = VehicleMarketCatalog.estimatedNewPrice(for: urbanway, gameYear: 2024)
        let yearAfterReference = VehicleMarketCatalog.estimatedNewPrice(for: urbanway, gameYear: 2025)

        precondition(referenceYear == 310_000, "Le repère CATP 2024 doit conserver son arrondi actuel.")
        precondition(yearBeforeReference == 305_000, "Le prix estimé avant l’année de référence doit refléter une année d’indexation inverse.")
        precondition(yearAfterReference == 315_000, "Le prix estimé après l’année de référence doit continuer à refléter l’indexation annuelle.")

        let historicalUsedOffers = VehicleMarketCatalog.offers(for: 2023).filter { $0.condition == .used }
        precondition(!historicalUsedOffers.isEmpty, "Le marché historique doit garder les offres d’occasion déjà existantes.")
        precondition(
            historicalUsedOffers.allSatisfy { $0.vehicleYear <= 2023 },
            "Une carrière 2023 ne doit pas proposer un bus d’occasion construit après 2023."
        )

        print("Validation de l’indexation tarifaire du marché réussie.")
    }
}
