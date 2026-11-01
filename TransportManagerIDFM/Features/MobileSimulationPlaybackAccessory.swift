import SwiftUI

#if os(iOS)

@available(iOS 26.0, *)
struct MobileSimulationPlaybackAccessory: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    let simulatedAt: Date
    let speed: SimulationSpeed
    let isRunning: Bool
    let onTogglePlayback: () -> Void
    let onAdvanceToNextEvent: () -> Void
    let onSetSpeed: (SimulationSpeed) -> Void

    var body: some View {
        Group {
            if placement == .inline {
                compactContent
            } else {
                expandedContent
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var compactContent: some View {
        HStack(spacing: 12) {
            status
            Spacer(minLength: 8)
            playbackButton
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 48)
    }

    private var expandedContent: some View {
        HStack(spacing: 12) {
            status
                .layoutPriority(1)
            Spacer(minLength: 4)
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    speedMenu
                    advanceButton
                    playbackButton
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 60)
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(simulatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Label(isRunning ? "Simulation en cours" : "En pause", systemImage: isRunning ? "play.circle.fill" : "pause.circle")
                .font(.caption)
                .foregroundStyle(isRunning ? Color.accentColor : Color.secondary)
                .lineLimit(1)
        }
    }

    private var speedMenu: some View {
        Menu {
            ForEach(SimulationSpeed.allCases.filter { $0 != .paused }) { option in
                Button {
                    onSetSpeed(option)
                } label: {
                    if option == speed {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            Image(systemName: "speedometer")
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Vitesse de simulation : \(speed.title)")
    }

    private var advanceButton: some View {
        Button(action: onAdvanceToNextEvent) {
            Image(systemName: "forward.end.fill")
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Avancer au prochain événement")
    }

    private var playbackButton: some View {
        Button(action: onTogglePlayback) {
            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(Color.accentColor)
        .accessibilityLabel(isRunning ? "Mettre en pause et sauvegarder" : "Reprendre la carrière")
    }
}
#endif
