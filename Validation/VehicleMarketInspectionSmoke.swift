import Foundation

@main
struct VehicleMarketInspectionSmoke {
    static func main() {
        let unknownDepotEnergy = DepotEnergyEvidence(
            status: .unknown,
            note: "L’installation réelle de ce dépôt n’est pas documentée.",
            dateLabel: nil,
            sources: []
        )
        let legacyReadiness = DepotEnergyReadiness.legacyUnverified(unknownDepotEnergy)
        let legacyCompatibility = VehicleMarketDepotCompatibilityRules.presentation(for: legacyReadiness)
        precondition(legacyReadiness.isReady, "Une sauvegarde ancienne conserve le comportement d’achat compatible avec son schéma.")
        precondition(legacyCompatibility.status.contains("Achat autorisé"))
        precondition(legacyCompatibility.status.contains("non vérifié"))
        precondition(legacyCompatibility.detail == unknownDepotEnergy.note)

        guard let hydrogenReference = VehicleMarketCatalog.model(id: "solaris-new-urbino-12-hydrogen-idfm") else {
            fatalError("Le modèle Solaris de référence doit rester consultable.")
        }
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "SOLARIS"))
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "hydrogene"))
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "12"))
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "  Solaris  "))
        precondition(!VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "articulé"))

        let requiredInstallation = DepotEnergyReadiness.requiresInstallation(unknownDepotEnergy)
        let blockedCompatibility = VehicleMarketDepotCompatibilityRules.presentation(for: requiredInstallation)
        precondition(!requiredInstallation.isReady, "Une carrière récente doit installer l’équipement requis avant l’achat.")
        precondition(blockedCompatibility.status == requiredInstallation.statusTitle, "Les autres états de compatibilité gardent leur libellé existant.")

        guard let usedOffer = VehicleMarketCatalog.offers(for: 2026).first(where: {
            $0.id == "irisbus-citelis-12-diesel-used-2012-2026"
        }) else {
            fatalError("L’offre d’occasion témoin doit exister pour la carrière 2026.")
        }

        let originalAskingPrice = usedOffer.askingPrice
        let firstReport = VehicleMarketInspectionRules.estimate(for: usedOffer, gameYear: 2026)
        guard let firstReport else {
            fatalError("Une offre d’occasion doit permettre une inspection estimée avant achat.")
        }

        precondition(firstReport.offerID == usedOffer.id)
        precondition(firstReport.estimatedConditionPercent == usedOffer.conditionPercent)
        precondition(firstReport.findings.contains { $0.id == "condition-remediation" })
        precondition(firstReport.findings.contains { $0.id == "high-mileage-wear" })
        precondition(firstReport.findings.contains { $0.id == "age-related-check" })
        precondition(firstReport.estimatedRemediationCostEuro > 0)
        precondition(
            firstReport.estimatedRemediationCostEuro == firstReport.findings.reduce(0) { $0 + $1.estimatedCostEuro },
            "Le devis estimé doit correspondre à la somme des interventions estimées."
        )
        precondition(
            VehicleMarketInspectionRules.estimate(for: usedOffer, gameYear: 2026) == firstReport,
            "L’estimation doit être reproductible pour une même offre et une même année."
        )
        precondition(
            usedOffer.askingPrice == originalAskingPrice,
            "L’inspection ne doit ni acheter le bus ni modifier son prix d’offre."
        )

        let cleanUsedOffer = VehicleMarketOffer(
            id: "clean-used-bus",
            modelID: usedOffer.modelID,
            condition: .used,
            vehicleYear: 2020,
            odometerKilometers: 80_000,
            conditionPercent: 100,
            estimatedPriceLow: 100_000,
            estimatedPriceHigh: 120_000,
            askingPrice: 110_000,
            estimateConfidence: .low,
            deliveryDays: 2,
            initialStock: 1,
            priceBasis: "Estimation de jeu"
        )
        guard let cleanReport = VehicleMarketInspectionRules.estimate(for: cleanUsedOffer, gameYear: 2026) else {
            fatalError("L’offre propre d’occasion doit rester inspectable.")
        }
        precondition(cleanReport.estimatedConditionPercent == 100)
        precondition(cleanReport.findings.isEmpty)
        precondition(cleanReport.estimatedRemediationCostEuro == 0)

        guard let newOffer = VehicleMarketCatalog.offers(for: 2026).first(where: { $0.condition == .new }) else {
            fatalError("Le marché doit contenir une offre neuve témoin.")
        }
        precondition(
            VehicleMarketInspectionRules.estimate(for: newOffer, gameYear: 2026) == nil,
            "L’inspection de remise en état concerne les offres d’occasion uniquement."
        )

        print("Vehicle market used-offer inspection smoke passed.")
    }
}
