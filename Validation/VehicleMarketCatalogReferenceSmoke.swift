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

        print("PASS : le Crealis 18 m est catalogué comme référence CATP sourcée, sans offre régionale inventée.")
    }
}
