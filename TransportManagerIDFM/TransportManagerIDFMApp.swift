import SwiftUI
#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
#elseif os(iOS)
import UIKit
typealias PlatformColor = UIColor
#endif

@main
struct TransportManagerIDFMApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            MobileOperationsView()
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

#if os(iOS)
@MainActor
private struct MobileOperationsView: View {
    @StateObject private var simulation = SimulationEngine()

    var body: some View {
        TabView {
            NavigationStack {
                careerOverview
                    .navigationTitle("Carrière")
            }
            .tabItem { Label("Carrière", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack {
                networkOverview
                    .navigationTitle("Réseau")
            }
            .tabItem { Label("Réseau", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }

            NavigationStack {
                fleetOverview
                    .navigationTitle("Parc")
            }
            .tabItem { Label("Parc", systemImage: "bus") }
        }
    }

    private var careerOverview: some View {
        Group {
            if let session = simulation.session {
                List {
                    Section("Partie en cours") {
                        LabeledContent("Dépôt", value: session.activeDepotID ?? session.depotID)
                        LabeledContent("Date simulée", value: session.simulatedAt.formatted(date: .long, time: .shortened))
                        LabeledContent("Lignes exploitées", value: "\(session.effectiveOperatedRouteIDs(for: session.effectiveActiveDepotID).count)")
                        LabeledContent("Trésorerie", value: (session.cashBalance ?? 0).formatted(.currency(code: "EUR")))
                    }

                    Section {
                        Button(simulation.isRunning ? "Mettre en pause et sauvegarder" : "Reprendre la carrière") {
                            if simulation.isRunning {
                                simulation.pauseAndSave()
                            } else {
                                simulation.resume()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(simulation.session == nil)
                        if let lastSavedAt = simulation.lastSavedAt {
                            Label("Sauvegardée \(lastSavedAt.formatted(date: .omitted, time: .shortened))", systemImage: "checkmark.icloud")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let recoveryNotice = simulation.recoveryNotice {
                        Section("Récupération") { Text(recoveryNotice).font(.footnote) }
                    }
                    if let errorMessage = simulation.errorMessage {
                        Section("Sauvegarde") { Text(errorMessage).font(.footnote).foregroundStyle(.red) }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Aucune carrière sauvegardée",
                    systemImage: "externaldrive",
                    description: Text("Créez une carrière sur votre Mac. Elle apparaîtra ici lorsque la synchronisation iCloud sera configurée.")
                )
            }
        }
    }

    private var networkOverview: some View {
        Group {
            if let session = simulation.session {
                List {
                    Section("Réseau épinglé par cette carrière") {
                        let routeIDs = session.effectiveOperatedRouteIDs(for: session.effectiveActiveDepotID).sorted()
                        LabeledContent("Lignes", value: "\(routeIDs.count)")
                        ForEach(routeIDs.prefix(40), id: \.self) { routeID in
                            Text(routeID).font(.body.monospaced())
                        }
                        if routeIDs.count > 40 {
                            Text("Et \(routeIDs.count - 40) autres lignes")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Section("Version") {
                        Text(String(describing: session.networkVersions))
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                }
            } else {
                ContentUnavailableView("Réseau indisponible", systemImage: "point.3.connected.trianglepath.dotted")
            }
        }
    }

    private var fleetOverview: some View {
        Group {
            if let session = simulation.session {
                List {
                    Section("Parc") {
                        LabeledContent("Bus possédés", value: "\(session.ownedBuses?.count ?? 0)")
                        LabeledContent("Machinistes", value: "\(session.machinists?.count ?? 0)")
                    }
                    ForEach(session.ownedBuses ?? []) { bus in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bus.coquilleNumber ?? bus.id)
                                .font(.headline)
                            Text(VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                ContentUnavailableView("Parc vide", systemImage: "bus")
            }
        }
    }
}
#endif
