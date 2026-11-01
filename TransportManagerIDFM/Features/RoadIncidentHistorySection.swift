import SwiftUI

struct RoadIncidentHistorySection: View {
    let detours: [SimulatedRouteDetour]
    let operatedRoutes: [GTFSRouteSummary]
    let simulatedAt: Date
    let actionIsBlocked: Bool
    let onDeclareAccident: (String) -> Void

    var body: some View {
        Section("Perturbations routières") {
            if operatedRoutes.isEmpty {
                Text("Aucune ligne exploitée n’est disponible pour déclarer une perturbation.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Menu {
                    ForEach(operatedRoutes) { route in
                        Button {
                            onDeclareAccident(route.routeID)
                        } label: {
                            if let secondaryName = route.secondaryName {
                                Text("\(route.displayName) · \(secondaryName)")
                            } else {
                                Text(route.displayName)
                            }
                        }
                    }
                } label: {
                    Label("Déclarer un accident routier…", systemImage: "car.rear.fill")
                }
                .disabled(actionIsBlocked)
                .accessibilityHint("Ouvre le choix d’une ligne exploitée puis le préparateur de déviation simulée.")
                .help("Déclarer une perturbation de jeu. Aucun accident réel n’est signalé.")
            }

            Text("Déclaration manuelle : choisis ensuite le segment, un détour routier, la durée, le retard et le message voyageurs. Les événements aléatoires ne sont pas activés.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if detours.isEmpty {
                Text("Aucun incident routier simulé dans cette carrière.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(detours) { detour in
                    incidentRow(detour)
                }
            }
        }
    }

    private func incidentRow(_ detour: SimulatedRouteDetour) -> some View {
        let cause = detour.cause ?? .other
        let status: String
        let statusColor: Color
        if detour.endedAt != nil || simulatedAt >= detour.scheduledEndAt {
            status = "Terminée"
            statusColor = .secondary
        } else if detour.startsAt > simulatedAt {
            status = "Planifiée"
            statusColor = .orange
        } else {
            status = "En cours"
            statusColor = .red
        }

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(cause.title, systemImage: cause.symbol)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Text(status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }
            Text("Ligne \(detour.routeID) · \(detour.fromStopName) → \(detour.toStopName)")
                .font(.callout)
            Text("\(detour.startsAt.formatted(date: .abbreviated, time: .shortened)) – \(detour.scheduledEndAt.formatted(date: .abbreviated, time: .shortened)) · +\(Int((detour.additionalTravelSeconds / 60).rounded())) min estimées")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let message = detour.passengerInformationMessage {
                Label(message, systemImage: "text.bubble")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
