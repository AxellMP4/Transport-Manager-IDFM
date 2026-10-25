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
                        Section("Action") { Text(mobileActionMessage).font(.footnote).foregroundStyle(.secondary) }
                    }
                }
            } else {
                newCareerOverview
            }
        }
    }

    private var newCareerOverview: some View {
        List {
            Section {
                Label("Nouvelle carrière", systemImage: "bus.doubledecker")
                    .font(.title3.weight(.semibold))
                Text("Choisis un dépôt, une date couverte par le GTFS et les lignes à exploiter. Les données de partie seront sauvegardées sur cet iPhone et pourront être synchronisées avec iCloud.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if library.catalog.activeVersion == nil {
                Section("Réseau") {
                    if library.importState.isImporting || library.gtfsImportProgress != nil {
                        ProgressView("Chargement du réseau IDFM…")
                    } else if let error = library.importState.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    } else {
                        ProgressView("Préparation des données du réseau…")
                    }
                }
            } else {
                Section("Départ") {
                    Picker("Dépôt", selection: $selectedDepotID) {
                        ForEach(playableDepots) { depot in
                            Text(depot.name).tag(depot.id)
                        }
                    }
                    .onChange(of: selectedDepotID) { _, _ in
                        selectedCandidateLineIDs.removeAll()
                        careerStartError = nil
                    }

                    if let range = playableDateRange {
                        DatePicker("Date et heure", selection: $careerStartMoment, in: range)
                            .onChange(of: careerStartMoment) { _, _ in
                                selectedCandidateLineIDs.removeAll()
                                careerStartError = nil
                            }
                    } else {
                        Label("La période des horaires n’est pas disponible.", systemImage: "calendar.badge.exclamationmark")
                            .foregroundStyle(.orange)
                    }

                    if let site = selectedDepotSite {
                        Label(site.availability.label, systemImage: site.availability.systemImage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if library.isLoadingBusRoutes || library.isLoadingLineReferences {
                        ProgressView("Recherche des lignes du dépôt…")
                    } else if mobileCareerChoices.isEmpty {
                        ContentUnavailableView(
                            "Aucune ligne jouable trouvée",
                            systemImage: "point.3.connected.trianglepath.dotted",
                            description: Text("Vérifie les données réseau et la date choisie avant de créer la partie.")
                        )
                    } else {
                        ForEach(mobileCareerChoices, id: \.id) { choice in
                            mobileCareerLineRow(choice)
                        }
                    }
                } header: {
                    HStack {
                        Text("Lignes")
                        Spacer()
                        Text("\(selectedCareerRouteIDs.count) variantes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Les lignes confirmées sont incluses. Les rattachements incertains ne démarrent que si tu les sélectionnes. Une ligne annoncée mais sans course GTFS ne peut pas être exploitée ici.")
                }

                Section {
                    Button(action: startMobileCareer) {
                        HStack {
                            Spacer()
                            if isPreparingTimetable {
                                ProgressView()
                                    .padding(.trailing, 6)
                                Text("Préparation des horaires…")
                            } else {
                                Label("Créer la carrière", systemImage: "play.fill")
                            }
                            Spacer()
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStartMobileCareer)

                    if let careerStartError {
                        Text(careerStartError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    } else if let version = library.catalog.activeVersion {
                        Text("Horaires du \(version.validFrom?.formatted(date: .abbreviated, time: .omitted) ?? "début inconnu") au \(version.validThrough?.formatted(date: .abbreviated, time: .omitted) ?? "fin inconnue")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .platformInsetListStyle()
    }

    private var playableDepots: [DepotReference] {
        DepotLineRoster.selectableSites
            .filter { $0.hasPlayableContractScope }
            .compactMap { site in
                ScenarioDefinition.forDepot(site.id).referenceDepots.first { $0.id == site.id }
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var selectedScenario: ScenarioDefinition {
        ScenarioDefinition.forDepot(selectedDepotID)
    }

    private var selectedDepotSite: DepotLineRosterSite? {
        DepotLineRoster.selectableSites.first { $0.id == selectedDepotID }
    }

    private var playableDateRange: ClosedRange<Date>? {
        guard let version = library.catalog.activeVersion,
              let validFrom = version.validFrom,
              let validThrough = version.validThrough else { return nil }
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let start = calendar.startOfDay(for: validFrom)
        let endDay = calendar.startOfDay(for: validThrough)
        guard let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: endDay) else { return nil }
        let end = dayAfterEnd.addingTimeInterval(-1)
        return start <= end ? start...end : nil
    }

    private var mobileCareerChoices: [MobileCareerLineChoice] {
        guard library.catalog.activeVersion != nil,
              library.catalog.activeLineReferenceVersion != nil else { return [] }
        let visibleRows = DepotLineRoster.rows.filter { $0.isVisible(atSite: selectedDepotID, on: careerStartMoment) }
        let rows = visibleRows + DepotContractLineScope.candidateRows(
            for: selectedDepotSite,
            references: library.lineReferences,
            serviceDate: careerStartMoment,
            excluding: visibleRows
        )
        return rows.compactMap { row in
            let evidenceStatus = row.evidenceStatus(on: careerStartMoment)
            guard evidenceStatus != .planned else { return nil }
            let normalizedName = row.line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let matchingLineIDs = Set(library.lineReferences.filter {
                $0.isActive(on: careerStartMoment) == true
                    && $0.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == normalizedName
            }.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) })
            let lineID = row.canonicalLineID ?? (matchingLineIDs.count == 1 ? matchingLineIDs.first : nil)
            guard let lineID, !lineID.isEmpty else { return nil }
            let routeIDs = library.busRoutes
                .filter { LineReferenceMatcher.canonicalIdentifier($0.routeID) == lineID }
                .map(\.routeID)
            guard !routeIDs.isEmpty else { return nil }
            return MobileCareerLineChoice(id: row.id, label: row.line, evidenceStatus: evidenceStatus, routeIDs: routeIDs)
        }
    }

    private var selectedCareerRouteIDs: Set<String> {
        MobileCareerLineSelection.routeIDs(from: mobileCareerChoices, selectedLineIDs: selectedCandidateLineIDs)
    }

    private var canStartMobileCareer: Bool {
        library.catalog.isPlayable
            && simulation.session == nil
            && playableDepots.contains { $0.id == selectedDepotID }
            && playableDateRange?.contains(careerStartMoment) == true
            && !selectedCareerRouteIDs.isEmpty
            && !isPreparingTimetable
            && !library.importState.isImporting
    }

    private func mobileCareerLineRow(_ choice: MobileCareerLineChoice) -> some View {
        let label = choice.label
        let status = choice.evidenceStatus
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.headline.monospaced())
                Text(status.rawValue)
                    .font(.caption)
                    .foregroundStyle(status == .confirmed ? Color.green : Color.secondary)
                Text("\(choice.routeIDs.count) variantes GTFS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if status == .confirmed {
                Label("Incluse", systemImage: "checkmark.seal.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Ligne confirmée, incluse")
            } else {
                Toggle("Exploiter \(label)", isOn: Binding(
                    get: { selectedCandidateLineIDs.contains(choice.id) },
                    set: { included in
                        if included { selectedCandidateLineIDs.insert(choice.id) }
                        else { selectedCandidateLineIDs.remove(choice.id) }
                    }
                ))
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }

    private func startMobileCareer() {
        guard canStartMobileCareer,
              let gtfsVersion = library.catalog.activeVersion,
              let geometryVersion = library.catalog.activeGeometryVersion,
              let contractVersion = library.catalog.activeContractVersion,
              let lineReferenceVersion = library.catalog.activeLineReferenceVersion else { return }
        let routeIDs = selectedCareerRouteIDs
        let startDate = careerStartMoment
        let horizonEnd = startDate.addingTimeInterval(48 * 60 * 60)
        let scenario = selectedScenario
        let depotID = selectedDepotID
        let assignmentIDs = library.operationalDepotAssignments(
            scenarioID: scenario.id,
            depotID: depotID,
            gtfsVersionID: gtfsVersion.id,
            contractVersionID: contractVersion.id
        ).filter { $0.contractID == scenario.idfmBusContractID && routeIDs.contains($0.routeID) }
            .map(\.id)
        isPreparingTimetable = true
        careerStartError = nil

        Task {
            defer { isPreparingTimetable = false }
            do {
                let departures = try await library.loadScheduledDepartures(
                    gtfsVersionID: gtfsVersion.id,
                    routeIDs: routeIDs,
                    from: startDate,
                    through: horizonEnd
                )
                guard !departures.isEmpty else {
                    careerStartError = "Aucune course active pour ces lignes dans les 48 heures suivant cette date. Essaie une autre date ou d’autres lignes."
                    return
                }
                try simulation.startNew(
                    scenarioID: scenario.id,
                    depotID: depotID,
                    networkVersions: SimulationDataVersions(
                        gtfsID: gtfsVersion.id,
                        routeGeometryID: geometryVersion.id,
                        contractID: contractVersion.id,
                        lineReferenceID: lineReferenceVersion.id
                    ),
                    startDate: startDate,
                    operatedRouteIDs: Array(routeIDs),
                    assignmentRecordIDs: assignmentIDs,
                    managedDepotIDs: [depotID],
                    operatedRouteIDsByDepot: [depotID: Array(routeIDs)],
                    scheduledDepartures: departures,
                    timetableHorizonEnd: horizonEnd,
                    breakdownFrequency: .standard
                )
            } catch {
                careerStartError = error.localizedDescription
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
                        Menu("Recruter un machiniste") {
                            ForEach(MachinistQualification.allCases) { qualification in
                                Button(qualification.title) {
                                    do {
                                        try simulation.hireMachinist(qualification: qualification)
                                        mobileActionMessage = "Machiniste recruté · \(qualification.title)"
                                    } catch {
                                        mobileActionMessage = error.localizedDescription
                                    }
                                }
                            }
                        }
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
                    Section("Marché") {
                        ForEach(session.marketOffers ?? []) { offer in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(VehicleMarketCatalog.model(id: offer.modelID)?.displayName ?? offer.modelID)
                                    .font(.headline)
                                Text("\(offer.condition.title) · année \(offer.vehicleYear) · livraison \(offer.deliveryDays) j")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(offer.askingPrice.formatted(.currency(code: "EUR")))
                                    .font(.title3.weight(.semibold))
                                Button("Acheter ce bus") {
                                    do {
                                        try simulation.purchaseVehicle(offerID: offer.id)
                                        mobileActionMessage = "Bus commandé. Il apparaîtra dans le parc à la fin du délai de livraison."
                                    } catch {
                                        mobileActionMessage = error.localizedDescription
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled((session.purchasedOfferQuantities?[offer.id] ?? 0) >= offer.initialStock)
                            }
                            .padding(.vertical, 5)
                        }
                        if let mobileActionMessage {
                            Text(mobileActionMessage)
                                .font(.footnote)
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
