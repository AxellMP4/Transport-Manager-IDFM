import SwiftUI

struct DepotFacilityObservationCard: View {
    let observation: DepotFacilityObservation

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(observation.periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(observation.metricLabels, id: \.self) { metric in
                    Label(metric, systemImage: "number.circle")
                        .font(.callout)
                }

                Text(observation.articulatedBusLimitation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(observation.limitationNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Link(observation.sourceTitle, destination: observation.sourceURL)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Repère historique sur le site", systemImage: "building.2.crop.circle")
                .font(.headline)
        }
    }
}
