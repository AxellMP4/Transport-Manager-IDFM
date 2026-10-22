import SwiftUI

struct CareerProgressionView: View {
    @ObservedObject var simulation: SimulationEngine

    var body: some View {
        Group {
            if let session = simulation.session {
                progressionContent(for: session)
            } else {
                ContentUnavailableView(
                    "Aucune carrière",
                    systemImage: "flag",
                    description: Text("Démarrez une partie pour suivre votre progression.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func progressionContent(for session: SimulationSession) -> some View {
        let snapshot = CareerProgressionCatalog.snapshot(for: session)

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Niveau de carrière") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(snapshot.rank.title)
                                    .font(.title2.weight(.semibold))
                                Text("Niveau \(snapshot.rank.rawValue) · \(snapshot.totalPoints) points de progression")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "medal")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }

                        if let nextRank = snapshot.nextRank {
                            ProgressView(value: snapshot.progressToNextRank)
                                .accessibilityLabel("Progression vers le niveau \(nextRank.rawValue), \(snapshot.totalPoints) points sur \(nextRank.minimumPoints)")
                            Text("\(snapshot.pointsTowardNextRank) / \(snapshot.pointsNeededForNextRank) points vers « \(nextRank.title) »")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Rang maximal atteint", systemImage: "checkmark.seal")
                                .font(.subheadline.weight(.medium))
                        }

                        Text("Les points et les niveaux sont des règles de progression du jeu. Ils ne modifient ni la trésorerie, ni les factures, ni les contrats.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Jalons") {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(snapshot.milestones) { milestone in
                            milestoneRow(milestone)
                            if milestone.id != snapshot.milestones.last?.id {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Historique des réussites") {
                    if snapshot.history.isEmpty {
                        Text("Vos jalons validés apparaîtront ici.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(snapshot.history) { achievement in
                                if let milestone = snapshot.milestones.first(where: { $0.id == achievement.id }) {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                            .accessibilityHidden(true)
                                        Text(milestone.title)
                                            .font(.subheadline.weight(.medium))
                                        Spacer(minLength: 8)
                                        Text("+\(achievement.points) pts")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(achievement.achievedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 26)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func milestoneRow(_ milestone: CareerMilestoneProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: statusSymbol(for: milestone))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(milestone.title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Text("+\(milestone.points) pts")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(milestone.criterion)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(statusText(for: milestone))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                if milestone.isEarned, let achievedAt = milestone.achievedAt {
                    Text(achievedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !milestone.isEarned {
                ProgressView(value: milestone.progress)
                    .controlSize(.small)
                    .accessibilityLabel("Avancement de \(milestone.title), \(milestone.currentValue) sur \(milestone.targetValue)")
            }
        }
        .padding(.vertical, 2)
    }

    private func statusSymbol(for milestone: CareerMilestoneProgress) -> String {
        if milestone.isEarned { return "checkmark.circle.fill" }
        if !milestone.isAvailable { return "lock.circle" }
        return "circle"
    }

    private func statusText(for milestone: CareerMilestoneProgress) -> String {
        if milestone.isEarned { return "Jalon validé" }
        if !milestone.isAvailable {
            let progress = "\(milestone.currentValue)/\(milestone.targetValue)"
            if milestone.criterionIsSatisfied {
                return "Critère atteint · rang requis : \(milestone.requiredRank.title)"
            }
            return "Rang requis : \(milestone.requiredRank.title) · \(progress)"
        }
        return "Avancement · \(milestone.currentValue)/\(milestone.targetValue)"
    }
}
