import SwiftUI
import UniformTypeIdentifiers
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
#endif

struct MobileCloudRestorePresentation: Equatable {
    let statusMessage: String
    let statusSymbol: String
    let isRetryEnabled: Bool

    init(statusMessage: String, isSyncing: Bool, hasConflict: Bool) {
        self.statusMessage = statusMessage
        statusSymbol = hasConflict ? "exclamationmark.icloud" : "icloud"
        isRetryEnabled = !isSyncing
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
    @State private var mobileSaveTransferMessage: String?
    @State private var isSaveImporterPresented = false
    @State private var isSaveExporterPresented = false
    @State private var saveExportDocument = SimulationSaveFile(data: Data())
    @State private var pendingSaveImportData: Data?
    @State private var isReplaceSaveConfirmationPresented = false
    @State private var selectedMobileDeparture: MobileDispatchableDeparture?

    var body: some View {
        TabView {
            NavigationStack {
                careerOverview
                    .navigationTitle("Carrière")
            }
            .tabItem { Label("Carrière", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack {
                courseDispatchOverview
                    .navigationTitle("Courses")
            }
            .tabItem { Label("Courses", systemImage: "tram.fill") }

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
        .sheet(item: $selectedMobileDeparture) { departure in
            NavigationStack {
                MobileScheduledDepartureAssignmentView(
                    departure: departure,
                    library: library,
                    simulation: simulation
                ) {
                    mobileActionMessage = "Course affectée à un bus et à un machiniste."
                    selectedMobileDeparture = nil
                }
            }
            .presentationDetents([.large])
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
        .fileImporter(
            isPresented: $isSaveImporterPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing { url.stopAccessingSecurityScopedResource() }
                }
                do {
                    let saveData = try Data(contentsOf: url)
                    guard simulation.session != nil else {
                        importMobileSave(saveData)
                        return
                    }
                    pendingSaveImportData = saveData
                    isReplaceSaveConfirmationPresented = true
                } catch {
                    mobileSaveTransferMessage = "Import impossible : \(error.localizedDescription)"
                }
            case let .failure(error):
                let nsError = error as NSError
                if nsError.code != NSUserCancelledError {
                    mobileSaveTransferMessage = "Import impossible : \(error.localizedDescription)"
                }
            }
        }
        .fileExporter(
            isPresented: $isSaveExporterPresented,
            document: saveExportDocument,
            contentType: .json,
            defaultFilename: "TransportManager-IDFM-\(simulation.session?.id ?? "carriere").json"
        ) { result in
            switch result {
            case let .success(url):
                mobileSaveTransferMessage = "Sauvegarde exportée : \(url.lastPathComponent)."
            case let .failure(error):
                let nsError = error as NSError
                if nsError.code != NSUserCancelledError {
                    mobileSaveTransferMessage = "Export impossible : \(error.localizedDescription)"
                }
            }
        }
        .confirmationDialog(
            "Remplacer la carrière actuelle ?",
            isPresented: $isReplaceSaveConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Remplacer la carrière", role: .destructive) {
                guard let pendingSaveImportData else { return }
                importMobileSave(pendingSaveImportData)
                self.pendingSaveImportData = nil
            }
            Button("Annuler", role: .cancel) {
                pendingSaveImportData = nil
            }
        } message: {
            Text("L’import remplace la partie sur cet iPhone. Sa nouvelle sauvegarde pourra ensuite être synchronisée avec iCloud. Les archives réseau ne sont pas incluses dans le fichier.")
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

                    Section("Fichier de sauvegarde") {
                        Button(action: prepareMobileSaveExport) {
                            Label("Exporter la sauvegarde JSON", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            isSaveImporterPresented = true
                        } label: {
                            Label("Importer une sauvegarde JSON", systemImage: "square.and.arrow.down")
                        }
                        if let mobileSaveTransferMessage {
                            Text(mobileSaveTransferMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
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
            Section("Synchronisation iCloud") {
                Label(cloudRestorePresentation.statusMessage, systemImage: cloudRestorePresentation.statusSymbol)
                    .font(.footnote)
                    .foregroundStyle(cloudSync.hasConflict ? .orange : .secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Task { await cloudSync.synchronize(with: simulation, library: library) }
                } label: {
                    Label("Réessayer la récupération iCloud", systemImage: "arrow.triangle.2.circlepath.icloud")
                        .frame(minHeight: 44, alignment: .leading)
                }
                .disabled(!cloudRestorePresentation.isRetryEnabled)
            }

            Section("Fichier de sauvegarde") {
                Button {
                    isSaveImporterPresented = true
                } label: {
                    Label("Importer une sauvegarde JSON", systemImage: "square.and.arrow.down")
                }
                if let mobileSaveTransferMessage {
                    Text(mobileSaveTransferMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

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
                        if let progress = library.gtfsImportProgress {
                            HStack(spacing: 12) {
                                if let fraction = progress.fraction {
                                    ProgressView(value: fraction)
                                        .progressViewStyle(.circular)
                                } else {
                                    ProgressView()
                                }
                                Text(progress.message)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            ProgressView("Chargement du réseau IDFM…")
                        }
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

    private var cloudRestorePresentation: MobileCloudRestorePresentation {
        MobileCloudRestorePresentation(
            statusMessage: cloudSync.statusMessage,
            isSyncing: cloudSync.isSyncing,
            hasConflict: cloudSync.hasConflict
        )
    }

    private func prepareMobileSaveExport() {
        do {
            saveExportDocument = SimulationSaveFile(data: try simulation.exportSaveData())
            isSaveExporterPresented = true
        } catch {
            mobileSaveTransferMessage = "Export impossible : \(error.localizedDescription)"
        }
    }

    private func importMobileSave(_ data: Data) {
        do {
            try simulation.importSaveData(data)
            if let activeDepotID = simulation.session?.effectiveActiveDepotID {
                selectedDepotID = activeDepotID
            }
            mobileSaveTransferMessage = "Carrière importée et mise en pause. Vérifie que ses archives réseau sont aussi présentes sur cet appareil."
        } catch {
            mobileSaveTransferMessage = "Import impossible : \(error.localizedDescription)"
        }
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
                    .foregroundStyle(status == .confirmed ? Color.primary : Color.secondary)
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

    private var courseDispatchOverview: some View {
        Group {
            if simulation.session == nil {
                ContentUnavailableView(
                    "Aucune carrière en cours",
                    systemImage: "tram",
                    description: Text("Crée ou importe une carrière pour affecter des bus et des machinistes aux départs GTFS.")
                )
            } else if mobileDispatchDepartures.isEmpty {
                ContentUnavailableView(
                    "Aucun départ à affecter",
                    systemImage: "calendar.badge.clock",
                    description: Text("Les départs en attente des lignes exploitées ont été affectés ou ne sont pas présents dans l’horizon chargé.")
                )
            } else {
                List {
                    Section {
                        Text("Choisis un départ théorique, puis affecte un bus disponible et un machiniste qualifié. Les contrôles de disponibilité et de service sont appliqués par le moteur de la carrière.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Section("Départs à affecter · \(mobileDispatchDepartures.count)") {
                        ForEach(mobileDispatchDepartures) { departure in
                            Button {
                                selectedMobileDeparture = departure
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(library.busRoutes.first(where: { $0.routeID == departure.routeID })?.displayName ?? departure.routeID)
                                            .font(.headline)
                                        Text("\(departure.departureAt.formatted(date: .abbreviated, time: .shortened)) · course \(departure.tripID)")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer(minLength: 4)
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Ouvre le choix d’un bus et d’un machiniste pour ce départ.")
                        }
                    }
                }
                .platformInsetListStyle()
            }
        }
    }

    private var mobileDispatchDepartures: [MobileDispatchableDeparture] {
        guard let session = simulation.session else { return [] }
        let routeIDs = session.effectiveOperatedRouteIDs(for: session.effectiveActiveDepotID)
        return session.pendingEvents.compactMap { event in
            guard case let .scheduledServiceDeparture(tripID, routeID, serviceDateKey) = event.kind,
                  routeIDs.contains(routeID) else { return nil }
            return MobileDispatchableDeparture(
                sequence: event.sequence,
                tripID: tripID,
                routeID: routeID,
                serviceDateKey: serviceDateKey,
                departureAt: event.simulatedAt
            )
        }
        .sorted {
            if $0.departureAt != $1.departureAt { return $0.departureAt < $1.departureAt }
            return $0.sequence < $1.sequence
        }
        .prefix(160)
        .map { $0 }
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

private struct MobileDispatchableDeparture: Identifiable, Hashable {
    let sequence: UInt64
    let tripID: String
    let routeID: String
    let serviceDateKey: Int
    let departureAt: Date

    var id: UInt64 { sequence }
}

@MainActor
private struct MobileScheduledDepartureAssignmentView: View {
    let departure: MobileDispatchableDeparture
    @ObservedObject var library: NetworkLibrary
    @ObservedObject var simulation: SimulationEngine
    let onDispatched: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var stopVisits: [ScheduledTripStopVisit] = []
    @State private var isLoadingSchedule = true
    @State private var scheduleError: String?
    @State private var selectedVehicleID: String?
    @State private var selectedMachinistID: String?
    @State private var deadheadPlan: VehicleDeadheadPlan?
    @State private var deadheadError: String?
    @State private var dispatchError: String?

    private var eligibleBuses: [PurchasedBus] {
        guard let session = simulation.session, let firstStopID = stopVisits.first?.stopID else { return [] }
        return (session.ownedBuses ?? []).filter { bus in
            guard bus.reservedTripKey == nil else { return false }
            if bus.status == .atDepot { return bus.depotID == session.effectiveActiveDepotID }
            return bus.status == .atStop && bus.currentStopID == firstStopID
        }
        .sorted { $0.acquiredAt < $1.acquiredAt }
    }

    private var selectedVehicle: PurchasedBus? {
        eligibleBuses.first { $0.id == selectedVehicleID }
    }

    private var deadheadDepartureAt: Date? {
        guard let firstStop = stopVisits.first, let deadheadPlan else { return nil }
        return firstStop.scheduledAt.addingTimeInterval(-deadheadPlan.expectedTravelSeconds)
    }

    private var eligibleMachinists: [Machinist] {
        guard let vehicle = selectedVehicle, let firstStop = stopVisits.first, let lastStop = stopVisits.last else { return [] }
        let serviceStartAt: Date
        if vehicle.status == .atDepot {
            guard let deadheadDepartureAt else { return [] }
            serviceStartAt = deadheadDepartureAt
        } else {
            serviceStartAt = firstStop.scheduledAt
        }
        return simulation.availableMachinists(
            forVehicleID: vehicle.id,
            serviceStartAt: serviceStartAt,
            serviceEndAt: lastStop.scheduledAt
        )
    }

    private var canDispatch: Bool {
        guard selectedVehicle != nil,
              eligibleMachinists.contains(where: { $0.id == selectedMachinistID }),
              !isLoadingSchedule,
              !stopVisits.isEmpty else { return false }
        return selectedVehicle?.status != .atDepot || (
            deadheadPlan != nil
                && deadheadDepartureAt.map { $0 >= (simulation.session?.simulatedAt ?? .distantFuture) } == true
        )
    }

    var body: some View {
        lifecycleContent
        .task(id: selectedVehicleID) { await calculateDeadheadRoute() }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private var lifecycleContent: some View {
        navigationContent
            .task { await loadSchedule() }
            .onChange(of: eligibleMachinists.map(\.id)) { _, currentIDs in
                updateSelectedMachinist(availableIDs: currentIDs)
            }
            .onChange(of: simulation.session?.simulatedAt) { _, _ in
                refreshSelectedMachinist()
            }
            .alert("Affectation impossible", isPresented: dispatchErrorPresentation) {
                Button("OK", role: .cancel) { dispatchError = nil }
            } message: {
                Text(dispatchError ?? "La course n’a pas pu être affectée.")
            }
    }

    private var navigationContent: some View {
        assignmentList
            .platformInsetListStyle()
            .navigationTitle("Affecter la course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
    }

    private var assignmentList: some View {
        List {
            Section("Départ GTFS") {
                Text(routeDisplayName)
                LabeledContent("Date et heure", value: departure.departureAt.formatted(date: .complete, time: .shortened))
                LabeledContent("Course", value: departure.tripID)
            }
            scheduleContent
        }
    }

    private var dispatchErrorPresentation: Binding<Bool> {
        Binding(
            get: { dispatchError != nil },
            set: { if !$0 { dispatchError = nil } }
        )
    }

    private func updateSelectedMachinist(availableIDs: [String]) {
        if let selectedMachinistID, availableIDs.contains(selectedMachinistID) { return }
        selectedMachinistID = availableIDs.first
    }

    private func refreshSelectedMachinist() {
        if let currentID = selectedMachinistID, !eligibleMachinists.contains(where: { $0.id == currentID }) {
            selectedMachinistID = eligibleMachinists.first?.id
        }
    }

    private var routeDisplayName: String {
        library.busRoutes.first(where: { $0.routeID == departure.routeID })?.displayName ?? departure.routeID
    }

    @ViewBuilder
    private var scheduleContent: some View {
        if isLoadingSchedule {
            Section { ProgressView("Chargement des arrêts…") }
        } else if let scheduleError {
            Section("Horaires indisponibles") { Text(scheduleError).foregroundStyle(.red) }
        } else if let firstStop = stopVisits.first, let lastStop = stopVisits.last {
            Section("Parcours") {
                LabeledContent("Premier arrêt", value: firstStop.stopName)
                LabeledContent("Dernier arrêt", value: lastStop.stopName)
                LabeledContent("Arrêts", value: "\(stopVisits.count)")
            }
            busAssignmentSection
            machinistAssignmentSection
            dispatchButtonSection
        }
    }

    private var busAssignmentSection: some View {
        Section("Bus") {
            if eligibleBuses.isEmpty {
                Text("Aucun bus disponible au dépôt actif ou déjà au premier arrêt.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Bus", selection: $selectedVehicleID) {
                    Text("Choisir un bus").tag(String?.none)
                    ForEach(eligibleBuses) { bus in
                        Text(busChoiceTitle(bus)).tag(Optional(bus.id))
                    }
                }
            }

            if selectedVehicle?.status == .atDepot {
                if let deadheadDepartureAt {
                    LabeledContent("Départ du dépôt", value: deadheadDepartureAt.formatted(date: .omitted, time: .shortened))
                    Text(deadheadPlan?.routingSourceTitle ?? "Calcul de l’itinéraire vers le premier arrêt…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if let deadheadError {
                    Text(deadheadError)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                } else if selectedVehicle != nil {
                    ProgressView("Calcul du trajet depuis le dépôt…")
                }
            }
        }
    }

    private var machinistAssignmentSection: some View {
        Section("Machiniste") {
            if selectedVehicle == nil {
                Text("Choisis d’abord un bus.").foregroundStyle(.secondary)
            } else if eligibleMachinists.isEmpty {
                Text("Aucun machiniste actuellement disponible et qualifié pour ce bus et cette course. Tu peux en recruter dans l’onglet Parc.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Machiniste", selection: $selectedMachinistID) {
                    Text("Choisir un machiniste").tag(String?.none)
                    ForEach(eligibleMachinists) { machinist in
                        Text("\(machinist.displayName) · \(machinist.qualification.title)")
                            .tag(Optional(machinist.id))
                    }
                }
            }
        }
    }

    private var dispatchButtonSection: some View {
        Section {
            Button(action: dispatchSelectedDeparture) {
                Label("Affecter bus et machiniste", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canDispatch)
        } footer: {
            Text("La validation du moteur contrôle notamment la disponibilité, la qualification, les repos, les conflits de service et l’énergie du bus.")
        }
    }

    private func busChoiceTitle(_ bus: PurchasedBus) -> String {
        let model = VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID
        return "\(model) · \(bus.coquilleNumber ?? bus.id)"
    }

    private func loadSchedule() async {
        guard let gtfsVersionID = simulation.session?.networkVersions.gtfsID else {
            scheduleError = "La version GTFS épinglée par cette carrière n’est pas disponible."
            isLoadingSchedule = false
            return
        }
        do {
            let visits = try await library.loadScheduledTripStopVisits(
                gtfsVersionID: gtfsVersionID,
                tripID: departure.tripID,
                serviceDateKey: departure.serviceDateKey
            )
            guard !Task.isCancelled else { return }
            guard visits.count >= 2 else {
                scheduleError = "Cette course ne contient pas assez d’arrêts utilisables pour lancer un service."
                isLoadingSchedule = false
                return
            }
            stopVisits = visits
        } catch {
            guard !Task.isCancelled else { return }
            scheduleError = error.localizedDescription
        }
        isLoadingSchedule = false
    }

    private func calculateDeadheadRoute() async {
        guard let vehicle = selectedVehicle,
              vehicle.status == .atDepot,
              let firstStop = stopVisits.first,
              let session = simulation.session,
              let depot = DepotCareerScope.depotReference(for: vehicle.depotID) else {
            deadheadPlan = nil
            deadheadError = nil
            return
        }
        deadheadPlan = nil
        deadheadError = nil
        do {
            let plan = try await VehicleDeadheadRouter.route(
                from: depot,
                to: firstStop,
                serviceStartAt: firstStop.scheduledAt,
                earliestDepartureAt: session.simulatedAt
            )
            guard !Task.isCancelled, selectedVehicleID == vehicle.id else { return }
            deadheadPlan = plan
        } catch {
            guard !Task.isCancelled, selectedVehicleID == vehicle.id else { return }
            deadheadError = error.localizedDescription
        }
    }

    private func dispatchSelectedDeparture() {
        guard let vehicleID = selectedVehicleID, let machinistID = selectedMachinistID else { return }
        do {
            try simulation.dispatchScheduledDeparture(
                eventSequence: departure.sequence,
                vehicleID: vehicleID,
                machinistID: machinistID,
                stopVisits: stopVisits,
                deadheadPlan: selectedVehicle?.status == .atDepot ? deadheadPlan : nil
            )
            onDispatched()
            dismiss()
        } catch {
            dispatchError = error.localizedDescription
        }
    }
}
#endif
