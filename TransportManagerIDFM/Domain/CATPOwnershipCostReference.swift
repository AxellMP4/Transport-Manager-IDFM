import Foundation

struct CATPOwnershipCostReference: Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let acquisitionCostEuro: Int
    let energyCostEuro: Int
    let preventiveMaintenanceCostEuro: Int

    var totalCostEuro: Int {
        acquisitionCostEuro + energyCostEuro + preventiveMaintenanceCostEuro
    }

    var costPerKilometerEuro: Double {
        Double(totalCostEuro) / Double(Self.horizonKilometers)
    }

    static let studyYear = 2024
    static let horizonYears = 15
    static let annualKilometers = 40_000
    static let horizonKilometers = horizonYears * annualKilometers
    static let sourceURL = URL(string: "https://www.agir-transport.org/wp-content/uploads/2024/07/Etude-comparative-des-differentes-motorisations-de-bus-2024.pdf")!

    static let all: [CATPOwnershipCostReference] = [
        CATPOwnershipCostReference(
            id: "diesel-euro-vi",
            title: "Diesel Euro VI step E",
            acquisitionCostEuro: 293_400,
            energyCostEuro: 329_500,
            preventiveMaintenanceCostEuro: 168_000
        ),
        CATPOwnershipCostReference(
            id: "mild-hybrid-diesel",
            title: "Mild-hybrid gazole",
            acquisitionCostEuro: 299_500,
            energyCostEuro: 275_500,
            preventiveMaintenanceCostEuro: 174_000
        ),
        CATPOwnershipCostReference(
            id: "gnv",
            title: "GNV",
            acquisitionCostEuro: 310_300,
            energyCostEuro: 230_200,
            preventiveMaintenanceCostEuro: 210_000
        ),
        CATPOwnershipCostReference(
            id: "mild-hybrid-gnv",
            title: "Mild-hybrid GNV",
            acquisitionCostEuro: 324_600,
            energyCostEuro: 206_800,
            preventiveMaintenanceCostEuro: 198_000
        ),
        CATPOwnershipCostReference(
            id: "electric-battery-slow-charge",
            title: "Électrique à batterie · charge lente",
            acquisitionCostEuro: 554_500,
            energyCostEuro: 148_000,
            preventiveMaintenanceCostEuro: 270_000
        )
    ]
}
