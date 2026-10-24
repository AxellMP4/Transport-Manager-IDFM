import SwiftUI

struct CATPOwnershipCostBenchmarkView: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Repères moyens de la CATP pour des autobus standards de 12 m. Ils décrivent des catégories de motorisation, pas le coût réel d’un modèle ou d’une offre du jeu.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(CATPOwnershipCostReference.all) { reference in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(reference.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 8)
                            Text("\(reference.costPerKilometerEuro.formatted(.currency(code: "EUR").precision(.fractionLength(2)))) / véhicule-km")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .accessibilityLabel("\(reference.costPerKilometerEuro.formatted(.currency(code: "EUR").precision(.fractionLength(2)))) par véhicule-kilomètre")
                        }

                        Text("Achat \(currency(reference.acquisitionCostEuro)) · énergie \(currency(reference.energyCostEuro)) · entretien préventif \(currency(reference.preventiveMaintenanceCostEuro))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Total \(currency(reference.totalCostEuro)) HT sur 15 ans et 600 000 km")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 9))
                }

                Text("Base CATP 2024 : 40 000 km par an, options comprises. Les coûts d’infrastructure et d’adaptation des ateliers sont exclus; l’entretien électrique inclut le renouvellement de batteries. Ces valeurs utilisent les prix d’énergie de l’étude et ne sont pas indexées sur l’année de la partie.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Link("Étude comparative des motorisations · CATP, édition 2024", destination: CATPOwnershipCostReference.sourceURL)
                    .font(.caption)
            }
            .padding(.top, 9)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text("Comparer les motorisations avec les repères CATP")
                    .font(.subheadline.weight(.semibold))
                Text("Autobus standard 12 m · coût total sur 15 ans")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(13)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 11))
    }

    private func currency(_ value: Int) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}
