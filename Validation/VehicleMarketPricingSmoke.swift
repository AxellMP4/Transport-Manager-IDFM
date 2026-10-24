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

        guard let scaniaCitywide = VehicleMarketCatalog.model(id: "scania-citywide-18-gnv-ratp"),
              let scaniaTechnicalVariant = scaniaCitywide.technicalVariants?.first(where: {
                  $0.id == "scania-citywide-lf-gaz-articule-range-2021"
              }) else {
            fatalError("La gamme Scania Citywide GNV doit garder sa fiche technique distincte de la série RATP.")
        }
        precondition(scaniaCitywide.lengthMeters == 18, "La série RATP est documentée comme articulée de 18 m.")
        precondition(
            scaniaCitywide.maximumCapacity == nil && scaniaCitywide.seatedCapacity == nil,
            "La capacité voyageurs exacte des 101 Scania RATP n’est pas publiée."
        )
        precondition(
            scaniaTechnicalVariant.widthMeters == 2.55 && scaniaTechnicalVariant.heightMeters == 3.17,
            "La variante technique doit conserver la largeur et la hauteur gaz publiées par Scania."
        )
        precondition(
            scaniaTechnicalVariant.maximumPowerKilowatts == nil
                && scaniaTechnicalVariant.maximumCapacity == nil
                && scaniaTechnicalVariant.applicabilityNote.contains("206 ou 250 kW")
                && scaniaTechnicalVariant.applicabilityNote.contains("1 260 à 1 875 litres"),
            "Les options et plages de la gamme ne doivent pas être transformées en équipement individuel."
        )
        precondition(
            scaniaCitywide.fleetEvidenceURL == "https://www.scania.com/fr/fr/home/about-scania/newsroom/news/2022/2/101-citywide-gaz-livres-scania-france-ratp.html"
                && scaniaCitywide.technicalEvidenceURL == "https://www.scania.com/content/dam/www/market/ch/products/buses-and-coaches/pdfs/citywide-lf/Scania-Citywide-LF-FR.pdf",
            "Les preuves du parc RATP et de la gamme constructeur doivent rester accessibles séparément."
        )
        precondition(
            VehicleMarketCatalog.offers(for: 2026).allSatisfy { $0.modelID != scaniaCitywide.id },
            "L’ajout de la fiche technique ne doit pas créer une offre d’achat non attestée."
        )

        print("Validation de l’indexation tarifaire du marché réussie.")
    }
}
