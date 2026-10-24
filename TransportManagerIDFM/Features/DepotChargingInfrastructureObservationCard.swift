import SwiftUI

struct DepotChargingInfrastructureObservationCard: View {
    let observation: DepotChargingInfrastructureObservation

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(observation.periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(observation.statusLabel, systemImage: "bolt.badge.clock")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.orange)

                ForEach(observation.metricLabels, id: \.self) { metric in
                    Label(metric, systemImage: "number.circle")
                        .font(.callout)
                }

                Text(observation.operationalNote)
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

                Link(observation.orderTitle, destination: observation.orderURL)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Bornes · dossier réglementaire", systemImage: "ev.charger")
                .font(.headline)
        }
    }
}
