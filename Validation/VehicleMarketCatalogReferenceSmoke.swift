import Foundation

@main
struct VehicleMarketCatalogReferenceSmoke {
    static func main() {
        let modelID = "iveco-crealis-18m-gnv-mild-hybrid-catp"
        guard let model = VehicleMarketCatalog.model(id: modelID),
              let technicalVariant = model.technicalVariants?.first(where: {
                  $0.id == "iveco-crealis-18m-gnv-mild-hybrid-catp-lot-16"
              }) else {
            fatalError("La référence CATP du Crealis articulé 18 m doit exister dans le catalogue technique.")
        }

        precondition(model.vehicleClass == .articulated && model.energy == .gnvHybrid)
        precondition(
            model.lengthMeters == 18.480
                && model.widthMeters == 2.50
                && model.heightMeters == 3.30
                && model.maximumPowerKilowatts == 265
                && model.maximumCapacity == 169
                && model.seatedCapacity == 43,
            "Le catalogue doit reprendre les caractéristiques publiées par CATP."
        )
        precondition(
            technicalVariant.fuelTankCapacitiesLiters == [1_280, 1_610, 1_940]
                && technicalVariant.batteryCapacityKWh == 1
                && technicalVariant.maximumPowerKilowatts == 265
                && technicalVariant.turningRadiusBetweenWallsMeters == 11.701
                && technicalVariant.turningRadiusBetweenCurbsMeters == 9.891
                && technicalVariant.applicabilityNote.contains("48 V")
                && technicalVariant.applicabilityNote.contains("25 kW")
                && technicalVariant.applicabilityNote.contains("35 kW"),
            "La variante CATP doit conserver les volumes, l’hybridation et les rayons publiés."
        )
        precondition(
            model.technicalEvidenceURL == "https://www.catp.fr/wp-content/uploads/2024/06/FP-IVECO-autobus-GNV-Mild-Hybrid-18m-BHNS.pdf"
                && technicalVariant.evidenceURL == model.technicalEvidenceURL,
            "La fiche technique détaillée CATP doit rester accessible."
        )
        precondition(
            model.regionalEvidenceYear == nil
                && model.estimatedNewPriceReference == nil
                && model.marketAvailabilityNote != nil
                && !VehicleMarketCatalog.marketableModels.contains(where: { $0.id == modelID }),
            "Une référence CATP ne prouve ni l’exploitation régionale ni un prix de vente."
        )
        for year in [2024, 2026] {
            precondition(
                !VehicleMarketCatalog.offers(for: year).contains(where: { $0.modelID == modelID }),
                "Le Crealis ne doit pas devenir une offre sans preuve régionale et prix unitaire."
            )
        }

        let crosswayID = "iveco-crossway-line-gnc-my2024-reference"
        guard let crossway = VehicleMarketCatalog.model(id: crosswayID),
              let crosswayVariants = crossway.technicalVariants,
              crosswayVariants.count == 2 else {
            fatalError("La référence Iveco Crossway doit distinguer les variantes constructeur 12 m et 13 m.")
        }
        let crossway12m = crosswayVariants.first { $0.id == "iveco-crossway-line-gnc-12m-my2024" }
        let crossway13m = crosswayVariants.first { $0.id == "iveco-crossway-line-gnc-13m-my2024" }
        precondition(
            crossway.regionalEvidenceYear == 2024
                && crossway.fleetEvidenceURL == "https://www.iledefrance-mobilites.fr/medias/portail-idfm/Zn0R95bWFbowe7qq_RAA_158-1.pdf"
                && crossway.fleetEvidenceTitle.contains("16 autocars IVECO Crossway")
                && crossway.displayEnergyTitle.contains("non établie"),
            "La preuve IDFM doit rester distincte de la motorisation régionale inconnue."
        )
        precondition(
            crossway12m?.lengthMeters == 12.097
                && crossway12m?.maximumPowerKilowatts == 265
                && crossway12m?.maximumCapacity == 55
                && crossway12m?.fuelTankCapacitiesLiters == [1_260]
                && crossway13m?.lengthMeters == 12.962
                && crossway13m?.maximumPowerKilowatts == 265
                && crossway13m?.maximumCapacity == 61
                && crossway13m?.fuelTankCapacitiesLiters == [1_260]
                && crosswayVariants.allSatisfy { $0.widthMeters == 2.55 && $0.heightMeters == 3.46 },
            "Les variantes constructeur doivent conserver les valeurs de la fiche MY2024."
        )
        precondition(
            crossway.technicalEvidenceURL == "https://www.ivecobus.com/france/-/media/IvecoBus/France/pdf/schede-tecniche/crossway/FR_CRW_NF_LINE_CNG_MY2024.pdf?rev=-1"
                && crossway.marketAvailabilityNote != nil
                && !VehicleMarketCatalog.marketableModels.contains(where: { $0.id == crosswayID }),
            "La fiche Crossway doit identifier sa source technique et rester non achetable."
        )
        for year in [2024, 2026] {
            precondition(
                !VehicleMarketCatalog.offers(for: year).contains(where: { $0.modelID == crosswayID }),
                "Aucune offre Crossway ne doit être inventée sans prix ni configuration de flotte attestés."
            )
        }

        print("PASS : les références Crealis et Crossway sont sourcées sans inventer de variante régionale ou d’offre.")
    }
}
