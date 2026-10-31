import SwiftUI

struct PassengerLoadGaugeView: View {
    let passengerCount: Int
    let capacity: Int
    let capacityIsEstimated: Bool
    var compact = false

    private var presentation: PassengerLoadPresentation {
        PassengerLoadPresentation(
            passengerCount: passengerCount,
            capacity: capacity,
            capacityIsEstimated: capacityIsEstimated
        )
    }

    private var statusColor: Color {
        switch presentation.status {
        case .normal: .green
        case .high: .orange
        case .full: .red
        }
    }

    private var accessibleValue: String {
        "\(presentation.passengerCount) sur \(presentation.capacity) voyageurs, \(presentation.occupancyPercent) %, \(presentation.status.title)\(capacityIsEstimated ? ", capacité estimée" : "")"
    }

    var body: some View {
        Group {
            if compact {
                Text("\(presentation.occupancyPercent) %")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.14), in: Capsule())
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("À bord · \(presentation.passengerCount)/\(presentation.capacity)")
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(presentation.occupancyPercent) %")
                            .monospacedDigit()
                            .fontWeight(.semibold)
                    }
                    .font(.caption2)

                    ProgressView(value: presentation.progressFraction)
                        .tint(statusColor)
                        .controlSize(.small)

                    Text("\(presentation.status.title)\(capacityIsEstimated ? " · capacité estimée" : "")")
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Jauge de remplissage du bus")
        .accessibilityValue(accessibleValue)
    }
}

struct PassengerVehicleMapMarkerView: View {
    let shellNumber: String
    let status: PurchasedBusStatus
    let mapColor: Color
    let passengerCount: Int
    let capacity: Int
    let capacityIsEstimated: Bool
    let action: () -> Void

    private var symbol: String {
        if status == .beingTowed { return "truck.box.fill" }
        if status == .outOfService { return "wrench.and.screwdriver.fill" }
        if status == .inMaintenance { return "wrench.and.screwdriver" }
        return "bus.fill"
    }

    private var occupancyPercent: Int {
        PassengerLoadPresentation(
            passengerCount: passengerCount,
            capacity: capacity,
            capacityIsEstimated: capacityIsEstimated
        ).occupancyPercent
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                Text(shellNumber)
                    .font(.caption2.monospaced().weight(.bold))
                    .foregroundStyle(.primary)
                PassengerLoadGaugeView(
                    passengerCount: passengerCount,
                    capacity: capacity,
                    capacityIsEstimated: capacityIsEstimated,
                    compact: true
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(mapColor, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ouvrir le bus \(shellNumber), \(status.title), \(occupancyPercent) % de remplissage")
    }
}
