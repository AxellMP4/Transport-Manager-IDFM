import SwiftUI
#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
#elseif os(iOS)
import UIKit
typealias PlatformColor = UIColor
#endif

#if !MOBILE_CLOUD_RESTORE_SMOKE
@main
struct TransportManagerIDFMApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            OperationsDashboardView()
                .tint(Color(red: 0.04, green: 0.48, blue: 0.40))
            #else
            OperationsDashboardView()
                .frame(minWidth: 1_180, minHeight: 760)
                .tint(Color(red: 0.04, green: 0.48, blue: 0.40))
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 1_420, height: 900)
        #endif
    }
}
#endif

struct CareerRestorePresentation: Equatable, Sendable {
    let statusMessage: String
    let statusSymbol: String
    let isRetryEnabled: Bool
    let isPending: Bool
    let canStartNewCareer: Bool
    let canImportSave: Bool

    init(statusMessage: String, isSyncing: Bool, hasConflict: Bool) {
        self.statusMessage = statusMessage
        statusSymbol = hasConflict ? "exclamationmark.icloud" : "icloud"
        isRetryEnabled = !isSyncing
        isPending = isSyncing || statusMessage == "iCloud non vérifié"
        canStartNewCareer = !isPending
        canImportSave = !isPending
    }
}

enum MobileDashboardTab: String, CaseIterable, Hashable, Identifiable, Sendable {
    case map
    case courses
    case fleet
    case reports
    case network

    var id: Self { self }

    var title: String {
        switch self {
        case .map: "Carte"
        case .courses: "Courses"
        case .fleet: "Parc"
        case .reports: "Rapports"
        case .network: "Réseau"
        }
    }

    var systemImage: String {
        switch self {
        case .map: "map.fill"
        case .courses: "tram.fill"
        case .fleet: "bus.fill"
        case .reports: "chart.bar.fill"
        case .network: "point.topleft.down.to.point.bottomright.curvepath"
        }
    }

    var workspaceKeys: [String] {
        switch self {
        case .map: ["network"]
        case .courses: ["assignments"]
        case .fleet: ["fleet", "staff", "depots"]
        case .reports: ["reports", "incidents"]
        case .network: ["lines", "coursesMotifs", "sources"]
        }
    }

    var defaultWorkspaceKey: String {
        switch self {
        case .map: "network"
        case .courses: "assignments"
        case .fleet: "fleet"
        case .reports: "reports"
        case .network: "lines"
        }
    }

    static func containing(workspaceKey: String) -> Self {
        allCases.first { $0.workspaceKeys.contains(workspaceKey) } ?? .map
    }
}

struct MobileDashboardWorkspaceSelection: Equatable, Sendable {
    private(set) var selectedTab: MobileDashboardTab
    private var workspaceKeysByTab: [MobileDashboardTab: String]

    init() {
        selectedTab = .map
        workspaceKeysByTab = Dictionary(
            uniqueKeysWithValues: MobileDashboardTab.allCases.map { ($0, $0.defaultWorkspaceKey) }
        )
    }

    mutating func selectTab(_ tab: MobileDashboardTab) {
        selectedTab = tab
    }

    mutating func selectWorkspace(workspaceKey: String) {
        guard let tab = MobileDashboardTab.allCases.first(where: { $0.workspaceKeys.contains(workspaceKey) }) else {
            return
        }
        workspaceKeysByTab[tab] = workspaceKey
        selectedTab = tab
    }

    func selectedWorkspaceKey(for tab: MobileDashboardTab) -> String {
        workspaceKeysByTab[tab] ?? tab.defaultWorkspaceKey
    }
}

enum PlatformColors {
    #if os(macOS)
    static let windowBackground = Color(platformColor: .windowBackgroundColor)
    static let controlBackground = Color(platformColor: .controlBackgroundColor)
    #elseif os(iOS)
    static let windowBackground = Color(platformColor: .systemBackground)
    static let controlBackground = Color(platformColor: .secondarySystemBackground)
    #endif
}

extension Color {
    init(platformColor: PlatformColor) {
        self.init(platformColor)
    }
}

extension View {
    @ViewBuilder
    func platformBorderedMenuStyle() -> some View {
        #if os(macOS)
        self.menuStyle(.borderedButton)
        #else
        self.menuStyle(.automatic)
        #endif
    }

    @ViewBuilder
    func platformNavigationSubtitle(_ subtitle: String) -> some View {
        #if os(macOS)
        self.navigationSubtitle(subtitle)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformInsetListStyle() -> some View {
        #if os(macOS)
        self.listStyle(.inset(alternatesRowBackgrounds: false))
        #else
        self.listStyle(.insetGrouped)
        #endif
    }
}
