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
    @StateObject private var library = NetworkLibrary()
    @StateObject private var cloudSync = CloudCareerSyncManager()
    @AppStorage("transportManager.mobileSelectedDepotID") private var selectedDepotID = "saint-maur"
    @State private var careerStartMoment = Date.now
    @State private var selectedCandidateLineIDs = Set<String>()
    @State private var isPreparingTimetable = false
    @State private var careerStartError: String?
    @State private var mobileActionMessage: String?

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
        .task {
            await library.seedBundledIDFMSnapshotsIfNeeded()
            await cloudSync.synchronize(with: simulation, library: library)
            if let activeDepotID = simulation.session?.effectiveActiveDepotID {
                selectedDepotID = activeDepotID
            } else if !playableDepots.contains(where: { $0.id == selectedDepotID }) {
                selectedDepotID = playableDepots.first?.id ?? "saint-maur"
            }
            await library.loadBusRoutes()
            await library.loadBusStops()
            await library.loadServiceCalendars()
            await library.loadActiveRouteGeometries()
            await library.loadActiveContracts()
            await library.loadActiveLineReferences()
            await library.loadActiveLineDocuments()
        }
        .onChange(of: simulation.lastSavedAt) { _, savedAt in
            guard savedAt != nil else { return }
            cloudSync.scheduleSynchronization(with: simulation, library: library)
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
                        Menu {
                            ForEach(SimulationSpeed.allCases.filter { $0 != .paused }) { speed in
                                Button(speed.title) { simulation.setSpeed(speed) }
                            }
                        } label: {
                            Label("Vitesse · \(session.speed.title)", systemImage: "speedometer")
                        }
                        Button {
                            if simulation.isRunning { simulation.pause() }
                            _ = simulation.advanceToNextEvent()
                        } label: {
                            Label("Avancer au prochain événement", systemImage: "forward.end")
                        }
                        if simulation.lastSavedAt != nil {
                            Label("Sauvegardée sur cet iPhone", systemImage: "checkmark.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Label(cloudSync.statusMessage, systemImage: cloudSync.hasConflict ? "exclamationmark.icloud" : "icloud")
                            .font(.footnote)
                            .foregroundStyle(cloudSync.hasConflict ? .orange : .secondary)
                        Button {
                            Task { await cloudSync.synchronize(with: simulation, library: library) }
                        } label: {
                            Label("Synchroniser maintenant", systemImage: "arrow.triangle.2.circlepath.icloud")
                        }
                        .disabled(cloudSync.isSyncing)
                        if cloudSync.hasConflict {
                            Button("Utiliser la version iCloud") {
                                Task { await cloudSync.resolveConflict(usingCloud: true, with: simulation, library: library) }
                            }
                            Button("Publier ma version locale") {
                                Task { await cloudSync.resolveConflict(usingCloud: false, with: simulation, library: library) }
                            }
                        }
                    }

                    if let recoveryNotice = simulation.recoveryNotice {
                        Section("Récupération") { Text(recoveryNotice).font(.footnote) }
                    }
                    if let errorMessage = simulation.errorMessage {
                        Section("Sauvegarde") { Text(errorMessage).font(.footnote).foregroundStyle(.red) }
                    }
                    if let mobileActionMessage {
                        Section("Action") { Text(mobileActionMessage).font(.footnote).