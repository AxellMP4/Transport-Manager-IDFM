import MapKit
import SwiftUI
import UniformTypeIdentifiers

private struct SimulationSaveFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct StopClosureRequest: Identifiable {
    let stop: GTFSStopSummary
    let routeID: String

    var id: String { "\(stop.stopID)|\(routeID)" }
}

private struct ActiveStopReplacementMapGuide: Identifiable {
    let id: String
    let closedStopName: String
    let guide: StopClosureReplacementGuide
    let passengerInformationMessage: String?
}

private struct AdditionalScenarioCoverageView: View {
    let coverage: ScenarioLineCoverage

    var body: some View {
        if !coverage.unresolvedActiveEntries.isEmpty {
            DisclosureGroup("Routes actives dont le lien roster–ID_Line reste à vérifier (\(coverage.unresolvedActiveRouteCount))") {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(coverage.unresolvedActiveEntries) { entry in
                        HStack(alignment: .firstTextBaseline) {
                            Text(entry.lineName)
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 8)
                            Text(entry.activeRouteIDs.joined(separator: ", "))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        if !entry.lineReferenceIDs.isEmpty {
                            Text("ID_Line candidats · \(entry.lineReferenceIDs.joined(separator: ", "))")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 5)
                Text("Le nom commercial correspond au repère, mais aucune correspondance unique entre l’ID_Line et la route GTFS n’est retenue.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 5)
            }
            .font(.caption.weight(.medium))
        }

        if coverage.unlistedActiveEntries.isEmpty {
            if coverage.unresolvedActiveEntries.isEmpty {
                Text("Aucune route bus active hors des ID_Line du repère ce jour-là.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            DisclosureGroup("Routes GTFS actives hors du repère · à qualifier (\(coverage.unlistedActiveRouteCount))") {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(coverage.unlistedActiveEntries) { entry in
                        HStack(alignment: .firstTextBaseline) {
                            Text(entry.lineName)
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 8)
                            Text(entry.activeRouteIDs.joined(separator: ", "))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        if !entry.lineReferenceIDs.isEmpty {
                            Text("ID_Line · \(entry.lineReferenceIDs.joined(separator: ", "))")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 5)
                Text("Ces routes ont au moins un départ ce jour-là, mais leur ID_Line n’est pas dans le repère publié. Leur présence ne confirme ni un rattachement à la DSP 45 ni une répartition entre COB.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 5)
            }
            .font(.caption.weight(.medium))
        }
    }
}

private struct MachinistPlannedReliefOption: Identifiable {
    let stop: MachinistReliefStop
    let candidate: Machinist

    var id: String { "\(stop.eventSequence)-\(candidate.id)" }
}

private struct MachinistPlannedReliefMenu: View {
    let options: [MachinistPlannedReliefOption]
    let machinistName: String
    let isPlanning: Bool
    let onSelect: (MachinistReliefStop, Machinist) -> Void

    var body: some View {
        Menu {
            if options.isEmpty {
                Text("Aucun machiniste qualifié et disponible pour les prochains arrêts.")
            } else {
                ForEach(options) { option in
                    Button("\(option.stop.stopName) · \(option.stop.scheduledAt.formatted(date: .omitted, time: .shortened)) → \(option.candidate.displayName)") {
                        onSelect(option.stop, option.candidate)
                    }
                }
            }
        } label: {
            if isPlanning {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "calendar.badge.clock")
            }
        }
        .buttonStyle(.borderless)
        .disabled(isPlanning)
        .help("Planifier une relève à un prochain arrêt")
        .accessibilityLabel("Planifier la relève de \(machinistName) à un prochain arrêt")
    }
}

private struct DepotMapLine: Identifiable {
    let row: DepotLineRosterRow
    let routes: [GTFSRouteSummary]
    let geometries: [NetworkRouteGeometry]

    var id: String { row.id }
}

private enum OperationsWorkspaceTab: String, CaseIterable, Identifiable {
    case network
    case depots
    case lines
    case assignments
    case fleet
    case staff
    case reports
    case incidents
    case sources

    var id: String { rawValue }

    var title: String {
        switch self {
        case .network: "Carte"
        case .lines: "Lignes"
        case .assignments: "Affectations"
        case .fleet: "Parc"
        case .staff: "Personnel"
        case .depots: "Dépôts"
        case .reports: "Rapports"
        case .incidents: "Incidents"
        case .sources: "Sources"
        }
    }

    var symbol: String {
        switch self {
        case .network: "map"
        case .lines: "list.bullet.rectangle"
        case .assignments: "arrow.triangle.branch"
        case .fleet: "bus"
        case .staff: "person.2"
        case .depots: "building.2"
        case .reports: "chart.bar"
        case .incidents: "wrench.and.screwdriver"
        case .sources: "tray.full"
        }
    }
}

private protocol WorkspacePickerSection: CaseIterable, Hashable, Identifiable {
    var title: String { get }
}

private enum AssignmentWorkspaceSection: String, WorkspacePickerSection {
    case depotLines
    case busDepartures

    var id: String { rawValue }
    var title: String {
        switch self {
        case .depotLines: "Lignes au dépôt"
        case .busDepartures: "Départs des bus"
        }
    }
}

private enum ReportWorkspaceSection: String, WorkspacePickerSection {
    case daily
    case finances
    case payroll
    case progression

    var id: String { rawValue }
    var title: String {
        switch self {
        case .daily: "Exploitation"
        case .finances: "Finances"
        case .payroll: "Paie"
        case .progression: "Progression"
        }
    }
}

private enum DataWorkspaceSection: String, CaseIterable, Identifiable {
    case fullNetwork
    case contracts
    case coverage

    var id: String { rawValue }
    var title: String {
        switch self {
        case .fullNetwork: "Toutes les lignes"
        case .contracts: "Contrats"
        case .coverage: "Couverture"
        }
    }
}

struct OperationsDashboardView: View {
    private enum LocalImportKind {
        case gtfs
        case routeGeometry
        case contracts
        case lineReference
        case lineDocuments

        var allowedContentTypes: [UTType] {
            switch self {
            case .gtfs:
                [.zip]
            case .routeGeometry:
                [.json, UTType(filenameExtension: "geojson", conformingTo: .json) ?? .json]
            case .contracts:
                [.json, UTType(filenameExtension: "geojson", conformingTo: .json) ?? .json]
            case .lineReference:
                [.commaSeparatedText]
            case .lineDocuments:
                [.commaSeparatedText]
            }
        }
    }

    private var scenario: ScenarioDefinition { ScenarioDefinition.forDepot(selectedDepotID) }
    @StateObject private var library = NetworkLibrary()
    @StateObject private var simulation = SimulationEngine()

    @AppStorage("transportManager.selectedDepotID") private var selectedDepotID = "saint-maur"
    @State private var careerStartMoment = Date.now
    @State private var selectedCandidateCareerLineIDs = Set<String>()
    @State private var breakdownFrequency: VehicleIncidentFrequency = .standard
    @State private var careerStartError: String?
    @State private var isPreparingTimetable = false
    @State private var isTimetableExtensionBlocked = false
    @State private var scenarioLineCoverage: ScenarioLineCoverage?
    @State private var scenarioLineCoverageError: String?
    @State private var isLoadingScenarioLineCoverage = false
    @State private var scenarioLineCoverageTaskKey = ""
    @State private var cameraPosition: MapCameraPosition = .region(Self.ileDeFranceRegion)
    @State private var visibleMapRegion = Self.ileDeFranceRegion
    @State private var selectedRouteID: String?
    @State private var selectedDepotLineID: String?
    @State private var browsedDepotID: String?
    @State private var selectedContractFeatureID: String?
    @State private var selectedStop: GTFSStopSummary?
    @State private var selectedBusID: String?
    // Keep the existing operational map composition on first launch; players can then
    // hide a layer without losing the persistent map legend or data-quality notices.
    @State private var showsNetworkLayer = true
    @State private var showsStopsLayer = true
    @State private var showsFleetLayer = true
    @State private var showsIncidentsLayer = true
    @State private var routeDetourRequest: RouteDetourRequest?
    @State private var stopClosureRequest: StopClosureRequest?
    @State private var routeDetourExtensionError: String?
    @State private var isDataImporterPresented = false
    @State private var localImportKind: LocalImportKind = .gtfs
    @State private var gtfsImportProvenance: GTFSImportProvenance = .unverifiedManual
    @State private var isRouteLibraryPresented = false
    @State private var isContractLibraryPresented = false
    @State private var isRegionalDepotRegistryPresented = false
    @State private var isDepotLineRosterPresented = false
    @State private var isIncidentResponsePresented = false
    @State private var incidentForResponse: VehicleIncident?
    @State private var isSaveImporterPresented = false
    @State private var isSaveExporterPresented = false
    @State private var saveExportDocument = SimulationSaveFile(data: Data())
    @State private var saveTransferNotice: String?
    @State private var activeTripShapes: [ActiveTripMapShape] = []
    @State private var depotFallbackShapesByRouteID: [String: [GTFSRouteShape]] = [:]
    @State private var isLoadingDepotFallbackShapes = false
    // A new player should first choose a real depot, then enter its line roster.
    // Existing careers are redirected to the operating map during dashboard setup.
    @State private var selectedWorkspaceTab: OperationsWorkspaceTab = .network
    @State private var assignmentWorkspaceSection: AssignmentWorkspaceSection = .depotLines
    @State private var reportWorkspaceSection: ReportWorkspaceSection = .daily
    @State private var dataWorkspaceSection: DataWorkspaceSection = .contracts

    private var catalog: NetworkCatalog { library.catalog }

    private var pendingIncidentResponse: VehicleIncident? {
        simulation.session?.incidentAwaitingRepairResponse
    }

    private var scenarioLineCoverageTaskID: String {
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let serviceDate = calendar.startOfDay(for: careerStartMoment)
        let dateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone) ?? -1
        return "\(simulation.session?.id ?? "préparation")|\(catalog.activeVersion?.id ?? "aucune")|\(catalog.activeLineReferenceVersion?.id ?? "aucune-référence")|\(dateKey)|\(library.busRoutes.count)|\(library.lineReferences.count)"
    }

    private var scenarioLineChecklist: ScenarioLineChecklist? {
        scenario.publishedLineChecklist(at: careerStartMoment)
    }

    private var canStartCareer: Bool {
        catalog.isPlayable
            && hasCareerContractScope
            && isCareerStartWithinNetworkValidity
            && isSelectedDepotPlayable
            && !selectedDepotRouteIDs.isEmpty
            && simulation.session == nil
            && !isPreparingTimetable
            && !library.importState.isImporting
            && !library.geometryImportState.isImporting
            && !library.contractImportState.isImporting
            && !library.lineReferenceImportState.isImporting
    }

    private var hasScenarioContractContour: Bool {
        library.contractFeatures.contains { $0.contractID == scenario.idfmBusContractID }
    }

    private var canUsePublishedDSPScopeWithoutContour: Bool {
        let contractID = LineReferenceMatcher.canonicalIdentifier(scenario.idfmBusContractID)
        guard !contractID.isEmpty,
              selectedDepotSite?.hasPlayableContractScope == true,
              let selectedContractID = selectedDepotSite?.idfmBusContractID,
              LineReferenceMatcher.canonicalIdentifier(selectedContractID) == contractID else {
            return false
        }
        // A boundary polygon is useful context but is not needed to operate real GTFS lines.
        // The active line reference and matching routes provide the contract scope when IDFM
        // has not published a contour for that DSP.
        return !selectedDepotRouteIDs.isEmpty
    }

    private var hasCareerContractScope: Bool {
        hasScenarioContractContour || canUsePublishedDSPScopeWithoutContour
    }

    private var isCareerStartWithinNetworkValidity: Bool {
        guard let version = catalog.activeVersion,
              let validFrom = version.validFrom,
              let validThrough = version.validThrough,
              let firstDate = GTFSServiceDate.key(
                for: validFrom,
                timeZone: TimeZone(secondsFromGMT: 0) ?? .current
              ),
              let lastDate = GTFSServiceDate.key(
                for: validThrough,
                timeZone: TimeZone(secondsFromGMT: 0) ?? .current
              ),
              let selectedDate = GTFSServiceDate.key(
                for: GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: careerStartMoment),
                timeZone: GTFSServiceDate.parisTimeZone
              ) else { return false }
        guard firstDate <= lastDate else { return false }
        return (firstDate...lastDate).contains(selectedDate)
    }

    private var selectedDepot: DepotReference? {
        scenario.referenceDepots.first { $0.id == selectedDepotID }
    }

    private var lineCatalogDepotID: String {
        simulation.session == nil ? selectedDepotID : (browsedDepotID ?? selectedDepotID)
    }

    private var lineCatalogCanShowOnMap: Bool {
        simulation.session == nil || lineCatalogDepotID == selectedDepotID
    }

    private var selectedDepotSite: DepotLineRosterSite? {
        DepotLineRoster.selectableSites.first { $0.id == selectedDepotID }
    }

    private var isSelectedDepotPlayable: Bool {
        selectedDepotSite?.hasPlayableContractScope == true
            && scenario.referenceDepots.contains { $0.id == selectedDepotID }
    }

    private var selectedDepotAssignments: [DepotLineAssignment] {
        guard let gtfsVersion = catalog.activeVersion,
              let contractVersion = catalog.activeContractVersion,
              let contractID = selectedDepotSite?.idfmBusContractID else { return [] }
        return library.operationalDepotAssignments(
            scenarioID: scenario.id,
            depotID: selectedDepotID,
            gtfsVersionID: gtfsVersion.id,
            contractVersionID: contractVersion.id
        ).filter { $0.contractID == contractID }
    }

    private var selectedDepotRosterDate: Date {
        simulation.session?.simulatedAt ?? careerStartMoment
    }

    private var selectedDepotMapLines: [DepotMapLine] {
        let rosterDate = selectedDepotRosterDate
        let rows = DepotLineRoster.rows.filter { row in
            row.isVisible(atSite: selectedDepotID, on: rosterDate)
        }
        let contractRows = DepotContractLineScope.candidateRows(
            for: selectedDepotSite,
            references: library.lineReferences,
            serviceDate: rosterDate,
            excluding: rows
        )

        let entries = (rows + contractRows).map { row in
            let normalizedName = row.line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let references = library.lineReferences.filter {
                $0.isActive(on: rosterDate) == true
                    && $0.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == normalizedName
            }
            let referenceIDs = Set(references.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) })
            let canonicalLineID = row.canonicalLineID
                ?? (referenceIDs.count == 1 ? referenceIDs.first : nil)
            let routes = canonicalLineID.map { lineID in
                library.busRoutes.filter { LineReferenceMatcher.canonicalIdentifier($0.routeID) == lineID }
            } ?? []
            var geometries = canonicalLineID.map { lineID in
                library.routeGeometries.filter { LineReferenceMatcher.canonicalIdentifier($0.lineID) == lineID }
            } ?? []
            if geometries.isEmpty {
                geometries = routes.flatMap { route in
                    RouteGeometryMatcher.matches(route: route, among: library.busRoutes, geometries: library.routeGeometries)
                }
            }
            let uniqueGeometries = Dictionary(geometries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            return DepotMapLine(row: row, routes: routes, geometries: uniqueGeometries.values.sorted { $0.id < $1.id })
        }

        guard let session = simulation.session else { return entries }
        let depotRouteIDs = session.effectiveOperatedRouteIDs(for: selectedDepotID)
        let matchedRouteIDs = Set(entries.flatMap(\.routes).map(\.routeID))
        let legacyLines = depotRouteIDs.filter { !matchedRouteIDs.contains($0) }.compactMap { routeID -> DepotMapLine? in
            guard let route = library.busRoutes.first(where: { $0.routeID == routeID }) else { return nil }
            let row = DepotLineRosterRow(
                line: route.displayName,
                category: "Ligne conservée dans la carrière",
                siteIDs: [selectedDepotID],
                evidenceStatus: .unresolved,
                note: "Cette ligne est épinglée à la carrière sauvegardée. Son rattachement historique au dépôt n’est pas confirmé par le repère actuel.",
                publicDocuments: [],
                claims: []
            )
            let geometries = RouteGeometryMatcher.matches(
                route: route,
                among: library.busRoutes,
                geometries: library.routeGeometries
            )
            return DepotMapLine(row: row, routes: [route], geometries: geometries)
        }
        return entries + legacyLines
    }

    private var selectedDepotRouteIDs: Set<String> {
        if let session = simulation.session {
            return session.effectiveOperatedRouteIDs(for: selectedDepotID)
        }
        let confirmedRouteIDs = Set(selectedDepotMapLines
            .filter { $0.row.evidenceStatus(on: selectedDepotRosterDate) == .confirmed }
            .flatMap { $0.routes.map(\.routeID) })
        let playerSelectedRouteIDs = Set(selectedDepotMapLines
            .filter { selectedCandidateCareerLineIDs.contains($0.id) }
            .flatMap { $0.routes.map(\.routeID) })
        return confirmedRouteIDs.union(playerSelectedRouteIDs)
    }

    private var selectedDepotLineCoverage: DepotLineCoverage {
        library.depotLineCoverage(
            depotID: selectedDepotID,
            serviceDate: selectedDepotRosterDate,
            operatedRouteIDs: simulation.session?.effectiveOperatedRouteIDs(for: selectedDepotID) ?? []
        )
    }

    private var depotFallbackShapeTaskKey: String {
        let versionID = simulation.session?.networkVersions.gtfsID ?? catalog.activeVersion?.id ?? ""
        let routeIDs = selectedDepotMapLines
            .filter { $0.geometries.isEmpty }
            .flatMap(\.routes)
            .map(\.routeID)
            .sorted()
        let serviceDateKey = GTFSServiceDate.key(
            for: GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: selectedDepotRosterDate),
            timeZone: GTFSServiceDate.parisTimeZone
        ) ?? 0
        return [versionID, selectedDepotID, String(serviceDateKey), routeIDs.joined(separator: ",")]
            .joined(separator: "|")
    }

    private var depotFallbackShapeLineCount: Int {
        selectedDepotMapLines.filter { line in
            line.geometries.isEmpty && line.routes.contains {
                !(depotFallbackShapesByRouteID[$0.routeID] ?? []).isEmpty
            }
        }.count
    }

    private var selectedContractFeature: NetworkContractFeature? {
        guard let selectedContractFeatureID else { return nil }
        return library.contractFeatures.first { $0.id == selectedContractFeatureID }
    }

    private var visibleBusStops: [GTFSStopSummary] {
        let depotRouteIDs = selectedDepotRouteIDs
        guard !depotRouteIDs.isEmpty else { return [] }
        return library.busStops.filter { stop in
            // Stops remain discoverable even when no line is selected, while staying
            // scoped to routes operated from the active depot and the current viewport.
            let isOnDepotNetwork = !depotRouteIDs.isDisjoint(with: stop.routeIDs)
            let isInViewport = abs(stop.latitude - visibleMapRegion.center.latitude) <= visibleMapRegion.span.latitudeDelta / 2
                && abs(stop.longitude - visibleMapRegion.center.longitude) <= visibleMapRegion.span.longitudeDelta / 2
            return isOnDepotNetwork && isInViewport
        }
    }

    private var mapLayerControls: some View {
        Menu {
            Toggle(isOn: $showsNetworkLayer) { Label("Réseau et lignes", systemImage: "point.topleft.down.curvedto.point.bottomright.up") }
            Toggle(isOn: $showsStopsLayer) { Label("Arrêts", systemImage: "bus.stop") }
            Toggle(isOn: $showsFleetLayer) { Label("Flotte", systemImage: "bus.fill") }
            Toggle(isOn: $showsIncidentsLayer) { Label("Incidents et travaux", systemImage: "wrench.and.screwdriver") }
        } label: {
            Label("Couches", systemImage: "square.3.layers.3d")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.regularMaterial, in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Couches de la carte")
        .help("Afficher ou masquer les couches de la carte d’exploitation")
    }

    private var mapLegend: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("LÉGENDE")
                .font(.caption2.weight(.bold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
            mapLegendLine(color: .primary, dash: [], title: "Tracé commercial · couleur par ligne")
            mapLegendLine(color: .teal, dash: [7, 5], title: "Tracé GTFS indicatif")
            mapLegendLine(color: .orange, dash: [3, 5], title: "Mouvement estimé")
            if let version = catalog.activeVersion {
                Divider()
                Text("Réseau · \(version.displaySourceTitle) · Licence \(version.displayLicense)")
                    .font(.caption2.weight(.medium))
                    .lineLimit(2)
                Text("Version \(version.id) · \(version.validFrom.map(Self.shortDate) ?? "date inconnue") – \(version.validThrough.map(Self.shortDate) ?? "date inconnue")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: 245, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Légende de la carte. Tracé commercial en couleur par ligne, tracé GTFS indicatif et mouvement estimé.")
    }

    private func mapLegendLine(color: Color, dash: [CGFloat], title: String) -> some View {
        HStack(spacing: 7) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 4))
                path.addLine(to: CGPoint(x: 30, y: 4))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: dash))
            .frame(width: 30, height: 8)
            Text(title).font(.caption2)
        }
        .accessibilityElement(children: .combine)
    }

    private var mapFleetBuses: [PurchasedBus] {
        guard let session = simulation.session else { return [] }
        let assignments = session.machinistServiceAssignments ?? []
        return (session.ownedBuses ?? []).filter { bus in
            (bus.status == .inService || bus.status == .atStop || bus.status == .waitingForWorkshop || bus.status == .inMaintenance || bus.status == .beingTowed || bus.status == .deadheadingToService || bus.status == .returningToDepot || bus.status == .outOfService)
                && bus.depotID == session.effectiveActiveDepotID
                && bus.latitude?.isFinite == true
                && bus.longitude?.isFinite == true
                && assignments.contains { assignment in
                    assignment.vehicleID == bus.id
                        && selectedDepotRouteIDs.contains(assignment.routeID)
                        && (assignment.tripID == bus.currentTripID
                            || (assignment.actualEndAt == nil
                                && assignment.plannedStartAt <= session.simulatedAt
                                && session.simulatedAt <= assignment.plannedEndAt))
                }
        }
    }

    private var activeBusTripIDs: [String] {
        Array(Set((simulation.session?.ownedBuses ?? []).compactMap(\.currentTripID))).sorted()
    }

    private var activeStopReplacementGuides: [ActiveStopReplacementMapGuide] {
        (simulation.session?.activeStopClosures ?? []).flatMap { closure in
            (closure.replacementGuidesByRouteID ?? [:]).values.map { guide in
                ActiveStopReplacementMapGuide(
                    id: "\(closure.id)|\(guide.routeID)",
                    closedStopName: closure.stopName,
                    guide: guide,
                    passengerInformationMessage: closure.passengerInformationMessage
                )
            }
        }
    }

    private var selectedRouteGeometries: [NetworkRouteGeometry] {
        guard let selectedRouteID,
              let route = library.busRoutes.first(where: { $0.routeID == selectedRouteID }) else { return [] }
        return RouteGeometryMatcher.matches(
            route: route,
            among: library.busRoutes,
            geometries: library.routeGeometries
        )
    }

    var body: some View { dashboardLifecycle }

    private var dashboardLayout: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            workspaceNavigationBar
            Divider()
            depotSelectionBar
            Divider()
            if simulation.session != nil {
                simulationControlBar
                Divider()
            }
            workspaceContent
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var dashboardFileHandling: some View {
        dashboardLayout
        .fileImporter(
            isPresented: $isDataImporterPresented,
            allowedContentTypes: localImportKind.allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                switch localImportKind {
                case .gtfs:
                    library.importGTFS(from: url, provenance: gtfsImportProvenance)
                case .routeGeometry:
                    library.importRouteGeometries(from: url)
                case .contracts:
                    library.importContracts(from: url)
                case .lineReference:
                    library.importLineReferences(from: url)
                case .lineDocuments:
                    library.importLineDocuments(from: url)
                }
            case let .failure(error):
                let nsError = error as NSError
                if nsError.code != NSUserCancelledError {
                    switch localImportKind {
                    case .gtfs:
                        library.reportImportError(error.localizedDescription)
                    case .routeGeometry:
                        library.reportRouteGeometryError(error.localizedDescription)
                    case .contracts:
                        library.reportContractError(error.localizedDescription)
                    case .lineReference:
                        library.reportLineReferenceError(error.localizedDescription)
                    case .lineDocuments:
                        library.reportLineDocumentError(error.localizedDescription)
                    }
                }
            }
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
                    try simulation.importSaveData(Data(contentsOf: url))
                    if let depotID = simulation.session?.effectiveActiveDepotID {
                        selectedDepotID = depotID
                    }
                    saveTransferNotice = "La carrière a été importée et mise en pause. Ses archives réseau doivent aussi être présentes dans cette installation."
                } catch {
                    saveTransferNotice = "Import impossible : \(error.localizedDescription)"
                }
            case let .failure(error):
                let nsError = error as NSError
                if nsError.code != NSUserCancelledError {
                    saveTransferNotice = "Import impossible : \(error.localizedDescription)"
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
                saveTransferNotice = "Sauvegarde exportée : \(url.lastPathComponent)."
            case let .failure(error):
                let nsError = error as NSError
                if nsError.code != NSUserCancelledError {
                    saveTransferNotice = "Export impossible : \(error.localizedDescription)"
                }
            }
        }
    }

    private var dashboardAlerts: some View {
        dashboardFileHandling
        .alert("Import du GTFS impossible", isPresented: Binding(
            get: { library.importState.errorMessage != nil },
            set: { isPresented in if !isPresented { library.clearImportError() } }
        )) {
            Button("OK", role: .cancel) { library.clearImportError() }
        } message: {
            Text(library.importState.errorMessage ?? "Une erreur est survenue.")
        }
        .alert("Import des tracés impossible", isPresented: Binding(
            get: { library.geometryImportState.errorMessage != nil },
            set: { isPresented in if !isPresented { library.clearRouteGeometryError() } }
        )) {
            Button("OK", role: .cancel) { library.clearRouteGeometryError() }
        } message: {
            Text(library.geometryImportState.errorMessage ?? "Une erreur est survenue.")
        }
        .alert("Import des contrats impossible", isPresented: Binding(
            get: { library.contractImportState.errorMessage != nil },
            set: { isPresented in if !isPresented { library.clearContractError() } }
        )) {
            Button("OK", role: .cancel) { library.clearContractError() }
        } message: {
            Text(library.contractImportState.errorMessage ?? "Une erreur est survenue.")
        }
        .alert("Import du référentiel impossible", isPresented: Binding(
            get: { library.lineReferenceImportState.errorMessage != nil },
            set: { isPresented in if !isPresented { library.clearLineReferenceError() } }
        )) {
            Button("OK", role: .cancel) { library.clearLineReferenceError() }
        } message: {
            Text(library.lineReferenceImportState.errorMessage ?? "Une erreur est survenue.")
        }
        .alert("Démarrage impossible", isPresented: Binding(
            get: { careerStartError != nil },
            set: { isPresented in
                if !isPresented {
                    careerStartError = nil
                    if isTimetableExtensionBlocked {
                        isTimetableExtensionBlocked = false
                        extendTimetableHorizonIfNeeded()
                    }
                }
            }
        )) {
            Button(isTimetableExtensionBlocked ? "Réessayer le chargement" : "OK", role: .cancel) {
                careerStartError = nil
                if isTimetableExtensionBlocked {
                    isTimetableExtensionBlocked = false
                    extendTimetableHorizonIfNeeded()
                }
            }
        } message: {
            Text(careerStartError ?? "La partie n’a pas pu être créée.")
        }
        .alert("Sauvegarde de la partie", isPresented: Binding(
            get: { simulation.errorMessage != nil },
            set: { isPresented in if !isPresented { simulation.clearError() } }
        )) {
            Button("OK", role: .cancel) { simulation.clearError() }
        } message: {
            Text(simulation.errorMessage ?? "Une erreur est survenue.")
        }
        .alert("Fichier de sauvegarde", isPresented: Binding(
            get: { saveTransferNotice != nil },
            set: { if !$0 { saveTransferNotice = nil } }
        )) {
            Button("OK", role: .cancel) { saveTransferNotice = nil }
        } message: {
            Text(saveTransferNotice ?? "Une erreur est survenue.")
        }
        .alert("Récupération de sauvegarde", isPresented: Binding(
            get: { simulation.recoveryNotice != nil },
            set: { if !$0 { simulation.clearRecoveryNotice() } }
        )) {
            Button("OK", role: .cancel) { simulation.clearRecoveryNotice() }
        } message: {
            Text(simulation.recoveryNotice ?? "La sauvegarde précédente a été chargée.")
        }
    }

    private var dashboardSheets: some View {
        dashboardAlerts
        .sheet(isPresented: $isRouteLibraryPresented) {
            NetworkRouteLibraryView(library: library, onSelectRoute: selectRoute)
                .frame(minWidth: 560, minHeight: 480)
        }
        .sheet(isPresented: $isContractLibraryPresented) {
            NetworkContractLibraryView(library: library, onSelectContract: selectContract)
                .frame(minWidth: 600, minHeight: 520)
        }
        .sheet(isPresented: $isRegionalDepotRegistryPresented) {
            RegionalDepotRegistryView(onSelectSiteID: { depotID in
                selectedDepotID = depotID
                selectedWorkspaceTab = .network
                isRegionalDepotRegistryPresented = false
            })
                .frame(minWidth: 620, minHeight: 560)
        }
        .sheet(isPresented: $isDepotLineRosterPresented) {
            DepotLineRosterView(
                initialDepotID: selectedDepotID,
                scenario: scenario,
                library: library,
                initialServiceDate: simulation.session?.simulatedAt ?? careerStartMoment
            )
            .frame(minWidth: 1040, minHeight: 700)
        }
        .sheet(isPresented: $isIncidentResponsePresented) {
            if let incident = incidentForResponse {
                IncidentResponseView(
                    simulation: simulation,
                    library: library,
                    initialIncident: incident,
                    depots: scenario.referenceDepots,
                    onIncidentUpdated: { incidentForResponse = $0 }
                )
                    .frame(minWidth: 720, minHeight: 760)
            }
        }
        .sheet(item: $routeDetourRequest) { request in
            RouteDetourEditorView(
                stop: request.stop,
                routeID: request.routeID,
                sourceObservation: request.sourceObservation,
                library: library,
                simulation: simulation
            )
            .frame(minWidth: 820, minHeight: 760)
        }
        .sheet(item: $stopClosureRequest) { request in
            StopClosureEditorView(
                stop: request.stop,
                routeID: request.routeID,
                library: library,
                simulation: simulation
            )
            .frame(minWidth: 760, minHeight: 700)
        }
    }

    private var dashboardLifecycle: some View {
        dashboardSheets
        .task {
            if let sessionDepotID = simulation.session?.effectiveActiveDepotID {
                selectedDepotID = sessionDepotID
                selectedWorkspaceTab = .network
            } else if !DepotLineRoster.selectableSites.contains(where: { $0.id == selectedDepotID }) {
                selectedDepotID = scenario.referenceDepots.first?.id ?? "saint-maur"
            }
            await library.seedBundledIDFMSnapshotsIfNeeded()
            await library.loadBusRoutes()
            await library.loadBusStops()
            await library.loadServiceCalendars()
            await library.loadActiveRouteGeometries()
            if catalog.activeGeometryVersion == nil {
                library.downloadLatestRouteGeometries()
            }
            await library.loadActiveContracts()
            await library.loadActiveLineReferences()
            await library.loadActiveLineDocuments()
            extendTimetableHorizonIfNeeded()
            fitSelectedDepotNetwork()
            if let incident = pendingIncidentResponse {
                incidentForResponse = incident
                isIncidentResponsePresented = true
            }
        }
        .task(id: scenarioLineCoverageTaskID) {
            await refreshScenarioLineCoverage(for: scenarioLineCoverageTaskID)
        }
        .task(id: activeBusTripIDs) {
            await loadActiveTripShapes()
        }
        .task(id: depotFallbackShapeTaskKey) {
            await loadDepotFallbackShapes()
        }
        .onChange(of: selectedDepotID) { _, _ in
            selectedCandidateCareerLineIDs.removeAll()
            browsedDepotID = nil
            selectedDepotLineID = nil
            selectedRouteID = nil
            selectedStop = nil
            selectedBusID = nil
            Task {
                await library.loadBusStops()
                fitSelectedDepotNetwork()
            }
        }
        .onChange(of: careerStartMoment) { _, _ in
            selectedCandidateCareerLineIDs.formIntersection(Set(selectedDepotMapLines.map(\.id)))
        }
        .onChange(of: library.routeGeometries.count) { _, count in
            if count > 0, selectedDepotLineID == nil {
                fitSelectedDepotNetwork()
            }
        }
        .onChange(of: depotFallbackShapeLineCount) { _, count in
            if count > 0, selectedDepotLineID == nil {
                fitSelectedDepotNetwork()
            }
        }
        .onChange(of: careerStartMoment) { _, _ in
            if !selectedDepotMapLines.contains(where: { $0.id == selectedDepotLineID }) {
                selectedDepotLineID = nil
                selectedRouteID = nil
            }
        }
        .onChange(of: simulation.session?.simulatedAt) { _, _ in
            extendTimetableHorizonIfNeeded()
        }
        .onChange(of: simulation.session?.id) { _, _ in
            browsedDepotID = nil
        }
        .onChange(of: pendingIncidentResponse?.id) { _, incidentID in
            guard let incidentID,
                  let incident = simulation.session?.vehicleIncidents?.first(where: { $0.id == incidentID }) else { return }
            incidentForResponse = incident
            isIncidentResponsePresented = true
        }
        .onDisappear {
            simulation.pauseAndSave()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "bus.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)
                .background(.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 1) {
                Text("Transport Manager IDFM")
                    .font(.headline)
                Text(simulation.session == nil
                     ? "Choisis un dépôt et exploite ses lignes réelles"
                     : "Partie en cours · \(scenario.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if library.importState.isImporting || library.geometryImportState.isImporting || catalog.activeVersion == nil {
                HStack(spacing: 6) {
                    if library.importState.isImporting || library.geometryImportState.isImporting {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(.secondary)
                    }
                    Text(networkStatusTitle)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.quaternary, in: Capsule())
                .help(networkStatusHelp)
            }

            if simulation.session == nil {
                DatePicker("Départ", selection: $careerStartMoment, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .frame(width: 190)
                    .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
                    .help("Date et heure de début de la carrière")
            }

            Menu {
                if simulation.session != nil {
                    Button {
                        prepareSaveExport()
                    } label: {
                        Label("Exporter la carrière…", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        simulation.save()
                    } label: {
                        Label("Sauvegarder maintenant", systemImage: "externaldrive")
                    }
                    Divider()
                }
                Button {
                    isSaveImporterPresented = true
                } label: {
                    Label("Importer une carrière…", systemImage: "square.and.arrow.down")
                }
                if simulation.session == nil {
                    Divider()
                    Picker("Fréquence des pannes", selection: $breakdownFrequency) {
                        ForEach(VehicleIncidentFrequency.allCases) { frequency in
                            Text(frequency.title).tag(frequency)
                        }
                    }
                    Text(breakdownFrequency.explanation)
                        .font(.caption)
                }
            } label: {
                Label("Options", systemImage: "ellipsis.circle")
            }
            .menuStyle(.borderedButton)
            .help("Sauvegarde et options de carrière")

            if simulation.session == nil, isSelectedDepotPlayable {
                Button(action: startCareer) {
                    if isPreparingTimetable {
                        Label("Chargement des horaires…", systemImage: "clock.arrow.circlepath")
                    } else {
                        Label("Démarrer", systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canStartCareer || isPreparingTimetable)
                .help(startCareerHelp)
            } else if simulation.session == nil {
                Button {
                    selectedWorkspaceTab = .lines
                } label: {
                    Label("Voir les lignes", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.borderedProminent)
                .help("Ouvre les lignes réelles, les plans PDF et les grilles horaires de ce dépôt")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
    }

    private var workspaceNavigationBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 3) {
                ForEach(OperationsWorkspaceTab.allCases) { tab in
                    Button {
                        selectedWorkspaceTab = tab
                    } label: {
                        VStack(spacing: 6) {
                            Label(tab.title, systemImage: tab.symbol)
                                .font(.system(size: 13, weight: selectedWorkspaceTab == tab ? .semibold : .medium))
                                .frame(maxWidth: .infinity)
                            Capsule()
                                .fill(selectedWorkspaceTab == tab ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .foregroundStyle(selectedWorkspaceTab == tab ? Color.accentColor : Color.secondary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedWorkspaceTab == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .scrollIndicators(.hidden)
        .background(Color.primary.opacity(0.02))
    }

    @ViewBuilder
    private var workspaceContent: some View {
        VStack(spacing: 0) {
            if selectedWorkspaceTab != .network {
                workspaceNavigationHeader
                Divider()
            }

            workspaceBody
        }
    }

    private var workspaceNavigationHeader: some View {
        HStack(spacing: 12) {
            Text(selectedWorkspaceTab.title)
                .font(.headline)

            Spacer()

            if simulation.session != nil, lineCatalogDepotID != selectedDepotID, selectedWorkspaceTab == .lines {
                Label("Consultation", systemImage: "eye")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text((selectedWorkspaceTab == .lines
                ? DepotLineRoster.selectableSites.first(where: { $0.id == lineCatalogDepotID })?.name
                : nil) ?? selectedDepotSite?.name ?? selectedDepot?.name ?? "Aucun dépôt")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.025))
    }

    @ViewBuilder
    private var workspaceBody: some View {
        switch selectedWorkspaceTab {
        case .network:
            HStack(spacing: 0) {
                depotLineSidebar
                Divider()
                mapPanel
            }
        case .lines:
            DepotLinesWorkspaceView(
                library: library,
                depotID: lineCatalogDepotID,
                serviceDate: selectedDepotRosterDate,
                selectedLineID: $selectedDepotLineID,
                showsMapNavigation: lineCatalogCanShowOnMap,
                operatedRouteIDs: selectedDepotRouteIDs,
                isPreparingTimetable: isPreparingTimetable,
                onOperateLine: simulation.session?.effectiveManagedDepotIDs.contains(selectedDepotID) == true
                    && lineCatalogDepotID == selectedDepotID
                    ? { row in
                        guard let line = selectedDepotMapLines.first(where: { $0.id == row.id }) else { return }
                        assignDepotLineToActiveDepot(line)
                    }
                    : nil,
                onShowOnMap: { row in
                    selectedDepotLineID = row.id
                    selectedWorkspaceTab = .network
                }
            )
        case .assignments:
            VStack(spacing: 0) {
                sectionPicker(AssignmentWorkspaceSection.allCases, selection: $assignmentWorkspaceSection, title: "Affectations")
                Group {
                    switch assignmentWorkspaceSection {
                    case .depotLines:
                        DepotAssignmentManagerView(
                            library: library,
                            scenario: scenario,
                            depot: selectedDepot,
                            showsCloseButton: false
                        )
                    case .busDepartures:
                        if simulation.session == nil {
                            sessionRequiredWorkspace(title: "Démarre une partie pour affecter un bus et un conducteur à un départ.", symbol: "arrow.triangle.branch")
                        } else {
                            TripDispatchView(
                                library: library,
                                simulation: simulation,
                                depotRouteIDs: selectedDepotRouteIDs,
                                showsCloseButton: false
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case .fleet:
            if simulation.session == nil {
                sessionRequiredWorkspace(title: "Démarre une partie pour acheter et gérer les bus du dépôt.", symbol: "bus")
            } else {
                VehicleMarketView(
                    simulation: simulation,
                    activeDepotID: simulation.session?.effectiveActiveDepotID ?? selectedDepotID,
                    showsCloseButton: false
                )
            }
        case .staff:
            if simulation.session == nil {
                sessionRequiredWorkspace(title: "Démarre une partie pour recruter et gérer l’équipe de conduite.", symbol: "person.2")
            } else {
                MachinistManagementView(
                    simulation: simulation,
                    activeDepotID: simulation.session?.effectiveActiveDepotID ?? selectedDepotID,
                    showsCloseButton: false
                )
            }
        case .reports:
            VStack(spacing: 0) {
                sectionPicker(ReportWorkspaceSection.allCases, selection: $reportWorkspaceSection, title: "Rapports")
                Group {
                    if simulation.session == nil {
                        sessionRequiredWorkspace(title: "Démarre une partie pour consulter les bilans d’exploitation, les finances, la paie et la progression.", symbol: "chart.bar")
                    } else {
                        switch reportWorkspaceSection {
                        case .daily:
                            DailyOperationsReportView(simulation: simulation, showsCloseButton: false)
                        case .finances:
                            MonthlyFinancialReportView(simulation: simulation, showsCloseButton: false)
                        case .payroll:
                            MonthlyMachinistPayrollView(simulation: simulation, showsCloseButton: false)
                        case .progression:
                            CareerProgressionView(simulation: simulation)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case .incidents:
            if simulation.session == nil {
                sessionRequiredWorkspace(title: "Démarre une partie pour suivre les pannes et les interventions.", symbol: "wrench.and.screwdriver")
            } else {
                IncidentHistoryView(
                    simulation: simulation,
                    showsCloseButton: false,
                    onPreparePRIMDetour: { alert in
                        routeDetourRequest = RouteDetourRequest(
                            stop: nil,
                            routeID: alert.routeID,
                            sourceObservation: alert.observation
                        )
                    },
                    onDismissPRIMAlert: { alertID in
                        simulation.dismissPRIMTrafficAlert(id: alertID)
                    }
                )
            }
        case .depots:
            DepotDirectoryWorkspaceView(
                library: library,
                selectedDepotID: browsedDepotID ?? selectedDepotID,
                careerDepotID: simulation.session?.effectiveActiveDepotID,
                managedDepotIDs: simulation.session?.effectiveManagedDepotIDs ?? [],
                selectionLocked: simulation.session != nil,
                serviceDate: selectedDepotRosterDate,
                operatedRouteIDsForDepot: { depotID in
                    simulation.session?.effectiveOperatedRouteIDs(for: depotID) ?? []
                },
                onSelect: { depotID in
                    selectedDepotID = depotID
                    browsedDepotID = nil
                },
                onOpen: { depotID in
                    if simulation.session == nil {
                        selectedDepotID = depotID
                        browsedDepotID = nil
                    } else {
                        browsedDepotID = depotID
                    }
                    selectedDepotLineID = nil
                    selectedRouteID = nil
                    selectedStop = nil
                    selectedBusID = nil
                    selectedWorkspaceTab = .network
                },
                onActivate: { depotID in
                    if simulation.session?.effectiveManagedDepotIDs.contains(depotID) == true {
                        simulation.setActiveDepot(depotID)
                        selectedDepotID = depotID
                        browsedDepotID = nil
                        selectedDepotLineID = nil
                        selectedWorkspaceTab = .network
                    } else {
                        addDepotToCareer(depotID)
                    }
                }
            )
        case .sources:
            VStack(spacing: 0) {
                dataWorkspaceNavigation
                Group {
                    switch dataWorkspaceSection {
                    case .fullNetwork:
                        NetworkRouteLibraryView(library: library) { route in
                            selectRoute(route)
                            selectedWorkspaceTab = .network
                        }
                    case .contracts:
                        NetworkContractLibraryView(library: library) { feature in
                            selectContract(feature)
                            selectedWorkspaceTab = .network
                        }
                    case .coverage:
                        NetworkCoverageAuditView(library: library, scenario: scenario, initialDate: selectedDepotRosterDate, showsCloseButton: false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func depotCoverageMetric(_ title: String, value: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 17)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption.weight(.semibold).monospacedDigit())
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
    }

    private func regionalDepotSummary(_ site: DepotLineRosterSite) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(site.availability.label, systemImage: site.availability.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(site.availability == .operational ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(site.name).font(.title2.weight(.semibold))
                Text(site.locality).foregroundStyle(.secondary)
            }
            Text(site.status)
                .font(.callout.weight(.medium))
            if let address = site.documentedAddress {
                Text("Adresse publiée : \(address)")
            }
            Text(site.evidenceNote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(site.evidenceLinks) { evidence in
                Link(evidence.title, destination: evidence.url)
                    .font(.callout)
            }
            Divider()
            if let contractID = site.idfmBusContractID {
                Text("\(selectedDepotMapLines.count) lignes du contrat DSP \(contractID) visibles · rattachement COB à confirmer selon la source")
                    .font(.subheadline.weight(.semibold))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), alignment: .leading)], alignment: .leading, spacing: 8) {
                    depotCoverageMetric("Lignes uniques · variantes", value: "\(selectedDepotLineCoverage.uniqueLineCount) · \(selectedDepotLineCoverage.routeVariantCount)", symbol: "point.3.connected.trianglepath.dotted")
                    depotCoverageMetric("Tracés officiels", value: selectedDepotLineCoverage.traceCoverage, symbol: "point.topleft.down.to.point.bottomright.curvepath")
                    depotCoverageMetric("Plans · fiches horaires", value: "\(selectedDepotLineCoverage.planCoverage) · \(selectedDepotLineCoverage.timetableCoverage)", symbol: "doc.text")
                    depotCoverageMetric("Références ambiguës / absentes", value: "\(selectedDepotLineCoverage.ambiguousReferenceCount) / \(selectedDepotLineCoverage.missingReferenceCount)", symbol: "questionmark.circle")
                    depotCoverageMetric("Sans route GTFS", value: "\(selectedDepotLineCoverage.missingGTFSCount)", symbol: "bus")
                    depotCoverageMetric("Variantes sans plan · horaire", value: "\(selectedDepotLineCoverage.routesWithoutPlans.count) · \(selectedDepotLineCoverage.routesWithoutTimetables.count)", symbol: "doc.text")
                    depotCoverageMetric("COB non confirmé", value: "\(selectedDepotLineCoverage.unconfirmedDepotEvidenceCount)/\(selectedDepotLineCoverage.uniqueLineCount)", symbol: "building.2")
                }
                DepotMissingRouteDocumentsDisclosure(coverage: selectedDepotLineCoverage)
                if DepotLineRoster.bordsDeMarneManifestSiteIDs.contains(selectedDepotID) {
                    Label(
                        "\(DepotLineRosterManifestCatalog.state.summary) · \(DepotLineRosterManifestCatalog.entries(for: selectedDepotRosterDate).count) actives à cette date",
                        systemImage: DepotLineRosterManifestCatalog.state.isValid ? "checkmark.seal" : "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(DepotLineRosterManifestCatalog.state.isValid ? Color.secondary : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }
                Text("Les lignes, tracés et horaires proviennent du réseau IDFM daté. Une ligne du contrat n’est attribuée à ce dépôt par le jeu que si elle est documentée ou si elle a été affectée ici dans la carrière.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("\(selectedDepotMapLines.count) lignes documentées pour ce site")
                    .font(.subheadline.weight(.semibold))
            }
            if selectedDepotMapLines.isEmpty {
                Text(site.idfmBusContractID == nil
                     ? "Le catalogue IDFM contient le réseau régional, mais aucune ligne n’est rattachée à ce site dans les sources enregistrées. Les lignes ne sont pas déduites de la seule adresse du dépôt."
                     : "Aucune référence IDFM active n’a été trouvée pour ce contrat à cette date.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                isDepotLineRosterPresented = true
            } label: {
                Label("Consulter les lignes et preuves", systemImage: "list.bullet.rectangle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(simulation.session != nil)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: 780, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func sectionPicker<Section: WorkspacePickerSection>(
        _ sections: [Section],
        selection: Binding<Section>,
        title: String
    ) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Picker(title, selection: selection) {
                ForEach(sections) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(Color.primary.opacity(0.025))
    }

    private var dataWorkspaceNavigation: some View {
        HStack(spacing: 12) {
            Picker("Référentiels", selection: $dataWorkspaceSection) {
                ForEach(DataWorkspaceSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)

            Menu {
                Button("Offre théorique GTFS…") { presentImporter(.gtfs) }
                Button("Tracés GeoJSON…") { presentImporter(.routeGeometry) }
                Button("Référentiel IDFM…") { presentImporter(.lineReference) }
                Button("Plans et horaires CSV…") { presentImporter(.lineDocuments) }
                Button("Contours de contrats GeoJSON…") { presentImporter(.contracts) }
            } label: {
                Label("Importer", systemImage: "square.and.arrow.down")
            }
            .menuStyle(.borderedButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.025))
    }

    private func sessionRequiredWorkspace(title: String, symbol: String) -> some View {
        ContentUnavailableView {
            Label("Aucune partie en cours", systemImage: symbol)
        } description: {
            Text(title)
        } actions: {
            Button("Démarrer une partie", action: startCareer)
                .buttonStyle(.borderedProminent)
                .disabled(!canStartCareer || isPreparingTimetable)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var networkStatusTitle: String {
        if library.importState.isImporting { return "Import initial du réseau" }
        if library.geometryImportState.isImporting { return "Chargement des tracés" }
        if catalog.activeVersion == nil { return "Réseau en attente" }
        return "\(selectedDepotMapLines.count) lignes affichées"
    }

    private var networkStatusHelp: String {
        if let version = catalog.activeVersion {
            let validThrough = version.validThrough.map { " · horaires jusqu’au \(Self.shortDate($0))" } ?? ""
            return "Réseau GTFS IDFM intégré\(validThrough)."
        }
        return "Le réseau intégré se charge au premier lancement."
    }

    private var startCareerHelp: String {
        if catalog.activeVersion == nil { return "Le réseau GTFS intégré est encore en cours de chargement." }
        if !isSelectedDepotPlayable { return "Ce site reste consultable. Pour démarrer, il faut un dépôt relié publiquement à une DSP avec des lignes actives." }
        if selectedDepotRouteIDs.isEmpty { return "Choisis au moins une ligne confirmée ou coche une ligne candidate à exploiter. Les candidates ne sont pas affectées automatiquement." }
        if !isCareerStartWithinNetworkValidity { return "Choisis une date couverte par les horaires GTFS intégrés." }
        if catalog.activeGeometryVersion == nil { return "Les tracés officiels du réseau sont en cours de chargement." }
        let statusNote = selectedDepotSite?.availability == .currentStatusUnverified
            ? " Le statut actuel du centre reste à vérifier."
            : ""
        return "Démarrer une partie avec les lignes réelles de la DSP \(scenario.idfmBusContractID). Les lignes non ventilées par COB restent signalées comme candidates.\(statusNote)"
    }

    private func presentImporter(_ kind: LocalImportKind) {
        localImportKind = kind
        isDataImporterPresented = true
    }

    private func presentStopClosureEditor(for stop: GTFSStopSummary, routeID: String) {
        selectedStop = nil
        Task { @MainActor in
            await Task.yield()
            stopClosureRequest = StopClosureRequest(stop: stop, routeID: routeID)
        }
    }

    private var depotSelectionBar: some View {
        HStack(spacing: 13) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("DÉPÔT")
                    .font(.caption2.weight(.bold))
                    .tracking(0.7)
                Text(currentlyDisplayedDepotName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 165, alignment: .leading)

            Menu {
                if let session = simulation.session {
                    Section("Dépôts de mon entreprise") {
                        ForEach(session.effectiveManagedDepotIDs.sorted(), id: \.self) { depotID in
                            Button {
                                simulation.setActiveDepot(depotID)
                                selectedDepotID = depotID
                                browsedDepotID = nil
                                selectedDepotLineID = nil
                                selectedWorkspaceTab = .network
                            } label: {
                                if depotID == session.effectiveActiveDepotID {
                                    Label(DepotCareerScope.depotReference(for: depotID)?.name ?? depotID, systemImage: "checkmark")
                                } else {
                                    Text(DepotCareerScope.depotReference(for: depotID)?.name ?? depotID)
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        browsedDepotID = nil
                        selectedWorkspaceTab = .depots
                    } label: {
                        Label("Choisir parmi tous les dépôts régionaux…", systemImage: "magnifyingglass")
                    }
                } else {
                    Button {
                        selectedWorkspaceTab = .depots
                    } label: {
                        Label("Choisir parmi tous les dépôts régionaux…", systemImage: "magnifyingglass")
                    }
                }
            } label: {
                Label(simulation.session == nil ? "Choisir un dépôt" : "Changer de dépôt", systemImage: "chevron.down")
            }
            .menuStyle(.borderedButton)
            .help(simulation.session == nil
                ? "Choisir un dépôt régional et consulter ses lignes réelles"
                : "Changer de dépôt actif ou choisir un site dans le répertoire régional complet")

            if let selectedDepotSite {
                Text(selectedDepotSite.availability.shortLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(selectedDepotSite.isOperational ? Color.green : Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background((selectedDepotSite.isOperational ? Color.green : Color.orange).opacity(0.11), in: Capsule())
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.025))
    }

    private var currentlyDisplayedDepotName: String {
        if let activeDepotID = simulation.session?.effectiveActiveDepotID {
            return DepotCareerScope.depotReference(for: activeDepotID)?.name ?? activeDepotID
        }
        return selectedDepotSite?.name ?? selectedDepot?.name ?? "Choisis ton centre"
    }

    private var simulationControlBar: some View {
        Group {
            if let session = simulation.session {
                HStack(spacing: 13) {
                    Label(session.simulatedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)

                    Label(simulation.isRunning ? "En marche" : "En pause", systemImage: simulation.isRunning ? "play.fill" : "pause.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(simulation.isRunning ? Color.green : Color.secondary)

                    if let lastSavedAt = simulation.lastSavedAt {
                        Label(lastSavedAt.formatted(date: .omitted, time: .shortened), systemImage: "checkmark.icloud")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .help("Dernière sauvegarde réussie · \(lastSavedAt.formatted(date: .complete, time: .shortened))")
                    }

                    Text("\(session.pendingServiceDepartureCount.formatted()) départs à assurer · \(session.missedServiceDepartureCount.formatted()) manqués")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(session.missedServiceDepartureCount == 0 ? Color.secondary : Color.orange)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Picker("Vitesse", selection: Binding(
                        get: { simulation.session?.speed ?? .paused },
                        set: { simulation.setSpeed($0) }
                    )) {
                        ForEach(SimulationSpeed.allCases) { speed in Text(speed.title).tag(speed) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 105)
                    .disabled((isTimetableExtensionBlocked && !simulation.isRunning) || pendingIncidentResponse != nil)

                    Button {
                        if simulation.isRunning { simulation.pause() } else { simulation.resume() }
                    } label: {
                        Label(simulation.isRunning ? "Pause" : "Reprendre", systemImage: simulation.isRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled((isTimetableExtensionBlocked && !simulation.isRunning) || pendingIncidentResponse != nil)

                    Button {
                        _ = simulation.advanceToNextEvent()
                    } label: {
                        Label("Prochain départ", systemImage: "forward.end.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(session.pendingEvents.isEmpty || pendingIncidentResponse != nil)

                    Button {
                        assignmentWorkspaceSection = .busDepartures
                        selectedWorkspaceTab = .assignments
                    } label: {
                        Label("Affecter un départ", systemImage: "arrow.triangle.branch")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(session.pendingServiceDepartureCount == 0
                              || !(session.ownedBuses ?? []).contains { $0.status == .atDepot || $0.status == .atStop })
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.015))
                .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
            }
        }
    }

    private var depotLineSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lignes du dépôt")
                        .font(.headline)
                    Text(simulation.session == nil
                         ? "\(selectedDepotRouteIDs.count) variantes retenues · \(selectedDepotMapLines.count) lignes au catalogue"
                         : "\(selectedDepotMapLines.count) lignes sur la carte")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button {
                    selectedWorkspaceTab = .lines
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Ouvrir les plans PDF, les fiches horaires et les preuves de chaque ligne")
            }
            .padding(14)

            Divider()

            if simulation.session == nil {
                Text("Les lignes confirmées sont incluses. Utilise le bouton rond pour choisir les autres lignes que tu veux exploiter.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
            } else if simulation.session?.effectiveManagedDepotIDs.contains(selectedDepotID) == true,
                      selectedDepotRouteIDs.isEmpty {
                Text("Aucune ligne n’est encore affectée à ce dépôt. Ouvre une ligne et choisis « Exploiter cette ligne depuis ce dépôt ».")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
            }

            if selectedDepotMapLines.isEmpty {
                ContentUnavailableView(
                    catalog.activeVersion == nil ? "Chargement du réseau" : "Aucune ligne trouvée",
                    systemImage: catalog.activeVersion == nil ? "arrow.triangle.2.circlepath" : "bus",
                    description: Text(catalog.activeVersion == nil
                        ? "Le réseau GTFS intégré est en cours de préparation."
                        : selectedDepotSite?.idfmBusContractID != nil
                            ? "Aucune référence IDFM active du contrat n’est disponible pour cette date."
                            : selectedDepotSite?.availability == .currentStatusUnverified
                                ? "Ce site est consultable, mais aucune ligne n’est encore reliée à lui dans le registre public. L’application n’invente pas d’affectation à partir de l’adresse."
                                : "Aucune ligne datée n’est recensée pour ce dépôt à cette date.")
                )
                .padding(12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(selectedDepotMapLines) { line in
                            HStack(spacing: 5) {
                                Button {
                                    selectDepotLine(line)
                                } label: {
                                    depotLineRow(line)
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                if simulation.session == nil,
                                   !line.routes.isEmpty,
                                   line.row.evidenceStatus(on: selectedDepotRosterDate) != .confirmed,
                                   line.row.evidenceStatus(on: selectedDepotRosterDate) != .planned {
                                    Button {
                                        toggleCandidateCareerLine(line)
                                    } label: {
                                        Image(systemName: selectedCandidateCareerLineIDs.contains(line.id)
                                            ? "checkmark.circle.fill"
                                            : "circle")
                                            .font(.title3)
                                            .foregroundStyle(selectedCandidateCareerLineIDs.contains(line.id) ? Color.accentColor : Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 3)
                                    .help(selectedCandidateCareerLineIDs.contains(line.id)
                                        ? "Retirer cette ligne des affectations de départ"
                                        : "Choisir cette ligne candidate pour la carrière")
                                    .accessibilityLabel(selectedCandidateCareerLineIDs.contains(line.id)
                                        ? "Retirer la ligne \(line.row.line) de la carrière"
                                        : "Inclure la ligne \(line.row.line) dans la carrière")
                                }
                            }
                            .contextMenu {
                                Button {
                                    selectedDepotLineID = line.id
                                    selectedWorkspaceTab = .lines
                                } label: {
                                    Label("Plans et horaires de la ligne", systemImage: "doc.text")
                                }
                                if let route = line.routes.first {
                                    Button {
                                        selectRoute(route)
                                    } label: {
                                        Label("Centrer la ligne sur la carte", systemImage: "scope")
                                    }
                                }
                                if simulation.session == nil,
                                   !line.routes.isEmpty,
                                   line.row.evidenceStatus(on: selectedDepotRosterDate) != .confirmed,
                                   line.row.evidenceStatus(on: selectedDepotRosterDate) != .planned {
                                    Button {
                                        toggleCandidateCareerLine(line)
                                    } label: {
                                        Label(
                                            selectedCandidateCareerLineIDs.contains(line.id)
                                                ? "Retirer de la carrière"
                                                : "Inclure dans la carrière",
                                            systemImage: selectedCandidateCareerLineIDs.contains(line.id)
                                                ? "minus.circle"
                                                : "checkmark.circle"
                                        )
                                    }
                                }
                                if simulation.session?.effectiveManagedDepotIDs.contains(selectedDepotID) == true,
                                   !line.routes.isEmpty {
                                    Button {
                                        assignDepotLineToActiveDepot(line)
                                    } label: {
                                        Label("Exploiter cette ligne depuis ce dépôt", systemImage: "arrow.down.left.and.arrow.up.right")
                                    }
                                    .disabled(Set(line.routes.map(\.routeID)).isSubset(of: selectedDepotRouteIDs) || isPreparingTimetable)
                                }
                            }
                        }
                    }
                    .padding(8)
                }
            }

            Divider()
            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.secondary)
                Text("Les pointillés signalent un rattachement à confirmer. Ouvre une ligne pour consulter ses sources et ses horaires.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
        }
        .frame(width: 286)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func depotLineRow(_ line: DepotMapLine) -> some View {
        let isSelected = selectedDepotLineID == line.id
        let color = line.geometries.first.map { routeColor(for: $0) } ?? .secondary
        let routeSummary = line.routes.isEmpty
            ? "Parcours à compléter"
            : "\(line.routes.count) \(line.routes.count == 1 ? "variante" : "variantes")"
        return HStack(spacing: 10) {
            Text(line.row.line)
                .font(.system(.body, design: .rounded).monospaced().weight(.bold))
                .foregroundStyle(line.geometries.isEmpty ? Color.secondary : color)
                .frame(minWidth: 45, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(line.row.category)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(routeSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: line.geometries.isEmpty ? "map" : "point.topleft.down.curvedto.point.bottomright.up")
                .font(.caption)
                .foregroundStyle(line.geometries.isEmpty ? Color.secondary.opacity(0.55) : color)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.11) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.055), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }

    private func refreshScenarioLineCoverage(for taskID: String) async {
        scenarioLineCoverageTaskKey = taskID
        guard simulation.session == nil,
              let checklist = scenarioLineChecklist,
              isCareerStartWithinNetworkValidity,
              let version = catalog.activeVersion,
              !library.busRoutes.isEmpty else {
            scenarioLineCoverage = nil
            scenarioLineCoverageError = nil
            isLoadingScenarioLineCoverage = false
            return
        }

        let expectedNames = checklist.lineNames
        let candidateRoutes = library.busRoutes

        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let serviceDayStart = calendar.startOfDay(for: careerStartMoment)
        guard let serviceDayEnd = calendar.date(byAdding: .day, value: 1, to: serviceDayStart) else {
            scenarioLineCoverageError = "La date de service sélectionnée est invalide."
            isLoadingScenarioLineCoverage = false
            return
        }

        isLoadingScenarioLineCoverage = true
        scenarioLineCoverageError = nil
        defer {
            if taskID == scenarioLineCoverageTaskID {
                isLoadingScenarioLineCoverage = false
            }
        }

        do {
            let departures = try await library.loadScheduledDepartures(
                gtfsVersionID: version.id,
                routeIDs: Set(candidateRoutes.map(\.routeID)),
                from: serviceDayStart,
                through: serviceDayEnd
            )
            guard !Task.isCancelled, taskID == scenarioLineCoverageTaskID else { return }
            let activeRouteIDs = Set(departures.map(\.routeID))
            let activeRoutes = candidateRoutes.filter { activeRouteIDs.contains($0.routeID) }
            scenarioLineCoverage = .compare(
                expectedLineNames: expectedNames,
                activeReferences: library.lineReferences,
                against: activeRoutes,
                on: careerStartMoment
            )
            scenarioLineCoverageError = nil
        } catch {
            guard !Task.isCancelled, taskID == scenarioLineCoverageTaskID else { return }
            scenarioLineCoverage = nil
            scenarioLineCoverageError = "Impossible de lire les services de cette date : \(error.localizedDescription)"
        }
    }

    private func addDepotToCareer(_ depotID: String) {
        guard let session = simulation.session,
              !session.effectiveManagedDepotIDs.contains(depotID),
              DepotCareerScope.depotReference(for: depotID) != nil,
              let site = DepotLineRoster.selectableSites.first(where: { $0.id == depotID }),
              site.hasPlayableContractScope,
              site.availability != .planned else { return }
        do {
            try simulation.addManagedDepot(depotID, operatedRouteIDs: [])
            selectedDepotID = depotID
            browsedDepotID = nil
            selectedDepotLineID = nil
            selectedWorkspaceTab = .network
        } catch {
            careerStartError = "Impossible d’ajouter ce dépôt à la carrière : \(error.localizedDescription)"
        }
    }

    private func assignDepotLineToActiveDepot(_ line: DepotMapLine) {
        guard let session = simulation.session,
              session.effectiveManagedDepotIDs.contains(selectedDepotID) else { return }
        let routeIDs = Set(line.routes.map(\.routeID))
        guard !routeIDs.isEmpty else { return }
        let newlyScheduledRouteIDs = routeIDs.subtracting(session.operatedRouteIDs ?? [])
        let horizonEnd = session.timetableHorizonEnd ?? session.simulatedAt.addingTimeInterval(48 * 60 * 60)
        isPreparingTimetable = true
        Task {
            defer { isPreparingTimetable = false }
            do {
                let departures = newlyScheduledRouteIDs.isEmpty ? [] : try await library.loadScheduledDepartures(
                    gtfsVersionID: session.networkVersions.gtfsID,
                    routeIDs: newlyScheduledRouteIDs,
                    from: session.simulatedAt,
                    through: horizonEnd
                )
                try simulation.assignRoutesToDepot(
                    Array(routeIDs),
                    depotID: selectedDepotID,
                    scheduledDepartures: departures
                )
                selectedDepotID = session.effectiveActiveDepotID
            } catch {
                careerStartError = "Affectation de ligne impossible : \(error.localizedDescription)"
            }
        }
    }

    private func toggleCandidateCareerLine(_ line: DepotMapLine) {
        guard simulation.session == nil,
              !line.routes.isEmpty,
              line.row.evidenceStatus(on: selectedDepotRosterDate) != .confirmed,
              line.row.evidenceStatus(on: selectedDepotRosterDate) != .planned else { return }
        if selectedCandidateCareerLineIDs.contains(line.id) {
            selectedCandidateCareerLineIDs.remove(line.id)
        } else {
            selectedCandidateCareerLineIDs.insert(line.id)
        }
    }

    private func startCareer() {
        guard canStartCareer,
              let gtfsVersion = catalog.activeVersion,
              let geometryVersion = catalog.activeGeometryVersion,
              let contractVersion = catalog.activeContractVersion,
              let lineReferenceVersion = catalog.activeLineReferenceVersion else { return }
        let depotID = selectedDepotID

        let networkVersions = SimulationDataVersions(
            gtfsID: gtfsVersion.id,
            routeGeometryID: geometryVersion.id,
            contractID: contractVersion.id,
            lineReferenceID: lineReferenceVersion.id
        )
        let startDate = careerStartMoment
        let initialHorizonEnd = startDate.addingTimeInterval(48 * 60 * 60)
        let careerScenarioID = scenario.id
        let operatedRouteIDs = selectedDepotRouteIDs
        let assignmentRecordIDs = selectedDepotAssignments
            .filter { operatedRouteIDs.contains($0.routeID) }
            .map(\.id)
        guard !operatedRouteIDs.isEmpty else { return }
        isPreparingTimetable = true
        Task {
            defer { isPreparingTimetable = false }
            do {
                let departures = try await library.loadScheduledDepartures(
                    gtfsVersionID: gtfsVersion.id,
                    routeIDs: operatedRouteIDs,
                    from: startDate,
                    through: initialHorizonEnd
                )
                guard !departures.isEmpty else {
                    careerStartError = "Aucun départ n’a été trouvé pour les lignes connues de ce dépôt dans les 48 prochaines heures. Vérifie la date et les calendriers GTFS."
                    return
                }
                try simulation.startNew(
                    scenarioID: careerScenarioID,
                    depotID: depotID,
                    networkVersions: networkVersions,
                    startDate: startDate,
                    operatedRouteIDs: Array(operatedRouteIDs),
                    assignmentRecordIDs: assignmentRecordIDs,
                    managedDepotIDs: [depotID],
                    operatedRouteIDsByDepot: [depotID: Array(operatedRouteIDs)],
                    scheduledDepartures: departures,
                    timetableHorizonEnd: initialHorizonEnd,
                    breakdownFrequency: breakdownFrequency
                )
                selectedWorkspaceTab = .network
            } catch {
                careerStartError = error.localizedDescription
            }
        }
    }

    private func prepareSaveExport() {
        do {
            saveExportDocument = SimulationSaveFile(data: try simulation.exportSaveData())
            isSaveExporterPresented = true
        } catch {
            saveTransferNotice = "Export impossible : \(error.localizedDescription)"
        }
    }

    private func loadActiveTripShapes() async {
        guard let gtfsVersionID = simulation.session?.networkVersions.gtfsID else {
            activeTripShapes = []
            return
        }
        let tripIDs = activeBusTripIDs
        do {
            let shapesByTripID = try await library.loadScheduledTripShapes(
                gtfsVersionID: gtfsVersionID,
                tripIDs: Set(tripIDs)
            )
            guard !Task.isCancelled else { return }
            var seenShapeIDs = Set<String>()
            activeTripShapes = tripIDs.compactMap { tripID in
                guard let shape = shapesByTripID[tripID], shape.points.count >= 2 else { return nil }
                guard seenShapeIDs.insert(shape.shapeID).inserted else { return nil }
                return ActiveTripMapShape(tripID: tripID, shapeID: shape.shapeID, points: shape.points)
            }
        } catch {
            if !Task.isCancelled { activeTripShapes = [] }
        }
    }

    private func loadDepotFallbackShapes() async {
        depotFallbackShapesByRouteID = [:]
        guard let gtfsVersionID = simulation.session?.networkVersions.gtfsID ?? catalog.activeVersion?.id else {
            isLoadingDepotFallbackShapes = false
            return
        }
        let routeIDs = Set(selectedDepotMapLines
            .filter { $0.geometries.isEmpty }
            .flatMap(\.routes)
            .map(\.routeID))
        guard !routeIDs.isEmpty,
              let serviceDateKey = GTFSServiceDate.key(
                for: GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: selectedDepotRosterDate),
                timeZone: GTFSServiceDate.parisTimeZone
              ) else {
            isLoadingDepotFallbackShapes = false
            return
        }

        isLoadingDepotFallbackShapes = true
        defer { isLoadingDepotFallbackShapes = false }
        do {
            let shapes = try await library.loadRouteShapes(
                gtfsVersionID: gtfsVersionID,
                routeIDs: routeIDs,
                serviceDateKey: serviceDateKey
            )
            guard !Task.isCancelled else { return }
            depotFallbackShapesByRouteID = shapes
        } catch {
            if !Task.isCancelled { depotFallbackShapesByRouteID = [:] }
        }
    }

    private func extendTimetableHorizonIfNeeded() {
        guard !isPreparingTimetable,
              !isTimetableExtensionBlocked,
              let session = simulation.session else { return }
        guard let operatedRouteIDs = session.operatedRouteIDs, !operatedRouteIDs.isEmpty else { return }
        let now = session.simulatedAt
        let horizonStart = session.timetableHorizonEnd ?? now
        if session.timetableHorizonEnd != nil,
           horizonStart.timeIntervalSince(now) > 24 * 60 * 60 { return }

        let horizonDuration: TimeInterval = session.timetableHorizonEnd == nil ? 48 * 60 * 60 : 24 * 60 * 60
        let horizonEnd = horizonStart.addingTimeInterval(horizonDuration)
        isPreparingTimetable = true
        Task {
            defer { isPreparingTimetable = false }
            do {
                let departures = try await library.loadScheduledDepartures(
                    gtfsVersionID: session.networkVersions.gtfsID,
                    routeIDs: Set(operatedRouteIDs),
                    from: horizonStart,
                    through: horizonEnd
                )
                simulation.appendScheduledDepartures(departures, through: horizonEnd)
            } catch {
                isTimetableExtensionBlocked = true
                careerStartError = "Le calendrier de la partie n’a pas pu être prolongé : \(error.localizedDescription) La simulation est mise en pause."
                simulation.pause()
            }
        }
    }

    private var scenarioPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 7) {
                eyebrow("SCÉNARIO DE RÉFÉRENCE")
                Text(scenario.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text(scenario.networkName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(scenario.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(scenario.contractID) · \(scenario.operatorName)")
                    .font(.subheadline.weight(.semibold))
                Text("Annonce IDFM à l’attribution · durée de base \(scenario.contractDurationYears) ans jusqu’au \(scenario.contractEndDate), avec prolongation possible de \(scenario.contractExtensionYears) ans · \(scenario.contractReportedLineCount) lignes · \(scenario.contractCOBCount) COB et \(scenario.contractPlannedCOBCount) en projet · \(scenario.contractFleetCount) véhicules · \(scenario.contractCommercialKilometers.formatted()) km commerciaux contractuels.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Données du contrat : elles ne représentent ni la flotte initiale de la partie ni les véhicules automatiquement remis au joueur.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("Le rapport annuel RATP 2025 donne un autre instantané du lot : \(scenario.operatorReportDurationYears) ans, \(scenario.operatorReportLineCount) lignes, \(scenario.operatorReportCOBCount) COB, \(scenario.operatorReportFleetCount) véhicules et \(scenario.operatorReportCommercialKilometers.formatted()) km commerciaux contractuels. Les écarts avec l’annonce IDFM sont conservés comme divergence entre sources, sans choisir un chiffre unique.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let lineCountReconciliationNote = scenario.lineCountReconciliationNote {
                    Label {
                        Text(lineCountReconciliationNote)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption2)
                    .padding(9)
                    .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
                }
                Link(scenario.contractSourceTitle, destination: scenario.contractSourceURL)
                    .font(.caption)
                Link(scenario.operatorReportSourceTitle, destination: scenario.operatorReportSourceURL)
                    .font(.caption)
                if let recentOfficialNetworkCountSourceURL = scenario.recentOfficialNetworkCountSourceURL {
                    Link("IDFM · communiqué réseau du 21 octobre 2026", destination: recentOfficialNetworkCountSourceURL)
                        .font(.caption)
                }
                Text("Budget IDFM 2026 : engagement publié de \(scenario.budgetEngagementEuro.formatted()) €. Sa période et sa nature comptable ne sont pas précisées ici ; ce montant n’est pas utilisé comme recette annuelle ni comme trésorerie de départ.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Link(scenario.budgetSourceTitle, destination: scenario.budgetSourceURL)
                    .font(.caption)

                DisclosureGroup("Repères financiers publiés") {
                    VStack(alignment: .leading, spacing: 11) {
                        ForEach(scenario.financialReference.facts) { fact in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(fact.label)
                                    .font(.caption.weight(.semibold))
                                Text(fact.value)
                                    .font(.callout.weight(.medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(fact.context)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Link(fact.sourceTitle, destination: fact.sourceURL)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Label(scenario.financialReference.separationNote, systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
                .font(.callout.weight(.medium))
            }
            .padding(12)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 11))

            if simulation.session == nil {
                DatePicker(
                    "Date et heure de départ",
                    selection: $careerStartMoment,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
                VStack(alignment: .leading, spacing: 5) {
                    Picker("Fréquence des pannes", selection: $breakdownFrequency) {
                        ForEach(VehicleIncidentFrequency.allCases) { frequency in
                            Text(frequency.title).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                    Text(breakdownFrequency.explanation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if catalog.activeVersion != nil && !isCareerStartWithinNetworkValidity {
                    Text("Choisissez une date comprise dans la période de validité du GTFS actif.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            } else if let session = simulation.session {
                VStack(alignment: .leading, spacing: 5) {
                    eyebrow("PARTIE EN COURS")
                    Text("Démarrée le \(session.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                    Text("Fréquence des pannes : \(session.effectiveBreakdownFrequency.title.lowercased()) · \(session.effectiveBreakdownFrequency.explanation.lowercased())")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Version réseau conservée : \(session.networkVersions.gtfsID.prefix(12))")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                    if let routeIDs = session.operatedRouteIDs, !routeIDs.isEmpty {
                        Text("\(routeIDs.count) route(s) GTFS réelle(s) épinglée(s) à cette partie. Les départs sont théoriques tant qu’aucun bus n’est acheté et affecté. Les lignes de ce lot qui ne sont pas ventilées par COB restent signalées comme candidates.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Cette ancienne sauvegarde ne conserve pas les lignes affectées. Aucun nouveau départ régional ne sera ajouté automatiquement.")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let session = simulation.session {
                careerObjectivesCard(for: session)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                eyebrow("COUVERTURE ATTENDUE")
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(scenario.referenceActiveLineCount)")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                    Text("lignes actives dans le repère IDFM")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("Dont \(scenario.referenceNoctilienCount) lignes Noctilien dans le repère pré-réorganisation. Le GTFS valide à la date choisie fait foi pour l’offre et ses variantes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let checklist = scenarioLineChecklist {
                    Text("\(checklist.lineNames.count) noms de ligne servent de repère publié pour cette période ; ce nombre ne redéfinit pas le décompte contractuel initial.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let sourceTitle = checklist.sourceTitle, let sourceURL = checklist.sourceURL {
                        Link(sourceTitle, destination: sourceURL)
                            .font(.caption)
                    }
                    if catalog.activeVersion == nil {
                        Text("Importez le GTFS pour comparer ce repère aux départs programmés.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if !isCareerStartWithinNetworkValidity {
                        Text("Choisissez une date couverte par le GTFS actif pour auditer les départs de la journée.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if library.isLoadingBusRoutes {
                        ProgressView("Lecture des lignes GTFS…")
                            .font(.caption)
                    } else if let routeError = library.busRoutesError {
                        Text("Lecture du GTFS impossible : \(routeError)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if isLoadingScenarioLineCoverage || scenarioLineCoverageTaskKey != scenarioLineCoverageTaskID {
                        ProgressView("Comparaison des départs GTFS du jour…")
                            .font(.caption)
                    } else if let scenarioLineCoverageError {
                        Text(scenarioLineCoverageError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if let scenarioLineCoverage {
                        Text("\(scenarioLineCoverage.matchedCount) / \(checklist.lineNames.count) lignes ont un ID_Line unique et au moins un départ GTFS exact le \(careerStartMoment.formatted(date: .abbreviated, time: .omitted)).")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(scenarioLineCoverage.matchedCount == checklist.lineNames.count ? Color.green : Color.orange)
                            .fixedSize(horizontal: false, vertical: true)
                        if !scenarioLineCoverage.missingLineNames.isEmpty {
                            Text("Sans départ trouvé ce jour-là : \(scenarioLineCoverage.missingLineNames.joined(separator: ", ")).")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !scenarioLineCoverage.missingReferenceNames.isEmpty {
                            Text("Sans référence IDFM active : \(scenarioLineCoverage.missingReferenceNames.joined(separator: ", ")).")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !scenarioLineCoverage.ambiguousReferenceEntries.isEmpty {
                            Text("Référence IDFM ambiguë : \(scenarioLineCoverage.ambiguousReferenceEntries.map { "\($0.lineName) (\($0.lineReferenceIDs.joined(separator: ", ")))" }.joined(separator: "; ")).")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        DisclosureGroup("Correspondances avec des identifiants GTFS") {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(scenarioLineCoverage.entries.filter(\.isPresent)) { entry in
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(entry.lineName)
                                            .font(.caption.weight(.semibold).monospaced())
                                        Spacer(minLength: 8)
                                        Text("\(entry.lineReferenceIDs.first ?? "ID_Line ?") → \(entry.activeRouteIDs.joined(separator: ", "))")
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                            .padding(.top, 5)
                        }
                        .font(.caption.weight(.medium))
                        AdditionalScenarioCoverageView(coverage: scenarioLineCoverage)
                    }
                    DisclosureGroup(checklist.title) {
                        Text(checklist.lineNames.joined(separator: " · "))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 5)
                    }
                    .font(.caption.weight(.medium))
                } else {
                    Text("Aucun repère de noms n’est défini hors de la période de la DSP 45 (1er novembre 2025 – 31 octobre 2031).")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("L’audit porte sur toutes les routes bus ayant un départ GTFS ce jour-là ; chaque identifiant de route reste visible. Il ne confirme pas le rattachement au contrat ou au COB.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    isRegionalDepotRegistryPresented = true
                } label: {
                    Label("Référentiel régional · \(RegionalDepotRegistry.seedEntries.count) libellés", systemImage: "building.2")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            ForEach(scenario.networkChanges) { change in
                VStack(alignment: .leading, spacing: 9) {
                    eyebrow("ÉVOLUTION RÉSEAU · \(change.effectiveDate.uppercased())")
                    Text(change.title)
                        .font(.subheadline.weight(.semibold))
                    ForEach(change.details, id: \.self) { detail in
                        HStack(alignment: .top, spacing: 7) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.tint)
                                .padding(.top, 2)
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Link(change.sourceTitle, destination: change.sourceURL)
                        .font(.caption)
                }
                .padding(12)
                .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 11))
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    eyebrow("DÉPÔT SÉLECTIONNÉ")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                if let selectedDepot {
                    Text(selectedDepot.name)
                        .font(.headline)
                    Text(selectedDepot.locality)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Change le dépôt avec les deux boutons en haut de l’écran. La fiche à droite affiche ses lignes, ses plans PDF et ses horaires GTFS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    assignmentWorkspaceSection = .depotLines
                    selectedWorkspaceTab = .assignments
                } label: {
                    Label("Gérer les affectations de la partie", systemImage: "checkmark.seal")
                }
                .buttonStyle(.bordered)
                .disabled(simulation.session != nil || library.busRoutes.isEmpty || library.contractFeatures.isEmpty)

                Text(selectedDepotAssignments.isEmpty
                     ? "Aucune ligne n’est encore affectée à la partie pour ce dépôt. Les lignes candidates restent visibles dans le catalogue, sans être présentées comme confirmées."
                     : "\(selectedDepotAssignments.count) ligne(s) affectée(s) à la partie pour ce dépôt.")
                    .font(.caption2)
                    .foregroundStyle(selectedDepotAssignments.isEmpty ? Color.orange : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(scenario.plannedDepots) { depot in
                VStack(alignment: .leading, spacing: 7) {
                    eyebrow("ÉQUIPEMENT PROJETÉ · NON JOUABLE")
                    Text(depot.name)
                        .font(.subheadline.weight(.semibold))
                    Text(depot.locationDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(depot.statusDescription)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(depot.sourceTitle, destination: depot.sourceURL)
                        .font(.caption)
                }
                .padding(12)
                .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 11))
            }

            Spacer(minLength: 0)

            Label("Aucune flotte offerte au démarrage", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 290)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(0.025))
        .alert("Import des plans et fiches horaires impossible", isPresented: Binding(
            get: { library.lineDocumentImportState.errorMessage != nil },
            set: { isPresented in if !isPresented { library.clearLineDocumentError() } }
        )) {
            Button("OK", role: .cancel) { library.clearLineDocumentError() }
        } message: {
            Text(library.lineDocumentImportState.errorMessage ?? "Une erreur est survenue.")
        }
    }

    private func careerObjectivesCard(for session: SimulationSession) -> some View {
        let objectives = CareerObjectiveCatalog.objectives(for: session)
        let nextObjective = objectives.first(where: { !$0.isComplete })
        let completedCount = objectives.filter(\.isComplete).count
        return GroupBox("Démarrage de carrière") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("\(completedCount)/\(objectives.count) étapes validées", systemImage: "flag.checkered")
                        .font(.caption.weight(.medium))
                    Spacer(minLength: 4)
                }
                ProgressView(value: Double(completedCount), total: Double(max(1, objectives.count)))
                    .controlSize(.small)

                if let nextObjective {
                    Text("À faire · \(nextObjective.title). \(nextObjective.instruction)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Parcours de démarrage terminé. Continuez à exploiter vos lignes et développer la flotte.")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .fixedSize(horizontal: false, vertical: true)
                }

                DisclosureGroup("Détail des étapes") {
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(objectives) { objective in
                            HStack(alignment: .top, spacing: 7) {
                                Image(systemName: objective.isComplete ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(objective.isComplete ? Color.green : Color.secondary)
                                    .padding(.top, 1)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(objective.title)
                                            .font(.caption.weight(.semibold))
                                        Spacer(minLength: 4)
                                        Text("\(min(objective.currentCount, objective.targetCount))/\(objective.targetCount)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(objective.isComplete ? "Objectif validé" : objective.instruction)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    ProgressView(value: objective.progress)
                                        .controlSize(.small)
                                }
                            }
                        }
                    }
                    .padding(.top, 5)
                }

                Text("Objectifs d’accompagnement : aucune prime financière n’est ajoutée automatiquement.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 3)
        }
    }

    private func busMapColor(_ status: PurchasedBusStatus) -> Color {
        switch status {
        case .inService: .green
        case .outOfService: .red
        case .waitingForWorkshop: .orange
        case .inMaintenance: .purple
        case .beingTowed: .blue
        case .deadheadingToService: .teal
        case .returningToDepot: .mint
        case .assigned, .inDelivery, .atDepot, .atStop: .orange
        }
    }

    private var recoveryTeamDispatchIncidents: [VehicleIncident] {
        (simulation.session?.vehicleIncidents ?? []).filter { incident in
            !incident.isResolved
                && incident.repairResponse == .towToDepot
                && !hasBusTowStarted(for: incident)
                && ((incident.towPlan?.dispatchRouteCoordinates?.count ?? 0) >= 2)
        }
    }

    private func hasBusTowStarted(for incident: VehicleIncident) -> Bool {
        if incident.busTowStartedAt != nil { return true }
        return simulation.session?.ownedBuses?.first(where: { $0.id == incident.vehicleID })?.status == .beingTowed
    }

    private func recoveryTeamCoordinate(for incident: VehicleIncident) -> CLLocationCoordinate2D? {
        if incident.recoveryTeamArrivedAt != nil && !hasBusTowStarted(for: incident) {
            return CLLocationCoordinate2D(latitude: incident.latitude, longitude: incident.longitude)
        }
        guard let plan = incident.towPlan,
              let coordinates = plan.dispatchRouteCoordinates,
              let startsAt = plan.dispatchStartsAt,
              let duration = plan.dispatchExpectedTravelSeconds,
              duration > 0,
              let sessionTime = simulation.session?.simulatedAt else { return nil }
        let progress = min(1, max(0, sessionTime.timeIntervalSince(startsAt) / duration))
        guard let location = interpolatedMapCoordinate(coordinates, progress: progress) else { return nil }
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }

    private func interpolatedMapCoordinate(
        _ coordinates: [BusMovementCoordinate],
        progress: Double
    ) -> BusMovementCoordinate? {
        guard coordinates.count >= 2 else { return nil }
        let segmentLengths = zip(coordinates, coordinates.dropFirst()).map { start, end in
            CLLocation(latitude: start.latitude, longitude: start.longitude)
                .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        }
        let totalDistance = segmentLengths.reduce(0, +)
        guard totalDistance > 0 else { return coordinates.first }
        var remainingDistance = totalDistance * min(1, max(0, progress))
        for index in segmentLengths.indices {
            let start = coordinates[index]
            let end = coordinates[index + 1]
            let length = segmentLengths[index]
            if remainingDistance <= length || index == segmentLengths.count - 1 {
                let fraction = length == 0 ? 0 : min(1, max(0, remainingDistance / length))
                return BusMovementCoordinate(
                    latitude: start.latitude + (end.latitude - start.latitude) * fraction,
                    longitude: start.longitude + (end.longitude - start.longitude) * fraction
                )
            }
            remainingDistance -= length
        }
        return coordinates.last
    }

    private var mapPanel: some View {
        Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            if showsNetworkLayer {
            ForEach(selectedDepotMapLines) { line in
                ForEach(line.geometries) { geometry in
                    ForEach(Array(geometry.paths.enumerated()), id: \.offset) { component in
                        MapPolyline(coordinates: component.element.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        })
                        .stroke(
                            routeColor(for: geometry),
                            style: StrokeStyle(
                                lineWidth: selectedDepotLineID == line.id ? 5 : 3.5,
                                lineCap: .round,
                                lineJoin: .round,
                                // These imported network geometries are the published commercial
                                // traces; GTFS fallback shapes below keep their dashed treatment.
                                dash: []
                            )
                        )
                    }
                }
                if line.geometries.isEmpty {
                    ForEach(line.routes, id: \.routeID) { route in
                        ForEach(depotFallbackShapesByRouteID[route.routeID] ?? []) { shape in
                            MapPolyline(coordinates: shape.points.map {
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            })
                            .stroke(
                                .teal,
                                style: StrokeStyle(
                                    lineWidth: selectedDepotLineID == line.id ? 4.5 : 3,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [7, 6]
                                )
                            )
                        }
                    }
                }
            }
            ForEach(selectedRouteGeometries.filter { geometry in
                !selectedDepotMapLines.flatMap(\.geometries).contains(where: { $0.id == geometry.id })
            }) { geometry in
                ForEach(Array(geometry.paths.enumerated()), id: \.offset) { component in
                    MapPolyline(coordinates: component.element.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(routeColor(for: geometry), lineWidth: 4)
                }
            }
            }
            if showsFleetLayer {
            ForEach(mapFleetBuses.filter { $0.status == .beingTowed || $0.status == .deadheadingToService || $0.status == .returningToDepot }) { bus in
                if let leg = bus.activeMovementLeg {
                    MapPolyline(coordinates: leg.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(
                        bus.status == .beingTowed ? .blue : (bus.status == .returningToDepot ? .mint : .teal),
                        style: StrokeStyle(lineWidth: 4, dash: [7, 6])
                    )
                }
            }
            ForEach(mapFleetBuses.filter { $0.activeMovementLeg?.geometrySource == .stopCoordinateEstimate }) { bus in
                if let leg = bus.activeMovementLeg {
                    MapPolyline(coordinates: leg.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(.orange, style: StrokeStyle(lineWidth: 3, dash: [3, 5]))
                }
            }
            }
            if showsIncidentsLayer {
            ForEach(recoveryTeamDispatchIncidents) { incident in
                if let plan = incident.towPlan,
                   let dispatchCoordinates = plan.dispatchRouteCoordinates {
                    MapPolyline(coordinates: dispatchCoordinates.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(.orange, style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                    if let location = recoveryTeamCoordinate(for: incident) {
                        Annotation(plan.recoveryTeamName ?? "Équipe de dépannage", coordinate: location) {
                            Image(systemName: "truck.box.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(7)
                                .background(.orange, in: Circle())
                                .accessibilityLabel(plan.recoveryTeamName ?? "Équipe de dépannage en route")
                        }
                    }
                }
            }
            }
            if showsNetworkLayer {
            if let selectedContractFeature {
                ForEach(Array(selectedContractFeature.outlines.enumerated()), id: \.offset) { outline in
                    MapPolyline(coordinates: outline.element.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(.purple, style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                }
            }
            ForEach(activeTripShapes) { tripShape in
                MapPolyline(coordinates: tripShape.points.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(Color.green.opacity(0.85), style: StrokeStyle(lineWidth: 4, dash: [9, 5]))
            }
            }
            if showsIncidentsLayer {
            ForEach(activeStopReplacementGuides) { item in
                MapPolyline(coordinates: item.guide.walkingCoordinates.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(.teal, style: StrokeStyle(lineWidth: 4, dash: [4, 6]))
                Annotation(
                    "Remplacement piéton · ligne \(item.guide.routeID)",
                    coordinate: CLLocationCoordinate2D(
                        latitude: item.guide.latitude,
                        longitude: item.guide.longitude
                    )
                ) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                        .accessibilityLabel("Arrêt de remplacement \(item.guide.replacementStopName), ligne \(item.guide.routeID)")
                }
            }
            ForEach(simulation.session?.activeRouteDetours ?? []) { detour in
                MapPolyline(coordinates: detour.replacementCoordinates.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(.pink, style: StrokeStyle(lineWidth: 5, dash: [10, 6]))
                if let first = detour.replacementCoordinates.first {
                    Annotation(
                        "Déviation temporaire · ligne \(detour.routeID)",
                        coordinate: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
                    ) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.pink)
                            .accessibilityLabel("Déviation temporaire de la ligne \(detour.routeID)")
                    }
                }
            }
            ForEach((simulation.session?.vehicleIncidents ?? []).filter { incident in
                !incident.isResolved
                    && selectedDepotRouteIDs.contains(incident.routeID)
                    && incident.latitude.isFinite
                    && incident.longitude.isFinite
            }) { incident in
                Annotation("Incident · ligne \(incident.routeID)", coordinate: CLLocationCoordinate2D(latitude: incident.latitude, longitude: incident.longitude)) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(.red, in: Circle())
                        .accessibilityLabel("Incident actif sur la ligne \(incident.routeID), arrêt \(incident.stopName)")
                }
            }
            }
            if showsStopsLayer {
            ForEach(visibleBusStops) { stop in
                let closure = simulation.session?.activeStopClosure(stopID: stop.stopID, routeIDs: stop.routeIDs)
                Annotation(stop.name, coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) {
                    Button {
                        selectedStop = stop
                    } label: {
                        Image(systemName: closure == nil ? "bus.fill" : "xmark.circle.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(closure == nil ? (selectedRouteID == nil ? Color.accentColor : Color.orange) : Color.red, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(closure == nil ? "Ouvrir la fiche de l’arrêt \(stop.name)" : "Arrêt fermé : \(stop.name)")
                }
            }
            }
            if showsFleetLayer {
            ForEach(mapFleetBuses) { bus in
                if let latitude = bus.latitude, let longitude = bus.longitude,
                   VehicleMarketCatalog.model(id: bus.modelID) != nil {
                    let shellNumber = busShellNumber(for: bus)
                    Annotation(
                        "Bus \(shellNumber)",
                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    ) {
                        Button {
                            selectedBusID = bus.id
                        } label: {
                            HStack(spacing: 5) {
                            Image(systemName: bus.status == .beingTowed
                                  ? "truck.box.fill"
                                  : (bus.status == .outOfService
                                      ? "wrench.and.screwdriver.fill"
                                      : (bus.status == .inMaintenance ? "wrench.and.screwdriver" : "bus.fill")))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                            Text(shellNumber)
                                .font(.caption2.monospaced().weight(.bold))
                                .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(busMapColor(bus.status), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Ouvrir le bus \(shellNumber), \(bus.status.title)")
                    }
                }
            }
            }
        }
            .mapStyle(.standard(elevation: .flat))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .topLeading) {
                HStack(spacing: 7) {
                    Image(systemName: "map.fill").foregroundStyle(.tint)
                    Text(selectedDepotSite?.name ?? selectedDepot?.name ?? "Réseau")
                        .font(.caption.weight(.semibold))
                    Text("·")
                    Text(selectedDepotLineID ?? "Toutes les lignes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .padding(14)
            }
            .overlay(alignment: .center) {
                if catalog.activeVersion == nil {
                    networkStartupCard
                        .padding(20)
                } else if library.geometryImportState.isImporting || library.isLoadingRouteGeometries {
                    geometryStartupCard
                        .padding(20)
                } else if let message = library.geometryImportState.errorMessage ?? library.routeGeometriesError {
                    geometryUnavailableCard(message: message)
                        .padding(20)
                }
            }
            .overlay(alignment: .topTrailing) {
                if catalog.activeVersion != nil {
                    HStack(spacing: 8) {
                        mapLayerControls
                        HStack(spacing: 6) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                            Text(isLoadingDepotFallbackShapes
                                ? "\(selectedDepotMapLines.count) lignes · chargement…"
                                : "\(selectedDepotMapLines.count) lignes · \(mapFleetBuses.count) bus")
                                .monospacedDigit()
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.regularMaterial, in: Capsule())
                    }
                    .padding(14)
                }
            }
            .overlay(alignment: .bottomLeading) {
                mapLegend.padding(16)
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(alignment: .trailing, spacing: 8) {
                    activeRouteClosuresCard
                    activeStopClosuresCard
                    activeRouteDetoursCard
                }
                .padding(16)
            }
            .overlay(alignment: .bottom) {
                if simulation.session != nil && mapFleetBuses.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "bus.fill").foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aucun bus en circulation")
                                .font(.subheadline.weight(.semibold))
                            Text("Achète un bus, engage un conducteur, puis affecte un départ pour le voir circuler.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Acheter un bus") { selectedWorkspaceTab = .fleet }
                            .buttonStyle(.borderedProminent)
                        Button("Engager un conducteur") { selectedWorkspaceTab = .staff }
                            .buttonStyle(.bordered)
                        Button("Affecter un départ") {
                            assignmentWorkspaceSection = .busDepartures
                            selectedWorkspaceTab = .assignments
                        }
                            .buttonStyle(.bordered)
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                    .padding(16)
                }
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleMapRegion = context.region
        }
        .alert("Prolongation impossible", isPresented: Binding(
            get: { routeDetourExtensionError != nil },
            set: { if !$0 { routeDetourExtensionError = nil } }
        )) {
            Button("OK", role: .cancel) { routeDetourExtensionError = nil }
        } message: {
            Text(routeDetourExtensionError ?? "Une erreur est survenue.")
        }
        .popover(item: $selectedStop) { stop in
            NetworkStopDetailPopover(
                stop: stop,
                visibleRouteIDs: selectedDepotRouteIDs,
                library: library,
                simulation: simulation,
                onPlanDetour: { routeID in
                    routeDetourRequest = RouteDetourRequest(
                        stop: stop,
                        routeID: routeID,
                        sourceObservation: nil
                    )
                },
                onCloseWithReplacement: { routeID in
                    presentStopClosureEditor(for: stop, routeID: routeID)
                }
            )
                .frame(width: 360, height: 500)
        }
        .popover(isPresented: Binding(
            get: { selectedBusID != nil },
            set: { if !$0 { selectedBusID = nil } }
        )) {
            if let session = simulation.session,
               let selectedBusID,
               let bus = session.ownedBuses?.first(where: { $0.id == selectedBusID }) {
                BusDetailPopover(
                    bus: bus,
                    fleet: session.ownedBuses ?? [],
                    session: session
                )
                .frame(width: 380, height: 500)
            }
        }
        .accessibilityLabel("Carte d’exploitation, \(visibleBusStops.count) arrêts de bus visibles")
    }

    @ViewBuilder
    private var activeRouteClosuresCard: some View {
        let closures = simulation.session?.activeRouteClosures ?? []
        if !closures.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("LIGNES SUSPENDUES · \(closures.count)", systemImage: "nosign")
                    .font(.caption.weight(.bold))
                    .tracking(0.35)
                    .foregroundStyle(.orange)
                ForEach(closures) { closure in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(library.busRoutes.first(where: { $0.routeID == closure.routeID })?.displayName ?? closure.routeName)
                            .font(.caption.weight(.semibold))
                        Text("Reprise des départs à \(closure.scheduledEndAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Les courses déjà engagées vont à leur terminus. Les files voyageurs restent aux arrêts.")
                            .font(.caption2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                }
            }
            .padding(12)
            .frame(maxWidth: 350, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
        }
    }

    @ViewBuilder
    private var activeStopClosuresCard: some View {
        let guides = activeStopReplacementGuides
        if !guides.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("ARRÊTS FERMÉS · REMPLACEMENTS", systemImage: "figure.walk")
                    .font(.caption.weight(.bold))
                    .tracking(0.35)
                    .foregroundStyle(.teal)
                ForEach(guides) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ligne \(item.guide.routeID) · \(item.closedStopName) → \(item.guide.replacementStopName)")
                            .font(.caption.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(Int(item.guide.walkingDistanceMeters.rounded())) m · environ \(Int((item.guide.expectedWalkingSeconds / 60).rounded())) min · accessibilité non vérifiée")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let message = item.passengerInformationMessage {
                            Label("Information voyageurs · simulation", systemImage: "text.bubble")
                                .font(.caption2.weight(.medium))
                            Text(message)
                                .font(.caption2)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Sans message voyageurs, les arrivants estimés restent comptés comme laissés à quai.")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                }
                Text("Chemins piétons estimés par Apple Plans.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: 350, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
        }
    }

    @ViewBuilder
    private var activeRouteDetoursCard: some View {
        let detours = simulation.session?.activeRouteDetours ?? []
        if !detours.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                Label("DÉVIATIONS ACTIVES · \(detours.count)", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.caption.weight(.bold))
                    .tracking(0.45)
                    .foregroundStyle(.pink)
                ScrollView {
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(detours) { detour in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(library.busRoutes.first(where: { $0.routeID == detour.routeID })?.displayName ?? detour.routeID) · \(detour.fromStopName) → \(detour.toStopName)")
                                    .font(.caption.weight(.semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Temps estimé : \(detourRemainingLabel(detour)) · fin prévue à \(detour.scheduledEndAt.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let observation = detour.sourceObservation {
                                    Label(
                                        "Référence PRIM · ligne IDFM \(observation.idfmLineID) · consultée \(observation.fetchedAt.formatted(date: .abbreviated, time: .shortened))",
                                        systemImage: "info.circle"
                                    )
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    Text(observation.report.title)
                                        .font(.caption2.weight(.medium))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(observation.report.message)
                                        .font(.caption2)
                                        .lineLimit(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                    HStack(spacing: 5) {
                                        Text(observation.license)
                                        Link("Source PRIM", destination: observation.sourceURL)
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                                if let message = detour.passengerInformationMessage {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Label("Information voyageurs · simulation", systemImage: "text.bubble")
                                            .font(.caption2.weight(.medium))
                                        Text(message)
                                            .font(.caption2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.top, 2)
                                }
                                Button("Prolonger d’une heure") {
                                    do {
                                        _ = try simulation.extendRouteDetour(
                                            id: detour.id,
                                            to: detour.scheduledEndAt.addingTimeInterval(60 * 60)
                                        )
                                        routeDetourExtensionError = nil
                                    } catch {
                                        routeDetourExtensionError = error.localizedDescription
                                    }
                                }
                                .controlSize(.small)
                                .disabled(simulation.session?.incidentAwaitingRepairResponse != nil)
                            }
                            .padding(9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                        }
                    }
                }
                .frame(maxHeight: 190)
                Text("Tracés et retards estimés par MapKit / simulation.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: 350, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
            .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
        }
    }

    private func detourRemainingLabel(_ detour: SimulatedRouteDetour) -> String {
        let remainingSeconds = max(0, Int(detour.scheduledEndAt.timeIntervalSince(simulation.session?.simulatedAt ?? .now)))
        let hours = remainingSeconds / 3_600
        let minutes = (remainingSeconds % 3_600) / 60
        if hours > 0 { return "\(hours) h \(minutes) min restantes" }
        return "\(max(1, minutes)) min restantes"
    }

    private func importedNetworkCard(version: NetworkVersion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Version GTFS archivée", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
            Text("\(version.busRouteCount) lignes • \(version.busStopCount) arrêts bus géolocalisés")
                .font(.callout.weight(.medium))
            if let quality = version.gtfsQuality {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(quality.busTripCount) courses bus • \(quality.tripScheduleCount) séquences d’arrêts archivées • \(quality.tripsWithoutStopTimes) sans passage exploitable.")
                        if let tripsWithoutActiveServiceDates = quality.tripsWithoutActiveServiceDates {
                            Text("Calendrier de service : \(tripsWithoutActiveServiceDates) courses sans service actif (service_id vide ou aucune date active dans calendar.txt/calendar_dates.txt).")
                                .foregroundStyle(tripsWithoutActiveServiceDates > 0 ? Color.orange : Color.secondary)
                        } else {
                            Text("Diagnostic du calendrier de service non enregistré pour cet ancien import.")
                                .foregroundStyle(.secondary)
                        }
                        if quality.containsFrequenciesFile == true {
                            Text("frequencies.txt détecté : les fréquences ne sont pas prises en charge par cet import et restent à contrôler.")
                                .foregroundStyle(.orange)
                        } else if quality.containsFrequenciesFile == false {
                            Text("Aucun frequencies.txt détecté.")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Présence de frequencies.txt non enregistrée pour cet ancien import.")
                                .foregroundStyle(.secondary)
                        }
                        if quality.hasScheduleIssues {
                            let missingStopIDDetail = quality.missingStopIDRowCount.map { ", dont \($0) sans stop_id" } ?? ""
                            Text("À contrôler : \(quality.tripsWithIncompleteTimes) horaires incomplets, \(quality.tripsWithInvalidChronology) chronologies incohérentes, \(quality.tripsWithMissingStopCoordinates) courses avec arrêts sans coordonnées, \(quality.tripsWithTooFewStops) courses avec moins de deux arrêts, \(quality.tripsWithInvalidStopSequence) séquences dupliquées et \(quality.invalidStopTimeRowCount) lignes de passage invalides\(missingStopIDDetail).")
                                .foregroundStyle(.orange)
                        } else {
                            Text("Aucun défaut de séquence, horaire ou coordonnées détecté dans ces contrôles.")
                                .foregroundStyle(.secondary)
                        }
                        Text("Formes : \(quality.availableShapeCount)/\(quality.referencedShapeCount) formes référencées disponibles • \(quality.tripsWithoutShapeReference) courses sans forme • \(quality.tripsWithUnavailableShape) courses avec forme référencée absente ou invalide • \(quality.invalidShapeCount) formes écartées.")
                            .foregroundStyle(quality.hasShapeIssues ? Color.orange : Color.secondary)
                        if let tripsWithUnmatchedShapeStops = quality.tripsWithUnmatchedShapeStops {
                            Text("Séquence arrêts–forme : \(tripsWithUnmatchedShapeStops) courses géolocalisées dont les arrêts ne se projettent pas en ordre sur la forme GTFS dans une tolérance de 350 m. Elles utilisent une estimation entre coordonnées d’arrêts.")
                                .foregroundStyle(tripsWithUnmatchedShapeStops > 0 ? Color.orange : Color.secondary)
                        } else {
                            Text("La compatibilité séquence d’arrêts–forme n’est pas archivée pour cet ancien import.")
                                .foregroundStyle(.secondary)
                        }
                        tripIssueDetails(quality.tripIssues)
                        Text("Cet audit vérifie la projection structurelle des arrêts géolocalisés sur leur forme GTFS ; il ne confirme pas la géométrie routière réelle ni les itinéraires de terrain.")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                } label: {
                    Label(
                        "Audit des données GTFS",
                        systemImage: quality.hasScheduleIssues || quality.hasShapeIssues || quality.hasServiceCalendarIssues || quality.hasUnsupportedFrequencyData ? "exclamationmark.triangle" : "checkmark.circle"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(quality.hasScheduleIssues || quality.hasShapeIssues || quality.hasServiceCalendarIssues || quality.hasUnsupportedFrequencyData ? Color.orange : Color.secondary)
                }
            }
            if let selectedRoute = library.busRoutes.first(where: { $0.routeID == selectedRouteID }) {
                Text("Arrêts de la ligne \(selectedRoute.displayName) — \(selectedRoute.routeID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !library.routeGeometries.isEmpty {
                    Label(
                        selectedRouteGeometries.isEmpty ? "Aucun rapprochement sûr du tracé" : "Tracé officiel affiché",
                        systemImage: selectedRouteGeometries.isEmpty ? "questionmark.circle" : "point.topleft.down.curvedto.point.bottomright.up"
                    )
                    .font(.caption)
                    .foregroundStyle(selectedRouteGeometries.isEmpty ? Color.orange : Color.secondary)
                }

                LineDocumentsForRouteView(
                    route: selectedRoute,
                    library: library,
                    hasDocumentCatalogue: catalog.activeLineDocumentVersion != nil
                )
                PRIMTrafficInformationForRouteView(
                    route: selectedRoute,
                    reference: library.lineReference(for: selectedRoute),
                    simulation: simulation,
                    isRouteOperated: selectedDepotRouteIDs.contains(selectedRoute.routeID),
                    onPrepareDetour: { observation in
                        routeDetourRequest = RouteDetourRequest(
                            stop: nil,
                            routeID: selectedRoute.routeID,
                            sourceObservation: observation
                        )
                    }
                )
                .id(selectedRoute.routeID)
            } else {
                Text("Choisissez une ligne ou zoomez pour voir les arrêts dans la zone affichée.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
                Text("Validité \(version.validFrom.map(Self.shortDate) ?? "inconnue") – \(version.validThrough.map(Self.shortDate) ?? "inconnue"). Les COB et les lignes du contrat restent à confirmer.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let geometryVersion = catalog.activeGeometryVersion {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(geometryVersion.featureCount) tracés IDFM • \(geometryVersion.license)")
                    Text(geometryVersion.attribution)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                Text("Les tracés commerciaux ne sont pas encore importés.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let contractVersion = catalog.activeContractVersion {
                VStack(alignment: .leading, spacing: 3) {
                    Label("\(contractVersion.featureCount) contours des contrats", systemImage: "map")
                    Text("Données IDFM traitées le \(contractVersion.sourceDataProcessedAt?.formatted(date: .abbreviated, time: .omitted) ?? "date inconnue") • importées le \(contractVersion.importedAt.formatted(date: .abbreviated, time: .omitted))")
                    Text("\(contractVersion.license) • \(contractVersion.attribution)")
                    Text("Rattachements lignes / COB : à confirmer")
                    if contractVersion.unresolvedFeatureCount > 0 {
                        Text("\(contractVersion.unresolvedFeatureCount) contour(s) avec id_contrat manquant ou non reconnu. Aucun rattachement n’est déduit de objectid.")
                            .foregroundStyle(.orange)
                    }
                    if !hasScenarioContractContour {
                        if canUsePublishedDSPScopeWithoutContour {
                            Text("Le contour DSP \(scenario.idfmBusContractID) n’est pas dans cette version. La carrière utilise les lignes GTFS documentées ; la limite du contrat ne sera pas dessinée sur la carte.")
                                .foregroundStyle(.orange)
                        } else {
                            Text("Le contour id_contrat = \(scenario.idfmBusContractID) requis par ce scénario est absent : la carrière reste indisponible.")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                Text(canUsePublishedDSPScopeWithoutContour
                    ? "Le contour de cette DSP n’est pas inclus ; les lignes réelles de la carrière restent consultables."
                    : "Contours des contrats non importés.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("Les contours peuvent se chevaucher. Ils ne prouvent pas le rattachement d’une ligne à un COB.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let referenceVersion = catalog.activeLineReferenceVersion {
                VStack(alignment: .leading, spacing: 3) {
                    Label("\(referenceVersion.lineCount) lignes dans le référentiel IDFM", systemImage: "list.bullet.rectangle")
                    Text("\(referenceVersion.license) • \(referenceVersion.attribution)")
                    if let coverage = catalog.activeLineReferenceCoverage {
                        Text("\(coverage.matchedRouteCount)/\(version.busRouteCount) lignes GTFS rapprochées par identifiant")
                        if !coverage.unmatchedRouteIDs.isEmpty {
                            Text("À rapprocher : \(coverage.unmatchedRouteIDs.prefix(5).joined(separator: ", "))\(coverage.unmatchedRouteIDs.count > 5 ? "…" : "")")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Importez le GTFS pour vérifier la couverture des identifiants.")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                Text("Référentiel des lignes non importé.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let documentVersion = catalog.activeLineDocumentVersion {
                VStack(alignment: .leading, spacing: 3) {
                    Label("\(documentVersion.recordCount) liens de plans et horaires archivés", systemImage: "doc.text")
                    Text("\(documentVersion.license) • \(documentVersion.attribution)")
                    Text("Version importée le \(documentVersion.importedAt.formatted(date: .numeric, time: .omitted)) • SHA-256 \(documentVersion.sha256.prefix(12))…")
                    if documentVersion.skippedRecordCount > 0 {
                        Text("\(documentVersion.skippedRecordCount) lignes du CSV ignorées faute d’identifiant ou d’URL HTTP(S).")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                Text("Liens vers les plans et horaires officiels non importés.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Button {
                library.downloadLatestLineDocuments()
            } label: {
                Label("Télécharger plans et fiches horaires IDFM", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)
            .disabled(library.lineDocumentImportState.isImporting || simulation.session != nil)
            if library.lineDocumentImportState.isImporting {
                HStack(spacing: 7) {
                    ProgressView().controlSize(.small)
                    Text("Actualisation des liens documentaires…")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Button {
                localImportKind = .lineDocuments
                isDataImporterPresented = true
            } label: {
                Label(
                    catalog.activeLineDocumentVersion == nil ? "Importer le CSV des plans et horaires…" : "Importer une nouvelle version des plans et horaires…",
                    systemImage: "doc.text"
                )
            }
            .buttonStyle(.bordered)
            .disabled(library.lineDocumentImportState.isImporting || simulation.session != nil)
            Link("Source officielle des plans et fiches horaires", destination: URL(string: "https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/")!)
                .font(.caption2)

            HStack(spacing: 8) {
                Button {
                    isRouteLibraryPresented = true
                } label: {
                    Label("Explorer les lignes", systemImage: "list.bullet")
                }
                .buttonStyle(.bordered)
                .disabled(library.importState.isImporting || library.isLoadingBusStops)
                if selectedRouteID != nil {
                    Button("Toutes") {
                        selectedRouteID = nil
                        cameraPosition = .region(Self.ileDeFranceRegion)
                    }
                    .buttonStyle(.bordered)
                }
            }
            HStack(spacing: 8) {
                Button {
                    isContractLibraryPresented = true
                } label: {
                    Label("Explorer contrats", systemImage: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .disabled(library.isLoadingContracts || library.contractFeatures.isEmpty)
                if selectedContractFeatureID != nil {
                    Button("Tous les contours") {
                        selectedContractFeatureID = nil
                        cameraPosition = .region(Self.ileDeFranceRegion)
                    }
                    .buttonStyle(.bordered)
                }
            }
            importButton
            Button {
                library.downloadLatestLineReferences()
            } label: {
                Label("Télécharger la version IDFM courante", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)
            .disabled(library.lineReferenceImportState.isImporting || simulation.session != nil)
            if library.lineReferenceImportState.isImporting {
                HStack(spacing: 7) {
                    ProgressView().controlSize(.small)
                    Text("Actualisation du référentiel…")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Button {
                localImportKind = .lineReference
                isDataImporterPresented = true
            } label: {
                Label(
                    catalog.activeLineReferenceVersion == nil ? "Importer le référentiel CSV…" : "Importer une nouvelle version du référentiel…",
                    systemImage: "list.bullet.rectangle"
                )
            }
            .buttonStyle(.bordered)
            .disabled(library.lineReferenceImportState.isImporting || simulation.session != nil)
            Button {
                localImportKind = .routeGeometry
                isDataImporterPresented = true
            } label: {
                Label(
                    catalog.activeGeometryVersion == nil ? "Importer les tracés GeoJSON…" : "Importer une nouvelle version des tracés…",
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up"
                )
            }
            .buttonStyle(.bordered)
            .disabled(library.geometryImportState.isImporting || simulation.session != nil)
            Button {
                library.downloadLatestRouteGeometries()
            } label: {
                Label("Télécharger les tracés IDFM courants", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)
            .disabled(library.geometryImportState.isImporting || simulation.session != nil)
            Text("Le jeu officiel couvre les tracés commerciaux réguliers de bus ; les lignes de substitution en sont exclues.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button {
                localImportKind = .contracts
                isDataImporterPresented = true
            } label: {
                Label(
                    catalog.activeContractVersion == nil ? "Importer les contours GeoJSON…" : "Importer une nouvelle version des contrats…",
                    systemImage: "map"
                )
            }
            .buttonStyle(.bordered)
            .disabled(library.contractImportState.isImporting || simulation.session != nil)
            Button {
                library.downloadLatestContracts()
            } label: {
                Label("Télécharger les contours IDFM courants", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)
            .disabled(library.contractImportState.isImporting || simulation.session != nil)
            if library.contractImportState.isImporting {
                HStack(spacing: 7) {
                    ProgressView().controlSize(.small)
                    Text("Actualisation des contours de contrats…")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Link("Source officielle des tracés IDFM", destination: URL(string: "https://data.iledefrance-mobilites.fr/explore/dataset/traces-des-lignes-regulieres-de-bus-en-ile-de-france/")!)
                .font(.caption2)
            Link("Source officielle des contours de contrats", destination: URL(string: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/contours-des-contrats")!)
                .font(.caption2)
            Link("Source officielle du référentiel des lignes", destination: URL(string: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/referentiel-des-lignes")!)
                .font(.caption2)
        }
        .padding(16)
        .frame(maxWidth: 330, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 18, y: 7)
    }

    @ViewBuilder
    private func tripIssueDetails(_ issues: [GTFSImportTripIssue]?) -> some View {
        if let issues {
            if issues.isEmpty {
                Text("Aucune course avec anomalie structurelle n’a été enregistrée pour cette version.")
                    .foregroundStyle(.secondary)
            } else {
                let issuesByRouteID = Dictionary(grouping: issues, by: \.routeID)
                DisclosureGroup("Détail des courses à contrôler · \(issues.count)") {
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(issuesByRouteID.keys.sorted(), id: \.self) { routeID in
                                let routeIssues = issuesByRouteID[routeID, default: []].sorted {
                                    $0.tripID < $1.tripID
                                }
                                let displayName = library.busRoutes.first(where: { $0.routeID == routeID })?.displayName ?? routeID
                                DisclosureGroup("\(displayName) · \(routeIssues.count) courses") {
                                    ForEach(routeIssues) { issue in
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(issue.tripID)
                                                .font(.caption.monospaced())
                                                .textSelection(.enabled)
                                            Text(issue.summary)
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                                .fixedSize(horizontal: false, vertical: true)
                                            if let stopIDs = issue.stopIDsWithoutCoordinates, !stopIDs.isEmpty {
                                                Text("Arrêts sans coordonnées : \(stopIDs.joined(separator: ", "))")
                                                    .font(.caption2.monospaced())
                                                    .foregroundStyle(.orange)
                                                    .textSelection(.enabled)
                                            }
                                            if let stopIDs = issue.stopIDsNotMatchedToShape, !stopIDs.isEmpty {
                                                Text("Arrêts non projetables sur la forme : \(stopIDs.joined(separator: ", "))")
                                                    .font(.caption2.monospaced())
                                                    .foregroundStyle(.orange)
                                                    .textSelection(.enabled)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                    .padding(.top, 4)
                }
            }
        } else {
            Text("Le détail des courses n’est pas archivé pour cet ancien import.")
                .foregroundStyle(.secondary)
        }
    }

    private var networkStartupCard: some View {
        VStack(spacing: 11) {
            if library.importState.isImporting {
                ProgressView()
                    .controlSize(.large)
                Text("Préparation du réseau IDFM")
                    .font(.headline)
                Text("Le jeu prépare les lignes, arrêts, horaires, plans et tracés déjà intégrés. Le premier lancement peut prendre plusieurs minutes et utiliser plusieurs Go d’espace disque.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let message = library.importState.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange)
                Text("Le réseau intégré n’a pas pu être importé")
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Choisir un ZIP GTFS…") { presentImporter(.gtfs) }
                    .buttonStyle(.borderedProminent)
            } else {
                ProgressView("Chargement du réseau intégré…")
                    .controlSize(.large)
            }
        }
        .padding(23)
        .frame(maxWidth: 410)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }

    private var geometryStartupCard: some View {
        VStack(spacing: 11) {
            ProgressView().controlSize(.large)
            Text("Préparation des tracés de toutes les lignes")
                .font(.headline)
            Text("Les itinéraires du dépôt s’afficheront dès que les tracés IDFM seront chargés.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: 410)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }

    private func geometryUnavailableCard(message: String) -> some View {
        VStack(spacing: 11) {
            Image(systemName: "map.slash")
                .font(.system(size: 28))
                .foregroundStyle(.orange)
            Text("Les lignes sont là, leurs tracés ne sont pas chargés")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Réessayer le chargement") {
                library.downloadLatestRouteGeometries()
            }
            .buttonStyle(.borderedProminent)
            .disabled(library.geometryImportState.isImporting || simulation.session != nil)
        }
        .padding(22)
        .frame(maxWidth: 430)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }

    private var importButton: some View {
        Menu {
            ForEach(GTFSImportProvenance.allCases) { provenance in
                Button {
                    gtfsImportProvenance = provenance
                    localImportKind = .gtfs
                    isDataImporterPresented = true
                } label: {
                    Label(provenance.menuTitle, systemImage: "archivebox")
                }
            }
        } label: {
            Label(catalog.activeVersion == nil ? "Choisir le ZIP GTFS…" : "Importer une nouvelle version…", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.borderedProminent)
        .disabled(library.importState.isImporting || simulation.session != nil)
        .help("Choisissez la provenance déclarée de l’archive GTFS avant de sélectionner le ZIP.")
    }

    private func eyebrow(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }

    private static let ileDeFranceRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.72, longitude: 2.45),
        span: MKCoordinateSpan(latitudeDelta: 0.58, longitudeDelta: 0.82)
    )

    private static func shortDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func routeColor(for geometry: NetworkRouteGeometry) -> Color {
        let hex = geometry.color.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return .accentColor }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    private func lineUsesDashedTrace(_ status: DepotLineEvidenceStatus) -> Bool {
        switch status {
        case .candidate, .unresolved, .conflict, .planned: true
        case .confirmed, .shared, .partial, .observedPool: false
        }
    }

    private func busShellNumber(for bus: PurchasedBus) -> String {
        if let coquilleNumber = bus.coquilleNumber, !coquilleNumber.isEmpty { return coquilleNumber }
        return "JEU-\(bus.id.prefix(4).uppercased())"
    }

    private func selectDepotLine(_ line: DepotMapLine) {
        selectedDepotLineID = line.id
        selectedRouteID = line.routes.first?.routeID
        selectedContractFeatureID = nil
        selectedStop = nil
        var coordinates = line.geometries.flatMap(\.paths).flatMap { $0 }
        if coordinates.isEmpty {
            coordinates = line.routes.flatMap { depotFallbackShapesByRouteID[$0.routeID] ?? [] }
                .flatMap(\.points)
                .map { GeographicCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        }
        if coordinates.isEmpty {
            let routeIDs = Set(line.routes.map(\.routeID))
            coordinates = library.busStops
                .filter { !routeIDs.isDisjoint(with: $0.routeIDs) }
                .map { GeographicCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        }
        fitMap(to: coordinates)
    }

    private func fitSelectedDepotNetwork() {
        let routeIDs = selectedDepotRouteIDs
        var coordinates = selectedDepotMapLines.flatMap(\.geometries).flatMap(\.paths).flatMap { $0 }
        coordinates += depotFallbackShapesByRouteID.values
            .flatMap { $0 }
            .flatMap(\.points)
            .map { GeographicCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        if coordinates.isEmpty {
            coordinates = library.busStops
                .filter { !routeIDs.isDisjoint(with: $0.routeIDs) }
                .map { GeographicCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        }
        fitMap(to: coordinates)
    }

    private func fitMap(to coordinates: [GeographicCoordinate]) {
        guard !coordinates.isEmpty else {
            cameraPosition = .region(Self.ileDeFranceRegion)
            return
        }
        let minLatitude = coordinates.map(\.latitude).min() ?? 0
        let maxLatitude = coordinates.map(\.latitude).max() ?? 0
        let minLongitude = coordinates.map(\.longitude).min() ?? 0
        let maxLongitude = coordinates.map(\.longitude).max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.3, 0.035),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.3, 0.035)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func selectDepotLineForRoute(_ route: GTFSRouteSummary) {
        selectedDepotLineID = selectedDepotMapLines.first(where: { $0.routes.contains(where: { $0.routeID == route.routeID }) })?.id
        selectedRouteID = route.routeID
    }

    private func selectRoute(_ route: GTFSRouteSummary) {
        selectDepotLineForRoute(route)
        selectedContractFeatureID = nil
        isRouteLibraryPresented = false
        Task {
            await library.loadBusStops()
            let stops = library.busStops.filter { $0.routeIDs.contains(route.routeID) }
            var coordinates = stops.map { GeographicCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
            if coordinates.isEmpty {
                coordinates = selectedRouteGeometries.flatMap(\.paths).flatMap { $0 }
            }
            fitMap(to: coordinates)
        }
    }

    private func selectContract(_ feature: NetworkContractFeature) {
        selectedRouteID = nil
        selectedContractFeatureID = feature.id
        isContractLibraryPresented = false

        let coordinates = feature.outlines.flatMap { $0 }
        guard !coordinates.isEmpty else { return }
        let minLatitude = coordinates.map(\.latitude).min() ?? 0
        let maxLatitude = coordinates.map(\.latitude).max() ?? 0
        let minLongitude = coordinates.map(\.longitude).min() ?? 0
        let maxLongitude = coordinates.map(\.longitude).max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.25, 0.035),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.25, 0.035)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

private struct NetworkContractLibraryView: View {
    @ObservedObject var library: NetworkLibrary
    let onSelectContract: (NetworkContractFeature) -> Void
    @State private var searchText = ""

    private var filteredContracts: [NetworkContractFeature] {
        guard !searchText.isEmpty else { return library.contractFeatures }
        return library.contractFeatures.filter { feature in
            feature.id.localizedCaseInsensitiveContains(searchText)
                || (feature.contractID?.localizedCaseInsensitiveContains(searchText) ?? false)
                || (feature.name?.localizedCaseInsensitiveContains(searchText) ?? false)
                || (feature.operatorName?.localizedCaseInsensitiveContains(searchText) ?? false)
                || feature.attributes.contains { key, value in
                    key.localizedCaseInsensitiveContains(searchText)
                        || value.searchableText.localizedCaseInsensitiveContains(searchText)
                }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if library.isLoadingContracts {
                    ProgressView("Lecture des contours de contrats…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = library.contractsError {
                    ContentUnavailableView(
                        "Catalogue des contrats indisponible",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if library.contractFeatures.isEmpty {
                    ContentUnavailableView(
                        "Aucun contour importé",
                    systemImage: "map",
                        description: Text("Importez l’export GeoJSON des contours de contrats depuis PRIM.")
                    )
                } else {
                    List(filteredContracts) { feature in
                        Button {
                            onSelectContract(feature)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(feature.displayName)
                                        .font(.headline)
                                    Spacer()
                                    Text(feature.contractID.map { "id_contrat \($0)" } ?? "id_contrat absent")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(feature.contractID == nil ? Color.orange : Color.secondary)
                                }
                                if let operatorName = feature.operatorName {
                                    Text(operatorName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text("objectid (identifiant de feature) \(feature.sourceObjectID ?? "inconnu") · \(feature.outlines.count) contour(s) · \(feature.attributes.count) attributs source")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 3)
                    }
                    .overlay {
                        if filteredContracts.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
                }
            }
            .navigationTitle("Contours des contrats bus")
            .navigationSubtitle("\(library.contractFeatures.count) entités • source conservée avec attribution")
            .searchable(text: $searchText, prompt: "Contrat, exploitant ou attribut source")
            .safeAreaInset(edge: .bottom) {
                Text("Un contour agrège des communes et peut chevaucher un autre contrat. Il ne rattache pas une ligne à un centre bus.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.bar)
            }
        }
    }
}

private struct NetworkRouteLibraryView: View {
    @ObservedObject var library: NetworkLibrary
    let onSelectRoute: (GTFSRouteSummary) -> Void
    @State private var searchText = ""

    private var filteredRoutes: [GTFSRouteSummary] {
        guard !searchText.isEmpty else { return library.busRoutes }
        return library.busRoutes.filter { route in
            let reference = library.lineReference(for: route)
            return route.routeID.localizedCaseInsensitiveContains(searchText)
                || route.shortName.localizedCaseInsensitiveContains(searchText)
                || route.longName.localizedCaseInsensitiveContains(searchText)
                || (reference?.operatorName.localizedCaseInsensitiveContains(searchText) ?? false)
                || (reference?.networkName.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if library.isLoadingBusRoutes {
                    ProgressView("Lecture du catalogue de lignes…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = library.busRoutesError {
                    ContentUnavailableView(
                        "Catalogue de lignes indisponible",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    List(filteredRoutes) { route in
                        Button {
                            onSelectRoute(route)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(route.displayName)
                                            .font(.headline)
                                        Spacer()
                                        Text("ID \(route.routeID)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                    if let secondaryName = route.secondaryName {
                                        Text(secondaryName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let reference = library.lineReference(for: route) {
                                        let operatorAndNetwork = [reference.operatorName, reference.networkName]
                                            .filter { !$0.isEmpty }
                                            .joined(separator: " • ")
                                        if !operatorAndNetwork.isEmpty {
                                            Text(operatorAndNetwork)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text("Référence IDFM \(reference.idLine)\(reference.status.isEmpty ? "" : " • \(reference.status)")")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    } else if !library.lineReferences.isEmpty {
                                        Text("ID_Line non rapproché")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    Text(routeGeometryStatus(for: route))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tint)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 3)
                    }
                    .overlay {
                        if filteredRoutes.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
                }
            }
            .navigationTitle("Lignes de bus importées")
            .navigationSubtitle("\(library.busRoutes.count) lignes GTFS • \(library.lineReferences.count) références IDFM")
            .searchable(text: $searchText, prompt: "Nom, numéro ou identifiant")
        }
        .task {
            await library.loadBusRoutes()
            await library.loadBusStops()
            await library.loadServiceCalendars()
            await library.loadActiveRouteGeometries()
            await library.loadActiveLineReferences()
            await library.loadActiveLineDocuments()
        }
    }

    private func routeGeometryStatus(for route: GTFSRouteSummary) -> String {
        if library.routeGeometries.isEmpty { return "Arrêts GTFS • tracé officiel à importer" }
        let matches = RouteGeometryMatcher.matches(
            route: route,
            among: library.busRoutes,
            geometries: library.routeGeometries
        )
        return matches.isEmpty ? "Tracé à rapprocher" : "Tracé officiel disponible"
    }
}

private struct LineDocumentsForRouteView: View {
    let route: GTFSRouteSummary
    @ObservedObject var library: NetworkLibrary
    let hasDocumentCatalogue: Bool

    private var documents: [NetworkLineDocument] {
        library.documents(for: route)
    }

    private var planDocuments: [NetworkLineDocument] {
        documents.filter { $0.documentType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "PLAN" }
    }

    private var timetableDocuments: [NetworkLineDocument] {
        documents.filter {
            ["HORAIRE", "FICHE HORAIRE"].contains($0.documentType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        }
    }

    private var otherDocuments: [NetworkLineDocument] {
        documents.filter {
            let type = $0.documentType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            return type != "PLAN" && !["HORAIRE", "FICHE HORAIRE"].contains(type)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DOCUMENTS OFFICIELS IDFM")
                .font(.caption2.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            if !hasDocumentCatalogue {
                Text("Importez le catalogue IDFM des plans et fiches horaires pour afficher les liens de cette ligne.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if library.lineReference(for: route) == nil {
                Text("Aucun ID_Line unique ne relie cette route GTFS au référentiel IDFM.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else if documents.isEmpty {
                Text("Aucun document associé à cette ID_Line dans la version importée.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                if !planDocuments.isEmpty {
                    documentSection("Plans", documents: planDocuments)
                }
                if !timetableDocuments.isEmpty {
                    documentSection("Fiches horaires", documents: timetableDocuments)
                }
                if !otherDocuments.isEmpty {
                    documentSection("Autres documents", documents: otherDocuments)
                }
            }
        }
    }

    private func documentSection(_ title: String, documents: [NetworkLineDocument]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(title) · \(documents.count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(documents) { document in
                if let destination = document.destination {
                    Link(document.documentName, destination: destination)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(document.documentName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PRIMTrafficInformationForRouteView: View {
    let route: GTFSRouteSummary
    let reference: NetworkLineReference?
    @ObservedObject var simulation: SimulationEngine
    let isRouteOperated: Bool
    let onPrepareDetour: (PRIMTrafficObservation) -> Void

    @State private var tokenDraft = ""
    @State private var hasSavedToken = false
    @State private var isEditingToken = false
    @State private var isLoading = false
    @State private var tokenError: String?
    @State private var requestError: String?
    @State private var careerAlertNotice: String?
    @State private var lastSuccessfulFetch: PRIMTrafficFetchResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OBSERVATIONS TRAFIC IDFM")
                .font(.caption2.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(.secondary)

            Text("Messages réels consultés à la demande. Ils restent séparés des événements de la simulation.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let reference {
                Text("Ligne IDFM · \(reference.idLine)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)

                if hasSavedToken && !isEditingToken {
                    Label("Jeton enregistré dans le trousseau macOS", systemImage: "key.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button("Modifier le jeton") {
                            tokenDraft = ""
                            isEditingToken = true
                            tokenError = nil
                        }
                        .buttonStyle(.borderless)
                        .font(.caption2)

                        Button("Effacer") {
                            clearToken()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption2)
                    }
                } else {
                    SecureField("Jeton API PRIM", text: $tokenDraft)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    HStack(spacing: 8) {
                        Button("Enregistrer dans le trousseau") {
                            saveToken()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if hasSavedToken {
                            Button("Annuler") {
                                tokenDraft = ""
                                isEditingToken = false
                                tokenError = nil
                            }
                            .buttonStyle(.borderless)
                            .font(.caption2)
                        }
                    }
                }

                Button {
                    Task { await fetchReports() }
                } label: {
                    Label(isLoading ? "Lecture des messages…" : "Actualiser les messages trafic", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isLoading || !hasSavedToken)

                if !hasSavedToken {
                    Text("Ajoutez un jeton de votre compte PRIM pour activer cette requête.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Importez le référentiel des lignes et vérifiez qu’un ID_Line unique relie cette route GTFS à IDFM.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let tokenError {
                Text(tokenError)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let requestError {
                Text(requestError)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let careerAlertNotice {
                Label(careerAlertNotice, systemImage: "bell.badge")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let fetch = lastSuccessfulFetch {
                Divider()
                Text("Mis à jour à \(fetch.fetchedAt.formatted(date: .abbreviated, time: .shortened)) · \(fetch.requestCount) requête(s) PRIM")
                    .font(.caption2.weight(.semibold))
                if fetch.reports.isEmpty {
                    Text("Aucun message n’a été renvoyé pour cette ligne lors de cette consultation.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(fetch.reports) { report in
                        trafficReportRow(report)
                    }
                }
                HStack(spacing: 4) {
                    Text(fetch.license)
                    Text("·")
                    Link("Source PRIM", destination: fetch.sourceURL)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
        .task {
            do {
                hasSavedToken = try PRIMTrafficTokenStore.hasToken()
            } catch {
                tokenError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func trafficReportRow(_ report: PRIMTrafficReport) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(report.title)
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            if let severity = report.severity, !severity.isEmpty {
                Text(severity.capitalized + (report.cause.map { " · \($0)" } ?? ""))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.orange)
            }
            Text(report.message)
                .font(.caption2)
                .fixedSize(horizontal: false, vertical: true)
            if report.applicationStart != nil || report.applicationEnd != nil {
                Text(applicationPeriod(for: report))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !report.affectedObjects.isEmpty {
                Text(report.affectedObjects.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let updatedAt = report.updatedAt {
                Text("Mise à jour IDFM · \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            Button {
                guard let fetch = lastSuccessfulFetch,
                      let reference else { return }
                onPrepareDetour(PRIMTrafficObservation(
                    report: report,
                    idfmLineID: reference.idLine,
                    fetch: fetch
                ))
            } label: {
                Label("Préparer une déviation de jeu", systemImage: "arrow.triangle.branch")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!canPrepareDetour(for: report))
            if simulation.session == nil || !isRouteOperated {
                Text("Démarrez une carrière qui exploite cette ligne pour créer une déviation.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if isReportExpired(report) {
                Text("Ce rapport est expiré dans la simulation; aucune nouvelle déviation ne peut en partir.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
        }
    }

    private func applicationPeriod(for report: PRIMTrafficReport) -> String {
        let start = report.applicationStart?.formatted(date: .abbreviated, time: .shortened) ?? "début non précisé"
        let end = report.applicationEnd?.formatted(date: .abbreviated, time: .shortened) ?? "fin non précisée"
        return "Période d’application · \(start) – \(end)"
    }

    private func isReportExpired(_ report: PRIMTrafficReport) -> Bool {
        let referenceDate = simulation.session?.simulatedAt ?? lastSuccessfulFetch?.fetchedAt ?? .now
        return report.applicationEnd.map { $0 < referenceDate } ?? false
    }

    private func canPrepareDetour(for report: PRIMTrafficReport) -> Bool {
        simulation.session != nil && isRouteOperated && !isReportExpired(report)
    }

    private func saveToken() {
        do {
            try PRIMTrafficTokenStore.save(tokenDraft)
            tokenDraft = ""
            hasSavedToken = true
            isEditingToken = false
            tokenError = nil
        } catch {
            tokenError = error.localizedDescription
        }
    }

    private func clearToken() {
        do {
            try PRIMTrafficTokenStore.delete()
            hasSavedToken = false
            isEditingToken = false
            tokenDraft = ""
            tokenError = nil
        } catch {
            tokenError = error.localizedDescription
        }
    }

    @MainActor
    private func fetchReports() async {
        guard let reference else { return }
        let careerSessionIDAtRequestStart = simulation.session?.id
        let routeWasOperatedAtRequestStart = isRouteOperated
        isLoading = true
        requestError = nil
        defer { isLoading = false }
        do {
            guard let token = try PRIMTrafficTokenStore.load() else {
                hasSavedToken = false
                throw PRIMTrafficInformationError.unauthorized
            }
            let result = try await PRIMTrafficInformationClient.fetchReports(
                idfmLineID: reference.idLine,
                token: token
            )
            lastSuccessfulFetch = result
            careerAlertNotice = nil
            if let careerSessionIDAtRequestStart,
               simulation.session?.id == careerSessionIDAtRequestStart,
               routeWasOperatedAtRequestStart,
               isRouteOperated {
                let observations = result.reports.map {
                    PRIMTrafficObservation(report: $0, idfmLineID: reference.idLine, fetch: result)
                }
                let addedCount = simulation.recordPRIMTrafficReports(observations, routeID: route.routeID)
                if result.reports.isEmpty {
                    careerAlertNotice = "La consultation n’a renvoyé aucun rapport; l’historique de la carrière est conservé."
                } else if addedCount == 1 {
                    careerAlertNotice = "1 nouvelle alerte PRIM ajoutée à l’onglet Incidents."
                } else if addedCount > 1 {
                    careerAlertNotice = "\(addedCount) nouvelles alertes PRIM ajoutées à l’onglet Incidents."
                } else {
                    careerAlertNotice = "Alertes PRIM actualisées dans l’onglet Incidents."
                }
            }
        } catch {
            requestError = error.localizedDescription
            careerAlertNotice = nil
            if (try? PRIMTrafficTokenStore.hasToken()) == false {
                hasSavedToken = false
            }
        }
    }
}

private struct NetworkStopDetailPopover: View {
    let stop: GTFSStopSummary
    let visibleRouteIDs: Set<String>
    @ObservedObject var library: NetworkLibrary
    @ObservedObject var simulation: SimulationEngine
    let onPlanDetour: (String) -> Void
    let onCloseWithReplacement: (String) -> Void
    @State private var selectedServiceMoment = Date.now
    @State private var onlyActiveDirections = false
    @State private var closureError: String?

    private var serviceMoment: Date {
        simulation.session?.simulatedAt ?? selectedServiceMoment
    }

    private var operatedRouteIDs: [String] {
        stop.routeIDs.filter { visibleRouteIDs.contains($0) }.sorted()
    }

    private var displayedRouteIDs: [String] {
        stop.routeIDs.filter { visibleRouteIDs.contains($0) }.sorted()
    }

    private var replacementEligibleRouteIDs: [String] {
        availableRouteIDs.filter { routeID in
            library.busStops.contains { $0.stopID != stop.stopID && $0.routeIDs.contains(routeID) }
        }
    }

    private var activeClosures: [SimulatedStopClosure] {
        guard let session = simulation.session else { return [] }
        let operatedRoutes = Set(operatedRouteIDs)
        return (session.stopClosures ?? [])
            .filter {
                $0.stopID == stop.stopID
                    && $0.isActive(at: session.simulatedAt)
                    && !operatedRoutes.isDisjoint(with: $0.routeIDs)
            }
            .sorted { $0.closedAt < $1.closedAt }
    }

    private var closedRouteIDs: Set<String> {
        Set(activeClosures.flatMap(\.routeIDs))
    }

    private var availableRouteIDs: [String] {
        operatedRouteIDs.filter { !closedRouteIDs.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.title3.weight(.semibold))
                Text("Identifiant GTFS : \(stop.stopID)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(String(format: "%.5f, %.5f", stop.latitude, stop.longitude))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            if simulation.session != nil {
                Divider()
                if !operatedRouteIDs.isEmpty {
                    Menu {
                        ForEach(operatedRouteIDs, id: \.self) { routeID in
                            let route = library.busRoutes.first { $0.routeID == routeID }
                            Button("\(route?.displayName ?? routeID) · \(routeID)") {
                                onPlanDetour(routeID)
                            }
                        }
                    } label: {
                        Label("Planifier une déviation", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                    .menuStyle(.borderedButton)
                    .disabled(simulation.session?.incidentAwaitingRepairResponse != nil)
                }
                ForEach(activeClosures) { closure in
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Arrêt fermé jusqu’à \(closure.scheduledOpenAt.formatted(date: .omitted, time: .shortened))", systemImage: "xmark.octagon.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
                        Text("Lignes touchées : \(closure.routeIDs.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(closure.routeIDs, id: \.self) { routeID in
                            if let guide = closure.replacementGuidesByRouteID?[routeID] {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Ligne \(routeID) · marche vers \(guide.replacementStopName)")
                                        .font(.caption.weight(.medium))
                                    Text("\(Int(guide.walkingDistanceMeters.rounded())) m · environ \(Int((guide.expectedWalkingSeconds / 60).rounded())) min · accessibilité non vérifiée")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if operatedRouteIDs.isEmpty {
                    Label("Aucune ligne de cette carrière ne dessert cet arrêt", systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if availableRouteIDs.isEmpty {
                    Label("Toutes les lignes exploitées à cet arrêt sont déjà fermées", systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 8) {
                        Button("Fermer · 1 h") {
                            createClosure(for: 60 * 60)
                        }
                        .buttonStyle(.bordered)
                        Button("Fermer · 4 h") {
                            createClosure(for: 4 * 60 * 60)
                        }
                        .buttonStyle(.bordered)
                    }
                    Menu("Fermer avec un arrêt de remplacement…") {
                        ForEach(replacementEligibleRouteIDs, id: \.self) { routeID in
                            let route = library.busRoutes.first { $0.routeID == routeID }
                            Button("\(route?.displayName ?? routeID) · \(routeID)") {
                                onCloseWithReplacement(routeID)
                            }
                        }
                    }
                    .menuStyle(.borderedButton)
                    .disabled(replacementEligibleRouteIDs.isEmpty || simulation.session?.incidentAwaitingRepairResponse != nil)
                    Text("Le bus conserve le tracé GTFS. L’arrêt de remplacement guide les voyageurs à pied et ne crée pas de déviation routière.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let session = simulation.session {
                Label("Horaires à l’heure de la partie", systemImage: "clock")
                    .font(.caption.weight(.medium))
                Text(session.simulatedAt.formatted(date: .abbreviated, time: .standard))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
            } else {
                DatePicker(
                    "Date et heure à examiner",
                    selection: $selectedServiceMoment,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
            }

            Toggle("Masquer les directions sans course confirmée", isOn: $onlyActiveDirections)
                .font(.caption)

            if library.serviceCalendarsError != nil {
                Label("Calendriers de service indisponibles", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Divider()

            Text("LIGNES ET DIRECTIONS")
                .font(.caption2.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(displayedRouteIDs, id: \.self) { routeID in
                        let route = library.busRoutes.first { $0.routeID == routeID }
                        let allDirections = stop.routeDirections.filter { $0.routeID == routeID }
                        let directions = onlyActiveDirections
                            ? allDirections.filter { library.isDirectionScheduled($0, at: serviceMoment) != false }
                            : allDirections

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(route?.displayName ?? routeID)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(routeID)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            if let secondaryName = route?.secondaryName {
                                Text(secondaryName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if allDirections.isEmpty {
                                Text("Direction non renseignée dans cette version GTFS")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if directions.isEmpty {
                                Text("Aucune direction en service à cette heure")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(directions) { direction in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Label(
                                            direction.headsign.isEmpty ? "Direction GTFS \(direction.directionID)" : direction.headsign,
                                            systemImage: "arrow.turn.down.right"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                        if let isScheduled = library.isDirectionScheduled(direction, at: serviceMoment) {
                                            Text(isScheduled ? "Course prévue pendant cette heure" : "Aucune course pendant cette heure")
                                                .font(.caption2)
                                                .foregroundStyle(isScheduled ? Color.green : Color.secondary)
                                        } else {
                                            Text("Calendrier ou horaire non indexé")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            Text(simulation.session == nil
                 ? "Ces filtres explorent les courses et calendriers GTFS de la version active. Une donnée absente reste indéterminée."
                 : "Les directions sont comparées aux courses et calendriers de la version GTFS conservée par la partie.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .alert("Fermeture impossible", isPresented: Binding(
            get: { closureError != nil },
            set: { if !$0 { closureError = nil } }
        )) {
            Button("OK", role: .cancel) { closureError = nil }
        } message: {
            Text(closureError ?? "Une erreur est survenue.")
        }
    }

    private func createClosure(for duration: TimeInterval) {
        do {
            try simulation.closeStop(
                stopID: stop.stopID,
                stopName: stop.name,
                routeIDs: availableRouteIDs,
                for: duration
            )
        } catch {
            closureError = error.localizedDescription
        }
    }
}

private struct BusDetailPopover: View {
    let bus: PurchasedBus
    let fleet: [PurchasedBus]
    let session: SimulationSession

    private var model: VehicleMarketModel? {
        VehicleMarketCatalog.model(id: bus.modelID)
    }

    private var serviceAssignment: MachinistServiceAssignment? {
        let assignments = (session.machinistServiceAssignments ?? [])
            .filter { $0.vehicleID == bus.id }
            .sorted { $0.plannedStartAt > $1.plannedStartAt }
        if let currentTripID = bus.currentTripID,
           let currentTrip = assignments.first(where: { $0.tripID == currentTripID }) {
            return currentTrip
        }
        return assignments.first(where: {
            $0.actualEndAt == nil
                && $0.plannedStartAt <= session.simulatedAt
                && session.simulatedAt <= $0.plannedEndAt
        })
    }

    private var assignedMachinist: Machinist? {
        guard let machinistID = serviceAssignment?.machinistID else { return nil }
        return session.machinists?.first(where: { $0.id == machinistID })
    }

    private var activeIncident: VehicleIncident? {
        session.vehicleIncidents?.last(where: { $0.vehicleID == bus.id && !$0.isResolved })
    }

    private var estimatedSpeedKilometersPerHour: Int? {
        guard let leg = bus.activeMovementLeg,
              leg.endsAt > leg.startsAt,
              leg.coordinates.count >= 2 else { return nil }
        let distanceMeters = zip(leg.coordinates, leg.coordinates.dropFirst()).reduce(into: 0.0) { total, pair in
            total += CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
        let speed = distanceMeters / leg.endsAt.timeIntervalSince(leg.startsAt) * 3.6
        return speed.isFinite ? Int(speed.rounded()) : nil
    }

    private var serviceKilometers: Double? {
        guard let assignment = serviceAssignment else { return nil }
        let shiftAssignments: [MachinistServiceAssignment]
        if let dutyBlockID = assignment.dutyBlockID {
            shiftAssignments = (session.machinistServiceAssignments ?? []).filter {
                $0.vehicleID == bus.id && $0.dutyBlockID == dutyBlockID
            }
        } else {
            shiftAssignments = [assignment]
        }
        let tripIDs = Set(shiftAssignments.map(\.tripID))
        let shiftStart = shiftAssignments.map(\.plannedStartAt).min() ?? assignment.plannedStartAt
        let recordedMeters = (session.tripDistanceRecords ?? []).reduce(into: 0.0) { total, record in
            guard record.vehicleID == bus.id,
                  tripIDs.contains(record.tripID),
                  record.isServiceDistance == true,
                  record.occurredAt >= shiftStart,
                  record.occurredAt <= session.simulatedAt else { return }
            total += record.distanceMeters
        }
        let currentLegMeters: Double
        if bus.status == .inService,
           bus.currentTripID.map(tripIDs.contains) == true,
           let leg = bus.activeMovementLeg,
           leg.endsAt > leg.startsAt,
           leg.coordinates.count >= 2 {
            let pathMeters = zip(leg.coordinates, leg.coordinates.dropFirst()).reduce(into: 0.0) { total, pair in
                total += CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                    .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
            }
            let progress = min(1, max(0, session.simulatedAt.timeIntervalSince(leg.startsAt) / leg.endsAt.timeIntervalSince(leg.startsAt)))
            currentLegMeters = pathMeters * progress
        } else {
            currentLegMeters = 0
        }
        return (recordedMeters + currentLegMeters) / 1_000
    }

    private var positionText: String {
        guard let latitude = bus.latitude, let longitude = bus.longitude else { return "Position indisponible" }
        return String(format: "%.5f, %.5f", latitude, longitude)
    }

    private var coquilleText: String {
        if let coquilleNumber = bus.coquilleNumber, !coquilleNumber.isEmpty { return coquilleNumber }
        return "JEU-\(bus.id.prefix(4).uppercased())"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 11) {
                Image(systemName: "bus.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.tint, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(model?.displayName ?? bus.modelID)
                        .font(.headline)
                    Text("Coquille de jeu · \(coquilleText)")
                        .font(.caption.monospaced().weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
            detailRow("État", value: bus.status.title)
            detailRow("Depuis début du service", value: serviceKilometers.map {
                "\($0.formatted(.number.precision(.fractionLength(1)))) km"
            } ?? "Aucune course affectée")
            detailRow("Ligne", value: serviceAssignment.map { "\($0.routeID) · course \($0.tripID)" } ?? "Aucune course en service")
            detailRow("Kilométrage d’ancienneté", value: "\(bus.odometerKilometers.formatted()) km")
            detailRow("Qui conduit", value: assignedMachinist?.displayName ?? "Aucun machiniste affecté")
            detailRow("Incident", value: activeIncident.map { "\($0.severity.title) · \($0.stopName)" } ?? "Aucun incident actif")

            Divider()
            Label("RADAR · POSITION SIMULÉE", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption.weight(.bold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
            HStack(spacing: 7) {
                Circle()
                    .fill(bus.activeMovementLeg == nil ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(bus.activeMovementLeg == nil ? "À l’arrêt" : "En mouvement")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(positionText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if let currentStopName = bus.currentStopName {
                detailRow("Arrêt courant", value: currentStopName)
            }
            if let estimatedSpeedKilometersPerHour {
                detailRow("Vitesse de la course", value: "~\(estimatedSpeedKilometersPerHour) km/h · estimation GTFS")
            }
            if let model {
                detailRow("Modèle", value: "\(model.vehicleClass.title) · \(model.energy.title)")
            }
            detailRow("État du véhicule", value: "\(bus.conditionPercent) %")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .multilineTextAlignment(.trailing)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

private struct DepotListRow: View {
    let depot: DepotReference
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "building.2")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 34, height: 34)
                .background(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text(depot.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(depot.locality)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(depot.address)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(9)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DepotAssignmentManagerView: View {
    @ObservedObject var library: NetworkLibrary
    let scenario: ScenarioDefinition
    let depot: DepotReference?
    let prefill: DepotLineAssignmentPrefill?
    var showsCloseButton = true

    @Environment(\.dismiss) private var dismiss
    @State private var selectedRouteID = ""
    @State private var selectedContractID = ""
    @State private var evidenceStatus: DepotAssignmentEvidenceStatus = .needsReview
    @State private var evidenceTitle = ""
    @State private var evidenceURL = ""
    @State private var additionalEvidenceText = ""
    @State private var evidenceDate = Date.now
    @State private var hasEvidenceDate = false
    @State private var notes = ""
    @State private var errorMessage: String?

    init(
        library: NetworkLibrary,
        scenario: ScenarioDefinition,
        depot: DepotReference?,
        prefill: DepotLineAssignmentPrefill? = nil,
        showsCloseButton: Bool = true
    ) {
        _library = ObservedObject(wrappedValue: library)
        self.scenario = scenario
        self.depot = depot
        self.prefill = prefill
        self.showsCloseButton = showsCloseButton
        _selectedRouteID = State(initialValue: prefill?.routeID ?? "")
        _selectedContractID = State(initialValue: scenario.idfmBusContractID)
        _evidenceStatus = State(initialValue: .needsReview)
        _evidenceTitle = State(initialValue: prefill?.evidenceTitle ?? "")
        _evidenceURL = State(initialValue: prefill?.evidenceURL ?? "")
        _additionalEvidenceText = State(initialValue: prefill?.additionalEvidenceURLs.joined(separator: "\n") ?? "")
        _evidenceDate = State(initialValue: prefill?.evidenceDate ?? Date.now)
        _hasEvidenceDate = State(initialValue: prefill?.evidenceDate != nil)
        _notes = State(initialValue: prefill?.notes ?? "")
    }

    private var contractIDs: [String] {
        [scenario.idfmBusContractID]
    }

    private var scopedAssignments: [DepotLineAssignment] {
        library.depotAssignments
            .filter { $0.scenarioID == scenario.id && $0.depotID == depot?.id }
            .sorted { lhs, rhs in
                if lhs.routeID != rhs.routeID { return lhs.routeID < rhs.routeID }
                return lhs.recordedAt > rhs.recordedAt
            }
    }

    private var canSave: Bool {
        library.depotAssignmentStoreError == nil
            && depot != nil
            && library.catalog.activeVersion != nil
            && library.catalog.activeContractVersion != nil
            && library.busRoutes.contains { $0.routeID == selectedRouteID }
            && contractIDs.contains(selectedContractID)
            && library.contractFeatures.contains { $0.contractID == selectedContractID }
            && !evidenceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !evidenceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (hasEvidenceDate || !evidenceStatus.isOperationallyUsable)
            && (evidenceStatus != .corroborated || additionalEvidenceText.split(whereSeparator: \.isNewline).contains { !String($0).trimmingCharacters(in: .whitespaces).isEmpty })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rattachement à documenter") {
                    if let depot {
                        LabeledContent("Centre bus", value: depot.name)
                    } else {
                        Text("Sélectionnez un centre bus dans le scénario.")
                            .foregroundStyle(.orange)
                    }

                    Picker("Ligne GTFS", selection: $selectedRouteID) {
                        Text("Choisir une ligne…").tag("")
                        ForEach(library.busRoutes.sorted { $0.displayName < $1.displayName }) { route in
                            Text("\(route.displayName) · ID \(route.routeID)").tag(route.routeID)
                        }
                    }
                    Picker("Contrat importé", selection: $selectedContractID) {
                        Text("Choisir un contrat…").tag("")
                        ForEach(contractIDs, id: \.self) { contractID in
                            Text(contractName(for: contractID)).tag(contractID)
                        }
                    }
                    if !library.contractFeatures.contains(where: { $0.contractID == scenario.idfmBusContractID }) {
                        Text("Le contour id_contrat = \(scenario.idfmBusContractID) doit être importé avant l’enregistrement.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let gtfsVersion = library.catalog.activeVersion,
                       let contractVersion = library.catalog.activeContractVersion {
                        Text("Épinglé à GTFS \(gtfsVersion.id.prefix(12)) et contrat \(contractVersion.id.prefix(12))")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Importez un GTFS et des contours contractuels avant d’enregistrer une affectation.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Preuve") {
                    if prefill != nil {
                        Label("Prérempli depuis le catalogue public. Ce rattachement ne sera exploitable qu’après votre revue et l’enregistrement d’un état confirmé.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Picker("État de vérification", selection: $evidenceStatus) {
                        ForEach(DepotAssignmentEvidenceStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    TextField("Titre de la source principale", text: $evidenceTitle)
                    TextField("URL de la source principale (https://…)", text: $evidenceURL)
                    Toggle("Date exacte de la source connue", isOn: $hasEvidenceDate)
                    if hasEvidenceDate {
                        DatePicker("Date de la source", selection: $evidenceDate, displayedComponents: .date)
                        Text("Saisissez la date de publication, d’édition ou d’observation indiquée par la source, pas la date de saisie.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Date inconnue. Cette entrée peut rester « À vérifier » ou « Historique », mais ne peut pas alimenter une carrière confirmée sans date exacte.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if evidenceStatus == .corroborated {
                        Text("Une deuxième URL est obligatoire pour enregistrer une corroboration.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Autres sources, une URL par ligne")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $additionalEvidenceText)
                            .frame(minHeight: 55, maxHeight: 90)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Notes de vérification")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 65, maxHeight: 110)
                    }

                    Text("« Confirmée par le joueur » signifie que vous assumez ce rattachement au vu de la source indiquée. Les contours géographiques ne constituent pas une preuve d’affectation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                Section("Rattachements enregistrés pour ce COB") {
                    if let error = library.depotAssignmentStoreError {
                        ContentUnavailableView(
                            "Registre indisponible",
                            systemImage: "externaldrive.badge.exclamationmark",
                            description: Text(error)
                        )
                    } else if scopedAssignments.isEmpty {
                        Text("Aucun rattachement pour ce centre bus.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(scopedAssignments) { assignment in
                            assignmentRow(assignment)
                        }
                    }
                }
            }
            .navigationTitle("Lignes et preuves · \(depot?.name ?? "COB")")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer le rattachement", action: saveAssignment)
                        .disabled(!canSave)
                }
            }
        }
    }

    @ViewBuilder
    private func assignmentRow(_ assignment: DepotLineAssignment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(routeName(for: assignment.routeID))
                    .font(.headline)
                Spacer()
                Text(assignment.evidenceStatus.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(assignment.isOperationallyUsable ? Color.green : Color.orange)
            }
            Text("Contrat \(assignment.contractID) · source du \(assignment.evidenceDateSummary)")
                .font(.caption)
                .foregroundStyle(.secondary)
            if assignment.contractID != scenario.idfmBusContractID {
                Label("Hors contrat du scénario · non utilisé dans la partie", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            HStack(spacing: 12) {
                if let url = URL(string: assignment.evidenceURL) {
                    Link(assignment.evidenceTitle, destination: url)
                        .font(.caption)
                }
                if assignment.gtfsVersionID != library.catalog.activeVersion?.id
                    || assignment.contractVersionID != library.catalog.activeContractVersion?.id {
                    Label("Versions anciennes", systemImage: "clock.arrow.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button(role: .destructive) {
                    do {
                        try library.removeDepotAssignment(id: assignment.id)
                    } catch {
                        errorMessage = "Le rattachement n’a pas pu être supprimé : \(error.localizedDescription)"
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Supprimer ce rattachement")
            }
            if !assignment.notes.isEmpty {
                Text(assignment.notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func routeName(for routeID: String) -> String {
        guard let route = library.busRoutes.first(where: { $0.routeID == routeID }) else { return "Ligne \(routeID)" }
        return "\(route.displayName) · ID \(routeID)"
    }

    private func contractName(for contractID: String) -> String {
        let name = library.contractFeatures.first(where: { $0.contractID == contractID })?.displayName ?? "Contrat \(contractID)"
        return "\(name) · ID \(contractID)"
    }

    private func saveAssignment() {
        guard let depot else { return }
        let additionalURLs = additionalEvidenceText
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        do {
            try library.saveDepotAssignment(
                scenario: scenario,
                depotID: depot.id,
                routeID: selectedRouteID,
                contractID: selectedContractID,
                evidenceStatus: evidenceStatus,
                evidenceTitle: evidenceTitle,
                evidenceURL: evidenceURL,
                additionalEvidenceURLs: additionalURLs,
                evidenceDate: hasEvidenceDate ? evidenceDate : nil,
                evidenceDateIsVerified: hasEvidenceDate,
                notes: notes
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct VehicleMarketView: View {
    private enum PendingConfirmation {
        case purchase(VehicleMarketOffer)
        case maintenance(PurchasedBus)
        case sale(PurchasedBus, quotedValue: Int)
        case returnToDepot(PurchasedBus, VehicleDepotReturnPlan)
        case workshopExpansion
        case energyInfrastructure(DepotEnergyInfrastructureKind)
    }

    @ObservedObject var simulation: SimulationEngine
    let activeDepotID: String
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss
    @State private var pendingConfirmation: PendingConfirmation?
    @State private var operationErrorMessage: String?
    @State private var calculatingDepotReturnBusID: String?
    @State private var depotReturnRequestID = UUID()

    private var session: SimulationSession? { simulation.session }
    private var offers: [VehicleMarketOffer] { session?.marketOffers ?? [] }
    private var fleet: [PurchasedBus] {
        (session?.ownedBuses ?? []).filter { $0.depotID == activeDepotID }
    }
    private var workshopBayCount: Int {
        session?.effectiveWorkshopBayCount(for: activeDepotID) ?? VehicleWorkshopRules.initialRepairBayCount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    capitalSummary
                    depotEnergyInfrastructureSummary
                    fleetSummary
                    workshopPartsSummary
                    Text("Offres simulées, générées pour cette partie. Les véhicules réels cités servent à documenter les modèles ; ces offres, états et prix ne sont pas des annonces de vente réelles. La revente suit une règle de jeu selon le prix d’achat, l’âge, le kilométrage et l’état du bus. Les coûts d’énergie sont débités pendant les courses selon les tarifs et consommations de jeu affichés. Le risque de panne dépend de l’âge, du kilométrage et de l’état du bus ; durée et réparation suivent des règles de jeu fixes.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                    CATPOwnershipCostBenchmarkView()

                    let serviceRevenueRate = VehicleMarketCatalog.estimatedServiceRevenuePerVehicleKilometerEuro
                    Text("Contribution contractuelle estimée (règle de jeu) : \(serviceRevenueRate.formatted(.currency(code: "EUR").precision(.fractionLength(2)))) par véhicule-kilomètre réellement parcouru. Au bilan quotidien, le taux de courses terminées ajoute 3 % à partir de 98 % de production, ou retire 5 % sous 94 %. Ces montants et seuils sont des règles de jeu, pas des clauses tarifaires de la DSP 45.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text("OFFRES DISPONIBLES")
                            .font(.caption.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(offers.count) offres • \(VehicleMarketCatalog.marketableModels.count) modèles proposés")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if offers.isEmpty {
                        ContentUnavailableView(
                            "Marché indisponible",
                            systemImage: "bus",
                            description: Text("Cette sauvegarde ne contient pas encore de marché versionné.")
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(offers) { offer in
                                if let model = VehicleMarketCatalog.model(id: offer.modelID) {
                                    offerCard(offer, model: model)
                                }
                            }
                        }
                    }

                    let referenceOnlyModels = VehicleMarketCatalog.models
                        .filter { $0.marketAvailabilityNote != nil }
                        .sorted { $0.displayName < $1.displayName }
                    if !referenceOnlyModels.isEmpty {
                        VStack(alignment: .leading, spacing: 11) {
                            Text("RÉFÉRENCES RÉGIONALES HORS MARCHÉ")
                                .font(.caption.weight(.bold))
                                .tracking(0.7)
                                .foregroundStyle(.secondary)
                            Text("Ces fiches regroupent des bus documentés en service, en essai ou en qualification en Île-de-France. Elles ne confirment ni une affectation à Bords de Marne ni une offre achetable.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(referenceOnlyModels) { model in
                                regionalReferenceCard(model)
                            }
                        }
                        .padding(15)
                        .background(Color.blue.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
                    }

                    ledgerSummary
                }
                .padding(22)
                .frame(maxWidth: 900, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Marché de véhicules")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
            .confirmationDialog(
                "Confirmer l’opération",
                isPresented: Binding(
                    get: { pendingConfirmation != nil },
                    set: { if !$0 { pendingConfirmation = nil } }
                ),
                titleVisibility: .visible
            ) {
                switch pendingConfirmation {
                case let .purchase(offer):
                    Button("Acheter pour \(currency(offer.askingPrice))") {
                        purchase(offerID: offer.id)
                    }
                case let .sale(bus, quotedValue):
                    Button("Vendre pour \(currency(quotedValue))", role: .destructive) {
                        sell(vehicleID: bus.id, quotedValue: quotedValue)
                    }
                case let .maintenance(bus):
                    Button("Planifier · \(currency(VehicleMarketCatalog.preventiveMaintenanceCost(for: bus.conditionPercent)))") {
                        scheduleMaintenance(vehicleID: bus.id)
                    }
                case let .returnToDepot(bus, plan):
                    if let staffing = simulation.depotReturnStaffing(vehicleID: bus.id, plan: plan) {
                        Button("Retourner au dépôt · paie ~\(currency(staffing.estimatedLaborCostEuro))") {
                            returnToDepot(bus: bus, plan: plan)
                        }
                    } else {
                        Button("Aucun machiniste disponible", action: {})
                            .disabled(true)
                    }
                case .workshopExpansion:
                    Button("Investir \(currency(VehicleWorkshopRules.expansionCostEuro))") {
                        expandWorkshop()
                    }
                case let .energyInfrastructure(infrastructure):
                    Button("Construire pour \(currency(infrastructure.installationCostEuro ?? 0))") {
                        installEnergyInfrastructure(infrastructure)
                    }
                case nil:
                    EmptyView()
                }
                Button("Annuler", role: .cancel) { pendingConfirmation = nil }
            } message: {
                switch pendingConfirmation {
                case let .purchase(offer):
                    if let model = VehicleMarketCatalog.model(id: offer.modelID) {
                        Text("\(model.displayName) sera commandé pour le COB de la partie. Livraison estimée : \(offer.deliveryDays) jours.")
                    } else {
                        Text("Cette offre sera achetée et livrée au dépôt de la partie.")
                    }
                case let .sale(bus, quotedValue):
                    Text("\(VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID) sera retiré de la flotte. Valeur estimée par la règle de jeu : \(currency(quotedValue)), selon l’âge, le kilométrage et l’état.")
                case let .maintenance(bus):
                    let cost = VehicleMarketCatalog.preventiveMaintenanceCost(for: bus.conditionPercent)
                    Text("\(VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID) sera immobilisé 4 h à sa position actuelle, puis remis à 100 % d’état. Coût estimé par la règle de jeu : \(currency(cost)).")
                case let .returnToDepot(bus, plan):
                    let distance = (plan.routeDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))
                    let eta = durationText(plan.expectedTravelSeconds)
                    let energy = estimatedEnergyCost(for: bus, distanceMeters: plan.routeDistanceMeters).map(currency) ?? "indisponible"
                    if let staffing = simulation.depotReturnStaffing(vehicleID: bus.id, plan: plan) {
                        Text("Trajet MapKit calculé depuis \(bus.currentStopName ?? "le terminus") vers \(plan.depotName) · \(distance) km · ETA \(eta). Machiniste : \(staffing.machinist.displayName). Paie estimée : \(currency(staffing.estimatedLaborCostEuro)) selon les règles de service de jeu. Énergie estimée : \(energy). Distance, usure, énergie et paie sont comptées à l’arrivée ; aucun revenu de service n’est crédité. L’ETA ne prédit pas la circulation future.")
                    } else {
                        Text("Trajet MapKit calculé depuis \(bus.currentStopName ?? "le terminus") vers \(plan.depotName) · \(distance) km · ETA \(eta) · énergie estimée \(energy). Aucun machiniste qualifié n’est disponible pour conduire ce retour selon les règles de repos et de durée de service.")
                    }
                case .workshopExpansion:
                    Text("La construction d’une deuxième baie sera débitée immédiatement. Elle augmentera la capacité de l’atelier dans 7 jours simulés. Prix et délai sont des règles de jeu.")
                case let .energyInfrastructure(infrastructure):
                    Text("Le coût estimé de jeu de \(currency(infrastructure.installationCostEuro ?? 0)) sera débité immédiatement. La construction simulée prendra \(durationText(infrastructure.installationDuration)), puis l’achat et l’affectation des bus nécessitant cet équipement seront disponibles. \(infrastructure.installationEstimateNote) Pour la recharge électrique, chaque chantier ajoute une borne de 60 kW, valeur de simulation et non caractéristique attestée du dépôt.")
                case nil:
                    EmptyView()
                }
            }
            .alert("Opération impossible", isPresented: Binding(
                get: { operationErrorMessage != nil },
                set: { if !$0 { operationErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { operationErrorMessage = nil }
            } message: {
                Text(operationErrorMessage ?? "Une erreur est survenue.")
            }
        }
    }

    private var capitalSummary: some View {
        HStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TRÉSORERIE")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(session?.cashBalance.map(currency) ?? "Indisponible")
                    .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
            }
            Divider().frame(height: 42)
            VStack(alignment: .leading, spacing: 4) {
                Text("DÉPÔT")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(depotName)
                    .font(.headline)
            }
            Spacer()
            Label("Aucun véhicule offert", systemImage: "bus")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var depotEnergyInfrastructureSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ÉNERGIE DU DÉPÔT")
                .font(.caption.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(.secondary)
            Text("L’état publié distingue l’équipement opérationnel de l’intention de conversion. Coût, délai et débit des bornes installées dans la partie sont des règles de jeu, pas des capacités réelles attestées pour ce dépôt.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let session, session.energySimulationVersion != nil {
                Label("\(session.installedChargingPointCount(for: activeDepotID)) borne(s) installée(s) · \(session.installedChargingPowerKilowatts(for: activeDepotID).formatted(.number.precision(.fractionLength(0)))) kW au total", systemImage: "ev.charger")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text("Règle de jeu : une borne de 60 kW par installation achevée; les bus électriques neufs suivis sont livrés batterie pleine. Les bornes des anciennes sauvegardes sans capacité enregistrée n’ajoutent pas de puissance simulée.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(DepotEnergyInfrastructureKind.allCases) { infrastructure in
                let readiness = session?.depotEnergyReadiness(for: infrastructure, depotID: activeDepotID)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(infrastructure.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if let readiness {
                            Label(readiness.statusTitle, systemImage: energyReadinessSymbol(readiness))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(energyReadinessColor(readiness))
                        }
                    }
                    if let readiness {
                        Text(readiness.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let dateLabel = readiness.evidence?.dateLabel {
                            Text("Repère temporel · \(dateLabel)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(readiness.sourceLinks) { source in
                            Link(source.title, destination: source.url)
                                .font(.caption2)
                        }

                        let canAddElectricCharger = infrastructure == .electricCharging
                            && session?.energySimulationVersion != nil
                            && readiness.isReady
                        if infrastructure.canBeInstalledByPlayer,
                           (readiness.isInstallable || canAddElectricCharger),
                           let cost = infrastructure.installationCostEuro {
                            HStack(spacing: 10) {
                                Button {
                                    pendingConfirmation = .energyInfrastructure(infrastructure)
                                } label: {
                                    Label(canAddElectricCharger ? "Ajouter une borne" : "Construire", systemImage: "hammer")
                                }
                                .buttonStyle(.bordered)
                                .disabled((session?.cashBalance ?? 0) < cost)

                                Text("\(currency(cost)) · \(durationText(infrastructure.installationDuration)) simulés · une borne 60 kW · règle de jeu")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private func energyReadinessColor(_ readiness: DepotEnergyReadiness) -> Color {
        switch readiness {
        case .readyFromEvidence, .installedByPlayer:
            .green
        case .readyFromGameplayRule, .underConstruction, .requiresInstallation, .legacyUnverified:
            .orange
        }
    }

    private func energyReadinessSymbol(_ readiness: DepotEnergyReadiness) -> String {
        switch readiness {
        case .readyFromEvidence, .readyFromGameplayRule, .installedByPlayer:
            "checkmark.circle.fill"
        case .underConstruction:
            "hammer.fill"
        case .requiresInstallation:
            "wrench.and.screwdriver"
        case .legacyUnverified:
            "questionmark.circle"
        }
    }

    private var fleetSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FLOTTE ACHETÉE")
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(fleet.count)")
                    .font(.caption.monospacedDigit().weight(.semibold))
            }

            if fleet.isEmpty {
                Text("Le dépôt est vide. Achetez un véhicule pour constituer le parc de la partie.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(fleet.sorted { $0.acquiredAt < $1.acquiredAt }) { bus in
                    HStack {
                        Image(systemName: "bus.fill")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID)
                                .font(.subheadline.weight(.medium))
                            Text("\(bus.modelYear) • \(bus.odometerKilometers.formatted()) km • état \(bus.conditionPercent) %")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let currentStopName = bus.currentStopName {
                                Text(bus.activeMovementLeg != nil
                                     ? "En route depuis \(currentStopName)"
                                     : "Dernier arrêt simulé · \(currentStopName)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if let distanceTravelledMeters = bus.distanceTravelledMeters,
                               distanceTravelledMeters > 0,
                               let model = VehicleMarketCatalog.model(id: bus.modelID) {
                                Text("Partie · \((distanceTravelledMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km · énergie \((bus.energyConsumedUnits ?? 0).formatted(.number.precision(.fractionLength(1)))) \(VehicleMarketCatalog.energyEstimate(for: model).unit)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            if let capacity = bus.batteryCapacityKWh,
                               let charge = simulation.projectedBatteryChargeKWh(for: bus.id) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Charge · \(charge.formatted(.number.precision(.fractionLength(1)))) / \(capacity.formatted(.number.precision(.fractionLength(1)))) kWh\(bus.batteryCapacityIsEstimated == true ? " · capacité estimée" : "")")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    ProgressView(value: min(capacity, max(0, charge)), total: capacity)
                                        .frame(maxWidth: 180)
                                        .accessibilityLabel("Charge de la batterie")
                                        .accessibilityValue("\(charge.formatted(.number.precision(.fractionLength(1)))) sur \(capacity.formatted(.number.precision(.fractionLength(1)))) kilowattheures")
                                    if let completionAt = pendingRechargeCompletion(for: bus.id) {
                                        Text("Recharge en cours · fin vers \(completionAt.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            if let model = VehicleMarketCatalog.model(id: bus.modelID) {
                                let capacity = VehicleMarketCatalog.passengerCapacity(for: model)
                                Text("Voyageurs estimés à bord · \(bus.onboardPassengerCount ?? 0)/\(capacity)\(VehicleMarketCatalog.usesEstimatedPassengerCapacity(for: model) ? " · capacité de jeu" : "")")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                if let passengersBoardedCount = bus.passengersBoardedCount,
                                   passengersBoardedCount > 0,
                                   let passengersLeftBehindCount = bus.passengersLeftBehindCount {
                                    Text("Partie · \(passengersBoardedCount) montés · \(passengersLeftBehindCount) laissés à quai (estimations)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 7) {
                            Label(bus.status.title, systemImage: fleetStatusSymbol(bus.status))
                                .font(.caption)
                                .foregroundStyle(fleetStatusColor(bus.status))
                            if let capacity = bus.batteryCapacityKWh,
                               let session,
                               session.energySimulationVersion != nil,
                               bus.status == .atDepot,
                               !session.pendingRechargeVehicleIDs.contains(bus.id),
                               (simulation.projectedBatteryChargeKWh(for: bus.id) ?? capacity) < capacity,
                               session.installedChargingPointCount(for: bus.depotID) > 0 {
                                Button {
                                    scheduleFullRecharge(vehicleID: bus.id)
                                } label: {
                                    Label("Recharger", systemImage: "ev.charger")
                                }
                                .buttonStyle(.borderless)
                                .help("Planifier une recharge complète au dépôt actif")
                            }
                            if bus.status == .atStop, bus.reservedTripKey == nil {
                                Button {
                                    prepareReturnToDepot(for: bus)
                                } label: {
                                    if calculatingDepotReturnBusID == bus.id {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Label("Retour au dépôt", systemImage: "building.2")
                                            .labelStyle(.iconOnly)
                                    }
                                }
                                .buttonStyle(.borderless)
                                .disabled(calculatingDepotReturnBusID != nil)
                                .help("Calculer un retour routier vers le dépôt actif")
                                .accessibilityLabel("Calculer le retour au dépôt pour ce bus")
                            }
                            if (bus.status == .atDepot || bus.status == .atStop),
                               bus.reservedTripKey == nil,
                               bus.conditionPercent < 100 {
                                Button {
                                    pendingConfirmation = .maintenance(bus)
                                } label: {
                                    Label("Entretenir", systemImage: "wrench.and.screwdriver")
                                        .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.borderless)
                                .help("Planifier l’entretien préventif de ce bus")
                                .accessibilityLabel("Planifier l’entretien préventif")
                            }
                            if bus.canBeSold {
                                Button {
                                    let quoteDate = session?.simulatedAt ?? Date()
                                    let quote = VehicleMarketCatalog.estimatedResaleValue(for: bus, at: quoteDate)
                                    pendingConfirmation = .sale(bus, quotedValue: quote)
                                } label: {
                                    Label("Vendre", systemImage: "banknote")
                                        .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.borderless)
                                .help("Vendre ce bus à l’arrêt ou au dépôt")
                                .accessibilityLabel("Vendre ce bus")
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            Text("L’odomètre cumule les kilomètres GTFS, sans perdre les fractions entre segments. L’état baisse d’un point tous les 10 000 km. Un entretien de jeu remet l’état à 100 %, coûte 450 € + 90 € par point à récupérer et immobilise le bus 4 h à l’arrêt.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Revente estimée par règle de jeu : prix d’achat × facteur de vente 88 % × facteur d’âge (−6 %/an, plancher 12 %) × facteur kilométrage (plancher 15 %) × facteur d’état (30–100 %), arrondie à l’euro, avec plancher de 1 000 € et plafond au prix payé.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private func prepareReturnToDepot(for bus: PurchasedBus) {
        guard calculatingDepotReturnBusID == nil,
              let session,
              session.effectiveManagedDepotIDs.contains(bus.depotID),
              DepotCareerScope.supports(scenarioID: session.scenarioID, depotID: bus.depotID),
              let depot = DepotCareerScope.depotReference(for: bus.depotID) else {
            return
        }
        let requestID = UUID()
        depotReturnRequestID = requestID
        calculatingDepotReturnBusID = bus.id
        Task { @MainActor in
            defer {
                if depotReturnRequestID == requestID { calculatingDepotReturnBusID = nil }
            }
            do {
                let plan = try await VehicleDeadheadRouter.routeToDepot(from: bus, depot: depot)
                guard depotReturnRequestID == requestID else { return }
                guard let currentSession = simulation.session,
                      currentSession.effectiveManagedDepotIDs.contains(bus.depotID),
                      let currentBus = currentSession.ownedBuses?.first(where: { $0.id == bus.id }),
                      currentBus.status == .atStop,
                      currentBus.currentStopID == bus.currentStopID,
                      currentBus.latitude == bus.latitude,
                      currentBus.longitude == bus.longitude else {
                    operationErrorMessage = "La position ou la disponibilité du bus a changé pendant le calcul. Recalculez le trajet."
                    return
                }
                guard simulation.depotReturnStaffing(vehicleID: bus.id, plan: plan) != nil else {
                    operationErrorMessage = "Aucun machiniste qualifié n’est disponible pour conduire ce retour en respectant les conflits, les 2 h de battement, la durée maximale de 10 h et le repos minimal de 11 h."
                    return
                }
                pendingConfirmation = .returnToDepot(bus, plan)
            } catch {
                guard depotReturnRequestID == requestID else { return }
                operationErrorMessage = error.localizedDescription
            }
        }
    }

    private func returnToDepot(bus: PurchasedBus, plan: VehicleDepotReturnPlan) {
        do {
            try simulation.scheduleReturnToDepot(vehicleID: bus.id, plan: plan)
            pendingConfirmation = nil
        } catch {
            operationErrorMessage = error.localizedDescription
        }
    }

    private func pendingRechargeCompletion(for vehicleID: String) -> Date? {
        session?.pendingEvents.compactMap { event -> Date? in
            guard case let .batteryRechargeCompleted(_, eventVehicleID, _) = event.kind,
                  eventVehicleID == vehicleID else { return nil }
            return event.simulatedAt
        }.min()
    }

    private func scheduleFullRecharge(vehicleID: String) {
        do {
            try simulation.scheduleFullRecharge(vehicleID: vehicleID)
        } catch {
            operationErrorMessage = "Recharge : \(error.localizedDescription)"
        }
    }

    private func estimatedEnergyCost(for bus: PurchasedBus, distanceMeters: Double) -> Int? {
        guard distanceMeters.isFinite,
              distanceMeters > 0,
              let model = VehicleMarketCatalog.model(id: bus.modelID) else { return nil }
        let estimate = VehicleMarketCatalog.energyEstimate(for: model)
        let previousUnits = bus.energyConsumedUnits ?? 0
        let totalUnits = previousUnits + distanceMeters / 100_000 * estimate.quantityPer100Kilometers
        guard totalUnits.isFinite else { return nil }
        let previousTotal = Int((previousUnits * estimate.pricePerUnitEuro).rounded())
        let total = Int((totalUnits * estimate.pricePerUnitEuro).rounded())
        return max(0, total - previousTotal)
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let minutes = max(0, Int(duration / 60))
        return "\(minutes / 60) h \(minutes % 60) min"
    }

    private var workshopPartsSummary: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("STOCK D’ATELIER")
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Dépôt · \(workshopBayCount) \(workshopBayCount == 1 ? "baie" : "baies")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let completionAt = session?.workshopExpansionCompletionDate(for: activeDepotID) {
                Label("Deuxième baie en chantier · disponible le \(completionAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "hammer")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if workshopBayCount < VehicleWorkshopRules.maximumRepairBayCount {
                HStack(spacing: 10) {
                    Button {
                        pendingConfirmation = .workshopExpansion
                    } label: {
                        Label("Construire une deuxième baie", systemImage: "hammer")
                    }
                    .buttonStyle(.bordered)
                    .disabled((session?.cashBalance ?? 0) < VehicleWorkshopRules.expansionCostEuro)

                    Text("\(currency(VehicleWorkshopRules.expansionCostEuro)) · 7 jours simulés")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Capacité maximale atteinte", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(VehicleMarketCatalog.marketableModels.sorted { $0.displayName < $1.displayName }) { model in
                DisclosureGroup(model.displayName) {
                    ForEach(VehicleWorkshopPart.allCases) { part in
                        let pendingOrders = simulation.pendingWorkshopPartOrders(for: part, modelID: model.id, depotID: activeDepotID)
                        let pendingQuantity = pendingOrders.reduce(0) { $0 + $1.quantity }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(part.title)
                                    .font(.subheadline.weight(.medium))
                                Text("\(currency(part.purchasePriceEuro)) · livraison de jeu en \(Int(part.gameDeliveryDuration / 3_600)) h")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if let nextDelivery = pendingOrders.first?.deliveryAt {
                                    Text("\(pendingQuantity) kit(s) en commande · prochain arrivage \(nextDelivery.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer()
                            Text("×\(simulation.workshopPartQuantity(for: part, modelID: model.id, depotID: activeDepotID))")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                            Button {
                                restockWorkshopPart(part, modelID: model.id)
                            } label: {
                                Label("Commander", systemImage: "shippingbox")
                            }
                            .buttonStyle(.bordered)
                            .disabled((session?.cashBalance ?? 0) < part.purchasePriceEuro)
                        }
                        if part != VehicleWorkshopPart.allCases.last { Divider() }
                    }
                }
            }

            Text("Chaque dépôt dispose de son propre stock de kits génériques par modèle de bus. Un kit est réservé à la planification du travail. Les commandes sont débitées sur la trésorerie commune et arrivent au dépôt choisi par événement simulé après un délai de jeu; ces pièces et délais restent des règles de jeu, sans fournisseur réel.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private func offerCard(_ offer: VehicleMarketOffer, model: VehicleMarketModel) -> some View {
        let purchasedCount = session?.purchasedOfferQuantities?[offer.id, default: 0] ?? 0
        let remainingStock = max(0, offer.initialStock - purchasedCount)
        let cash = session?.cashBalance ?? 0
        let energyReadiness = session?.depotEnergyReadiness(for: model.energy.depotInfrastructure, depotID: activeDepotID)
        let ownershipCost = VehicleMarketCatalog.ownershipCostEstimate(
            for: offer,
            model: model,
            startingAt: session?.simulatedAt ?? Date()
        )

        return VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 12) {
                BusIllustrationView(model: model)
                    .frame(width: 150, height: 68)
                    .accessibilitySortPriority(1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                    Text("\(model.vehicleClass.title) • \(model.lengthMeters.map { "\($0.formatted(.number.precision(.fractionLength(2)))) m" } ?? "longueur à confirmer") • \(model.energy.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(offer.condition.title) • année \(offer.vehicleYear) • \(offer.odometerKilometers.formatted()) km • état \(offer.conditionPercent) %")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currency(offer.askingPrice))
                        .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                    Text("estimation \(currency(offer.estimatedPriceLow))–\(currency(offer.estimatedPriceHigh))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 14) {
                Label(model.maximumCapacity.map { "\($0) places max. · fiche" } ?? "Capacité source à documenter", systemImage: "person.2")
                if let seatedCapacity = model.seatedCapacity {
                    Text("\(seatedCapacity) assises")
                }
                if let batteryCapacityKWh = model.batteryCapacityKWh {
                    Text("Batterie \(batteryCapacityKWh) kWh")
                } else if session?.energySimulationVersion != nil,
                          let gameplayBattery = VehicleMarketCatalog.gameplayBatteryCapacity(for: model) {
                    Text("Batterie de jeu ≈ \(gameplayBattery.kWh.formatted(.number.precision(.fractionLength(1)))) kWh\(gameplayBattery.isEstimated ? " · estimée" : "")")
                }
                if let maximumPowerKilowatts = model.maximumPowerKilowatts {
                    Text("Puissance max. \(maximumPowerKilowatts) kW")
                }
                Label("\(model.energy.requiresDepotEquipment) requis", systemImage: model.energy.systemImageName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let technicalDataNote = model.technicalDataNote {
                Text(technicalDataNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            vehicleTechnicalVariants(for: model)

            if let energyReadiness {
                Label("Dépôt · \(energyReadiness.statusTitle)", systemImage: energyReadinessSymbol(energyReadiness))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(energyReadinessColor(energyReadiness))
                if !energyReadiness.isReady {
                    Text(energyReadiness.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if model.energy == .electric,
               session?.energySimulationVersion != nil,
               session?.installedChargingPointCount(for: activeDepotID) == 0 {
                Text("Installez une borne électrique dans cette carrière avant l’achat.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            if let regionalEvidenceYear = model.regionalEvidenceYear {
                Text("Référence de modèle en Île-de-France : \(regionalEvidenceYear). Cette référence ne prouve pas à elle seule une présence à Bords de Marne.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let firstObservedInScenarioYear = model.firstObservedInScenarioYear {
                Text("Observation à Bords de Marne recensée par une source secondaire : \(firstObservedInScenarioYear). Variante exacte, quantité, capacité et prix non confirmés.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if model.regionalEvidenceYear != nil {
                Text("Aucune présence à Bords de Marne n’est documentée par cette référence régionale.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let rangeKilometers = model.rangeKilometers {
                Label("Autonomie annoncée jusqu’à \(rangeKilometers) km", systemImage: "battery.100percent")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let rangeEvidenceNote = model.rangeEvidenceNote {
                Text(rangeEvidenceNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if model.id == "bluebus-12m-electric" {
                Text("Non documentés pour cette référence : capacité voyageurs exacte, capacité de batterie, nombre de portes et aménagement PMR. La compatibilité de recharge du dépôt reste à vérifier.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if VehicleMarketCatalog.usesEstimatedPassengerCapacity(for: model) {
                Text("Capacité utilisée pour la simulation : \(VehicleMarketCatalog.passengerCapacity(for: model)) voyageurs (estimation de jeu).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            let energyEstimate = VehicleMarketCatalog.energyEstimate(for: model)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Label("Énergie estimée", systemImage: model.energy.systemImageName)
                Spacer()
                Text("\(energyEstimate.assumptionDescription) · ≈ \(energyEstimate.estimatedCostPer100KilometersEuro.formatted(.currency(code: "EUR").precision(.fractionLength(1)))) / 100 km")
                    .multilineTextAlignment(.trailing)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text("COÛT TOTAL DE POSSESSION ESTIMÉ")
                        .font(.caption.weight(.bold))
                        .tracking(0.45)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text(currency(ownershipCost.netOwnershipCostEuro))
                        .font(.system(.headline, design: .rounded).weight(.bold).monospacedDigit())
                }
                Text("\(ownershipCost.horizonKilometers.formatted()) km · \(ownershipCost.horizonYears) ans · confiance faible")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ownershipCostRow("Achat", amount: ownershipCost.acquisitionCostEuro)
                ownershipCostRow("Énergie", amount: ownershipCost.energyCostEuro)
                ownershipCostRow("Entretiens", amount: ownershipCost.maintenanceCostEuro)
                ownershipCostRow("Kits d’entretien", amount: ownershipCost.maintenanceKitsCostEuro)
                ownershipCostRow("Revente estimée", amount: -ownershipCost.estimatedResaleValueEuro)
                Text("Projection de jeu sur 100 000 km en 5 ans, pour un bus seul : énergie extrapolée de l’estimation affichée, entretien tous les 10 000 km avec remise à 100 % (plus remise initiale si besoin) et un kit au tarif catalogue par intervention. Les kits initiaux, partagés entre les bus d’un même modèle en partie, sont imputés au TCO comme coût d’usage, pas comme décaissement futur. Revente selon l’âge, le kilométrage et l’état. Hors financement, assurance, pneus, remplacement de batterie et infrastructure du dépôt.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(11)
            .background(Color.accentColor.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Confiance \(offer.estimateConfidence.title.lowercased()) • livraison \(offer.deliveryDays) j • stock \(remainingStock)")
                        .font(.caption2.weight(.medium))
                    Text(offer.priceBasis)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    pendingConfirmation = .purchase(offer)
                } label: {
                    Label("Acheter", systemImage: "cart.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(remainingStock == 0 || cash < offer.askingPrice || session?.cashBalance == nil || energyReadiness?.isReady != true || (model.energy == .electric && session?.energySimulationVersion != nil && (session?.installedChargingPointCount(for: activeDepotID) ?? 0) == 0))
            }

            VStack(alignment: .leading, spacing: 5) {
                if let url = URL(string: model.fleetEvidenceURL) {
                    Link(model.fleetEvidenceTitle, destination: url)
                }
                if let technicalTitle = model.technicalEvidenceTitle,
                   let technicalURL = model.technicalEvidenceURL,
                   let url = URL(string: technicalURL) {
                    Link(technicalTitle, destination: url)
                } else {
                    Text("Fiche technique détaillée à documenter")
                }
                if let additionalEvidenceTitle = model.additionalEvidenceTitle,
                   let additionalEvidenceURL = model.additionalEvidenceURL,
                   additionalEvidenceURL != model.fleetEvidenceURL,
                   additionalEvidenceURL != model.technicalEvidenceURL,
                   let url = URL(string: additionalEvidenceURL) {
                    Link(additionalEvidenceTitle, destination: url)
                }
                if let estimateURL = URL(string: model.estimateEvidenceURL) {
                    Link(model.estimateEvidenceTitle, destination: estimateURL)
                }
            }
            .font(.caption2)
            .foregroundStyle(.tint)
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private func ownershipCostRow(_ title: String, amount: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(amount.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                .monospacedDigit()
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func vehicleTechnicalVariants(for model: VehicleMarketModel) -> some View {
        if let variants = model.technicalVariants, !variants.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(variants) { variant in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(variant.title)
                            .font(.caption.weight(.semibold))
                        Text(variant.specificationSummary)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(variant.applicabilityNote)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let url = URL(string: variant.evidenceURL) {
                            Link(variant.evidenceTitle, destination: url)
                                .font(.caption2)
                        }
                    }
                    .padding(.leading, 8)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.35))
                            .frame(width: 2)
                    }
                }
            }
        }
    }

    private func regionalReferenceCard(_ model: VehicleMarketModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BusIllustrationView(model: model)
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .background(Color.accentColor.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            HStack(alignment: .firstTextBaseline) {
                Text(model.displayName)
                    .font(.headline)
                Spacer()
                Text(model.regionalEvidenceLabel ?? "Référence \(model.regionalEvidenceYear ?? VehicleMarketCatalog.referenceYear)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text("\(model.vehicleClass.title) · \(model.lengthMeters.map { "\($0.formatted(.number.precision(.fractionLength(1)))) m" } ?? "longueur à documenter") · \(model.widthMeters.map { "\($0.formatted(.number.precision(.fractionLength(2)))) m de large" } ?? "largeur à documenter") · \(model.heightMeters.map { "\($0.formatted(.number.precision(.fractionLength(2)))) m de haut" } ?? "hauteur à documenter")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let maximumPowerKilowatts = model.maximumPowerKilowatts {
                Text("Puissance maximale indiquée · \(maximumPowerKilowatts) kW")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let technicalDataNote = model.technicalDataNote {
                Text(technicalDataNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            vehicleTechnicalVariants(for: model)
            HStack(spacing: 12) {
                Label("\(model.maximumCapacity.map(String.init) ?? "Capacité inconnue") voyageurs max.", systemImage: "person.2")
                if let seatedCapacity = model.seatedCapacity {
                    Text("\(seatedCapacity) assises")
                }
                if let doubleDoorCount = model.doubleDoorCount {
                    Text("\(doubleDoorCount) portes doubles")
                }
                if let wheelchairSpaces = model.wheelchairSpaces {
                    Text("\(wheelchairSpaces) emplacements UFR")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text(model.energy.title)
                .font(.caption)
            if let note = model.marketAvailabilityNote {
                Text(note)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            let gameYear = session.map {
                GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).component(.year, from: $0.simulatedAt)
            } ?? VehicleMarketCatalog.referenceYear
            if let priceRange = VehicleMarketCatalog.estimatedNewPriceRange(for: model, gameYear: gameYear),
               let priceEstimateNote = model.priceEstimateNote {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimation de référence pour \(gameYear) : \(currency(priceRange.lowerBound))–\(currency(priceRange.upperBound)) · confiance faible")
                        .font(.caption.weight(.medium))
                    Text("\(priceEstimateNote) Indexation de jeu de \(Int((VehicleMarketCatalog.annualPriceIndexRate * 100).rounded())) %/an et fourchette de ±12 %. Cette estimation ne prouve ni un prix individuel observé ni une disponibilité à la vente.")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Prix individuel non documenté ; aucune offre de vente n’est simulée.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 5) {
                if let url = URL(string: model.fleetEvidenceURL) {
                    Link(model.fleetEvidenceTitle, destination: url)
                }
                if let technicalTitle = model.technicalEvidenceTitle,
                   let technicalURL = model.technicalEvidenceURL,
                   technicalURL != model.fleetEvidenceURL,
                   let url = URL(string: technicalURL) {
                    Link(technicalTitle, destination: url)
                }
                if let additionalEvidenceTitle = model.additionalEvidenceTitle,
                   let additionalEvidenceURL = model.additionalEvidenceURL,
                   additionalEvidenceURL != model.fleetEvidenceURL,
                   additionalEvidenceURL != model.technicalEvidenceURL,
                   let url = URL(string: additionalEvidenceURL) {
                    Link(additionalEvidenceTitle, destination: url)
                }
            }
            .font(.caption)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 11))
    }

    @ViewBuilder
    private var ledgerSummary: some View {
        let entries = session?.ledgerEntries ?? []
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                Text("JOURNAL FINANCIER")
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)
                ForEach(entries.reversed()) { entry in
                    let depotLabel = entry.depotID.map { DepotCareerScope.depotReference(for: $0)?.name ?? $0 }
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.description)
                                .font(.subheadline)
                            Text("\(entry.category) · \(entry.occurredAt.formatted(date: .abbreviated, time: .shortened))\(depotLabel.map { " · \($0)" } ?? "")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(ledgerAmountText(entry))
                            .font(.subheadline.monospacedDigit().weight(.medium))
                            .foregroundStyle(ledgerAmountColor(entry))
                    }
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func ledgerAmountText(_ entry: SimulationLedgerEntry) -> String {
        if entry.nature == .settlement {
            return "Trésorerie \(signedLedgerCurrency(entry.cashMovementEuro))"
        }
        guard entry.cashMovementEuro != entry.amount else { return signedLedgerCurrency(entry.amount) }
        return "\(signedLedgerCurrency(entry.amount)) acquis · trésorerie \(signedLedgerCurrency(entry.cashMovementEuro))"
    }

    private func ledgerAmountColor(_ entry: SimulationLedgerEntry) -> Color {
        let amount = entry.nature == .settlement ? entry.cashMovementEuro : entry.amount
        return amount >= 0 ? .green : .orange
    }

    private func signedLedgerCurrency(_ amount: Int) -> String {
        let sign = amount > 0 ? "+" : (amount < 0 ? "−" : "")
        return sign + currency(abs(amount))
    }

    private var depotName: String {
        session.flatMap { DepotCareerScope.depotReference(for: $0.effectiveActiveDepotID)?.name }
            ?? session?.effectiveActiveDepotID
            ?? "Dépôt"
    }

    private func fleetStatusSymbol(_ status: PurchasedBusStatus) -> String {
        switch status {
        case .inDelivery: "shippingbox"
        case .assigned: "calendar.badge.clock"
        case .inService: "bus.fill"
        case .atDepot: "building.2"
        case .atStop: "mappin.and.ellipse"
        case .waitingForWorkshop: "hourglass"
        case .inMaintenance: "wrench.and.screwdriver"
        case .beingTowed: "truck.box.fill"
        case .deadheadingToService: "bus.fill"
        case .returningToDepot: "bus.fill"
        case .outOfService: "wrench.and.screwdriver.fill"
        }
    }

    private func fleetStatusColor(_ status: PurchasedBusStatus) -> Color {
        switch status {
        case .inDelivery: .orange
        case .assigned: .blue
        case .inService: .green
        case .atDepot: .secondary
        case .atStop: .orange
        case .waitingForWorkshop: .orange
        case .inMaintenance: .purple
        case .beingTowed: .blue
        case .deadheadingToService: .teal
        case .returningToDepot: .mint
        case .outOfService: .red
        }
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func purchase(offerID: String) {
        do {
            try simulation.purchaseVehicle(offerID: offerID)
            pendingConfirmation = nil
        } catch {
            operationErrorMessage = "Achat : \(error.localizedDescription)"
            pendingConfirmation = nil
        }
    }

    private func restockWorkshopPart(_ part: VehicleWorkshopPart, modelID: String) {
        do {
            try simulation.restockWorkshopParts(part, forModelID: modelID, depotID: activeDepotID)
        } catch {
            operationErrorMessage = "Réapprovisionnement : \(error.localizedDescription)"
        }
    }

    private func expandWorkshop() {
        do {
            try simulation.purchaseWorkshopExpansion()
            pendingConfirmation = nil
        } catch {
            operationErrorMessage = "Extension d’atelier : \(error.localizedDescription)"
            pendingConfirmation = nil
        }
    }

    private func installEnergyInfrastructure(_ infrastructure: DepotEnergyInfrastructureKind) {
        do {
            try simulation.scheduleDepotEnergyInfrastructureInstallation(infrastructure)
            pendingConfirmation = nil
        } catch {
            operationErrorMessage = "Infrastructure : \(error.localizedDescription)"
            pendingConfirmation = nil
        }
    }

    private func scheduleMaintenance(vehicleID: String) {
        do {
            try simulation.schedulePreventiveMaintenance(vehicleID: vehicleID)
            pendingConfirmation = nil
        } catch {
            operationErrorMessage = "Entretien : \(error.localizedDescription)"
            pendingConfirmation = nil
        }
    }

    private func sell(vehicleID: String, quotedValue: Int) {
        do {
            try simulation.sellVehicle(vehicleID: vehicleID, quotedValue: quotedValue)
            pendingConfirmation = nil
        } catch {
            operationErrorMessage = "Vente : \(error.localizedDescription)"
            pendingConfirmation = nil
        }
    }
}

private struct MachinistManagementView: View {
    @ObservedObject var simulation: SimulationEngine
    let activeDepotID: String
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss
    @State private var pendingQualification: MachinistQualification?
    @State private var machinistForAbsence: Machinist?
    @State private var machinistForTraining: Machinist?
    @State private var machinistForBreak: Machinist?
    @State private var machinistBlockForCorrection: MachinistDutyBlock?
    @State private var recruitmentError: String?
    @State private var trainingError: String?
    @State private var breakError: String?
    @State private var reliefError: String?
    @State private var isPlanningRelief = false

    private var session: SimulationSession? { simulation.session }
    private var machinists: [Machinist] {
        (session?.machinists ?? [])
            .filter { ($0.depotID ?? session?.depotID) == activeDepotID }
            .sorted { $0.employeeNumber < $1.employeeNumber }
    }
    private var activeMachinistIDs: Set<String> { Set(machinists.map(\.id)) }
    private var activeOrUpcomingAbsences: [MachinistAbsence] {
        let now = session?.simulatedAt ?? .distantPast
        return (session?.machinistAbsences ?? [])
            .filter { $0.endsAt > now && activeMachinistIDs.contains($0.machinistID) }
            .sorted { $0.startsAt < $1.startsAt }
    }
    private var absenceHistory: [MachinistAbsence] {
        (session?.machinistAbsences ?? [])
            .filter { activeMachinistIDs.contains($0.machinistID) }
            .sorted { $0.startsAt > $1.startsAt }
            .prefix(20)
            .map { $0 }
    }
    private var trainingHistory: [MachinistTrainingRecord] {
        (session?.machinistTrainings ?? [])
            .filter { activeMachinistIDs.contains($0.machinistID) }
            .sorted { $0.startsAt > $1.startsAt }
            .prefix(12)
            .map { $0 }
    }
    private var breakHistory: [MachinistBreak] {
        (session?.machinistBreaks ?? [])
            .filter { activeMachinistIDs.contains($0.machinistID) }
            .sorted { $0.startsAt > $1.startsAt }
            .prefix(20)
            .map { $0 }
    }
    private var settledDutyBlockHistory: [MachinistDutyBlock] {
        (session?.machinistDutyBlocks ?? [])
            .filter {
                $0.actualEndAt != nil
                    && $0.lastSettledAt != nil
                    && activeMachinistIDs.contains($0.machinistID)
            }
            .sorted { ($0.lastSettledAt ?? .distantPast) > ($1.lastSettledAt ?? .distantPast) }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EFFECTIF")
                                .font(.caption2.weight(.bold))
                                .tracking(0.7)
                                .foregroundStyle(.secondary)
                            Text("\(machinists.count) machiniste(s)")
                                .font(.title2.weight(.bold).monospacedDigit())
                        }
                        Spacer()
                        Label("Paie débitée après chaque service", systemImage: "eurosign.circle")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 9) {
                        Text("RECRUTER")
                            .font(.caption.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        ForEach(MachinistQualification.allCases) { qualification in
                            Button {
                                pendingQualification = qualification
                            } label: {
                                HStack(spacing: 11) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(qualification.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text("Coût employeur de jeu estimé · \(currency(qualification.estimatedLoadedCostPerServiceHourEuro))/h travaillé")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background, in: RoundedRectangle(cornerRadius: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(15)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("MACHINISTES EN POSTE")
                            .font(.caption.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        if machinists.isEmpty {
                            ContentUnavailableView(
                                "Aucun machiniste recruté",
                                systemImage: "person.2",
                                description: Text("Recrutez un machiniste avant d’affecter une course.")
                            )
                        } else {
                            ForEach(machinists) { machinist in
                                machinistRow(machinist)
                            }
                        }
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("HISTORIQUE DES SERVICES")
                            .font(.caption.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        if settledDutyBlockHistory.isEmpty {
                            Text("Les blocs apparaîtront ici après leur clôture et leur règlement.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(settledDutyBlockHistory) { block in
                                settledDutyBlockRow(block)
                            }
                        }
                        Text("La correction porte sur tout le bloc, conserve les heures et le montant de paie déjà enregistrés et ajoute un motif à l’historique. Les qualifications, le dépôt, les conflits, les absences, les formations et le repos de jeu sont vérifiés.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("ABSENCES ET RÈGLEMENTS")
                                .font(.caption.weight(.bold))
                                .tracking(0.7)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                machinistForAbsence = machinists.first
                            } label: {
                                Label("Planifier", systemImage: "calendar.badge.plus")
                            }
                            .buttonStyle(.bordered)
                            .disabled(machinists.isEmpty)
                        }

                        if absenceHistory.isEmpty {
                            Text("Aucune absence enregistrée.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(absenceHistory) { absence in
                                absenceRow(absence)
                            }
                        }
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("PAUSES ENTRE COURSES")
                            .font(.caption.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        if breakHistory.isEmpty {
                            Text("Aucune pause planifiée. Une pause de jeu de 30 min peut être placée dans un battement entre deux courses du même bloc.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(breakHistory) { scheduledBreak in
                                breakRow(scheduledBreak)
                            }
                        }
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("FORMATIONS ET QUALIFICATIONS")
                            .font(.caption.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        if trainingHistory.isEmpty {
                            Text("Aucune formation planifiée ou terminée.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(trainingHistory) { training in
                                trainingRow(training)
                            }
                        }
                        Text("La formation bus articulé dure 8 h simulées. Son salaire estimé utilise le taux horaire chargé du machiniste et est débité à la fin. Un repos de jeu de 11 h est requis de part et d’autre. Ces valeurs sont des règles de jeu, pas une norme de formation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14))

                    Text("Plusieurs courses peuvent former un même service machiniste si le battement ne dépasse pas 2 h. Un bloc ne dépasse pas 10 h et deux blocs distincts sont séparés par 11 h de repos minimum. Ces seuils et la pause non rémunérée de 30 min sont des règles de jeu, pas une vérification réglementaire. La pause doit tenir entre deux courses planifiées du même bloc ; son temps est déduit du coût horaire du bloc. Une relève en cours de course peut être effectuée à l’arrêt courant ou planifiée pour un prochain arrêt, avec qualification, disponibilité et repos vérifiés ; la rémunération suit les règles de jeu du bloc du machiniste. Les absences sont typées et leur rémunération estimée est inscrite à leur fin. Le repos avancé et la réouverture générale des blocs restent hors simulation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(13)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
                }
                .padding(22)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Personnel")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
            .sheet(item: $machinistForAbsence) { machinist in
                MachinistAbsenceEditorView(
                    simulation: simulation,
                    machinist: machinist,
                    machinists: machinists
                )
                .frame(minWidth: 500, minHeight: 380)
            }
            .sheet(item: $machinistForTraining) { machinist in
                MachinistTrainingEditorView(simulation: simulation, machinist: machinist)
                    .frame(minWidth: 500, minHeight: 340)
            }
            .sheet(item: $machinistForBreak) { machinist in
                MachinistBreakEditorView(
                    simulation: simulation,
                    machinist: machinist,
                    windows: simulation.availableMachinistBreakWindows(for: machinist.id)
                )
                .frame(minWidth: 520, minHeight: 340)
            }
            .sheet(item: $machinistBlockForCorrection) { block in
                MachinistAssignmentCorrectionEditorView(
                    simulation: simulation,
                    dutyBlock: block,
                    previousMachinistName: machinistName(block.machinistID),
                    candidates: simulation.availableMachinistDutyBlockCorrectionCandidates(dutyBlockID: block.id)
                )
                .frame(minWidth: 540, minHeight: 440)
            }
            .confirmationDialog(
                "Confirmer le recrutement",
                isPresented: Binding(
                    get: { pendingQualification != nil },
                    set: { if !$0 { pendingQualification = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let pendingQualification {
                    Button("Recruter · \(pendingQualification.title)") {
                        hire(pendingQualification)
                    }
                }
                Button("Annuler", role: .cancel) { pendingQualification = nil }
            } message: {
                if let pendingQualification {
                    Text("Ce machiniste pourra être affecté à un service correspondant à sa qualification. Le coût employeur estimé de \(currency(pendingQualification.estimatedLoadedCostPerServiceHourEuro)) par heure sera débité au terme du service.")
                }
            }
            .alert("Action impossible", isPresented: Binding(
                get: { recruitmentError != nil },
                set: { if !$0 { recruitmentError = nil } }
            )) {
                Button("OK", role: .cancel) { recruitmentError = nil }
            } message: {
                Text(recruitmentError ?? "Une erreur est survenue.")
            }
            .alert("Formation impossible", isPresented: Binding(
                get: { trainingError != nil },
                set: { if !$0 { trainingError = nil } }
            )) {
                Button("OK", role: .cancel) { trainingError = nil }
            } message: {
                Text(trainingError ?? "Une erreur est survenue.")
            }
            .alert("Pause impossible", isPresented: Binding(
                get: { breakError != nil },
                set: { if !$0 { breakError = nil } }
            )) {
                Button("OK", role: .cancel) { breakError = nil }
            } message: {
                Text(breakError ?? "Une erreur est survenue.")
            }
            .alert("Relève impossible", isPresented: Binding(
                get: { reliefError != nil },
                set: { if !$0 { reliefError = nil } }
            )) {
                Button("OK", role: .cancel) { reliefError = nil }
            } message: {
                Text(reliefError ?? "Une erreur est survenue.")
            }
        }
    }

    private func machinistRow(_ machinist: Machinist) -> some View {
        let machinistAssignments = (session?.machinistServiceAssignments ?? [])
            .filter { $0.machinistID == machinist.id }
        let currentBreak = (session?.machinistBreaks ?? []).first(where: {
            $0.machinistID == machinist.id && $0.isPending
                && $0.startsAt <= (session?.simulatedAt ?? .distantPast)
                && (session?.simulatedAt ?? .distantPast) < $0.endsAt
        })
        let assignment = machinistAssignments
            .filter { $0.machinistID == machinist.id && $0.actualEndAt == nil }
            .sorted { $0.plannedStartAt < $1.plannedStartAt }
            .first
        let scheduledReliefPlan = assignment.flatMap { currentAssignment in
            (session?.plannedMachinistReliefs ?? []).first(where: {
                $0.outgoingAssignmentID == currentAssignment.id && $0.cancelledAt == nil
            })
        }
        let scheduledReliefEvent = scheduledReliefPlan.flatMap { plan in
            session?.pendingEvents.first(where: { $0.sequence == plan.eventSequence })
        }
        let incomingReliefPlan = assignment.flatMap { currentAssignment in
            (session?.plannedMachinistReliefs ?? []).first(where: { reliefPlan in
                reliefPlan.incomingAssignmentID == currentAssignment.id
                    && reliefPlan.cancelledAt == nil
                    && session?.pendingEvents.contains(where: { $0.sequence == reliefPlan.eventSequence }) == true
            })
        }
        let incomingReliefEvent = incomingReliefPlan.flatMap { plan in
            session?.pendingEvents.first(where: { $0.sequence == plan.eventSequence })
        }
        let dutyBlock = assignment.flatMap { currentAssignment in
            session?.machinistDutyBlocks?.first(where: { $0.id == currentAssignment.dutyBlockID })
        }
        let dutyBlockAssignments = dutyBlock.map { block in
            machinistAssignments.filter { $0.dutyBlockID == block.id }
        } ?? []
        let hasIncident = assignment.flatMap { currentAssignment in
            session?.vehicleIncidents?.first(where: {
                $0.vehicleID == currentAssignment.vehicleID && !$0.isResolved
            })
        } != nil
        let now = session?.simulatedAt ?? .distantPast
        let canOfferRelief = assignment.map { currentAssignment in
            session?.ownedBuses?.contains(where: { bus in
                bus.id == currentAssignment.vehicleID
                    && bus.currentTripID == currentAssignment.tripID
                    && bus.status == .inService
                    && bus.activeMovementLeg == nil
                    && bus.currentStopID != nil
                    && currentAssignment.plannedStartAt <= now
                    && now < currentAssignment.plannedEndAt
            }) == true
        } ?? false
        let reliefCandidates = canOfferRelief
            ? simulation.availableMachinistReliefCandidates(forVehicleID: assignment?.vehicleID ?? "")
            : []
        let plannedReliefStops = assignment.map {
            simulation.upcomingMachinistReliefStops(forVehicleID: $0.vehicleID)
        } ?? []
        let canPlanRelief = assignment.map { currentAssignment in
            session?.ownedBuses?.contains(where: { bus in
                bus.id == currentAssignment.vehicleID
                    && bus.currentTripID == currentAssignment.tripID
                    && bus.status == .inService
                    && currentAssignment.plannedStartAt <= now
                    && now < currentAssignment.plannedEndAt
            }) == true
        } ?? false
        let plannedReliefOptions = plannedMachinistReliefOptions(
            vehicleID: assignment?.vehicleID ?? "",
            stops: plannedReliefStops
        )
        let absence = activeOrUpcomingAbsences.first(where: { $0.machinistID == machinist.id })
        let training = (session?.machinistTrainings ?? []).first(where: {
            $0.machinistID == machinist.id && $0.isPending
        })
        let serviceRestUntil = (session?.machinistServiceAssignments ?? [])
            .filter { $0.machinistID == machinist.id }
            .compactMap { $0.actualEndAt }
            .max()
            .map { $0.addingTimeInterval(MachinistWorkRules.minimumRestBetweenDutyBlocks) }
            .flatMap { $0 > now ? $0 : nil }
        let trainingRestUntil = (session?.machinistTrainings ?? [])
            .filter { $0.machinistID == machinist.id && $0.cancelledAt == nil && $0.endsAt <= now }
            .map { $0.endsAt.addingTimeInterval(MachinistWorkRules.minimumRestBetweenDutyBlocks) }
            .filter { $0 > now }
            .max()
        let restUntil = [serviceRestUntil, trainingRestUntil].compactMap { $0 }.max()

        return HStack(spacing: 11) {
            Image(systemName: "person.fill")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(machinist.displayName)
                    .font(.subheadline.weight(.semibold))
                Text("\(machinist.qualification.title) · \(currency(machinist.estimatedLoadedCostPerServiceHourEuro))/h travaillé")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let currentBreak {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("En pause")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                    Text("Jusqu’à \(currentBreak.endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else if let assignment {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(hasIncident ? "Attente après panne" : machinistAssignmentStatus(
                        assignment,
                        incomingReliefPlan: incomingReliefPlan,
                        now: now
                    ))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(hasIncident ? Color.orange : Color.secondary)
                    Text("Ligne \(assignment.routeID) · bloc de \(max(1, dutyBlockAssignments.count)) course(s) · \((dutyBlock?.plannedStartAt ?? assignment.plannedStartAt).formatted(date: .omitted, time: .shortened))–\((dutyBlock?.plannedEndAt ?? assignment.plannedEndAt).formatted(date: .omitted, time: .shortened))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if let scheduledReliefEvent,
                       case let .machinistRelieved(_, _, _, _, incomingName, stopName) = scheduledReliefEvent.kind {
                        Text("Relève prévue à \(stopName) · \(scheduledReliefEvent.simulatedAt.formatted(date: .omitted, time: .shortened)) avec \(incomingName)")
                            .font(.caption2)
                            .foregroundStyle(.tint)
                        if let transferPlan = scheduledReliefPlan?.transferPlan {
                            Text("Trajet estimé : \(transferPlan.originName) → \(Int(ceil(transferPlan.expectedTravelSeconds / 60))) min · arrivée prévue à \(transferPlan.expectedArrivalAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .help(transferPlan.routingSourceTitle)
                        }
                    }
                    if let incomingReliefPlan,
                       let incomingReliefEvent,
                       case let .machinistRelieved(_, _, _, _, _, stopName) = incomingReliefEvent.kind,
                       let transferPlan = incomingReliefPlan.transferPlan {
                        Text("Vers la relève à \(stopName) · départ \(transferPlan.departureAt.formatted(date: .omitted, time: .shortened)) · arrivée estimée \(transferPlan.expectedArrivalAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.tint)
                            .help(transferPlan.routingSourceTitle)
                    }
                }
            } else if let training {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(training.statusTitle(at: now))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.orange)
                    Text("Jusqu’au \(training.endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else if let absence, absence.startsAt <= now {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Absent jusqu’au \(absence.endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                    Text(absence.reason)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if absence != nil {
                Label("Absence prévue", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            } else if let restUntil {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Repos jusqu’à \(restUntil.formatted(date: .omitted, time: .shortened))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("Minimum de jeu · \(MachinistWorkRules.minimumRestHours) h")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Label("Disponible", systemImage: "checkmark.circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
            if canOfferRelief, let assignment {
                Menu {
                    if reliefCandidates.isEmpty {
                        Text("Aucun machiniste qualifié et disponible pour la fin de cette course.")
                    } else {
                        ForEach(reliefCandidates) { candidate in
                            Button(candidate.displayName) {
                                relieve(vehicleID: assignment.vehicleID, with: candidate.id)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "person.2")
                }
                .buttonStyle(.borderless)
                .disabled(reliefCandidates.isEmpty)
                .help("Organiser la relève à l’arrêt actuel")
                .accessibilityLabel("Organiser la relève de \(machinist.displayName) à l’arrêt actuel")
            }
            if canPlanRelief, let assignment, !plannedReliefStops.isEmpty {
                MachinistPlannedReliefMenu(
                    options: plannedReliefOptions,
                    machinistName: machinist.displayName,
                    isPlanning: isPlanningRelief
                ) { stop, candidate in
                    planRelief(
                        vehicleID: assignment.vehicleID,
                        at: stop.eventSequence,
                        with: candidate.id
                    )
                }
            }
            if let scheduledReliefPlan, scheduledReliefEvent != nil {
                Button(role: .destructive) {
                    cancelPlannedRelief(eventSequence: scheduledReliefPlan.eventSequence)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .help("Annuler la relève planifiée")
                .accessibilityLabel("Annuler la relève planifiée de \(machinist.displayName)")
            }
            if machinist.qualification == .standard && training == nil {
                Button {
                    machinistForTraining = machinist
                } label: {
                    Image(systemName: "graduationcap")
                }
                .buttonStyle(.borderless)
                .help("Planifier la formation bus articulé")
                .accessibilityLabel("Planifier la formation bus articulé pour \(machinist.displayName)")
            }
            Button {
                machinistForBreak = machinist
            } label: {
                Image(systemName: "cup.and.saucer")
            }
            .buttonStyle(.borderless)
            .disabled(simulation.availableMachinistBreakWindows(for: machinist.id).isEmpty)
            .help("Planifier une pause de 30 min entre deux courses de ce bloc")
            .accessibilityLabel("Planifier une pause pour \(machinist.displayName)")
        }
        .padding(11)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func settledDutyBlockRow(_ block: MachinistDutyBlock) -> some View {
        let assignments = (session?.machinistServiceAssignments ?? [])
            .filter { $0.dutyBlockID == block.id }
            .sorted { $0.plannedStartAt < $1.plannedStartAt }
        let routes = Array(Set(assignments.map(\.routeID))).sorted()
        let routeDescription = routes.isEmpty ? "Service machiniste" : "Ligne(s) \(routes.joined(separator: ", "))"
        let corrections = (session?.machinistAssignmentCorrections ?? [])
            .filter { $0.dutyBlockID == block.id }
            .sorted { $0.recordedAt < $1.recordedAt }
        let candidates = simulation.availableMachinistDutyBlockCorrectionCandidates(dutyBlockID: block.id)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: corrections.isEmpty ? "person.text.rectangle" : "person.crop.circle.badge.checkmark")
                    .foregroundStyle(corrections.isEmpty ? Color.secondary : Color.accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(machinistName(block.machinistID)) · \(routeDescription)")
                        .font(.subheadline.weight(.semibold))
                    Text("\(block.plannedStartAt.formatted(date: .abbreviated, time: .shortened))–\((block.actualEndAt ?? block.plannedEndAt).formatted(date: .omitted, time: .shortened)) · \(assignments.count) course(s) · paie enregistrée \(currency(block.laborCostEuro ?? 0))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                Button("Corriger") {
                    machinistBlockForCorrection = block
                }
                .buttonStyle(.bordered)
                .disabled(candidates.isEmpty)
                .help(candidates.isEmpty ? "Aucun machiniste admissible pour ce bloc complet." : "Corriger le machiniste enregistré pour ce bloc clôturé")
            }
            ForEach(corrections) { correction in
                Text("Correction · \(machinistName(correction.previousMachinistID)) → \(machinistName(correction.correctedMachinistID)) · \(correction.recordedAt.formatted(date: .abbreviated, time: .shortened)) · \(correction.reason)")
                    .font(.caption)
                    .foregroundStyle(.tint)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 28)
            }
        }
        .padding(11)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func machinistName(_ machinistID: String) -> String {
        session?.machinists?.first(where: { $0.id == machinistID })?.displayName ?? "Machiniste archivé"
    }

    private func breakRow(_ scheduledBreak: MachinistBreak) -> some View {
        let name = machinists.first(where: { $0.id == scheduledBreak.machinistID })?.displayName ?? "Machiniste"
        let now = session?.simulatedAt ?? .distantPast
        return HStack(spacing: 10) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundStyle(scheduledBreak.cancelledAt == nil ? .orange : .secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Text("\(scheduledBreak.startsAt.formatted(date: .abbreviated, time: .shortened))–\(scheduledBreak.endsAt.formatted(date: .omitted, time: .shortened)) · 30 min non rémunérées")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(scheduledBreak.statusTitle(at: now))
                .font(.caption.weight(.medium))
                .foregroundStyle(scheduledBreak.cancelledAt == nil ? .orange : .secondary)
            if scheduledBreak.isPending && scheduledBreak.startsAt > now {
                Button(role: .destructive) {
                    do {
                        try simulation.cancelMachinistBreak(breakID: scheduledBreak.id)
                    } catch {
                        breakError = error.localizedDescription
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .help("Annuler cette pause avant son début")
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func absenceRow(_ absence: MachinistAbsence) -> some View {
        let name = machinists.first(where: { $0.id == absence.machinistID })?.displayName ?? "Machiniste"
        let now = session?.simulatedAt ?? .distantPast
        return HStack(spacing: 10) {
            Image(systemName: "calendar.badge.minus")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(name) · \(absence.absenceType?.title ?? "Ancienne absence")")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                Text("\(absence.startsAt.formatted(date: .abbreviated, time: .shortened)) – \(absence.endsAt.formatted(date: .abbreviated, time: .shortened)) · \(absence.reason)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let cost = absence.estimatedPayrollCostEuro,
                   let hours = absence.estimatedPaidHours {
                    Text("\(absence.statusTitle(at: now)) · \(hours.formatted(.number.precision(.fractionLength(1)))) h estimées · coût de jeu \(currency(cost))")
                        .font(.caption2)
                        .foregroundStyle(absence.settledAt == nil && absence.endsAt <= now ? Color.orange : Color.secondary)
                } else {
                    Text(absence.statusTitle(at: now))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if absence.startsAt >= now {
                Button(role: .destructive) {
                    cancelAbsence(absence.id)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .help("Retirer cette absence")
            } else {
                Text("En cours")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func trainingRow(_ training: MachinistTrainingRecord) -> some View {
        let now = session?.simulatedAt ?? .distantPast
        let name = machinists.first(where: { $0.id == training.machinistID })?.displayName ?? "Machiniste"
        return HStack(spacing: 10) {
            Image(systemName: training.cancelledAt == nil ? "graduationcap.fill" : "graduationcap")
                .foregroundStyle(training.cancelledAt == nil ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(name) · \(training.sourceQualification.title) → \(training.targetQualification.title)")
                    .font(.subheadline.weight(.medium))
                Text("\(training.statusTitle(at: now)) · \(training.startsAt.formatted(date: .abbreviated, time: .shortened)) – \(training.endsAt.formatted(date: .abbreviated, time: .shortened)) · salaire estimé \(currency(training.estimatedLaborCostEuro))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if training.isPending && training.startsAt > now {
                Button(role: .destructive) {
                    do {
                        try simulation.cancelMachinistTraining(trainingID: training.id)
                    } catch {
                        trainingError = error.localizedDescription
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .help("Annuler la formation avant son début")
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func hire(_ qualification: MachinistQualification) {
        do {
            try simulation.hireMachinist(qualification: qualification, depotID: activeDepotID)
            pendingQualification = nil
        } catch {
            recruitmentError = error.localizedDescription
            pendingQualification = nil
        }
    }

    private func relieve(vehicleID: String, with incomingMachinistID: String) {
        do {
            try simulation.relieveMachinist(
                vehicleID: vehicleID,
                incomingMachinistID: incomingMachinistID
            )
        } catch {
            reliefError = error.localizedDescription
        }
    }

    private func plannedMachinistReliefOptions(
        vehicleID: String,
        stops: [MachinistReliefStop]
    ) -> [MachinistPlannedReliefOption] {
        stops.flatMap { stop in
            simulation.availableMachinistPlannedReliefCandidates(
                forVehicleID: vehicleID,
                stopEventSequence: stop.eventSequence
            ).map { MachinistPlannedReliefOption(stop: stop, candidate: $0) }
        }
    }

    private func planRelief(vehicleID: String, at stopEventSequence: UInt64, with incomingMachinistID: String) {
        guard !isPlanningRelief else { return }
        isPlanningRelief = true
        Task { @MainActor in
            defer { isPlanningRelief = false }
            do {
                guard let request = simulation.machinistTransferRequest(
                    machinistID: incomingMachinistID,
                    stopEventSequence: stopEventSequence
                ) else {
                    throw SimulationEngineError.machinistTransferUnavailable
                }
                let transferPlan = try await MachinistTransferRouter.plan(for: request)
                try simulation.scheduleMachinistRelief(
                    vehicleID: vehicleID,
                    incomingMachinistID: incomingMachinistID,
                    stopEventSequence: stopEventSequence,
                    transferPlan: transferPlan
                )
            } catch {
                reliefError = error.localizedDescription
            }
        }
    }

    private func machinistAssignmentStatus(
        _ assignment: MachinistServiceAssignment,
        incomingReliefPlan: MachinistReliefPlan?,
        now: Date
    ) -> String {
        guard let transferPlan = incomingReliefPlan?.transferPlan else {
            return assignment.plannedStartAt > now ? "Service prévu" : "En service"
        }
        if now < transferPlan.departureAt { return "Départ vers relève prévu" }
        if now < transferPlan.expectedArrivalAt { return "En trajet vers relève" }
        return "Arrivé, relève en attente"
    }

    private func cancelPlannedRelief(eventSequence: UInt64) {
        do {
            try simulation.cancelScheduledMachinistRelief(eventSequence: eventSequence)
        } catch {
            reliefError = error.localizedDescription
        }
    }

    private func cancelAbsence(_ absenceID: String) {
        do {
            try simulation.cancelMachinistAbsence(absenceID: absenceID)
        } catch {
            recruitmentError = error.localizedDescription
        }
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

private struct MachinistAssignmentCorrectionEditorView: View {
    @ObservedObject var simulation: SimulationEngine
    let dutyBlock: MachinistDutyBlock
    let previousMachinistName: String
    let candidates: [Machinist]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMachinistID: String
    @State private var reason = ""
    @State private var errorMessage: String?

    init(
        simulation: SimulationEngine,
        dutyBlock: MachinistDutyBlock,
        previousMachinistName: String,
        candidates: [Machinist]
    ) {
        self.simulation = simulation
        self.dutyBlock = dutyBlock
        self.previousMachinistName = previousMachinistName
        self.candidates = candidates
        _selectedMachinistID = State(initialValue: candidates.first?.id ?? "")
    }

    private var selectedMachinist: Machinist? {
        candidates.first(where: { $0.id == selectedMachinistID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bloc terminé et soldé") {
                    LabeledContent("Machiniste enregistré", value: previousMachinistName)
                    LabeledContent(
                        "Période",
                        value: "\(dutyBlock.plannedStartAt.formatted(date: .abbreviated, time: .shortened))–\((dutyBlock.actualEndAt ?? dutyBlock.plannedEndAt).formatted(date: .omitted, time: .shortened))"
                    )
                    LabeledContent("Paie enregistrée", value: currency(dutyBlock.laborCostEuro ?? 0))
                }

                Section("Correction") {
                    if candidates.isEmpty {
                        ContentUnavailableView(
                            "Aucun remplacement admissible",
                            systemImage: "person.crop.circle.badge.xmark",
                            description: Text("Un machiniste doit être recruté dans le même dépôt, qualifié et libre sur toute la période du bloc.")
                        )
                    } else {
                        Picker("Machiniste corrigé", selection: $selectedMachinistID) {
                            ForEach(candidates) { candidate in
                                Text("\(candidate.displayName) · \(candidate.qualification.title)")
                                    .tag(candidate.id)
                            }
                        }
                        TextField("Motif de la correction", text: $reason, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }

                Text("La correction réattribue toutes les courses du bloc. Elle conserve les heures, le montant déjà enregistré et les règlements; elle ne recalcule pas la paie selon le nouveau machiniste. Le motif et chaque transition restent visibles dans l’historique.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .formStyle(.grouped)
            .navigationTitle("Corriger l’affectation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { saveCorrection() }
                        .disabled(selectedMachinist == nil || reason.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)
                }
            }
            .alert("Correction impossible", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Une erreur est survenue.")
            }
        }
    }

    private func saveCorrection() {
        guard let selectedMachinist else { return }
        do {
            try simulation.correctMachinistDutyBlock(
                dutyBlockID: dutyBlock.id,
                toMachinistID: selectedMachinist.id,
                reason: reason
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

private struct MachinistBreakEditorView: View {
    @ObservedObject var simulation: SimulationEngine
    let machinist: Machinist
    let windows: [MachinistBreakWindow]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWindowID: String
    @State private var errorMessage: String?

    init(simulation: SimulationEngine, machinist: Machinist, windows: [MachinistBreakWindow]) {
        self.simulation = simulation
        self.machinist = machinist
        self.windows = windows
        _selectedWindowID = State(initialValue: windows.first?.id ?? "")
    }

    private var selectedWindow: MachinistBreakWindow? {
        windows.first(where: { $0.id == selectedWindowID })
    }

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Machiniste", value: machinist.displayName)
                if windows.isEmpty {
                    ContentUnavailableView(
                        "Aucun créneau de pause",
                        systemImage: "cup.and.saucer",
                        description: Text("Aucune pause de 30 min ne tient dans un battement libre entre deux courses de ce bloc.")
                    )
                } else {
                    Picker("Battement", selection: $selectedWindowID) {
                        ForEach(windows) { window in
                            Text("\(window.startsAt.formatted(date: .abbreviated, time: .shortened)) · avant \(window.nextCourseStartsAt.formatted(date: .omitted, time: .shortened))")
                                .tag(window.id)
                        }
                    }
                    if let selectedWindow {
                        LabeledContent(
                            "Fin de pause",
                            value: selectedWindow.endsAt.formatted(date: .abbreviated, time: .shortened)
                        )
                        LabeledContent("Durée", value: "30 min simulées")
                        LabeledContent("Rémunération", value: "Déduite du bloc")
                    }
                }
                Text("Cette pause est une règle de jeu, non une vérification réglementaire. Elle est enregistrée dans la sauvegarde, occupe le créneau dans le planning et son temps est retiré des heures rémunérées du bloc.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .navigationTitle("Planifier une pause")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Planifier") { scheduleBreak() }
                        .disabled(selectedWindow == nil)
                }
            }
            .alert("Pause impossible", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Une erreur est survenue.")
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private func scheduleBreak() {
        do {
            try simulation.scheduleMachinistBreak(machinistID: machinist.id, windowID: selectedWindowID)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct MachinistAbsenceEditorView: View {
    @ObservedObject var simulation: SimulationEngine
    let machinist: Machinist
    let machinists: [Machinist]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMachinistID: String
    @State private var startsAt: Date
    @State private var endsAt: Date
    @State private var absenceType: MachinistAbsenceType = .paidLeave
    @State private var estimatedPaidHours = 8.0
    @State private var reason = ""
    @State private var errorMessage: String?

    init(simulation: SimulationEngine, machinist: Machinist, machinists: [Machinist]) {
        self.simulation = simulation
        self.machinist = machinist
        self.machinists = machinists
        let now = simulation.session?.simulatedAt ?? .now
        _selectedMachinistID = State(initialValue: machinist.id)
        _startsAt = State(initialValue: now.addingTimeInterval(60 * 60))
        _endsAt = State(initialValue: now.addingTimeInterval(9 * 60 * 60))
    }

    private var intervalHours: Double {
        max(0, endsAt.timeIntervalSince(startsAt) / 3_600)
    }

    private var estimatedPayrollCostEuro: Int {
        let hourlyCost = machinists.first(where: { $0.id == selectedMachinistID })?
            .estimatedLoadedCostPerServiceHourEuro ?? 0
        return Int((Double(hourlyCost) * estimatedPaidHours * absenceType.estimatedPayFactor).rounded())
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Machiniste", selection: $selectedMachinistID) {
                    ForEach(machinists) { machinist in
                        Text(machinist.displayName).tag(machinist.id)
                    }
                }
                DatePicker(
                    "Début",
                    selection: $startsAt,
                    in: (simulation.session?.simulatedAt ?? .now)...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                DatePicker(
                    "Fin",
                    selection: $endsAt,
                    in: startsAt...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                Picker("Type d’absence", selection: $absenceType) {
                    ForEach(MachinistAbsenceType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                if absenceType == .unpaidLeave {
                    LabeledContent("Rémunération", value: "Aucune")
                } else {
                    Stepper(value: $estimatedPaidHours, in: 0...intervalHours, step: 0.5) {
                        LabeledContent(
                            "Heures de travail estimées",
                            value: "\(estimatedPaidHours.formatted(.number.precision(.fractionLength(1)))) h"
                        )
                    }
                    LabeledContent("Taux de jeu", value: absenceType.estimatedPayFactor.formatted(.percent))
                    LabeledContent(
                        "Coût employeur estimé",
                        value: estimatedPayrollCostEuro.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
                    )
                }
                TextField("Note facultative", text: $reason)
                Text("Les heures de travail rémunérées sont saisies séparément de la plage qui bloque le planning. Les taux sont des règles de jeu : congé rémunéré 100 %, maladie simulée 50 %, absence non rémunérée 0 %. Une absence qui chevauche un service ou une formation est refusée.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .navigationTitle("Planifier une absence")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { saveAbsence() }
                        .disabled(selectedMachinistID.isEmpty || endsAt <= startsAt)
                }
            }
            .onChange(of: startsAt) { _, newValue in
                if endsAt <= newValue { endsAt = newValue.addingTimeInterval(8 * 60 * 60) }
                clampEstimatedPaidHours()
            }
            .onChange(of: endsAt) { _, _ in
                clampEstimatedPaidHours()
            }
            .onChange(of: absenceType) { _, newType in
                if newType == .unpaidLeave {
                    estimatedPaidHours = 0
                } else if estimatedPaidHours == 0 {
                    estimatedPaidHours = min(8, intervalHours)
                }
            }
            .alert("Absence impossible", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Une erreur est survenue.")
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private func saveAbsence() {
        do {
            try simulation.scheduleMachinistAbsence(
                machinistID: selectedMachinistID,
                startsAt: startsAt,
                endsAt: endsAt,
                absenceType: absenceType,
                estimatedPaidHours: estimatedPaidHours,
                reason: reason
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clampEstimatedPaidHours() {
        estimatedPaidHours = min(max(0, estimatedPaidHours), intervalHours)
    }
}

private struct MachinistTrainingEditorView: View {
    @ObservedObject var simulation: SimulationEngine
    let machinist: Machinist
    @Environment(\.dismiss) private var dismiss
    @State private var startsAt: Date
    @State private var errorMessage: String?

    init(simulation: SimulationEngine, machinist: Machinist) {
        self.simulation = simulation
        self.machinist = machinist
        _startsAt = State(initialValue: (simulation.session?.simulatedAt ?? .now).addingTimeInterval(60 * 60))
    }

    private var endsAt: Date {
        startsAt.addingTimeInterval(MachinistWorkRules.articulatedTrainingDuration)
    }

    private var estimatedLaborCost: Int {
        machinist.estimatedLoadedCostPerServiceHourEuro
            * MachinistWorkRules.articulatedTrainingDurationHours
    }

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Qualification actuelle", value: machinist.qualification.title)
                LabeledContent("Qualification obtenue", value: MachinistQualification.articulated.title)
                DatePicker(
                    "Début",
                    selection: $startsAt,
                    in: (simulation.session?.simulatedAt ?? .now)...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                LabeledContent("Fin prévue", value: endsAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Durée", value: "8 h simulées")
                LabeledContent("Salaire de formation estimé", value: estimatedLaborCost.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                Text("La formation bloque les affectations pendant 8 h et impose 11 h de repos de jeu avant et après. Le coût est débité à sa fin. Le cours et son tarif sont des règles de jeu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .navigationTitle("Formation bus articulé")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Planifier") { scheduleTraining() }
                        .disabled(machinist.qualification != .standard)
                }
            }
            .alert("Formation impossible", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Une erreur est survenue.")
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private func scheduleTraining() {
        do {
            try simulation.scheduleMachinistTraining(machinistID: machinist.id, startsAt: startsAt)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct RouteDetourRequest: Identifiable {
    let stop: GTFSStopSummary?
    let routeID: String
    let sourceObservation: PRIMTrafficObservation?

    var id: String { "\(stop?.stopID ?? "line")|\(routeID)|\(sourceObservation?.report.id ?? "manual")" }
}

private struct ActiveTripMapShape: Identifiable {
    let tripID: String
    let shapeID: String
    let points: [GTFSShapePoint]

    var id: String { shapeID }
}

private struct DispatchableDeparture: Identifiable {
    let sequence: UInt64
    let tripID: String
    let routeID: String
    let serviceDateKey: Int
    let departureAt: Date

    var id: UInt64 { sequence }
}

private struct TripDispatchView: View {
    @ObservedObject var library: NetworkLibrary
    @ObservedObject var simulation: SimulationEngine
    var depotRouteIDs: Set<String>? = nil
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDepartureSequence: UInt64?
    @State private var selectedVehicleID: String?
    @State private var selectedMachinistID: String?
    @State private var stopVisits: [ScheduledTripStopVisit] = []
    @State private var deadheadPlan: VehicleDeadheadPlan?
    @State private var isCalculatingDeadhead = false
    @State private var deadheadError: String?
    @State private var deadheadRequestID = UUID()
    @State private var loadedSequence: UInt64?
    @State private var isLoadingSchedule = false
    @State private var scheduleError: String?
    @State private var dispatchError: String?

    private var departures: [DispatchableDeparture] {
        guard let session = simulation.session else { return [] }
        let operatedRouteIDs = depotRouteIDs ?? Set(session.operatedRouteIDs ?? [])
        return session.pendingEvents.compactMap { event in
            guard case let .scheduledServiceDeparture(tripID, routeID, serviceDateKey) = event.kind,
                  operatedRouteIDs.contains(routeID) else { return nil }
            return DispatchableDeparture(
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

    private var selectedDeparture: DispatchableDeparture? {
        guard let selectedDepartureSequence else { return nil }
        return departures.first { $0.sequence == selectedDepartureSequence }
    }

    private var eligibleBuses: [PurchasedBus] {
        guard loadedSequence == selectedDepartureSequence,
              let firstStopID = stopVisits.first?.stopID else { return [] }
        return (simulation.session?.ownedBuses ?? []).filter { bus in
            guard bus.reservedTripKey == nil else { return false }
            if bus.status == .atDepot { return bus.depotID == simulation.session?.effectiveActiveDepotID }
            return bus.status == .atStop && bus.currentStopID == firstStopID
        }
        .sorted { $0.acquiredAt < $1.acquiredAt }
    }

    private var selectedVehicle: PurchasedBus? {
        eligibleBuses.first { $0.id == selectedVehicleID }
    }

    private var selectedDepotName: String {
        guard let depotID = simulation.session?.effectiveActiveDepotID else { return "dépôt" }
        return DepotCareerScope.depotReference(for: depotID)?.name ?? depotID
    }

    private var deadheadDepartureAt: Date? {
        guard let firstStop = stopVisits.first,
              let deadheadPlan else { return nil }
        return firstStop.scheduledAt.addingTimeInterval(-deadheadPlan.expectedTravelSeconds)
    }

    private var canReachFirstStopFromDepot: Bool {
        guard let deadheadDepartureAt,
              let simulatedAt = simulation.session?.simulatedAt else { return false }
        return deadheadDepartureAt >= simulatedAt
    }

    private var canDispatchSelection: Bool {
        guard selectedDeparture != nil,
              selectedVehicle != nil,
              selectedMachinist != nil,
              !isLoadingSchedule,
              !isCalculatingDeadhead else { return false }
        return selectedVehicle?.status != .atDepot || (deadheadPlan != nil && canReachFirstStopFromDepot)
    }

    private var eligibleMachinists: [Machinist] {
        guard loadedSequence == selectedDepartureSequence,
              let vehicle = selectedVehicle,
              let firstStop = stopVisits.first,
              let lastStop = stopVisits.last else { return [] }
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

    private var selectedMachinist: Machinist? {
        eligibleMachinists.first { $0.id == selectedMachinistID }
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                departureList
                    .frame(width: 340)
                Divider()
                departureDetails
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Affecter une course GTFS")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Affecter bus et machiniste") { dispatchSelectedDeparture() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canDispatchSelection)
                }
            }
            .task(id: selectedDepartureSequence) {
                await loadSelectedSchedule()
            }
            .onChange(of: departures.map(\.id)) { _, currentIDs in
                if let selectedDepartureSequence, !currentIDs.contains(selectedDepartureSequence) {
                    self.selectedDepartureSequence = nil
                    selectedVehicleID = nil
                    stopVisits = []
                    deadheadPlan = nil
                    deadheadError = nil
                    loadedSequence = nil
                }
            }
            .onChange(of: eligibleMachinists.map(\.id)) { _, currentIDs in
                if let selectedMachinistID, currentIDs.contains(selectedMachinistID) { return }
                selectedMachinistID = currentIDs.first
            }
            .onChange(of: selectedVehicleID) { _, _ in
                let requestID = UUID()
                deadheadRequestID = requestID
                deadheadPlan = nil
                deadheadError = nil
                selectedMachinistID = eligibleMachinists.first?.id
                Task { await calculateDeadheadRoute(requestID: requestID) }
            }
            .alert("Affectation impossible", isPresented: Binding(
                get: { dispatchError != nil },
                set: { if !$0 { dispatchError = nil } }
            )) {
                Button("OK", role: .cancel) { dispatchError = nil }
            } message: {
                Text(dispatchError ?? "La course n’a pas pu être affectée.")
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private var departureList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DÉPARTS THÉORIQUES")
                .font(.caption.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(.secondary)
                .padding(16)
            Divider()
            if departures.isEmpty {
                ContentUnavailableView(
                    "Aucun départ en attente",
                    systemImage: "calendar.badge.clock",
                    description: Text("Les départs GTFS chargés pour les lignes affectées ont été consommés ou ne figurent pas dans l’horizon actuel.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 7) {
                        ForEach(departures) { departure in
                            departureRow(departure)
                        }
                    }
                    .padding(10)
                }
            }
        }
        .background(Color.primary.opacity(0.025))
    }

    private func departureRow(_ departure: DispatchableDeparture) -> some View {
        let isSelected = selectedDepartureSequence == departure.sequence
        let routeName = library.busRoutes.first(where: { $0.routeID == departure.routeID })?.displayName
        return Button {
            selectedDepartureSequence = departure.sequence
            selectedVehicleID = nil
            stopVisits = []
            deadheadPlan = nil
            deadheadError = nil
            loadedSequence = nil
            scheduleError = nil
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Ligne \(routeName ?? departure.routeID)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(departure.departureAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption.monospacedDigit().weight(.semibold))
                }
                Text("ID \(departure.routeID) · Course \(departure.tripID)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("Service \(departure.serviceDateKey)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.13) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var departureDetails: some View {
        if let selectedDeparture {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("COURSE GTFS \(selectedDeparture.tripID)")
                            .font(.caption.weight(.bold))
                            .tracking(0.7)
                            .foregroundStyle(.secondary)
                        Text("Ligne \(selectedDeparture.routeID) · départ \(selectedDeparture.departureAt.formatted(date: .complete, time: .shortened))")
                            .font(.title3.weight(.semibold))
                        Text("La course reste une donnée théorique jusqu’à l’affectation d’un véhicule.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    GroupBox("Séquence géolocalisée") {
                        if isLoadingSchedule {
                            ProgressView("Chargement des horaires et arrêts GTFS…")
                                .frame(maxWidth: .infinity, minHeight: 90)
                        } else if let scheduleError {
                            Label(scheduleError, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else if stopVisits.isEmpty {
                            Text("Sélectionnez une course pour charger ses arrêts horodatés.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(stopVisits.indices, id: \.self) { index in
                                    let visit = stopVisits[index]
                                    HStack(spacing: 11) {
                                        Text(visit.scheduledAt.formatted(date: .omitted, time: .shortened))
                                            .font(.caption.monospacedDigit().weight(.semibold))
                                            .frame(width: 54, alignment: .leading)
                                        Image(systemName: index == 0 ? "play.circle.fill" : (index == stopVisits.count - 1 ? "flag.circle.fill" : "circle.fill"))
                                            .font(.caption)
                                            .foregroundStyle(index == stopVisits.count - 1 ? Color.orange : Color.accentColor)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(visit.stopName)
                                                .font(.subheadline.weight(.medium))
                                            Text("ID arrêt \(visit.stopID) · séquence \(visit.stopSequence)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 6)
                                    if index < stopVisits.count - 1 { Divider().padding(.leading, 67) }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if stopVisits.dropLast().contains(where: {
                                $0.movementGeometrySource == .stopCoordinateEstimate
                            }) {
                                Label(
                                    "Au moins un segment est estimé en ligne droite entre deux coordonnées d’arrêts, faute de forme GTFS raccordable. Ce segment n’est pas un tracé officiel.",
                                    systemImage: "point.3.connected.trianglepath.dotted"
                                )
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 9)
                            }
                        }
                    }

                    GroupBox("Bus disponible au départ") {
                        if eligibleBuses.isEmpty {
                            Text(stopVisits.isEmpty
                                 ? "Achetez un véhicule puis attendez sa livraison au dépôt."
                                 : "Aucun bus au dépôt ou présent au premier arrêt de cette course.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 7) {
                                ForEach(eligibleBuses) { bus in
                                    busChoice(bus)
                                }
                            }
                        }
                    }

                    if selectedVehicle?.status == .atDepot {
                        GroupBox("Acheminement à vide vers le premier arrêt") {
                            if isCalculatingDeadhead {
                                ProgressView("Calcul de l’itinéraire depuis \(selectedDepotName)…")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            } else if deadheadPlan != nil, !canReachFirstStopFromDepot {
                                Label("L’heure de départ du dépôt est dépassée dans la simulation. Choisissez un bus déjà au premier arrêt ou un départ ultérieur.", systemImage: "clock.badge.exclamationmark")
                                    .font(.callout)
                                    .foregroundStyle(.orange)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            } else if let deadheadPlan, let deadheadDepartureAt {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("\(deadheadPlan.resolvedDepotAddress) → \(deadheadPlan.stopName) · \((deadheadPlan.routeDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km · ETA MapKit \(durationText(deadheadPlan.expectedTravelSeconds))")
                                    Text("Départ du dépôt \(deadheadDepartureAt.formatted(date: .omitted, time: .shortened)) · arrivée prévue \(selectedDeparture.departureAt.formatted(date: .omitted, time: .shortened)) · \(deadheadPlan.routingSourceTitle)")
                                        .foregroundStyle(.secondary)
                                    Text("Le machiniste est planifié dès la sortie du dépôt. Le trajet compte dans les kilomètres, l’usure et l’énergie, sans recette de service.")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                            } else if let deadheadError {
                                Label(deadheadError, systemImage: "exclamationmark.triangle")
                                    .font(.callout)
                                    .foregroundStyle(.orange)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            } else {
                                Text("Aucun itinéraire utilisable n’est calculé pour ce bus.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                        }
                    }

                    GroupBox("Machiniste qualifié et disponible") {
                        Text("Les courses espacées de 2 h au plus peuvent partager un bloc de 10 h maximum ; le repos minimal de 11 h s’applique entre blocs.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if selectedVehicle == nil {
                            Text("Choisissez d’abord le bus de cette course.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else if eligibleMachinists.isEmpty {
                            Text((simulation.session?.machinists ?? []).isEmpty
                                 ? "Aucun machiniste recruté. Fermez cette fenêtre et recrutez-en un dans Personnel."
                                : "Aucun machiniste qualifié n’est libre sur toute la durée prévue, son repos minimum ou une absence.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 7) {
                                ForEach(eligibleMachinists) { machinist in
                                    machinistChoice(machinist)
                                }
                            }
                        }
                    }

                    Text("Un bus au dépôt suit un itinéraire routier MapKit jusqu’au premier arrêt et doit y arriver à l’heure prévue. Les courses restent affectables sans trajet de dépôt pour un bus déjà au premier arrêt. Sur la ligne, le bus suit la forme GTFS quand elle se raccorde aux arrêts dans l’ordre ; sinon, une liaison estimée entre coordonnées d’arrêts est utilisée et affichée en pointillé orange. Sa distance ne représente pas un itinéraire réel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        } else {
            ContentUnavailableView(
                "Choisir un départ",
                systemImage: "arrow.triangle.branch",
                description: Text("Sélectionnez un départ théorique pour consulter sa séquence d’arrêts et choisir un bus disponible.")
            )
        }
    }

    private func busChoice(_ bus: PurchasedBus) -> some View {
        let isSelected = selectedVehicleID == bus.id
        let modelName = VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID
        return Button {
            selectedVehicleID = bus.id
            selectedMachinistID = nil
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bus.fill")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(modelName) · \(bus.modelYear)")
                        .font(.subheadline.weight(.medium))
                    Text("\(bus.id) · \(bus.status.title)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private func machinistChoice(_ machinist: Machinist) -> some View {
        let isSelected = selectedMachinistID == machinist.id
        return Button {
            selectedMachinistID = machinist.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(machinist.displayName)
                        .font(.subheadline.weight(.medium))
                    Text("\(machinist.qualification.title) · \(machinist.estimatedLoadedCostPerServiceHourEuro) €/h travaillé")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 9))
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private func loadSelectedSchedule() async {
        guard let departure = selectedDeparture,
              let gtfsVersionID = simulation.session?.networkVersions.gtfsID else {
            stopVisits = []
            deadheadPlan = nil
            deadheadError = nil
            loadedSequence = nil
            selectedMachinistID = nil
            return
        }
        let sequence = departure.sequence
        isLoadingSchedule = true
        scheduleError = nil
        stopVisits = []
        loadedSequence = nil
        defer {
            if selectedDepartureSequence == sequence { isLoadingSchedule = false }
        }

        do {
            let visits = try await library.loadScheduledTripStopVisits(
                gtfsVersionID: gtfsVersionID,
                tripID: departure.tripID,
                serviceDateKey: departure.serviceDateKey
            )
            guard !Task.isCancelled, selectedDepartureSequence == sequence else { return }
            stopVisits = visits
            loadedSequence = sequence
            selectedVehicleID = eligibleBuses.first?.id
            selectedMachinistID = nil
        } catch {
            guard !Task.isCancelled, selectedDepartureSequence == sequence else { return }
            scheduleError = error.localizedDescription
        }
    }

    private func calculateDeadheadRoute(requestID: UUID) async {
        guard let vehicleID = selectedVehicleID,
              let vehicle = selectedVehicle,
              vehicle.status == .atDepot,
              let stop = stopVisits.first,
              let departure = selectedDeparture,
              loadedSequence == departure.sequence,
              let session = simulation.session,
              session.effectiveManagedDepotIDs.contains(vehicle.depotID),
              DepotCareerScope.supports(scenarioID: session.scenarioID, depotID: vehicle.depotID),
              let depot = DepotCareerScope.depotReference(for: vehicle.depotID) else {
            guard deadheadRequestID == requestID else { return }
            deadheadPlan = nil
            deadheadError = nil
            isCalculatingDeadhead = false
            return
        }
        deadheadPlan = nil
        deadheadError = nil
        isCalculatingDeadhead = true
        defer {
            if deadheadRequestID == requestID { isCalculatingDeadhead = false }
        }

        do {
            let plan = try await VehicleDeadheadRouter.route(
                from: depot,
                to: stop,
                serviceStartAt: stop.scheduledAt,
                earliestDepartureAt: session.simulatedAt
            )
            guard !Task.isCancelled,
                  deadheadRequestID == requestID,
                  selectedVehicleID == vehicleID,
                  selectedDepartureSequence == departure.sequence,
                  let currentSession = simulation.session else { return }
            let leaveAt = stop.scheduledAt.addingTimeInterval(-plan.expectedTravelSeconds)
            guard leaveAt >= currentSession.simulatedAt else {
                deadheadError = "L’ETA MapKit ne laisse pas assez de temps pour rejoindre le départ GTFS depuis le dépôt. Choisissez un bus déjà au premier arrêt ou un départ ultérieur."
                return
            }
            deadheadPlan = plan
        } catch {
            guard !Task.isCancelled,
                  deadheadRequestID == requestID,
                  selectedVehicleID == vehicleID,
                  selectedDepartureSequence == departure.sequence else { return }
            deadheadError = error.localizedDescription
        }
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let minutes = max(0, Int(duration / 60))
        return "\(minutes / 60) h \(minutes % 60) min"
    }

    private func dispatchSelectedDeparture() {
        guard let departure = selectedDeparture,
              let vehicleID = selectedVehicleID,
              let machinistID = selectedMachinistID,
              loadedSequence == departure.sequence else { return }
        do {
            try simulation.dispatchScheduledDeparture(
                eventSequence: departure.sequence,
                vehicleID: vehicleID,
                machinistID: machinistID,
                stopVisits: stopVisits,
                deadheadPlan: selectedVehicle?.status == .atDepot ? deadheadPlan : nil
            )
            dismiss()
        } catch {
            dispatchError = error.localizedDescription
        }
    }
}

private struct DailyOperationsReportView: View {
    @ObservedObject var simulation: SimulationEngine
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss

    private var reports: [DailyOperationsReport] {
        (simulation.session?.dailyOperationsReports ?? []).sorted { $0.dateKey > $1.dateKey }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Bilans produits à chaque clôture de journée simulée. Les files estimées restent sauvegardées par ligne et arrêt ; la demande tient compte de l’intervalle de service. Les voyageurs laissés à quai peuvent monter dans une course suivante. Ces volumes de jeu ne sont pas des comptages réels.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if reports.isEmpty {
                        ContentUnavailableView(
                            "Aucun bilan journalier",
                            systemImage: "chart.bar",
                            description: Text("Le premier bilan apparaîtra à minuit, après une journée de simulation.")
                        )
                    } else {
                        ForEach(reports) { report in
                            reportCard(report)
                        }
                    }

                    Text("La contribution estimée suit les véhicule-kilomètres réellement parcourus. Le bilan quotidien compare les courses terminées aux départs planifiés et applique, le cas échéant, le bonus ou malus de jeu indiqué au marché. Les taux et seuils ne sont pas publiés comme termes financiers de la DSP 45 ; les validations voyageurs ne sont pas comptées comme recettes opérateur. Le coût horaire machiniste et l’entretien préventif restent des estimations de jeu.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(13)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
                    Text("Repère régional IDFM : en mai 2026, la part variable de rémunération liée à la qualité est annoncée à 10 % du chiffre d’affaires, contre 1 % auparavant ; la production DSP45 était supérieure à 94 % en 2025. Ce contexte ne donne pas le barème en euros de la DSP45 et ne modifie pas les règles de jeu ci-dessus.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Link("IDFM · rémunération variable et qualité de service · 27 mai 2026", destination: URL(string: "https://presse.iledefrance-mobilites.fr/qualite-de-service-des-bus-en-ile-de-france-une-progression-continue-au-benefice-des-voyageurs/?lang=fr")!)
                        .font(.caption)
                }
                .padding(22)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Bilans d’exploitation")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private func reportCard(_ report: DailyOperationsReport) -> some View {
        GroupBox(dateTitle(report.dateKey)) {
            VStack(spacing: 11) {
                HStack(spacing: 0) {
                    metric("Départs assurés", value: report.servedDepartureCount.formatted(), symbol: "bus.fill", color: .green)
                    Divider().frame(height: 48)
                    metric("Non assurés", value: report.missedDepartureCount.formatted(), symbol: "exclamationmark.triangle", color: report.missedDepartureCount == 0 ? .secondary : .orange)
                    Divider().frame(height: 48)
                    metric("Courses terminées", value: report.completedTripCount.formatted(), symbol: "checkmark.circle", color: .blue)
                }

                if let boardings = report.estimatedPassengerBoardings,
                   let leftBehind = report.estimatedPassengersLeftBehind {
                    Divider()
                    HStack(spacing: 0) {
                        metric("Montées estimées", value: boardings.formatted(), symbol: "person.2.fill", color: .teal)
                        Divider().frame(height: 48)
                        metric("Nouveaux laissés à quai", value: leftBehind.formatted(), symbol: "person.crop.circle.badge.exclamationmark", color: leftBehind == 0 ? .secondary : .orange)
                    }
                }

                if let incidentCount = report.incidentCount,
                   let interruptedTripCount = report.interruptedTripCount {
                    Divider()
                    HStack(spacing: 0) {
                        metric("Pannes", value: incidentCount.formatted(), symbol: "wrench.and.screwdriver.fill", color: incidentCount == 0 ? .secondary : .red)
                        Divider().frame(height: 48)
                        metric("Courses interrompues", value: interruptedTripCount.formatted(), symbol: "bus.fill", color: interruptedTripCount == 0 ? .secondary : .orange)
                    }
                }

                Divider()

                HStack {
                    Label("Distance parcourue", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    Spacer()
                    Text("\((report.tracedDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
                Text("Total des segments de service et des trajets à vide enregistrés.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let estimatedConnectors = report.estimatedStopConnectorDistanceMeters, estimatedConnectors > 0 {
                    HStack {
                        Label("Dont liaisons estimées entre arrêts", systemImage: "point.3.connected.trianglepath.dotted")
                        Spacer()
                        Text("\((estimatedConnectors / 1_000).formatted(.number.precision(.fractionLength(1)))) km")
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(.orange)
                }
                if let detourDistance = report.temporaryDetourDistanceMeters, detourDistance > 0 {
                    HStack {
                        Label("Dont déviations temporaires MapKit · estimation de jeu", systemImage: "arrow.triangle.branch")
                        Spacer()
                        Text("\((detourDistance / 1_000).formatted(.number.precision(.fractionLength(1)))) km")
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(.orange)
                }

                if let serviceRevenue = report.estimatedServiceRevenueEuro {
                    HStack {
                        Label("Contribution de service estimée", systemImage: "eurosign.circle")
                        Spacer()
                        Text(currency(serviceRevenue))
                            .font(.subheadline.monospacedDigit().weight(.medium))
                    }
                    Divider()
                }

                if let completionRate = report.contractCompletionRate {
                    HStack {
                        Label("Départs terminés", systemImage: "checkmark.seal")
                        Spacer()
                        Text("\((completionRate * 100).formatted(.number.precision(.fractionLength(1)))) %")
                            .font(.subheadline.monospacedDigit().weight(.medium))
                    }
                    Divider()
                }
                if let qualityAdjustment = report.contractQualityAdjustmentEuro {
                    HStack {
                        Label("Bonus / malus de production · jeu", systemImage: qualityAdjustment >= 0 ? "arrow.up.right.circle" : "arrow.down.right.circle")
                        Spacer()
                        Text("\(qualityAdjustment >= 0 ? "+" : "−")\(currency(abs(qualityAdjustment)))")
                            .font(.subheadline.monospacedDigit().weight(.medium))
                            .foregroundStyle(qualityAdjustment == 0 ? Color.secondary : (qualityAdjustment > 0 ? Color.green : Color.red))
                    }
                    Divider()
                }

                if let estimatedEnergyExpenses = report.estimatedEnergyExpenses {
                    HStack {
                        Label("Énergie estimée", systemImage: "fuelpump")
                        Spacer()
                        Text(currency(estimatedEnergyExpenses))
                            .font(.subheadline.monospacedDigit().weight(.medium))
                    }
                    Divider()
                }
                if let machinistLaborExpenses = report.machinistLaborExpensesEuro {
                    HStack {
                        Label("Rémunération machinistes", systemImage: "person.2")
                        Spacer()
                        Text(currency(machinistLaborExpenses))
                            .font(.subheadline.monospacedDigit().weight(.medium))
                    }
                    Divider()
                }
                if let repairExpenses = report.repairExpenses {
                    HStack {
                        Label("Pannes et réparations", systemImage: "wrench.and.screwdriver")
                        Spacer()
                        Text(currency(repairExpenses))
                            .font(.subheadline.monospacedDigit().weight(.medium))
                    }
                    Divider()
                }
                if let preventiveMaintenanceExpenses = report.preventiveMaintenanceExpenses {
                    HStack {
                        Label("Entretien préventif", systemImage: "wrench.and.screwdriver")
                        Spacer()
                        Text(currency(preventiveMaintenanceExpenses))
                            .font(.subheadline.monospacedDigit().weight(.medium))
                    }
                    Divider()
                }
                HStack {
                    Label("Achats consignés", systemImage: "cart")
                    Spacer()
                    Text(currency(report.recordedPurchaseExpenses))
                        .font(.subheadline.monospacedDigit().weight(.medium))
                }
                if let vehicleSaleRevenue = report.recordedVehicleSaleRevenue {
                    Divider()
                    HStack {
                        Label("Reventes estimées", systemImage: "banknote")
                        Spacer()
                        Text(currency(vehicleSaleRevenue))
                            .font(.subheadline.monospacedDigit().weight(.medium))
                    }
                }

                if let closingCashBalance = report.closingCashBalance {
                    HStack {
                        Label("Trésorerie à la clôture", systemImage: "banknote")
                        Spacer()
                        Text(currency(closingCashBalance))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                    }
                }

                if let depotSummaries = report.depotSummaries, !depotSummaries.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Répartition par dépôt")
                            .font(.subheadline.weight(.semibold))
                        Text("Courses et distances suivent le dépôt du bus; les départs non assurés sont attribués par ligne. Les dépenses n’incluent que les écritures explicitement rattachées à un dépôt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(depotSummaries) { summary in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(DepotCareerScope.depotReference(for: summary.depotID)?.name ?? summary.depotID)
                                    .font(.caption.weight(.semibold))
                                HStack(spacing: 8) {
                                    Text("Assurés \(summary.servedDepartureCount.formatted())")
                                    Text("Non assurés \(summary.missedDepartureCount.formatted())")
                                    Text("Terminées \(summary.completedTripCount.formatted())")
                                    Spacer(minLength: 4)
                                    Text("\((summary.tracedDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km")
                                    Text(currency(summary.recordedDepotExpensesEuro))
                                }
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            }
                            .padding(9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func metric(_ title: String, value: String, symbol: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func dateTitle(_ dateKey: Int) -> String {
        let year = dateKey / 10_000
        let month = (dateKey / 100) % 100
        let day = dateKey % 100
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

private struct MonthlyLedgerSummary: Identifiable {
    let monthKey: Int
    let entries: [SimulationLedgerEntry]
    let openingBalance: Int?
    let closingBalance: Int?

    var id: Int { monthKey }
    var income: Int {
        entries.reduce(into: 0) {
            if ($1.nature ?? .operating) == .operating, $1.amount > 0 { $0 += $1.amount }
        }
    }
    var expenses: Int {
        entries.reduce(into: 0) {
            if ($1.nature ?? .operating) == .operating, $1.amount < 0 { $0 -= $1.amount }
        }
    }
    var financingFlow: Int {
        entries.reduce(into: 0) {
            if $1.nature == .financing { $0 += $1.amount }
        }
    }
    var netChange: Int { entries.reduce(into: 0) { $0 += $1.cashMovementEuro } }
}

private struct LedgerCategoryTotal: Identifiable {
    let category: String
    let amount: Int

    var id: String { category }
}

private struct MonthlyFinancialReportView: View {
    @ObservedObject var simulation: SimulationEngine
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLoanPrincipalEuro = 100_000
    @State private var selectedLoanTermMonths = 36
    @State private var loanMessage: String?
    @State private var loanError: String?

    private var loans: [SimulationLoan] {
        simulation.session?.loans ?? []
    }

    private var invoices: [SimulationInvoice] {
        (simulation.session?.invoices ?? []).sorted {
            if $0.isPaid != $1.isPaid { return !$0.isPaid }
            if $0.dueAt != $1.dueAt { return $0.dueAt < $1.dueAt }
            return $0.id < $1.id
        }
    }

    private var outstandingDebtEuro: Int {
        loans.reduce(0) { $0 + $1.outstandingPrincipalEuro }
    }

    private var loanCapacityEuro: Int {
        max(0, SimulationLoanRules.maximumOutstandingPrincipalEuro - outstandingDebtEuro)
    }

    private var roundedLoanCapacityEuro: Int {
        loanCapacityEuro / SimulationLoanRules.principalIncrementEuro * SimulationLoanRules.principalIncrementEuro
    }

    private var loanPreview: SimulationLoan? {
        guard let simulatedAt = simulation.session?.simulatedAt,
              selectedLoanPrincipalEuro <= loanCapacityEuro else { return nil }
        return SimulationLoanRules.loan(
            id: "preview",
            principalEuro: selectedLoanPrincipalEuro,
            termMonths: selectedLoanTermMonths,
            issuedAt: simulatedAt
        )
    }

    private var monthlyReports: [MonthlyLedgerSummary] {
        guard let session = simulation.session else { return [] }
        let entries = (session.ledgerEntries ?? []).sorted { $0.occurredAt < $1.occurredAt }
        let datedEntries = entries.compactMap { entry -> (monthKey: Int, entry: SimulationLedgerEntry)? in
            guard let monthKey = Self.monthKey(for: entry.occurredAt) else { return nil }
            return (monthKey, entry)
        }
        let currentMonth = Self.monthKey(for: session.simulatedAt)
        let monthKeys = Set(datedEntries.map { $0.monthKey }).union(currentMonth.map { [$0] } ?? [])
        return monthKeys.sorted(by: >).map { monthKey in
            let monthlyEntries = datedEntries.filter { $0.monthKey == monthKey }.map(\.entry)
            let laterNet = datedEntries
                .filter { $0.monthKey > monthKey }
                .reduce(into: 0) { $0 += $1.entry.cashMovementEuro }
            let closingBalance = session.cashBalance.map { $0 - laterNet }
            let openingBalance = closingBalance.map { $0 - monthlyEntries.reduce(into: 0) { $0 += $1.cashMovementEuro } }
            return MonthlyLedgerSummary(
                monthKey: monthKey,
                entries: monthlyEntries.sorted { $0.occurredAt > $1.occurredAt },
                openingBalance: openingBalance,
                closingBalance: closingBalance
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let cashBalance = simulation.session?.cashBalance {
                        HStack {
                            Label("Trésorerie actuelle", systemImage: "banknote")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(currency(cashBalance))
                                .font(.title3.monospacedDigit().weight(.bold))
                        }
                        .padding(15)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                    }

                    Text("Le résultat mensuel suit les recettes et charges à leur date d’acquisition; la variation de trésorerie suit les encaissements et paiements. Les montants de service, d’énergie, de réparation et de paie restent des estimations de jeu.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    gameFinancingPanel
                    invoicePanel

                    if monthlyReports.allSatisfy({ $0.entries.isEmpty }) {
                        ContentUnavailableView(
                            "Aucune écriture financière",
                            systemImage: "eurosign.square",
                            description: Text("Les achats, services, coûts d’énergie, réparations et rémunérations apparaîtront ici après leur enregistrement au journal.")
                        )
                    } else {
                        ForEach(monthlyReports) { report in
                            monthCard(report)
                        }
                    }

                    Text("Les soldes mensuels sont reconstitués depuis les mouvements de trésorerie du journal. Les factures de prestation et d’énergie sont émises à la clôture quotidienne puis réglées 30 jours calendaires après, selon une règle de jeu. Le capital emprunté, son remboursement et les intérêts restent des flux de financement distincts. Ces délais, taux et montants ne décrivent pas les conditions réelles de la DSP 45 ou d’un fournisseur.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(13)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
                }
                .padding(22)
                .frame(maxWidth: 900, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Finances mensuelles")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private var invoicePanel: some View {
        GroupBox("Factures · règle de jeu") {
            VStack(alignment: .leading, spacing: 10) {
                Text("La prestation contractuelle et l’énergie sont acquises pendant l’exploitation. Elles sont regroupées à minuit et réglées automatiquement 30 jours calendaires après l’émission.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                let openInvoices = invoices.filter { !$0.isPaid }
                let paidInvoices = invoices.filter(\.isPaid)
                if invoices.isEmpty {
                    ContentUnavailableView(
                        "Aucune facture émise",
                        systemImage: "doc.text",
                        description: Text("Les premières factures apparaîtront à la clôture d’une journée avec une recette contractuelle ou des coûts d’énergie.")
                    )
                    .frame(minHeight: 100)
                } else {
                    if !openInvoices.isEmpty {
                        Label("À encaisser ou à régler", systemImage: "clock")
                            .font(.subheadline.weight(.semibold))
                        ForEach(openInvoices) { invoice in
                            invoiceRow(invoice)
                        }
                    }
                    if !paidInvoices.isEmpty {
                        if !openInvoices.isEmpty { Divider() }
                        Label("Réglées", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.semibold))
                        ForEach(paidInvoices) { invoice in
                            invoiceRow(invoice)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func invoiceRow(_ invoice: SimulationInvoice) -> some View {
        let isReceivable = invoice.direction == .receivable
        let status = invoice.isPaid
            ? (isReceivable ? "Encaissée" : "Payée")
            : (isReceivable ? "À encaisser" : "À régler")
        let statusDate = invoice.paidAt ?? invoice.dueAt
        let datePhrase = invoice.isPaid ? "le" : "avant le"

        return VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: invoice.isPaid ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundStyle(invoice.isPaid ? Color.green : Color.orange)
                    .accessibilityLabel(status)
                VStack(alignment: .leading, spacing: 3) {
                    Text(invoice.title)
                        .font(.subheadline.weight(.semibold))
                    Text(invoice.counterparty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Émise le \(invoice.issuedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(status) \(datePhrase) \(statusDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(invoice.isPaid ? Color.green : Color.orange)
                }
                Spacer(minLength: 10)
                Text(currency(invoice.totalEuro))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
            }

            DisclosureGroup("Détail · \(invoice.lineItems.count) poste(s)") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(invoice.lineItems) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Text(line.category)
                                .font(.caption)
                            Spacer(minLength: 8)
                            Text(signedCurrency(line.amountEuro))
                                .font(.caption.monospacedDigit())
                        }
                    }
                }
                .padding(.top, 6)
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
    }

    private var gameFinancingPanel: some View {
        GroupBox("Financement de la flotte · règle de jeu") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Capital emprunté", systemImage: "banknote")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if roundedLoanCapacityEuro >= SimulationLoanRules.minimumPrincipalEuro {
                        Stepper(
                            value: $selectedLoanPrincipalEuro,
                            in: SimulationLoanRules.minimumPrincipalEuro...roundedLoanCapacityEuro,
                            step: SimulationLoanRules.principalIncrementEuro
                        ) {
                            Text(currency(selectedLoanPrincipalEuro))
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .frame(minWidth: 104, alignment: .trailing)
                        }
                        .fixedSize()
                    } else {
                        Text("Plafond atteint")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Durée")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Durée", selection: $selectedLoanTermMonths) {
                        ForEach(SimulationLoanRules.termOptionsMonths, id: \.self) { months in
                            Text("\(months) mois").tag(months)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 125)
                }

                if let loanPreview,
                   let firstInstallment = loanPreview.installments.first {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Échéance mensuelle estimée")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currency(firstInstallment.totalEuro))
                                .font(.title3.monospacedDigit().weight(.bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Intérêts totaux")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currency(loanPreview.totalInterestEuro))
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                        }
                    }

                    Button {
                        do {
                            let loan = try simulation.takeGameLoan(
                                principalEuro: selectedLoanPrincipalEuro,
                                termMonths: selectedLoanTermMonths
                            )
                            loanMessage = "\(currency(loan.principalEuro)) versés à la trésorerie. Première échéance le \(loan.installments[0].dueAt.formatted(date: .abbreviated, time: .shortened))."
                            loanError = nil
                            let nextCapacity = max(0, roundedLoanCapacityEuro - loan.principalEuro)
                            if nextCapacity >= SimulationLoanRules.minimumPrincipalEuro {
                                selectedLoanPrincipalEuro = min(selectedLoanPrincipalEuro, nextCapacity)
                            }
                        } catch {
                            loanError = error.localizedDescription
                            loanMessage = nil
                        }
                    } label: {
                        Label("Recevoir le crédit", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("Taux fixe : 6 % nominal annuel · plafond de dette : 500 000 € · capital versé maintenant, puis remboursé par échéances mensuelles automatiques. Une trésorerie insuffisante peut devenir négative. Ces paramètres sont des choix d’équilibrage du jeu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let loanError {
                    Label(loanError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let loanMessage {
                    Label(loanMessage, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                Text("CRÉDITS EN COURS · dette restante \(currency(outstandingDebtEuro))")
                    .font(.caption.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)

                if loans.isEmpty {
                    Text("Aucun crédit dans cette carrière.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(loans) { loan in
                        loanRow(loan)
                    }
                }
            }
            .padding(.vertical, 3)
        }
    }

    private func loanRow(_ loan: SimulationLoan) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(currency(loan.principalEuro)) · \(loan.termMonths) mois · \(loan.annualInterestRateBasisPoints / 100) %")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Solde \(currency(loan.outstandingPrincipalEuro))")
                    .font(.subheadline.monospacedDigit())
            }
            HStack {
                Text("\(loan.paidInstallmentCount)/\(loan.termMonths) échéances payées · intérêts prévus \(currency(loan.totalInterestEuro))")
                Spacer()
                if let installment = loan.nextInstallment {
                    Text("Prochaine : \(installment.dueAt.formatted(date: .abbreviated, time: .shortened)) · \(currency(installment.totalEuro))")
                } else {
                    Text("Remboursé")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            ProgressView(value: Double(loan.paidInstallmentCount), total: Double(max(1, loan.termMonths)))
                .tint(.accentColor)
        }
        .padding(.vertical, 5)
    }

    private func monthCard(_ report: MonthlyLedgerSummary) -> some View {
        GroupBox(monthTitle(report.monthKey)) {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 0) {
                    financeMetric("Recettes d’exploitation", amount: report.income, symbol: "arrow.down.left", color: .green)
                    Divider().frame(height: 48)
                    financeMetric("Charges d’exploitation", amount: report.expenses, symbol: "arrow.up.right", color: .orange)
                    Divider().frame(height: 48)
                    financeMetric("Financement net", amount: report.financingFlow, symbol: "building.columns", color: report.financingFlow >= 0 ? .blue : .orange)
                    Divider().frame(height: 48)
                    financeMetric("Variation de trésorerie", amount: report.netChange, symbol: "equal", color: report.netChange >= 0 ? .green : .red)
                }

                Divider()
                balanceRow("Solde d’ouverture", amount: report.openingBalance)
                balanceRow("Solde de clôture", amount: report.closingBalance)

                if !report.entries.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 7) {
                        Text("MONTANTS PAR CATÉGORIE · ACQUIS + RÉGLÉ")
                            .font(.caption.weight(.bold))
                            .tracking(0.6)
                            .foregroundStyle(.secondary)
                        ForEach(categoryTotals(report.entries)) { total in
                            HStack {
                                Text(total.category)
                                    .font(.subheadline)
                                Spacer()
                                Text(signedCurrency(total.amount))
                                    .font(.subheadline.monospacedDigit().weight(.medium))
                                    .foregroundStyle(total.amount >= 0 ? Color.green : Color.orange)
                            }
                        }
                    }

                    DisclosureGroup("Écritures · \(report.entries.count)") {
                        VStack(alignment: .leading, spacing: 9) {
                            ForEach(report.entries) { entry in
                                let depotLabel = entry.depotID.map { DepotCareerScope.depotReference(for: $0)?.name ?? $0 }
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.description)
                                            .font(.subheadline)
                                        Text("\(entry.category) · \(entry.occurredAt.formatted(date: .abbreviated, time: .shortened))\(depotLabel.map { " · \($0)" } ?? "")")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    Text(ledgerAmountText(entry))
                                        .font(.subheadline.monospacedDigit().weight(.medium))
                                        .foregroundStyle(ledgerAmountColor(entry))
                                }
                                if entry.id != report.entries.last?.id { Divider() }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.top, 4)
                } else {
                    Text("Aucune écriture ce mois-ci.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func categoryTotals(_ entries: [SimulationLedgerEntry]) -> [LedgerCategoryTotal] {
        Dictionary(grouping: entries, by: \.category)
            .map { category, entries in
                LedgerCategoryTotal(category: category, amount: entries.reduce(into: 0) {
                    $0 += $1.nature == .settlement ? $1.cashMovementEuro : $1.amount
                })
            }
            .sorted { abs($0.amount) > abs($1.amount) }
    }

    private func ledgerAmountText(_ entry: SimulationLedgerEntry) -> String {
        if entry.nature == .settlement {
            return "Trésorerie \(signedCurrency(entry.cashMovementEuro))"
        }
        guard entry.cashMovementEuro != entry.amount else { return signedCurrency(entry.amount) }
        return "\(signedCurrency(entry.amount)) acquis · trésorerie \(signedCurrency(entry.cashMovementEuro))"
    }

    private func ledgerAmountColor(_ entry: SimulationLedgerEntry) -> Color {
        let amount = entry.nature == .settlement ? entry.cashMovementEuro : entry.amount
        return amount >= 0 ? .green : .orange
    }

    private func financeMetric(_ title: String, amount: Int, symbol: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .foregroundStyle(color)
        Text(title.hasPrefix("Charges") ? currency(amount) : signedCurrency(amount))
                .font(.title3.monospacedDigit().weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func balanceRow(_ title: String, amount: Int?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            if let amount {
                Text(currency(amount))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            } else {
                Text("Indisponible")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.subheadline)
    }

    private func monthTitle(_ monthKey: Int) -> String {
        String(format: "%04d-%02d", monthKey / 100, monthKey % 100)
    }

    private static func monthKey(for date: Date) -> Int? {
        GTFSServiceDate.key(for: date, timeZone: GTFSServiceDate.parisTimeZone).map { $0 / 100 }
    }

    private func signedCurrency(_ amount: Int) -> String {
        let sign = amount > 0 ? "+" : (amount < 0 ? "−" : "")
        return sign + currency(abs(amount))
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

private struct MachinistPayrollEmployeeSummary: Identifiable {
    let machinistID: String
    let name: String
    let entries: [MachinistPayrollRecord]

    var id: String { machinistID }
    var totalHours: Double { entries.reduce(into: 0) { $0 += $1.workHours } }
    var totalAmount: Int { entries.reduce(into: 0) { $0 += $1.amountEuro } }

    func hours(for kind: MachinistPayrollKind) -> Double {
        entries.filter { $0.kind == kind }.reduce(into: 0) { $0 += $1.workHours }
    }

    func amount(for kind: MachinistPayrollKind) -> Int {
        entries.filter { $0.kind == kind }.reduce(into: 0) { $0 += $1.amountEuro }
    }
}

private struct MachinistPayrollMonthSummary: Identifiable {
    let monthKey: Int
    let employees: [MachinistPayrollEmployeeSummary]

    var id: Int { monthKey }
    var totalHours: Double { employees.reduce(into: 0) { $0 += $1.totalHours } }
    var totalAmount: Int { employees.reduce(into: 0) { $0 += $1.totalAmount } }
}

private struct MonthlyMachinistPayrollView: View {
    @ObservedObject var simulation: SimulationEngine
    var showsCloseButton = true
    @Environment(\.dismiss) private var dismiss

    private var monthlyReports: [MachinistPayrollMonthSummary] {
        guard let session = simulation.session else { return [] }
        let machinistNames = Dictionary(uniqueKeysWithValues: (session.machinists ?? []).map { ($0.id, $0.displayName) })
        let recordsByMonth = Dictionary(grouping: session.machinistPayrollRecords ?? []) { record in
            Self.monthKey(for: record.occurredAt) ?? 0
        }
        return recordsByMonth
            .filter { $0.key > 0 }
            .map { monthKey, records in
                let employees = Dictionary(grouping: records, by: \.machinistID)
                    .map { machinistID, entries in
                        MachinistPayrollEmployeeSummary(
                            machinistID: machinistID,
                            name: machinistNames[machinistID] ?? "Machiniste archivé",
                            entries: entries.sorted { $0.occurredAt > $1.occurredAt }
                        )
                    }
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                return MachinistPayrollMonthSummary(monthKey: monthKey, employees: employees)
            }
            .sorted { $0.monthKey > $1.monthKey }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Récapitulatif des rémunérations estimées enregistrées à la fin des services, formations et absences. Les heures et montants suivent les règles de jeu de la carrière.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if monthlyReports.isEmpty {
                        ContentUnavailableView(
                            "Aucune rémunération enregistrée",
                            systemImage: "person.text.rectangle",
                            description: Text("Les montants apparaîtront à la clôture d’un service, d’une formation ou d’une absence planifiée.")
                        )
                    } else {
                        ForEach(monthlyReports) { report in
                            monthCard(report)
                        }
                    }

                    Text("La paie reste une estimation de jeu : elle n’applique ni règles légales, ni convention, ni cotisations détaillées. Les écritures des anciennes sauvegardes restent visibles dans les finances mensuelles, sans ventilation rétroactive par machiniste.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(13)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
                }
                .padding(22)
                .frame(maxWidth: 900, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Paie mensuelle")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private func monthCard(_ report: MachinistPayrollMonthSummary) -> some View {
        GroupBox(String(format: "%04d-%02d", report.monthKey / 100, report.monthKey % 100)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(report.totalHours.formatted(.number.precision(.fractionLength(1)))) h enregistrées", systemImage: "clock")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(currency(report.totalAmount))
                        .font(.title3.monospacedDigit().weight(.bold))
                }

                ForEach(report.employees) { employee in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(employee.name)
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(currency(employee.totalAmount))
                                    .font(.subheadline.monospacedDigit().weight(.semibold))
                                Text("\(employee.totalHours.formatted(.number.precision(.fractionLength(1)))) h")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 6) {
                            ForEach(MachinistPayrollKind.allCases) { kind in
                                HStack(spacing: 5) {
                                    Text(kind.title)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                    Spacer(minLength: 2)
                                    Text("\(employee.hours(for: kind).formatted(.number.precision(.fractionLength(1)))) h · \(currency(employee.amount(for: kind)))")
                                        .monospacedDigit()
                                }
                                .font(.caption)
                            }
                        }

                        DisclosureGroup("Détail · \(employee.entries.count) événement(s)") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(employee.entries) { entry in
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.kind.title)
                                                .font(.subheadline.weight(.medium))
                                            Text("\(entry.details) · \(entry.occurredAt.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 8)
                                        Text(currency(entry.amountEuro))
                                            .font(.subheadline.monospacedDigit().weight(.medium))
                                    }
                                    if entry.id != employee.entries.last?.id { Divider() }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 4)
                    if employee.id != report.employees.last?.id { Divider() }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private static func monthKey(for date: Date) -> Int? {
        GTFSServiceDate.key(for: date, timeZone: GTFSServiceDate.parisTimeZone).map { $0 / 100 }
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

private struct IncidentHistoryView: View {
    @ObservedObject var simulation: SimulationEngine
    var showsCloseButton = true
    let onPreparePRIMDetour: (PRIMTrafficAlert) -> Void
    let onDismissPRIMAlert: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private var incidents: [VehicleIncident] {
        (simulation.session?.vehicleIncidents ?? []).sorted { $0.occurredAt > $1.occurredAt }
    }

    private var primTrafficAlerts: [PRIMTrafficAlert] {
        (simulation.session?.primTrafficAlerts ?? []).sorted { $0.lastSeenAt > $1.lastSeenAt }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Alertes trafic PRIM") {
                    if primTrafficAlerts.isEmpty {
                        Text("Aucune alerte trafic consultée pour les lignes exploitées.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(primTrafficAlerts) { alert in
                            primTrafficAlertRow(alert)
                        }
                    }
                }
                Section("Pannes de véhicules") {
                    if incidents.isEmpty {
                        ContentUnavailableView(
                            "Aucune panne simulée",
                            systemImage: "wrench.and.screwdriver",
                            description: Text("Les pannes dépendent de l’âge, du kilométrage, de l’état du bus, du tracé et de la graine sauvegardée.")
                        )
                    } else {
                        ForEach(incidents) { incident in
                            incidentRow(incident)
                        }
                    }
                }
            }
            .navigationTitle("Incidents d’exploitation")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private func primTrafficAlertRow(_ alert: PRIMTrafficAlert) -> some View {
        let report = alert.observation.report
        let simulatedAt = simulation.session?.simulatedAt ?? alert.lastSeenAt
        let isExpired = alert.isExpired(at: simulatedAt)
        let statusSymbol: String = switch alert.disposition {
        case .needsReview: "bell.badge.fill"
        case .detourPlanned: "arrow.triangle.branch"
        case .dismissed: "xmark.circle"
        }

        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(alert.disposition.title, systemImage: statusSymbol)
                    .font(.headline)
                    .foregroundStyle(alert.disposition == .needsReview ? Color.orange : Color.secondary)
                Spacer()
                Text("Ligne \(alert.routeID)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(report.title)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(report.message)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            if let severity = report.severity, !severity.isEmpty {
                Text(severity.capitalized + (report.cause.map { " · \($0)" } ?? ""))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.orange)
            }

            Text("IDFM · \(alert.observation.idfmLineID) · première consultation \(alert.firstSeenAt.formatted(date: .abbreviated, time: .shortened)) · dernière \(alert.lastSeenAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if report.applicationStart == nil && report.applicationEnd == nil {
                Text("Période d’application non précisée · validité non évaluée.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                let start = report.applicationStart?.formatted(date: .abbreviated, time: .shortened) ?? "début non précisé"
                let end = report.applicationEnd?.formatted(date: .abbreviated, time: .shortened) ?? "fin non précisée"
                Text("Période d’application · \(start) – \(end)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if isExpired, let applicationEnd = report.applicationEnd {
                Label("Rapport expiré le \(applicationEnd.formatted(date: .abbreviated, time: .shortened)) · déviation indisponible.", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let updatedAt = report.updatedAt {
                Text("Mise à jour IDFM · \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 5) {
                Text(alert.observation.license)
                Text("·")
                Link("Source PRIM", destination: alert.observation.sourceURL)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if alert.disposition == .detourPlanned, let detourID = alert.plannedDetourID {
                Text("Déviation de jeu enregistrée · \(detourID)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if alert.disposition == .needsReview {
                HStack(spacing: 8) {
                    if !isExpired {
                        Button {
                            onPreparePRIMDetour(alert)
                        } label: {
                            Label("Préparer une déviation", systemImage: "arrow.triangle.branch")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Button("Ignorer") {
                        onDismissPRIMAlert(alert.id)
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 5)
    }

    private func incidentRow(_ incident: VehicleIncident) -> some View {
        let isAwaitingResponse = simulation.session?.incidentAwaitingRepairResponse?.id == incident.id
        let hasScheduledRepair = simulation.session?.pendingEvents.contains(where: { event in
            guard case let .vehicleRepairCompleted(incidentID) = event.kind else { return false }
            return incidentID == incident.id
        }) ?? false
        let simulatedAt = simulation.session?.simulatedAt ?? incident.occurredAt
        let session = simulation.session
        let incidentMachinistID = incident.machinistID ?? session?.machinistServiceAssignments?.last(where: {
            $0.vehicleID == incident.vehicleID && $0.tripID == incident.tripID
        })?.machinistID
        let incidentMachinist = session?.machinists?.first(where: { $0.id == incidentMachinistID })
        let waitingEndAt: Date = {
            if incident.repairResponse == nil { return simulatedAt }
            if incident.repairResponse == .towToDepot {
                if let teamArrivedAt = incident.recoveryTeamArrivedAt { return teamArrivedAt }
                if let expectedTeamArrival = incident.towPlan?.expectedRecoveryTeamArrivalAt {
                    return min(simulatedAt, expectedTeamArrival)
                }
                if let legacyTowArrival = incident.towArrivedAt { return legacyTowArrival }
                let legacyExpectedArrival = incident.occurredAt.addingTimeInterval(incident.towPlan?.expectedTravelSeconds ?? 0)
                return min(simulatedAt, legacyExpectedArrival)
            }
            return incident.resolvedAt ?? min(simulatedAt, incident.repairCompletedAt)
        }()
        let incidentWaitingHours = max(0, waitingEndAt.timeIntervalSince(incident.occurredAt)) / 3_600
        let incidentWaitingCost = incidentMachinist.map {
            Int((incidentWaitingHours * Double($0.estimatedLoadedCostPerServiceHourEuro)).rounded())
        }
        let incidentWaitingCostText = incidentWaitingCost.map { currency($0) } ?? "indisponible"
        let incidentWaitingRateText = incidentMachinist.map {
            "\(currency($0.estimatedLoadedCostPerServiceHourEuro))/h"
        } ?? "taux indisponible"
        let machinistAssignmentEndedAtIncident = simulation.session?.machinistServiceAssignments?.last(where: {
            $0.vehicleID == incident.vehicleID && $0.tripID == incident.tripID
        })?.actualEndAt.map { abs($0.timeIntervalSince(incident.occurredAt)) < 1 } ?? false
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(incident.severity.title, systemImage: incident.isResolved ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(incident.isResolved ? Color.green : Color.red)
                Spacer()
                Text(incident.isResolved
                     ? "Réparé"
                     : (incident.repairResponse == .towToDepot
                        ? ((incident.depotArrivedAt ?? incident.towArrivedAt) != nil
                            ? ((incident.workshopStartedAt ?? simulatedAt) > simulatedAt ? "File d’atelier" : "En atelier")
                            : (incident.recoveryTeamArrivedAt != nil
                                ? ((incident.busTowStartedAt != nil || simulation.session?.ownedBuses?.first(where: { $0.id == incident.vehicleID })?.status == .beingTowed)
                                    ? "Bus en remorquage"
                                    : "Équipe sur place · attelage")
                                : ((incident.towPlan?.dispatchStartsAt ?? simulatedAt) > simulatedAt ? "Équipe en attente" : "Équipe en route")))
                        : "Immobilisé"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(incident.isResolved ? Color.green : (incident.repairResponse == .towToDepot ? Color.blue : Color.red))
            }

            Text("\(incident.vehicleModelName) · ligne \(incident.routeID) · course \(incident.tripID)")
                .font(.subheadline.weight(.medium))
            Text("\(incident.stopName) · arrêt \(incident.stopID) · \(incident.occurredAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
            if incident.requiresDiagnosis {
                if let finding = incident.diagnosticFinding,
                   let diagnosisCompletedAt = incident.diagnosisCompletedAt {
                    Text("Diagnostic de jeu · \(finding.title) · terminé \(diagnosisCompletedAt.formatted(date: .omitted, time: .shortened)) · orientation : \(finding.recommendedResponse(for: incident.severity).title)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let expectedAt = incident.diagnosisExpectedCompletionAt {
                    Text("Diagnostic de jeu en cours · résultat prévu \(expectedAt.formatted(date: .omitted, time: .shortened)) · reste simulé \(durationText(from: simulatedAt, to: expectedAt))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Diagnostic de jeu requis avant intervention · 15 min simulées et 180 €")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if machinistAssignmentEndedAtIncident {
                Text("Affectation machiniste clôturée à l’incident · le temps de réparation n’est pas compté comme service.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text("Attente machiniste · \(durationText(from: incident.occurredAt, to: waitingEndAt)) · taux \(incidentWaitingRateText) · coût estimé \(incidentWaitingCostText) (règle de jeu)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(incident.displacedPassengerCount) voyageurs remis en attente", systemImage: "person.2")
                Spacer()
                Text(isAwaitingResponse ? "Intervention à choisir" : "Intervention · \(currency(incident.repairCostEuro))")
                    .font(.caption.monospacedDigit().weight(.medium))
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let replacementVehicleID = incident.replacementVehicleID {
                let replacementModel = incident.replacementVehicleModelName ?? "Bus de réserve"
                let replacementDelay = max(0, incident.replacementDelaySeconds ?? 0)
                Text("Reprise affectée · \(replacementModel) · bus \(replacementVehicleID) · retard estimé \(durationText(from: incident.occurredAt, to: incident.occurredAt.addingTimeInterval(replacementDelay)))")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }

            if isAwaitingResponse {
                Text("Intervention à choisir. La carrière continue pendant que ce véhicule attend un dépannage.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            } else {
                let currentTime = simulatedAt
                let endTime = incident.resolvedAt ?? min(currentTime, incident.repairCompletedAt)
                Text(interventionStatusText(for: incident, currentTime: currentTime, endTime: endTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let response = incident.repairResponse {
                    Text(response.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let towPlan = incident.towPlan {
                        let dispatchDistance = ((towPlan.dispatchRouteDistanceMeters ?? 0) / 1_000)
                            .formatted(.number.precision(.fractionLength(1)))
                        let towDistance = (towPlan.routeDistanceMeters / 1_000)
                            .formatted(.number.precision(.fractionLength(1)))
                        let teamETA = towPlan.expectedRecoveryTeamArrivalAt
                            ?? incident.occurredAt.addingTimeInterval(towPlan.expectedTravelSeconds)
                        let depotETA = towPlan.expectedDepotArrivalAt
                            ?? incident.occurredAt.addingTimeInterval(towPlan.expectedTravelSeconds)
                        Text("\(towPlan.recoveryTeamName ?? "Équipe de dépannage") · départ \((towPlan.dispatchStartsAt ?? incident.occurredAt).formatted(date: .omitted, time: .shortened)) · arrivée à la panne \(teamETA.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Équipe jusqu’à la panne : \(dispatchDistance) km · bus jusqu’au dépôt : \(towDistance) km · arrivée dépôt \(depotETA.formatted(date: .omitted, time: .shortened)) · \(towPlan.routingSourceTitle)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if hasScheduledRepair {
                    Text("Réparation programmée dans une sauvegarde antérieure")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
    }

    private func durationText(from start: Date, to end: Date) -> String {
        let minutes = max(0, Int(end.timeIntervalSince(start) / 60))
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours) h \(remainingMinutes) min"
    }

    private func interventionStatusText(for incident: VehicleIncident, currentTime: Date, endTime: Date) -> String {
        if incident.isResolved {
            return "Immobilisation : \(durationText(from: incident.occurredAt, to: endTime))"
        }
        if let towPlan = incident.towPlan,
           incident.recoveryTeamArrivedAt == nil,
           incident.depotArrivedAt == nil,
           incident.towArrivedAt == nil {
            let expectedTeamArrival = towPlan.expectedRecoveryTeamArrivalAt
                ?? incident.occurredAt.addingTimeInterval(towPlan.expectedTravelSeconds)
            let departure = towPlan.dispatchStartsAt ?? incident.occurredAt
            let state = departure > currentTime ? "Équipe en attente" : "Équipe en route"
            return "\(state) · départ \(departure.formatted(date: .omitted, time: .shortened)) · arrivée à la panne prévue \(expectedTeamArrival.formatted(date: .omitted, time: .shortened))"
        }
        if let towPlan = incident.towPlan,
           let recoveryTeamArrivedAt = incident.recoveryTeamArrivedAt,
           incident.depotArrivedAt == nil,
           incident.towArrivedAt == nil {
            let busTowStarted = incident.busTowStartedAt != nil
                || simulation.session?.ownedBuses?.first(where: { $0.id == incident.vehicleID })?.status == .beingTowed
            if !busTowStarted {
                let expectedTowStart = towPlan.expectedBusTowStartAt
                    ?? recoveryTeamArrivedAt.addingTimeInterval(VehicleRecoveryRules.towHookupDuration)
                return "Équipe sur place · attelage jusqu’à \(expectedTowStart.formatted(date: .omitted, time: .shortened))"
            }
            guard let expectedDepotArrival = towPlan.expectedDepotArrivalAt else {
                return "Bus en remorquage vers \(towPlan.depotName)"
            }
            return "Bus remorqué vers \(towPlan.depotName) · arrivée prévue \(expectedDepotArrival.formatted(date: .omitted, time: .shortened))"
        }
        if let towArrivedAt = incident.depotArrivedAt ?? incident.towArrivedAt {
            if let workshopStartedAt = incident.workshopStartedAt, workshopStartedAt > currentTime {
                return "Arrivé à l’atelier \(towArrivedAt.formatted(date: .omitted, time: .shortened)) · baie prévue à \(workshopStartedAt.formatted(date: .omitted, time: .shortened)) · remise \(incident.repairCompletedAt.formatted(date: .omitted, time: .shortened))"
            }
            return "En atelier depuis \(towArrivedAt.formatted(date: .omitted, time: .shortened)) · remise prévue \(incident.repairCompletedAt.formatted(date: .omitted, time: .shortened))"
        }
        return "Immobilisé depuis \(durationText(from: incident.occurredAt, to: min(currentTime, incident.repairCompletedAt))) · remise prévue \(incident.repairCompletedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

private enum IncidentReplacementError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case let .unavailable(message): message
        }
    }
}

private struct IncidentResponseView: View {
    @ObservedObject var simulation: SimulationEngine
    @ObservedObject var library: NetworkLibrary
    let initialIncident: VehicleIncident
    let depots: [DepotReference]
    let onIncidentUpdated: (VehicleIncident) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var towPlan: VehicleTowPlan?
    @State private var towRouteError: String?
    @State private var isCalculatingTowRoute = false
    @State private var sourceReplacementStopVisits: [ScheduledTripStopVisit] = []
    @State private var replacementStopVisits: [ScheduledTripStopVisit] = []
    @State private var replacementDeadheadPlan: VehicleDeadheadPlan?
    @State private var selectedReplacementBusID: String?
    @State private var selectedReplacementMachinistID: String?
    @State private var replacementScheduleError: String?
    @State private var replacementRouteError: String?
    @State private var isLoadingReplacementSchedule = false
    @State private var isCalculatingReplacementRoute = false
    @State private var isDispatchingReplacement = false

    private var incident: VehicleIncident {
        simulation.session?.vehicleIncidents?.first(where: { $0.id == initialIncident.id }) ?? initialIncident
    }

    private var cashBalance: Int? { simulation.session?.cashBalance }
    private var diagnosisIsComplete: Bool {
        !incident.requiresDiagnosis || incident.diagnosisCompletedAt != nil
    }
    private var incidentRoutingTaskID: String {
        "\(incident.id)|\(incident.diagnosisCompletedAt?.timeIntervalSince1970 ?? -1)"
    }
    private var requiredRepairPart: VehicleWorkshopPart {
        VehicleWorkshopPart.repairKit(for: incident.severity)
    }
    private var requiredRepairModelID: String {
        simulation.session?.ownedBuses?.first(where: { $0.id == incident.vehicleID })?.modelID ?? ""
    }
    private var requiredRepairDepotID: String {
        simulation.session?.ownedBuses?.first(where: { $0.id == incident.vehicleID })?.depotID
            ?? simulation.session?.depotID
            ?? ""
    }
    private var requiredRepairModelName: String {
        VehicleMarketCatalog.model(id: requiredRepairModelID)?.displayName ?? "modèle inconnu"
    }
    private var repairPartPurchaseCost: Int {
        guard simulation.workshopPartQuantity(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID) == 0,
              simulation.availableWorkshopPartOrderQuantity(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID) == 0 else { return 0 }
        return requiredRepairPart.purchasePriceEuro
    }

    private var replacementCandidateBuses: [PurchasedBus] {
        guard let session = simulation.session else { return [] }
        return (session.ownedBuses ?? []).filter { bus in
            guard bus.id != incident.vehicleID,
                  bus.reservedTripKey == nil,
                  bus.currentTripID == nil,
                  bus.activeMovementLeg == nil else { return false }
            if bus.status == .atStop {
                return bus.currentStopID == incident.stopID
            }
            return bus.status == .atDepot && bus.depotID == session.effectiveActiveDepotID
        }
        .sorted {
            let leftAtIncident = $0.status == .atStop
            let rightAtIncident = $1.status == .atStop
            if leftAtIncident != rightAtIncident { return leftAtIncident }
            return $0.acquiredAt < $1.acquiredAt
        }
    }

    private var selectedReplacementBus: PurchasedBus? {
        replacementCandidateBuses.first { $0.id == selectedReplacementBusID }
    }

    private var eligibleReplacementMachinists: [Machinist] {
        guard let bus = selectedReplacementBus,
              let firstStop = replacementStopVisits.first,
              let lastStop = replacementStopVisits.last else { return [] }
        let serviceStartAt = replacementDeadheadPlan.map {
            firstStop.scheduledAt.addingTimeInterval(-$0.expectedTravelSeconds)
        } ?? firstStop.scheduledAt
        return simulation.availableMachinists(
            forVehicleID: bus.id,
            serviceStartAt: serviceStartAt,
            serviceEndAt: lastStop.scheduledAt
        )
    }

    private var replacementDelay: TimeInterval {
        max(0, (replacementStopVisits.first?.scheduledAt ?? incident.occurredAt).timeIntervalSince(incident.occurredAt))
    }

    private var canDispatchReplacement: Bool {
        diagnosisIsComplete
            && incident.replacementVehicleID == nil
            && selectedReplacementBus != nil
            && selectedReplacementMachinistID != nil
            && replacementStopVisits.count >= 2
            && !isLoadingReplacementSchedule
            && !isCalculatingReplacementRoute
            && !isDispatchingReplacement
    }

    @ViewBuilder
    private var replacementDispatchContent: some View {
        if let replacementVehicleID = incident.replacementVehicleID {
            let modelName = incident.replacementVehicleModelName ?? "Bus de réserve"
            let delay = max(0, incident.replacementDelaySeconds ?? 0)
            VStack(alignment: .leading, spacing: 8) {
                Label("Suite de course affectée", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                incidentDetail("Bus de réserve", value: "\(modelName) · \(replacementVehicleID)")
                if let machinistID = incident.replacementMachinistID,
                   let machinist = simulation.session?.machinists?.first(where: { $0.id == machinistID }) {
                    incidentDetail("Machiniste", value: machinist.displayName)
                }
                if let startsAt = incident.replacementServiceStartsAt {
                    incidentDetail("Départ de reprise", value: startsAt.formatted(date: .abbreviated, time: .shortened))
                }
                incidentDetail("Retard estimé", value: durationText(delay))
                Text("Le retard et l’itinéraire sont des estimations de jeu. Le bus immobilisé reste en attente du dépannage choisi.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else if isLoadingReplacementSchedule {
            ProgressView("Chargement des arrêts GTFS restants…")
                .font(.callout)
        } else if let replacementScheduleError {
            Text(replacementScheduleError)
                .font(.callout)
                .foregroundStyle(.secondary)
        } else if incident.stopSequence == nil || sourceReplacementStopVisits.count < 2 {
            Text("Cette sauvegarde ne contient pas la séquence GTFS restante de la panne. Un bus de réserve ne peut pas reprendre la course automatiquement.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else if replacementCandidateBuses.isEmpty {
            Text("Aucun bus libre n’est à l’arrêt de la panne ou au dépôt actif. Les bus en course, affectés ou en atelier ne peuvent pas être mobilisés.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else if let bus = selectedReplacementBus {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Bus de réserve", selection: $selectedReplacementBusID) {
                    ForEach(replacementCandidateBuses) { candidate in
                        Text(replacementBusTitle(candidate)).tag(Optional(candidate.id))
                    }
                }

                if bus.status == .atDepot {
                    if isCalculatingReplacementRoute {
                        ProgressView("Calcul de l’acheminement MapKit…")
                            .font(.callout)
                    } else if let replacementDeadheadPlan {
                        incidentDetail("Acheminement à vide", value: "\((replacementDeadheadPlan.routeDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km · ETA \(durationText(replacementDeadheadPlan.expectedTravelSeconds))")
                        Text(replacementDeadheadPlan.routingSourceTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if let replacementRouteError {
                        Text("Acheminement indisponible : \(replacementRouteError)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } else {
                    incidentDetail("Position", value: "Déjà à \(incident.stopName)")
                }

                if !replacementStopVisits.isEmpty {
                    incidentDetail("Arrivée au point de reprise", value: replacementStopVisits[0].scheduledAt.formatted(date: .abbreviated, time: .shortened))
                    incidentDetail("Retard estimé", value: durationText(replacementDelay))
                    incidentDetail("Arrêts restants", value: "\(replacementStopVisits.count)")
                }

                if eligibleReplacementMachinists.isEmpty {
                    Text("Aucun machiniste qualifié et disponible pour la durée restante de cette course.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Machiniste", selection: $selectedReplacementMachinistID) {
                        ForEach(eligibleReplacementMachinists) { machinist in
                            Text(machinist.displayName).tag(Optional(machinist.id))
                        }
                    }
                }

                Text("La suite reprend à l’arrêt de la panne. Les horaires restants sont décalés du même retard pour préserver les intervalles GTFS. Préparez l’affectation du bus de réserve pendant que l’exploitation continue.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button {
                    dispatchReplacement()
                } label: {
                    Label("Affecter la suite au bus de réserve", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canDispatchReplacement || (bus.status == .atDepot && replacementDeadheadPlan == nil))
            }
        } else {
            Text("Choisissez un bus disponible à l’arrêt de la panne ou au dépôt actif.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var diagnosticContent: some View {
        if let finding = incident.diagnosticFinding,
           incident.diagnosisCompletedAt != nil {
            VStack(alignment: .leading, spacing: 8) {
                Label("Résultat du scénario", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                incidentDetail("Orientation de jeu", value: finding.title)
                Text(finding.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                incidentDetail(
                    "Intervention suggérée",
                    value: finding.recommendedResponse(for: incident.severity).title
                )
                Text("Résultat fictif et reproductible pour le jeu ; ce n’est pas un diagnostic technique réel. Vous gardez le choix de l’intervention.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else if let startedAt = incident.diagnosisStartedAt {
            VStack(alignment: .leading, spacing: 8) {
                Label("Diagnostic de jeu en cours", systemImage: "stethoscope")
                    .font(.subheadline.weight(.semibold))
                incidentDetail("Commencé", value: startedAt.formatted(date: .abbreviated, time: .shortened))
                if let expectedAt = incident.diagnosisExpectedCompletionAt {
                    incidentDetail("Résultat prévu", value: expectedAt.formatted(date: .abbreviated, time: .shortened))
                    incidentDetail(
                        "Reste simulé",
                        value: durationText(max(0, expectedAt.timeIntervalSince(simulation.session?.simulatedAt ?? startedAt)))
                    )
                }
                Text("Le diagnostic se termine après 15 min simulées. Les événements indépendants continuent tant que la partie reste en marche.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Un diagnostic de jeu estime une famille de panne avant d’ouvrir les choix d’intervention.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button {
                    do {
                        let updatedIncident = try simulation.scheduleVehicleDiagnosis(incidentID: incident.id)
                        onIncidentUpdated(updatedIncident)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } label: {
                    HStack {
                        Label("Lancer le diagnostic", systemImage: "stethoscope")
                        Spacer()
                        Text(currency(VehicleIncidentDiagnosisRules.costEuro))
                            .font(.headline.monospacedDigit())
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .disabled((cashBalance ?? 0) < VehicleIncidentDiagnosisRules.costEuro)
                Text("Durée : 15 min simulées · coût : 180 € · règles de jeu. Les autres courses continuent si la partie reste en marche.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Label("Bus immobilisé", systemImage: "exclamationmark.triangle.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.red)

                    Text("La course a été interrompue à l’arrêt. Les voyageurs à bord ont rejoint la file d’attente. Effectuez le diagnostic de jeu, puis choisissez une intervention pour remettre le véhicule en service.")
                        .foregroundStyle(.secondary)

                    GroupBox("Incident") {
                        VStack(alignment: .leading, spacing: 8) {
                            incidentDetail("Panne", value: incident.severity.title)
                            incidentDetail("Véhicule", value: incident.vehicleModelName)
                            incidentDetail("Ligne et course", value: "\(incident.routeID) · \(incident.tripID)")
                            incidentDetail("Immobilisé à", value: "\(incident.stopName) · arrêt \(incident.stopID)")
                            incidentDetail("Voyageurs affectés", value: "\(incident.displacedPassengerCount)")
                        }
                    }

                    if incident.requiresDiagnosis {
                        GroupBox("Diagnostic de jeu") {
                            diagnosticContent
                        }
                    }

                    if diagnosisIsComplete {
                        GroupBox("Bus de réserve · continuité de course") {
                            replacementDispatchContent
                        }

                        GroupBox("Pièce de rechange") {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(requiredRepairPart.title)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(requiredRepairModelName) · stock : \(simulation.workshopPartQuantity(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID)) kit(s)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let deliveryAt = simulation.pendingWorkshopPartOrders(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID).first?.deliveryAt {
                                        Text("Livraison prévue \(deliveryAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    } else if let deliveryAt = simulation.workshopPartDeliveryEstimate(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID) {
                                        Text("Délai estimé de jeu : \(durationText(max(0, deliveryAt.timeIntervalSince(simulation.session?.simulatedAt ?? incident.occurredAt))))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if simulation.workshopPartQuantity(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID) == 0,
                                   simulation.availableWorkshopPartOrderQuantity(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID) == 0 {
                                    Button("Commander · \(currency(requiredRepairPart.purchasePriceEuro))") {
                                        restockRequiredRepairPart()
                                    }
                                    .disabled((cashBalance ?? 0) < requiredRepairPart.purchasePriceEuro)
                                }
                            }
                            Text("La réparation réserve un kit du stock ou d’une commande en cours. Sans kit, le choix de l’intervention commande automatiquement la pièce et retarde la remise en service jusqu’à sa livraison.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }

                        GroupBox("Dépannage sur place") {
                            VStack(alignment: .leading, spacing: 10) {
                                responseButton(.standardOnSite, subtitle: "Délai de jeu : \(durationText(VehicleRepairResponse.standardOnSite.duration(for: incident.severity)))")
                                responseButton(.priorityOnSite, subtitle: "Délai de jeu : \(durationText(VehicleRepairResponse.priorityOnSite.duration(for: incident.severity)))")
                            }
                        }

                        GroupBox("Remorquage vers le dépôt actif") {
                            VStack(alignment: .leading, spacing: 10) {
                                if let towPlan {
                                    incidentDetail("Équipe assignée", value: towPlan.recoveryTeamName ?? "Équipe simulée du dépôt")
                                    incidentDetail(
                                        "Départ de l’équipe",
                                        value: (towPlan.dispatchStartsAt ?? simulation.session?.simulatedAt ?? incident.occurredAt)
                                            .formatted(date: .abbreviated, time: .shortened)
                                    )
                                    incidentDetail("Dépôt retenu", value: towPlan.depotName)
                                    incidentDetail("Adresse résolue", value: towPlan.resolvedDepotAddress)
                                    incidentDetail(
                                        "Dépôt → panne",
                                        value: "\(((towPlan.dispatchRouteDistanceMeters ?? 0) / 1_000).formatted(.number.precision(.fractionLength(1)))) km · ETA \(durationText(towPlan.dispatchExpectedTravelSeconds ?? 0))"
                                    )
                                    incidentDetail("Prise en charge", value: "\(durationText(VehicleRecoveryRules.towHookupDuration)) · règle de jeu")
                                    incidentDetail(
                                        "Panne → dépôt",
                                        value: "\((towPlan.routeDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km · ETA \(durationText(towPlan.expectedTravelSeconds))"
                                    )
                                    if let expectedTeamArrival = towPlan.expectedRecoveryTeamArrivalAt {
                                        incidentDetail("Équipe sur place", value: expectedTeamArrival.formatted(date: .abbreviated, time: .shortened))
                                    }
                                    if let expectedDepotArrival = towPlan.expectedDepotArrivalAt {
                                        incidentDetail("Bus à l’atelier", value: expectedDepotArrival.formatted(date: .abbreviated, time: .shortened))
                                    }
                                    if let depot = depots.first(where: { $0.id == towPlan.depotID }) {
                                        Link(depot.addressSourceTitle, destination: depot.addressSourceURL)
                                            .font(.caption)
                                    }
                                    Text("Une seule équipe de récupération est simulée par dépôt. Elle est réservée jusqu’à l’arrivée du bus à l’atelier. Les trajets automobiles Apple Plans sont calculés à l’instant du choix et ne simulent pas la circulation future de la partie.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("Règle de jeu : 2 500 € d’intervention + 12 €/km parcouru par l’équipe (dépôt → panne → dépôt) + réparation selon la gravité.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    let workshopEstimate = simulation.workshopRepairEstimate(
                                        for: towPlan,
                                        severity: incident.severity,
                                        modelID: requiredRepairModelID
                                    )
                                    let waitingDuration = workshopEstimate.map { max(0, $0.startsAt.timeIntervalSince($0.arrivalAt)) } ?? 0
                                    if let workshopEstimate {
                                        incidentDetail("Baie disponible", value: workshopEstimate.startsAt.formatted(date: .abbreviated, time: .shortened))
                                        incidentDetail("Remise estimée", value: workshopEstimate.completesAt.formatted(date: .abbreviated, time: .shortened))
                                    }
                                    if let completionAt = simulation.session?.workshopExpansionCompletionDate(for: towPlan.depotID) {
                                        let bayCount = simulation.session?.effectiveWorkshopBayCount(for: towPlan.depotID) ?? VehicleWorkshopRules.initialRepairBayCount
                                        let bayUnit = bayCount == 1 ? "baie" : "baies"
                                        Text("Capacité actuelle : \(bayCount) \(bayUnit). La deuxième baie sera disponible le \(completionAt.formatted(date: .abbreviated, time: .shortened)).")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        let bayCount = simulation.session?.effectiveWorkshopBayCount(for: towPlan.depotID) ?? VehicleWorkshopRules.initialRepairBayCount
                                        Text("Capacité simulée de l’atelier du dépôt d’attache du bus : \(bayCount) \(bayCount == 1 ? "baie" : "baies") de réparation.")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    responseButton(
                                        .towToDepot,
                                        subtitle: "Équipe sur place \(towPlan.expectedRecoveryTeamArrivalAt?.formatted(date: .omitted, time: .shortened) ?? "à calculer") · prise en charge 15 min · bus à l’atelier \(towPlan.expectedDepotArrivalAt?.formatted(date: .omitted, time: .shortened) ?? "à calculer") · attente baie/pièce \(durationText(waitingDuration)) + réparation \(durationText(incident.severity.repairDuration))",
                                        towPlan: towPlan
                                    )
                                } else if isCalculatingTowRoute {
                                    ProgressView("Recherche d’un itinéraire vers les dépôts…")
                                        .font(.callout)
                                } else {
                                    Text("Remorquage indisponible : \(towRouteError ?? "aucun itinéraire routier n’a été calculé").")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                    Text("Les dépannages sur place restent disponibles.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Text("Les tarifs, durées et la capacité de l’atelier sont des règles de jeu. Le service MapKit et les adresses géocodées ne confirment pas la capacité réelle des ateliers.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Les choix d’intervention s’ouvriront après le diagnostic.", systemImage: "stethoscope")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Choisir un dépannage")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Plus tard") { dismiss() }
                }
            }
        }
        .task(id: incidentRoutingTaskID) {
            await calculateTowRoute()
        }
        .task(id: incidentRoutingTaskID) {
            await loadReplacementStopVisits()
        }
        .task(id: selectedReplacementBusID) {
            await prepareReplacementDispatch()
        }
        .onChange(of: eligibleReplacementMachinists.map(\.id)) { _, currentIDs in
            if let selectedReplacementMachinistID, currentIDs.contains(selectedReplacementMachinistID) { return }
            selectedReplacementMachinistID = currentIDs.first
        }
        .alert("Dépannage impossible", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Une erreur est survenue.")
        }
    }

    private func incidentDetail(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func responseButton(
        _ response: VehicleRepairResponse,
        subtitle: String,
        towPlan: VehicleTowPlan? = nil
    ) -> some View {
        let cost = response.cost(for: incident.severity, towDistanceMeters: towPlan?.totalServiceDistanceMeters ?? 0)
        let displayedCost = cost + repairPartPurchaseCost
        let deliveryDelay = simulation.workshopPartDeliveryEstimate(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID)
            .map { max(0, $0.timeIntervalSince(simulation.session?.simulatedAt ?? incident.occurredAt)) } ?? 0
        let effectiveSubtitle = simulation.workshopPartQuantity(for: requiredRepairPart, modelID: requiredRepairModelID, depotID: requiredRepairDepotID) == 0
            ? "\(subtitle) · pièce disponible dans \(durationText(deliveryDelay))"
            : subtitle
        return Button {
            do {
                try simulation.scheduleVehicleRepair(incidentID: incident.id, response: response, towPlan: towPlan)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(response.title).font(.headline)
                    Text(effectiveSubtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(displayedCost.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                        .font(.headline.monospacedDigit())
                    Text(balanceLabel)
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .disabled((cashBalance ?? 0) < displayedCost)
    }

    private func loadReplacementStopVisits() async {
        guard diagnosisIsComplete else {
            sourceReplacementStopVisits = []
            replacementStopVisits = []
            replacementDeadheadPlan = nil
            selectedReplacementBusID = nil
            return
        }
        guard let serviceDateKey = incident.serviceDateKey,
              let stopSequence = incident.stopSequence,
              let gtfsVersionID = simulation.session?.networkVersions.gtfsID else {
            replacementScheduleError = "La version GTFS ou la position de la panne manque dans cette sauvegarde."
            return
        }
        isLoadingReplacementSchedule = true
        defer { isLoadingReplacementSchedule = false }
        do {
            let visits = try await library.loadScheduledTripStopVisits(
                gtfsVersionID: gtfsVersionID,
                tripID: incident.tripID,
                serviceDateKey: serviceDateKey
            )
            let remainingVisits = visits.filter { $0.stopSequence >= stopSequence }
            guard remainingVisits.count >= 2,
                  remainingVisits.first?.stopID == incident.stopID else {
                replacementScheduleError = "Le GTFS épinglé ne contient pas assez d’arrêts après le point de panne."
                return
            }
            sourceReplacementStopVisits = remainingVisits
            replacementScheduleError = nil
            selectedReplacementBusID = incident.replacementVehicleID ?? replacementCandidateBuses.first?.id
        } catch is CancellationError {
            return
        } catch {
            replacementScheduleError = "Impossible de relire la course dans la version GTFS de la carrière : \(error.localizedDescription)"
        }
    }

    private func prepareReplacementDispatch() async {
        guard let bus = selectedReplacementBus,
              let firstVisit = sourceReplacementStopVisits.first,
              let activeSession = simulation.session else {
            replacementStopVisits = []
            replacementDeadheadPlan = nil
            return
        }
        isCalculatingReplacementRoute = true
        replacementRouteError = nil
        replacementDeadheadPlan = nil
        replacementStopVisits = []
        defer { isCalculatingReplacementRoute = false }

        do {
            let deadheadPlan: VehicleDeadheadPlan?
            let replacementStartAt: Date
            if bus.status == .atDepot {
                guard let depot = depots.first(where: { $0.id == bus.depotID }) else {
                    throw IncidentReplacementError.unavailable("Le dépôt actif de la carrière n’est pas renseigné.")
                }
                let plan = try await VehicleDeadheadRouter.routeForImmediateDispatch(
                    from: depot,
                    to: firstVisit,
                    earliestDepartureAt: activeSession.simulatedAt
                )
                deadheadPlan = plan
                replacementStartAt = activeSession.simulatedAt.addingTimeInterval(plan.expectedTravelSeconds)
            } else if bus.status == .atStop && bus.currentStopID == incident.stopID {
                deadheadPlan = nil
                replacementStartAt = activeSession.simulatedAt
            } else {
                throw IncidentReplacementError.unavailable("Le bus n’est plus à l’arrêt de panne ou au dépôt actif.")
            }

            let delay = max(0, replacementStartAt.timeIntervalSince(firstVisit.scheduledAt))
            let adjustedVisits = sourceReplacementStopVisits.map { visit in
                ScheduledTripStopVisit(
                    stopID: visit.stopID,
                    stopName: visit.stopName,
                    stopSequence: visit.stopSequence,
                    latitude: visit.latitude,
                    longitude: visit.longitude,
                    scheduledAt: visit.scheduledAt.addingTimeInterval(delay),
                    departureAt: visit.departureAt?.addingTimeInterval(delay),
                    movementToNext: visit.movementToNext,
                    movementGeometrySource: visit.movementGeometrySource
                )
            }
            guard let lastVisit = adjustedVisits.last else {
                throw IncidentReplacementError.unavailable("La course ne contient aucun arrêt après la panne.")
            }
            replacementDeadheadPlan = deadheadPlan
            replacementStopVisits = adjustedVisits
            let dutyStartAt = deadheadPlan.map {
                replacementStartAt.addingTimeInterval(-$0.expectedTravelSeconds)
            } ?? replacementStartAt
            let machinists = simulation.availableMachinists(
                forVehicleID: bus.id,
                serviceStartAt: dutyStartAt,
                serviceEndAt: lastVisit.scheduledAt
            )
            if selectedReplacementMachinistID.map({ id in machinists.contains(where: { $0.id == id }) }) != true {
                selectedReplacementMachinistID = machinists.first?.id
            }
        } catch is CancellationError {
            return
        } catch {
            replacementRouteError = error.localizedDescription
        }
    }

    private func replacementBusTitle(_ bus: PurchasedBus) -> String {
        let model = VehicleMarketCatalog.model(id: bus.modelID)?.displayName ?? bus.modelID
        let location = bus.status == .atStop ? incident.stopName : "dépôt actif"
        return "\(model) · \(location) · \(bus.conditionPercent) %"
    }

    private func dispatchReplacement() {
        guard let bus = selectedReplacementBus,
              let machinistID = selectedReplacementMachinistID else { return }
        isDispatchingReplacement = true
        defer { isDispatchingReplacement = false }
        do {
            let updatedIncident = try simulation.dispatchIncidentReplacement(
                incidentID: incident.id,
                vehicleID: bus.id,
                machinistID: machinistID,
                stopVisits: replacementStopVisits,
                deadheadPlan: replacementDeadheadPlan
            )
            onIncidentUpdated(updatedIncident)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func calculateTowRoute() async {
        guard diagnosisIsComplete else {
            towPlan = nil
            towRouteError = nil
            return
        }
        guard incident.latitude.isFinite, incident.longitude.isFinite else {
            towRouteError = "La panne n’a pas de coordonnées"
            return
        }
        guard let activeSession = simulation.session,
              let incidentBus = activeSession.ownedBuses?.first(where: { $0.id == incident.vehicleID }),
              let activeDepot = depots.first(where: { $0.id == incidentBus.depotID }) else {
            towRouteError = "Le dépôt d’attache du bus n’est pas renseigné"
            return
        }
        isCalculatingTowRoute = true
        defer { isCalculatingTowRoute = false }
        do {
            towPlan = try await VehicleTowRouter.nearestDepot(
                from: CLLocationCoordinate2D(latitude: incident.latitude, longitude: incident.longitude),
                depots: [activeDepot],
                teamAvailableAt: activeSession.nextRecoveryTeamAvailableAt(depotID: activeDepot.id)
            )
            towRouteError = nil
        } catch is CancellationError {
            return
        } catch {
            towPlan = nil
            towRouteError = error.localizedDescription
        }
    }

    private var balanceLabel: String {
        guard let cashBalance else { return "Solde indisponible" }
        return "Solde : \(cashBalance.formatted(.currency(code: "EUR").precision(.fractionLength(0))))"
    }

    private func restockRequiredRepairPart() {
        do {
            try simulation.restockWorkshopParts(requiredRepairPart, forModelID: requiredRepairModelID, depotID: requiredRepairDepotID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let minutes = max(0, Int(duration / 60))
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours == 0 ? "\(remainingMinutes) min" : "\(hours) h \(remainingMinutes) min"
    }
}
