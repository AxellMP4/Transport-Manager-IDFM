import SwiftUI

@main
struct TransportManagerIDFMApp: App {
    var body: some Scene {
        WindowGroup {
            OperationsDashboardView()
                .frame(minWidth: 1_180, minHeight: 760)
                .tint(Color(red: 0.04, green: 0.48, blue: 0.40))
        }
        .defaultSize(width: 1_420, height: 900)
    }
}
