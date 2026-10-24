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

        guard let eCitaro = VehicleMarketCatalog.model(id: "mercedes-ecitaro-12m-catp-2024"),
              let catpVariant = eCitaro.technicalVariants?.first(where: {
                  $0.id == "mercedes-ecitaro-12m-catp-2023-27"
              }),
              let currentVariant = eCitaro.technicalVariants?.first(where: {
                  $0.id == "mercedes-ecitaro-12m-nmc4-current"
              }) else {
            fatalError("L’eCitaro doit distinguer la variante CATP 2023–2027 de la gamme constructeur actuelle.")
        }
        precondition(
            catpVariant.maximumCapacity == 90
                && catpVariant.seatedCapacity == 24
                && catpVariant.batteryCapacityKWh == 588
                && catpVariant.maximumPowerKilowatts == 240,
            "La variante de l’accord-cadre CATP doit conserver ses caractéristiques propres."
        )
        precondition(
            currentVariant.maximumCapacity == 88
                && currentVariant.batteryCapacityKWh == 666
                && currentVariant.rangeKilometers == 600,
            "Les capacités de la gamme actuelle ne doivent pas être attribuées à l’eCitaro CATP antérieur."
        )
        precondition(
            eCitaro.marketAvailabilityNote?.contains("aucune présence IDFM") == true
                && VehicleMarketCatalog.offers(for: 2026).allSatisfy { $0.modelID != eCitaro.id },
            "La référence CATP seule ne prouve pas une flotte régionale ni une offre à acheter."
        )

        guard let manParis = VehicleMarketCatalog.model(id: "man-lions-city-standard-gnv-paris"),
              let manCurrentVariant = manParis.technicalVariants?.first(where: {
                  $0.id == "man-lions-city-12g-gnv-current-range"
              }) else {
            fatalError("La variante technique MAN actuelle doit être visible séparément de la série parisienne de 2020.")
        }
        precondition(
            manParis.lengthMeters == nil
                && manParis.maximumCapacity == nil
                && manParis.seatedCapacity == nil,
            "Les caractéristiques précises de la série RATP 2020 ne sont pas publiées par MAN."
        )
        precondition(
            manParis.regionalEvidenceLabel?.contains("en cours de livraison") == true,
            "Le communiqué d’octobre 2020 décrit les 100 bus parisiens comme étant en cours de livraison."
        )
        precondition(
            manCurrentVariant.lengthMeters == 12.185
                && manCurrentVariant.widthMeters == 2.55
                && manCurrentVariant.heightMeters == 3.295
                && manCurrentVariant.seatedCapacity == 37
                && manCurrentVariant.maximumPowerKilowatts == nil
                && manCurrentVariant.applicabilityNote.contains("206 ou 235 kW")
                && manCurrentVariant.applicabilityNote.contains("ne sont pas attribués aux 100 véhicules RATP"),
            "La fiche de gamme doit garder ses options moteur et ne pas les attribuer aux autobus parisiens."
        )
        precondition(
            manCurrentVariant.evidenceURL == "https://www.man.eu/content/dam/man/countries/doc/bw-master/bus/datenblaetter/man-lions-city/en/man_lions_city_datenblatt_12-g_EN.pdf"
                && VehicleMarketCatalog.offers(for: 2026).allSatisfy { $0.modelID != manParis.id },
            "La variante MAN doit citer le constructeur sans créer d’offre individuelle."
        )

        guard let ebuscoRBus = VehicleMarketCatalog.model(id: "ebusco-electric-standard-2015"),
              let ebusco22Variant = ebuscoRBus.technicalVariants?.first(where: {
                  $0.id == "ebusco-22-12m-range-2020"
              }) else {
            fatalError("La variante Ebusco 2.2 doit rester distincte de l’essai R’Bus dont le sous-modèle est inconnu.")
        }
        precondition(
            ebuscoRBus.lengthMeters == 12
                && ebuscoRBus.maximumCapacity == 95
                && ebuscoRBus.seatedCapacity == nil,
            "La fiche R’Bus doit conserver ses données IDFM de 2015 sans les remplacer par celles du 2.2."
        )
        precondition(
            ebusco22Variant.lengthMeters == 12
                && ebusco22Variant.widthMeters == 2.55
                && ebusco22Variant.heightMeters == 3.35
                && ebusco22Variant.maximumCapacity == 90
                && ebusco22Variant.seatedCapacity == 41
                && ebusco22Variant.maximumPowerKilowatts == 270
                && ebusco22Variant.batteryCapacityKWh == nil
                && ebusco22Variant.applicabilityNote.contains("363 ou 423 kWh")
                && ebusco22Variant.applicabilityNote.contains("pas attribuées à l’essai R’Bus de 2015"),
            "La brochure Ebusco doit conserver ses options de batterie et ne pas les attribuer au bus essayé en 2015."
        )
        precondition(
            ebusco22Variant.evidenceURL == "https://www.ebusco.com/wp-content/uploads/Ebusco-2.2-Brochure-2020-FR-Online.pdf"
                && VehicleMarketCatalog.offers(for: 2026).allSatisfy { $0.modelID != ebuscoRBus.id },
            "La variante Ebusco doit citer la brochure constructeur sans créer d’offre individuelle."
        )

        print("Validation de l’indexation tarifaire du marché réussie.")
    }
}
