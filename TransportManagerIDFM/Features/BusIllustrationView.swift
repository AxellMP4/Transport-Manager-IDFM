import SwiftUI

/// Generic game artwork for a bus model. It deliberately avoids copying a
/// manufacturer body or operator livery when the exact vehicle variant is unknown.
struct BusIllustrationView: View {
    let model: VehicleMarketModel

    private var accent: Color {
        switch model.energy {
        case .diesel: Color(red: 0.79, green: 0.35, blue: 0.22)
        case .dieselHybrid: Color(red: 0.72, green: 0.49, blue: 0.20)
        case .gnv: Color(red: 0.23, green: 0.54, blue: 0.39)
        case .gnvHybrid: Color(red: 0.26, green: 0.56, blue: 0.47)
        case .electric: Color(red: 0.20, green: 0.47, blue: 0.76)
        }
    }

    private var bodySections: Int {
        guard model.vehicleClass == .articulated else { return 1 }
        return (model.lengthMeters ?? 18) >= 20 ? 3 : 2
    }

    private var doorCount: Int {
        model.doubleDoorCount ?? (model.vehicleClass == .midibus ? 2 : (model.vehicleClass == .articulated ? 4 : 3))
    }

    var body: some View {
        Canvas { context, size in
            let sx = size.width / 300
            let sy = size.height / 110
            context.scaleBy(x: sx, y: sy)

            let shell = Path(roundedRect: CGRect(x: 10, y: 24, width: 280, height: 48), cornerRadius: 9)
            context.fill(shell, with: .color(Color(nsColor: .controlBackgroundColor)))

            // Continuous lower belt gives the model a recognisable transit profile.
            let belt = Path(roundedRect: CGRect(x: 13, y: 58, width: 274, height: 10), cornerRadius: 4)
            context.fill(belt, with: .color(accent))

            let windshield = Path(roundedRect: CGRect(x: 18, y: 29, width: 25, height: 26), cornerRadius: 4)
            context.fill(windshield, with: .color(Color(red: 0.20, green: 0.28, blue: 0.36)))

            let windowStarts: [CGFloat] = bodySections == 1
                ? [51, 82, 113, 144, 175, 206, 237, 263]
                : (bodySections == 2 ? [51, 80, 109, 138, 181, 210, 239, 263] : [51, 78, 104, 130, 166, 192, 218, 244, 266])
            for (index, x) in windowStarts.enumerated() {
                let window = Path(roundedRect: CGRect(x: x, y: 30, width: index == windowStarts.count - 1 ? 18 : 24, height: 22), cornerRadius: 3)
                context.fill(window, with: .color(Color(red: 0.25, green: 0.35, blue: 0.43)))
            }

            if bodySections > 1 {
                let jointX: CGFloat = bodySections == 3 ? 158 : 155
                let joint = Path(roundedRect: CGRect(x: jointX, y: 25, width: 10, height: 45), cornerRadius: 2)
                context.fill(joint, with: .color(Color(nsColor: .windowBackgroundColor).opacity(0.85)))
                for rib in stride(from: 0, to: 3, by: 1) {
                    var ribPath = Path()
                    ribPath.move(to: CGPoint(x: jointX + 2 + CGFloat(rib) * 3, y: 27))
                    ribPath.addLine(to: CGPoint(x: jointX + 2 + CGFloat(rib) * 3, y: 68))
                    context.stroke(ribPath, with: .color(Color.secondary.opacity(0.5)), lineWidth: 1)
                }
            }

            // Doors are cues for vehicle scale, not a claim about an undocumented variant.
            let doorPositions: [CGFloat] = switch doorCount {
            case ...2: [215]
            case 3: [190, 253]
            default: [130, 190, 250]
            }
            for x in doorPositions {
                let door = Path(roundedRect: CGRect(x: x, y: 28, width: 18, height: 39), cornerRadius: 2)
                context.stroke(door, with: .color(accent.opacity(0.9)), lineWidth: 2)
            }

            for x: CGFloat in [65, 230] {
                let wheel = Path(ellipseIn: CGRect(x: x, y: 62, width: 26, height: 26))
                context.fill(wheel, with: .color(Color(red: 0.12, green: 0.14, blue: 0.16)))
                let hub = Path(ellipseIn: CGRect(x: x + 7, y: 69, width: 12, height: 12))
                context.fill(hub, with: .color(Color(nsColor: .controlBackgroundColor)))
            }

            let headlight = Path(roundedRect: CGRect(x: 282, y: 49, width: 6, height: 8), cornerRadius: 2)
            context.fill(headlight, with: .color(Color(red: 0.98, green: 0.78, blue: 0.35)))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Illustration de jeu d’un bus \(model.displayName), \(model.vehicleClass.title.lowercased()), énergie \(model.energy.title)")
        .accessibilityAddTraits(.isImage)
        .accessibilityIdentifier("bus-illustration-\(model.id)")
    }
}
