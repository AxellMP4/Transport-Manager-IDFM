import SwiftUI

private enum DepotRosterSheet: Identifiable {
    case timetable(GTFSRouteSummary)
    case assignment(DepotLineAssignmentPrefill)

    var id: String {
        switch self {
        case .timetable(let route): "timetable|\(route.id)"
        case .assignment(let prefill): "assignment|\(prefill.id)"
        }
    }
}

struct DepotInspectorView: View {
    @Environment(\.dismiss) private var dismiss
    let depot: DepotReference?
    let scenario: ScenarioDefinition
    let catalog: NetworkCatalog
    @ObservedObject var library: NetworkLibrary
    let serviceDate: Date
    var showsCloseButton = true
    @State private var isDepotLineRosterPresented = false
    private var coverageSourceTaskID: String {
        let geometryID = library.catalog.activeGeometryVersion?.id ?? "aucune-geometrie"
        let documentsID = library.catalog.activeLineDocumentVersion?.id ?? "aucun-document"
        return "\(geometryID)|\(documentsID)"
    }

    private func selectedSiteCoverageLabel(for coverage: DepotLineCoverage) -> String {
        let lineLabel = coverage.hasLoadedLineReferenceCatalog
            ? "\(coverage.uniqueLineCount) lignes uniques"
            : "\(coverage.uniqueLineCount) lignes documentées"
        let routeLabel = coverage.hasLoadedGTFSRouteCatalog
            ? "\(coverage.routeVariantCount) variantes"
            : "variantes GTFS inconnues"
        return "\(lineLabel) · \(routeLabel)"
    }


    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 38, height: 38)
                    .background(Color.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fiche du dépôt")
                        .font(.headline)
                    Text(depot?.name ?? "Aucun dépôt sélectionné")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Button {
                    isDepotLineRosterPresented = true
                } label: {
                    Label("Lignes, plans et horaires", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(depot == nil)
                if showsCloseButton {
                    Button("Fermer") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 13)

            Divider()

            if let depot {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14)], alignment: .leading, spacing: 14) {
                            depotSummary(depot)
                            networkSummary
                        }

                        GroupBox {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 18)], alignment: .leading, spacing: 13) {
                                ForEach(catalog.sources) { source in
                                    SourceRow(source: source)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 5)
                        } label: {
                            Label("Sources et données du réseau", systemImage: "tray.full")
                                .font(.headline)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 1160, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            } else {
                ContentUnavailableView("Aucun dépôt sélectionné", systemImage: "building.2")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $isDepotLineRosterPresented) {
            if let depot {
                DepotLineRosterView(
                    initialDepotID: depot.id,
                    scenario: scenario,
                    library: library,
                    initialServiceDate: serviceDate
                )
                .frame(minWidth: 1040, minHeight: 700)
            }
        }
    }

    private func depotSummary(_ depot: DepotReference) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(depot.name)
                        .font(.title3.weight(.semibold))
                    Text(depot.locality)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                StatusLabel(text: depot.evidenceLabel, systemImage: "building.2.fill", tint: .green)

                Text(depot.address)
                    .font(.callout.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                Link(destination: depot.addressSourceURL) {
                    Label(depot.addressSourceTitle, systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
                .fixedSize(horizontal: false, vertical: true)

                Divider()
                InspectorValue(title: "Scénario", value: scenario.name)
                InspectorValue(title: "Réseau", value: scenario.networkName)
                InspectorValue(title: "Contrat", value: "\(scenario.contractID) · \(scenario.operatorName)")
                InspectorValue(title: "Validité", value: "\(scenario.contractStartDate) – \(scenario.contractEndDate)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Centre bus", systemImage: "building.2")
                .font(.headline)
        }
    }

    private var networkSummary: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 13) {
                if let version = catalog.activeVersion {
                    HStack(spacing: 12) {
                        networkMetric("Lignes bus", value: version.busRouteCount.formatted(), symbol: "bus")
                        networkMetric("Arrêts géolocalisés", value: version.busStopCount.formatted(), symbol: "mappin.and.ellipse")
                        networkMetric("Réseau", value: version.feedStopCount.formatted(), symbol: "point.3.connected.trianglepath.dotted")
                    }
                    Divider()
                    InspectorValue(title: "Version active", value: version.id)
                    InspectorValue(title: "Importée le", value: version.importedAt.formatted(date: .abbreviated, time: .omitted))
                    InspectorValue(title: "Licence", value: version.license)
                } else {
                    ContentUnavailableView(
                        "Offre GTFS non chargée",
                        systemImage: "archivebox",
                        description: Text("Importe l’offre théorique pour afficher les lignes, horaires et arrêts du réseau.")
                    )
                    .frame(minHeight: 170)
                }

                Text("Les lignes du dépôt restent accessibles même quand leur rattachement est à vérifier. Le niveau de preuve s’affiche dans le catalogue des lignes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("Réseau importé", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.headline)
        }
    }

    private func networkMetric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct DepotLineRosterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: NetworkLibrary
    let scenario: ScenarioDefinition
    @State private var selectedDepotID: String
    @State private var serviceDate: Date
    @State private var isGTFSImporterPresented = false
    @State private var presentedSheet: DepotRosterSheet?

    init(initialDepotID: String, scenario: ScenarioDefinition, library: NetworkLibrary, initialServiceDate: Date) {
        _library = ObservedObject(wrappedValue: library)
        self.scenario = scenario
        _selectedDepotID = State(initialValue: initialDepotID)
        _serviceDate = State(initialValue: initialServiceDate)
    }

    private var selectedDepotName: String {
        DepotLineRoster.selectableSites.first(where: { $0.id == selectedDepotID })?.name ?? selectedDepotID
    }

    private var candidateLines: [DepotLineRosterRow] {
        DepotLineRoster.rows.filter {
            $0.isVisible(atSite: selectedDepotID, on: serviceDate)
        }
    }

    private var contractScopeLines: [DepotLineRosterRow] {
        DepotContractLineScope.candidateRows(
            for: selectedSite,
            references: library.lineReferences,
            serviceDate: serviceDate,
            excluding: candidateLines
        )
    }

    private var unassignedLines: [DepotLineRosterRow] {
        DepotLineRoster.rows.filter {
            $0.isVisible(on: serviceDate) && $0.siteIDsWithEvidence(on: serviceDate).isEmpty
        }
    }

    private var selectedSite: DepotLineRosterSite? {
        DepotLineRoster.selectableSites.first { $0.id == selectedDepotID }
    }

    private var isBordsDeMarneSite: Bool {
        scenario.referenceDepots.contains { $0.id == selectedDepotID }
            || ["freres-lumiere", "neuilly-sur-marne-projet"].contains(selectedDepotID)
    }

    private var bordsDeMarneRosterReference: BordsDeMarneRosterReference {
        .forServiceDate(serviceDate)
    }

    private var canPrepareCareerAssignment: {
        selectedSite?.isOperational == true
            && scenario.referenceDepots.contains { $0.id == selectedDepotID }
            && library.catalog.activeContractVersion != nil
            && library.contractFeatures.contains { $0.contractID == scenario.idfmBusContractID }
    }

    private func prepareCareerAssignment(for row: DepotLineRosterRow, route: GTFSRouteSummary) {
        guard canPrepareCareerAssignment else { return }
        let depotClaims = row.siteEvidenceClaims(for: selectedDepotID, on: serviceDate)
        let primaryClaim = depotClaims.first(where: { $0.sourceURL != nil })
        guard let primaryClaim, let evidenceURL = primaryClaim.sourceURL else { return }
        let additionalEvidenceURLs = row.claims
            .filter { $0.isVisible(on: serviceDate) }
            .compactMap { $0.sourceURL?.absoluteString }
            .filter { $0 != evidenceURL.absoluteString }
            .reduce(into: [String]()) { urls, url in
                if !urls.contains(url) { urls.append(url) }
            }
        presentedSheet = .assignment(DepotLineAssignmentPrefill(
            depotID: selectedDepotID,
            routeID: route.routeID,
            evidenceTitle: primaryClaim.sourceTitle,
            evidenceURL: evidenceURL.absoluteString,
            additionalEvidenceURLs: additionalEvidenceURLs,
            evidenceDate: primaryClaim.sourceDate,
            notes: "Préremplissage documentaire à vérifier et confirmer manuellement pour le \(serviceDate.formatted(date: .numeric, time: .omitted)). État du catalogue public : \(row.evidenceStatus(on: serviceDate).rawValue). \(row.note)\n\(primaryClaim.kind.rawValue) · \(primaryClaim.sourceDateSummary) · \(primaryClaim.validitySummary). \(primaryClaim.note ?? "")"
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lignes · \(selectedDepotName)")
                        .font(.title2.weight(.semibold))
                    Text(selectedSite?.idfmBusContractID.map { "DSP \($0) · lignes du lot et preuves COB" }
                        ?? (isBordsDeMarneSite
                            ? "DSP 45 · preuves, affectations et variantes"
                            : "Catalogue régional · rattachements à documenter"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Fermer") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 14) {
                        Picker("Dépôt", selection: $selectedDepotID) {
                            ForEach(DepotLineRoster.selectableSites) { site in
                                Text("\(site.name) · \(site.availability.label)").tag(site.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 300, alignment: .leading)

                        DatePicker("Date de service", selection: $serviceDate, displayedComponents: .date)
                            .datePickerStyle(.field)
                            .frame(maxWidth: 250)
                    }

                    if let selectedSite {
                        Label(selectedSite.status, systemImage: selectedSite.availability.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedSite.isOperational ? Color.green : Color.orange)
                        Text(selectedSite.evidenceNote)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let observation = selectedSite.fleetObservation {
                            DepotFleetObservationCard(observation: observation)
                        }
                        ForEach(selectedSite.facilityObservations) { observation in
                            DepotFacilityObservationCard(observation: observation)
                        }
                        if let address = selectedSite.documentedAddress {
                            Text("Adresse publiée : \(address)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let title = selectedSite.evidenceTitle, let url = selectedSite.sourceURL {
                            Link(title, destination: url)
                                .font(.caption)
                        }
                        if let title = selectedSite.additionalEvidenceTitle,
                           let url = selectedSite.additionalEvidenceURL {
                            Link(title, destination: url)
                                .font(.caption)
                        }
                    }

                    Label(selectedSite?.idfmBusContractID == nil
                        ? "Lignes recensées pour ce site"
                        : "Lignes et variantes du contrat", systemImage: "bus.fill")
                        .font(.headline)
                    Text("Le registre distingue les lignes présentes dans le réseau, les affectations de centre publiées et les services partagés ou partiels. Le niveau de preuve est indiqué ligne par ligne.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Le catalogue ne rattache une ligne au dépôt que lorsqu’une affirmation liée à ce site couvre la date choisie. Une période de validité inconnue reste à vérifier et ne suffit pas à confirmer un rattachement actuel.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if isBordsDeMarneSite {
                        Text(bordsDeMarneRosterReference.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Link(bordsDeMarneRosterReference.sourceTitle, destination: bordsDeMarneRosterReference.sourceURL)
                            .font(.caption)
                    } else if let contractID = selectedSite?.idfmBusContractID {
                        Text("Le contrat DSP \(contractID) donne le périmètre des lignes. Il ne précise pas quelle ligne est exploitée depuis ce COB ; ces références restent visibles comme candidates jusqu’à preuve de répartition.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Le GTFS régional contient des lignes, horaires et tracés. Aucune ligne n’est attribuée à ce site sans une preuve publique de rattachement au dépôt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(candidateLines) { row in
                            DepotLineCatalogCard(
                                row: row,
                                serviceDate: serviceDate,
                                library: library,
                                onShowTimetable: { presentedSheet = .timetable($0) },
                                onPrepareAssignment: canPrepareCareerAssignment
                                    ? { row, route in prepareCareerAssignment(for: row, route: route) }
                                    : nil
                            )
                        }
                    }

                    if !contractScopeLines.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Lignes du contrat · COB à confirmer", systemImage: "point.3.connected.trianglepath.dotted")
                                .font(.headline)
                            Text("Ce sont les lignes actives du lot IDFM associé au site. Le contrat ne permet pas de les répartir entre les dépôts ; les tracés, variantes, horaires et liens documentaires sont affichés comme références du lot.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(contractScopeLines) { row in
                                DepotLineCatalogCard(
                                    row: row,
                                    serviceDate: serviceDate,
                                    library: library,
                                    onShowTimetable: { presentedSheet = .timetable($0) },
                                    onPrepareAssignment: canPrepareCareerAssignment
                                        ? { row, route in prepareCareerAssignment(for: row, route: route) }
                                        : nil
                                )
                            }
                        }
                    }

                    if candidateLines.isEmpty && contractScopeLines.isEmpty {
                        ContentUnavailableView(
                            "Aucune ligne reliée à ce site",
                            systemImage: "bus",
                            description: Text(isBordsDeMarneSite
                                ? "Aucune affirmation conservée pour ce site ne couvre la date choisie."
                                : "Le site est consultable, mais ses lignes ne sont pas encore rattachées dans le registre public de l’application.")
                        )
                    }

                    if isBordsDeMarneSite && !unassignedLines.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Lignes sans COB établi à cette date")
                            .font(.headline)
                            ForEach(unassignedLines) { row in
                                DepotLineCatalogCard(
                                    row: row,
                                    serviceDate: serviceDate,
                                    library: library,
                                    onShowTimetable: { presentedSheet = .timetable($0) },
                                    onPrepareAssignment: nil
                                )
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Synchroniser les données de ligne")
                            .font(.headline)
                        Text("Les liens de plans PDF et de fiches horaires viennent du catalogue IDFM. Importez le GTFS PRIM couvrant la date choisie pour afficher la grille théorique des courses, directions et arrêts.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Link(destination: DepotLineRoster.gtfsDatasetURL) {
                            Label("Ouvrir l’offre théorique GTFS sur PRIM", systemImage: "arrow.up.right.square")
                        }
                        Text("Le jeu GTFS IDFM décrit les 30 prochains jours et est mis à jour trois fois par jour. Il est soumis à la Licence Mobilité et peut demander une connexion/clé PRIM.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            Button {
                                library.downloadLatestLineReferences()
                            } label: {
                                if library.lineReferenceImportState.isImporting || library.isLoadingLineReferences {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Label("Référentiel IDFM", systemImage: "arrow.down.circle")
                                }
                            }
                            .disabled(library.lineReferenceImportState.isImporting || library.isLoadingLineReferences)

                            Button {
                                library.downloadLatestLineDocuments()
                            } label: {
                                if library.lineDocumentImportState.isImporting || library.isLoadingLineDocuments {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Label("Plans et horaires", systemImage: "arrow.down.circle")
                                }
                            }
                            .disabled(library.lineDocumentImportState.isImporting || library.isLoadingLineDocuments)

                            Button {
                                isGTFSImporterPresented = true
                            } label: {
                                Label("Choisir le ZIP GTFS…", systemImage: "archivebox")
                            }
                            .disabled(library.importState.isImporting)
                        }

                        Text("Référentiel : \(library.lineReferences.count) lignes · Documents : \(library.lineDocuments.count) liens · GTFS : \(library.catalog.activeVersion?.id ?? "aucune version")")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)

                        if let message = library.lineReferencesError ?? library.lineDocumentsError ?? library.busRoutesError {
                            Label(message, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Link(destination: DepotLineRoster.contractEvidenceURL) {
                            Label("Contrat IDFM · lignes et centres d’exploitation", systemImage: "doc.text")
                        }
                        Link(destination: DepotLineRoster.awardEvidenceURL) {
                            Label("IDFM · périmètre et centres de la DSP 45", systemImage: "building.2")
                        }
                        Link(destination: DepotLineRoster.reorganizationURL) {
                            Label("Source IDFM · réorganisation au 1er novembre 2026", systemImage: "calendar")
                        }
                        Link(destination: DepotLineRoster.wikipediaURL) {
                            Label("Wikipédia · lignes et centres opérationnels publiés", systemImage: "link")
                        }
                        Link(destination: DepotLineRoster.tcInfosDepotURL(for: selectedDepotID)) {
                            Label("TC Infos · parc du dépôt", systemImage: "bus")
                        }
                        Link(destination: DepotLineRoster.databusURL) {
                            Label("DataBus / BusParisiens · données de parc", systemImage: "link")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
        }
        .frame(minWidth: 720, minHeight: 640)
        .fileImporter(isPresented: $isGTFSImporterPresented, allowedContentTypes: [.zip], allowsMultipleSelection: false) { result in
            if case let .success(urls) = result, let url = urls.first {
                library.importGTFS(from: url)
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .timetable(let route):
                if let version = library.catalog.activeVersion {
                    GTFSRouteTimetableGridView(
                        library: library,
                        route: route,
                        version: version,
                        documents: documents(for: route),
                        initialServiceDate: serviceDate
                    )
                } else {
                    ContentUnavailableView("GTFS absent", systemImage: "archivebox", description: Text("Importez une archive GTFS pour afficher une grille horaire par course et par arrêt."))
                        .frame(minWidth: 600, minHeight: 260)
                }
            case .assignment(let prefill):
                DepotAssignmentManagerView(
                    library: library,
                    scenario: scenario,
                    depot: scenario.referenceDepots.first { $0.id == prefill.depotID },
                    prefill: prefill
                )
                .frame(minWidth: 720, minHeight: 620)
            }
        }
        .task {
            await library.loadBusRoutes()
            await library.loadActiveLineReferences()
            await library.loadActiveLineDocuments()
        }
    }

    private func documents(for route: GTFSRouteSummary) -> [NetworkLineDocument] {
        library.documents(for: route)
    }
}

private struct BordsDeMarneRosterReference {
    let summary: String
    let sourceTitle: String
    let sourceURL: URL

    static func forServiceDate(_ serviceDate: Date) -> Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        let serviceDay = calendar.startOfDay(for: serviceDate)
        let transferDate = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1))
        let reorganizationDate = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))

        guard let transferDate, let reorganizationDate else {
            return Self(
                summary: "Le décompte des lignes dépend de la date de service. Les rattachements au COB restent à confirmer par des sources datées.",
                sourceTitle: "Tableau ligne–centre historique IDFM–RATP",
                sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/aTFjzHNYClf9nz_6_ContratBUS2025-2026_vsigne%CC%81eLP.pdf")!
            )
        }

        if serviceDay < transferDate {
            return Self(
                summary: "Avant le transfert DSP45 du 1er novembre 2025, le décompte du réseau attribué à RATP Cap ne s’applique pas. Les rattachements de l’ancien contrat sont datés séparément dans le registre.",
                sourceTitle: "Tableau ligne–centre historique IDFM–RATP",
                sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/aTFjzHNYClf9nz_6_ContratBUS2025-2026_vsigne%CC%81eLP.pdf")!
            )
        }

        if serviceDay < reorganizationDate {
            return Self(
                summary: "Du 1er novembre 2025 au 31 octobre 2026 : 29 lignes DSP45 (22 régulières et 7 Noctilien). N31 reste un conflit historique hors roster actif. Les preuves par COB ne répartissent pas toutes les courses.",
                sourceTitle: "IDFM · attribution de la DSP45 et périmètre annoncé",
                sourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/mise-en-concurrence-des-transports-franciliens/?lang=fr")!
            )
        }

        return Self(
            summary: "À partir du 1er novembre 2026, IDFM annonce 23 lignes de jour et 7 de nuit (30 au total). La 314 démarre alors, mais le GTFS embarqué du 20 octobre ne vérifie pas encore le service 214/314 après la réorganisation. Le communiqué ne répartit pas les lignes par COB.",
            sourceTitle: "IDFM · réorganisation du réseau au 1er novembre 2026",
            sourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-restructure-et-reorganise-loffre-de-bus-sur-les-territoires-des-bords-de-marne-et-de-boucle-nord-de-seine/?lang=fr")!
        )
    }
}

private struct InspectorValue: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct SourceRow: View {
    let source: NetworkDataSource

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "arrow.down.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                if let destination = source.destination {
                    Link(source.title, destination: destination)
                        .font(.caption.weight(.medium))
                        .lineLimit(2)
                } else {
                    Text(source.title)
                        .font(.caption.weight(.medium))
                        .lineLimit(2)
                }
                Text(source.purpose)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Text(source.state.label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
        }
    }
}

private struct DepotFleetObservationCard: View {
    let observation: DepotFleetObservation
    var compact = false

    private var energySummary: String {
        observation.energyCounts
            .map { "\($0.energyTitle) : \($0.vehicleCount)" }
            .joined(separator: " · ")
    }

    private var conditionSummary: String? {
        var values: [String] = []
        if let averageAge = observation.averageFleetAgeYears {
            values.append("Âge moyen : \(averageAge.formatted(.number.precision(.fractionLength(1)))) ans")
        }
        if let airConditionedShare = observation.airConditionedVehicleSharePercent {
            values.append("Climatisés : \(airConditionedShare) %")
        }
        return values.isEmpty ? nil : values.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Label("Parc observé", systemImage: "bus.fill")
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 8)
                Text("\(observation.totalVehicleCount) véhicules")
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            if compact, let comparisonNote = observation.comparisonNote {
                Label("Total à vérifier", systemImage: "exclamationmark.triangle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
                    .help(comparisonNote)
            }
            Text(energySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let conditionSummary {
                Text(conditionSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !compact {
                Text(observation.reviewedOnLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(observation.sourceFreshnessNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(observation.limitationNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let comparisonNote = observation.comparisonNote {
                    Label("Écart entre les vues de la source", systemImage: "exclamationmark.triangle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text(comparisonNote)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let title = observation.comparisonSourceTitle,
                       let url = observation.comparisonSourceURL {
                        Link(title, destination: url)
                            .font(.caption2)
                    }
                }
            }
            Link(observation.sourceTitle, destination: observation.sourceURL)
                .font(compact ? .caption2 : .caption)
                .lineLimit(compact ? 1 : nil)
        }
        .padding(compact ? 0 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            compact ? Color.clear : Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}

private struct StatusLabel: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.10), in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct RegionalDepotRegistryView: View {
    @Environment(\.dismiss) private var dismiss
    var showsCloseButton = true
    var onSelectSiteID: ((String) -> Void)? = nil
    @State private var searchText = ""

    private var directorySites: [DepotLineRosterSite] {
        DepotLineRoster.selectableSites.filter { site in
            searchText.isEmpty
                || site.name.localizedCaseInsensitiveContains(searchText)
                || site.locality.localizedCaseInsensitiveContains(searchText)
                || site.documentedAddress?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    private var operationalSites: [DepotLineRosterSite] {
        directorySites.filter { $0.availability == .operational }
    }

    private var unverifiedSites: [DepotLineRosterSite] {
        directorySites.filter { $0.availability == .currentStatusUnverified }
    }

    private var plannedSites: [DepotLineRosterSite] {
        directorySites.filter { $0.availability == .planned }
    }

    private var unclassifiedLabels: [DepotRegistryEntry] {
        RegionalDepotRegistry.seedEntries.filter {
            $0.kind == .unclassifiedLabel
                && (searchText.isEmpty || $0.originalLabel.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choisis un dépôt pour ouvrir sa carte et son réseau. Le catalogue reprend les centres du répertoire public des COB stratégiques, complétés par les sites cités dans les sources IDFM. Les vraies lignes et leurs horaires sont chargés par contrat ; quand les documents ne disent pas quel dépôt exploite une ligne, elle reste marquée « affectation au dépôt à confirmer ».")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .listRowBackground(Color.clear)
                }

                if !operationalSites.isEmpty {
                    Section("Dépôts recensés en activité · \(operationalSites.count)") {
                        ForEach(operationalSites) { site in
                            directorySiteRow(site)
                        }
                    }
                }

                if !unverifiedSites.isEmpty {
                    Section("Dépôts à vérifier · \(unverifiedSites.count)") {
                        ForEach(unverifiedSites) { site in
                            directorySiteRow(site)
                        }
                    }
                }

                if !plannedSites.isEmpty {
                    Section("Projets · non jouables · \(plannedSites.count)") {
                        ForEach(plannedSites) { site in
                            directorySiteRow(site)
                        }
                    }
                }

                if !unclassifiedLabels.isEmpty {
                    Section("Libellés conservés · pas encore identifiés comme dépôts · \(unclassifiedLabels.count)") {
                        ForEach(unclassifiedLabels) { entry in
                            registryRow(entry)
                        }
                    }
                }

                if directorySites.isEmpty && unclassifiedLabels.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher un dépôt ou une ville")
            .navigationTitle(onSelectSiteID == nil ? "Référentiel régional des dépôts" : "Choisir un dépôt")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func directorySiteRow(_ site: DepotLineRosterSite) -> some View {
        if let onSelectSiteID {
            Button {
                onSelectSiteID(site.id)
                dismiss()
            } label: {
                directorySiteContents(site, isSelectable: true)
            }
            .buttonStyle(.plain)
        } else {
            directorySiteContents(site, isSelectable: false)
        }
    }

    private func directorySiteContents(_ site: DepotLineRosterSite, isSelectable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(site.name)
                    .font(.headline)
                Spacer()
                Text(site.availability.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(site.availability == .operational ? Color.green : Color.orange)
                if isSelectable {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            Text("\(site.locality) · \(site.status)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let address = site.documentedAddress {
                Text("Adresse publiée : \(address)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(site.evidenceNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let observation = site.fleetObservation {
                DepotFleetObservationCard(observation: observation, compact: true)
            }
            if let evidenceTitle = site.evidenceTitle {
                Text(evidenceTitle)
                    .font(.caption2)
                    .foregroundStyle(.tint)
                    .lineLimit(1)
            }
            if let title = site.additionalEvidenceTitle, let url = site.additionalEvidenceURL {
                Link(title, destination: url)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func registryRow(_ entry: DepotRegistryEntry) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.originalLabel)
                    .font(.headline)
                Spacer()
                Text(entry.kind == .confirmedAlias ? "COB du scénario" : entry.kind == .datedAddressReference ? "Référence 2022" : "À vérifier")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.kind == .confirmedAlias ? Color.green : Color.orange)
            }
            Text(entry.kind.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let linkedDepotID = entry.linkedDepotID,
               let depot = ScenarioDefinition.bordsDeMarne.referenceDepots.first(where: { $0.id == linkedDepotID }) {
                Text("Centre identifié : \(depot.name) · \(depot.address)")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let documentedAddress = entry.documentedAddress {
                Text("Adresse publiée : \(documentedAddress)")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let evidenceTitle = entry.evidenceTitle, let evidenceURL = entry.evidenceURL {
                Link(evidenceTitle, destination: evidenceURL)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DepotDirectoryWorkspaceView: View {
    @ObservedObject var library: NetworkLibrary
    /// The depot currently selected in the directory; it can differ from the active career depot.
    let selectedDepotID: String
    let careerDepotID: String?
    let managedDepotIDs: Set<String>
    let selectionLocked: Bool
    let serviceDate: Date
    let operatedRouteIDsForDepot: (String) -> Set<String>
    let onSelect: (String) -> Void
    let onOpen: (String) -> Void
    let onActivate: (String) -> Void

    @State private var searchText = ""
    @State private var browseSelectionID: String?
    @State private var selectedSiteServiceAudit: DepotGTFSServiceAudit?
    @State private var selectedSiteServiceAuditError: String?
    @State private var isLoadingSelectedSiteServiceAudit = false
    @State private var isPresentingRegionalCoverageAudit = false


    private var directorySelectedDepotID: String {
        selectionLocked ? (browseSelectionID ?? selectedDepotID) : selectedDepotID
    }

    private var sites: [DepotLineRosterSite] {
        DepotLineRoster.selectableSites
            .filter { site in
                searchText.isEmpty
                    || site.name.localizedCaseInsensitiveContains(searchText)
                    || site.locality.localizedCaseInsensitiveContains(searchText)
                    || site.documentedAddress?.localizedCaseInsensitiveContains(searchText) == true
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var activeSites: [DepotLineRosterSite] { sites.filter { $0.availability == .operational } }
    private var unverifiedSites: [DepotLineRosterSite] { sites.filter { $0.availability == .currentStatusUnverified } }
    private var plannedSites: [DepotLineRosterSite] { sites.filter { $0.availability == .planned } }

    private var selectedSite: DepotLineRosterSite? {
        DepotLineRoster.selectableSites.first { $0.id == directorySelectedDepotID }
    }

    private var selectedSiteRows: [DepotLineRosterRow] {
        guard let selectedSite else { return [] }
        let documentedRows = DepotLineRoster.rows.filter { $0.isVisible(atSite: directorySelectedDepotID, on: serviceDate) }
        let contractRows = DepotContractLineScope.candidateRows(
            for: selectedSite,
            references: library.lineReferences,
            serviceDate: serviceDate,
            excluding: documentedRows
        )
        return documentedRows + contractRows
    }

    private var selectedSiteLineCoverage: DepotLineCoverage {
        library.depotLineCoverage(
            depotID: directorySelectedDepotID,
            serviceDate: serviceDate,
            operatedRouteIDs: operatedRouteIDsForDepot(directorySelectedDepotID)
        )
    }

    private var selectedSiteServiceAuditTaskID: String {
        let dateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone) ?? -1
        return "\(directorySelectedDepotID)|\(dateKey)|\(library.catalog.activeVersion?.id ?? "aucun-gtfs")|\(library.catalog.activeLineReferenceVersion?.id ?? "aucune-reference")|\(library.busRoutesVersionID ?? "routes-en-attente")|\(library.lineReferenceVersionID ?? "references-en-attente")|\(library.busRoutes.count)|\(library.lineReferences.count)|\(library.isLoadingBusRoutes)|\(library.isLoadingLineReferences)"
    }

    var body: some View {
        HStack(spacing: 0) {
            directoryList
                .frame(minWidth: 320, idealWidth: 390, maxWidth: 480)
            Divider()
            selectedDepotDetail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task(id: coverageSourceTaskID) {
            await library.loadActiveRouteGeometries()
            await library.loadActiveLineDocuments()
        }
        .task(id: selectedSiteServiceAuditTaskID) {
            let taskID = selectedSiteServiceAuditTaskID
            await loadSelectedSiteServiceAudit(taskID: taskID)
        }
        .sheet(isPresented: $isPresentingRegionalCoverageAudit) {
            DepotRegionalCoverageAuditView(
                library: library,
                serviceDate: serviceDate,
                operatedRouteIDsForDepot: operatedRouteIDsForDepot,
                onSelect: { depotID in
                    if selectionLocked {
                        browseSelectionID = depotID
                    } else {
                        onSelect(depotID)
                    }
                    isPresentingRegionalCoverageAudit = false
                }
            )
        }
    }

    private var directoryList: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tous les dépôts")
                    .font(.title2.weight(.semibold))
                Text("\(DepotLineRoster.selectableSites.count) sites recensés en Île-de-France")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Button {
                isPresentingRegionalCoverageAudit = true
            } label: {
                Label("Audit régional complet", systemImage: "checklist")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            TextField("Nom du dépôt ou de la ville", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.bottom, 9)

            Divider()
            List {
                if !activeSites.isEmpty {
                    Section("En activité selon les sources · \(activeSites.count)") {
                        ForEach(activeSites) { site in siteRow(site) }
                    }
                }
                if !unverifiedSites.isEmpty {
                    Section("Statut actuel à vérifier · \(unverifiedSites.count)") {
                        ForEach(unverifiedSites) { site in siteRow(site) }
                    }
                }
                if !plannedSites.isEmpty {
                    Section("Projets · \(plannedSites.count)") {
                        ForEach(plannedSites) { site in siteRow(site) }
                    }
                }
                if sites.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: false))
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private func siteRow(_ site: DepotLineRosterSite) -> some View {
        let isSelected = directorySelectedDepotID == site.id
        Button {
            if selectionLocked {
                browseSelectionID = site.id
            } else {
                onSelect(site.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: site.availability.systemImage)
                    .foregroundStyle(site.availability == .operational ? Color.green : Color.orange)
                    .frame(width: 19)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(site.name)
                        .font(.subheadline.weight(.semibold))
                    Text(site.locality)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let contractID = site.idfmBusContractID {
                        Text("Contrat DSP \(contractID)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tint)
                    } else {
                        Text(site.availability == .planned ? "Projet de dépôt" : "Lignes à établir")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(selectionLocked ? "Consulter \(site.name) sans changer la carrière en cours." : "Sélectionner \(site.name)")
    }

    private var selectedDepotDetail: some View {
        ScrollView {
            if let selectedSite {
                let coverage = selectedSiteLineCoverage
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.tint)
                            .frame(width: 52, height: 52)
                            .background(Color.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedSite.name)
                                .font(.title2.weight(.semibold))
                            Text(selectedSite.locality)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 6)
                    }

                    Label(selectedSite.availability.label, systemImage: selectedSite.availability.systemImage)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedSite.availability == .operational ? Color.green : Color.orange)

                    if let address = selectedSite.documentedAddress {
                        Label(address, systemImage: "mappin.and.ellipse")
                            .font(.callout)
                    }
                    Text(selectedSite.evidenceNote)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let observation = selectedSite.fleetObservation {
                        DepotFleetObservationCard(observation: observation)
                    }
                    ForEach(selectedSite.facilityObservations) { observation in
                        DepotFacilityObservationCard(observation: observation)
                    }
                    if let evidenceTitle = selectedSite.evidenceTitle, let sourceURL = selectedSite.sourceURL {
                        Link(evidenceTitle, destination: sourceURL)
                            .font(.callout)
                    }

                    Divider()
                    HStack(alignment: .firstTextBaseline) {
                        Text("Réseau associé")
                            .font(.headline)
                        Spacer()
                        Text(selectedSiteCoverageLabel(for: coverage))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    if coverage.uniqueLineCount > 0 {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), alignment: .leading)], alignment: .leading, spacing: 8) {
                            depotCoverageMetric("Lignes GTFS", value: coverageMetricValue(
                                coverage.gtfsCoverage,
                                isAvailable: coverage.hasLoadedGTFSRouteCatalog,
                                isLoading: library.isLoadingBusRoutes,
                                error: library.busRoutesError,
                                hasVersion: library.catalog.activeVersion != nil
                            ), symbol: "clock.arrow.circlepath")
                            depotCoverageMetric("Tracés officiels", value: coverageMetricValue(
                                coverage.traceCoverage,
                                isAvailable: coverage.hasLoadedGTFSRouteCatalog
                                    && coverage.hasLoadedRouteGeometryCatalog,
                                isLoading: library.isLoadingBusRoutes || library.isLoadingRouteGeometries,
                                error: library.busRoutesError ?? library.routeGeometriesError,
                                hasVersion: library.catalog.activeVersion != nil && library.catalog.activeGeometryVersion != nil
                            ), symbol: "point.topleft.down.to.point.bottomright.curvepath")
                            depotCoverageMetric("Plans PDF", value: coverageMetricValue(
                                coverage.planCoverage,
                                isAvailable: coverage.hasLoadedLineReferenceCatalog
                                    && coverage.hasLoadedLineDocumentCatalog,
                                isLoading: library.isLoadingLineReferences || library.isLoadingLineDocuments,
                                error: library.lineReferencesError ?? library.lineDocumentsError,
                                hasVersion: library.catalog.activeLineReferenceVersion != nil
                                    && library.catalog.activeLineDocumentVersion != nil
                            ), symbol: "map")
                            depotCoverageMetric("Fiches horaires", value: coverageMetricValue(
                                coverage.timetableCoverage,
                                isAvailable: coverage.hasLoadedLineReferenceCatalog
                                    && coverage.hasLoadedLineDocumentCatalog,
                                isLoading: library.isLoadingLineReferences || library.isLoadingLineDocuments,
                                error: library.lineReferencesError ?? library.lineDocumentsError,
                                hasVersion: library.catalog.activeLineReferenceVersion != nil
                                    && library.catalog.activeLineDocumentVersion != nil
                            ), symbol: "doc.text")
                            depotCoverageMetric("Références ambiguës / absentes", value: coverageMetricValue(
                                "\(coverage.ambiguousReferenceCount) / \(coverage.missingReferenceCount)",
                                isAvailable: coverage.hasLoadedLineReferenceCatalog,
                                isLoading: library.isLoadingLineReferences,
                                error: library.lineReferencesError,
                                hasVersion: library.catalog.activeLineReferenceVersion != nil
                            ), symbol: "questionmark.circle")
                            depotCoverageMetric("Sans route GTFS", value: coverageMetricValue(
                                "\(coverage.missingGTFSCount)",
                                isAvailable: coverage.hasLoadedLineReferenceCatalog
                                    && coverage.hasLoadedGTFSRouteCatalog,
                                isLoading: library.isLoadingLineReferences || library.isLoadingBusRoutes,
                                error: library.lineReferencesError ?? library.busRoutesError,
                                hasVersion: library.catalog.activeLineReferenceVersion != nil && library.catalog.activeVersion != nil
                            ), symbol: "bus")
                            depotCoverageMetric("Variantes sans plan · horaire", value: coverageMetricValue(
                                "\(coverage.routesWithoutPlans.count) · \(coverage.routesWithoutTimetables.count)",
                                isAvailable: coverage.hasLoadedLineReferenceCatalog
                                    && coverage.hasLoadedGTFSRouteCatalog
                                    && coverage.hasLoadedLineDocumentCatalog,
                                isLoading: library.isLoadingLineReferences || library.isLoadingBusRoutes || library.isLoadingLineDocuments,
                                error: library.lineReferencesError ?? library.busRoutesError ?? library.lineDocumentsError,
                                hasVersion: library.catalog.activeLineReferenceVersion != nil
                                    && library.catalog.activeVersion != nil
                                    && library.catalog.activeLineDocumentVersion != nil
                            ), symbol: "doc.text")
                            depotCoverageMetric("COB non confirmé", value: coverageMetricValue(
                                "\(coverage.unconfirmedDepotEvidenceCount)/\(coverage.uniqueLineCount)",
                                isAvailable: coverage.hasLoadedLineReferenceCatalog
                                    && coverage.hasLoadedGTFSRouteCatalog,
                                isLoading: library.isLoadingLineReferences || library.isLoadingBusRoutes,
                                error: library.lineReferencesError ?? library.busRoutesError,
                                hasVersion: library.catalog.activeLineReferenceVersion != nil && library.catalog.activeVersion != nil
                            ), symbol: "building.2")
                        }
                        if !coverage.hasLoadedLineReferenceCatalog
                            || !coverage.hasLoadedGTFSRouteCatalog
                            || !coverage.hasLoadedLineDocumentCatalog
                            || !coverage.hasLoadedRouteGeometryCatalog {
                            Text("Les compteurs de couverture restent inconnus tant que les index des sources actives ne sont pas chargés; une source en erreur n’est pas comptée comme une couverture nulle.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if coverage.hasLoadedLineReferenceCatalog
                            && coverage.hasLoadedGTFSRouteCatalog
                            && coverage.hasLoadedLineDocumentCatalog {
                            DepotMissingRouteDocumentsDisclosure(coverage: coverage)
                        }
                    }
                    if !selectedSiteRows.isEmpty {
                        if isLoadingSelectedSiteServiceAudit {
                            ProgressView("Lecture des départs GTFS de la date…")
                                .font(.caption)
                        } else if let selectedSiteServiceAuditError {
                            Text("Audit GTFS impossible : \(selectedSiteServiceAuditError)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if let selectedSiteServiceAudit {
                            DepotGTFSServiceAuditCard(audit: selectedSiteServiceAudit, serviceDate: serviceDate)
                        }
                    }
                    if DepotLineRoster.bordsDeMarneManifestSiteIDs.contains(selectedSite.id) {
                        Label(
                            "\(DepotLineRosterManifestCatalog.state.summary) · \(DepotLineRosterManifestCatalog.entries(for: serviceDate).count) actives à cette date",
                            systemImage: DepotLineRosterManifestCatalog.state.isValid ? "checkmark.seal" : "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(DepotLineRosterManifestCatalog.state.isValid ? Color.secondary : Color.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    if let contractID = selectedSite.idfmBusContractID {
                        Text("Lignes réelles du contrat DSP \(contractID). Quand IDFM ne ventile pas les lignes entre les centres du contrat, elles restent identifiées comme candidates.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if selectedSiteRows.isEmpty {
                        Text("Le répertoire confirme ce site, mais les sources publiques chargées ne donnent pas encore de lignes rattachées à ce dépôt.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let rosterNote = DepotContractLineScope.publicRosterNote(for: selectedSite, serviceDate: serviceDate) {
                        Label(rosterNote, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        Button {
                            onOpen(selectedSite.id)
                        } label: {
                            Label(selectedSiteRows.isEmpty ? "Consulter ce site" : "Afficher ses lignes", systemImage: "arrow.right")
                        }
                        .buttonStyle(.borderedProminent)

                        if selectionLocked, selectedSite.hasPlayableContractScope {
                            Button {
                                onActivate(selectedSite.id)
                            } label: {
                                Label(
                                    managedDepotIDs.contains(selectedSite.id)
                                        ? (selectedSite.id == careerDepotID ? "Dépôt actif" : "Changer pour ce dépôt")
                                        : "Ajouter à l’entreprise",
                                    systemImage: managedDepotIDs.contains(selectedSite.id)
                                        ? (selectedSite.id == careerDepotID ? "checkmark.circle.fill" : "arrow.triangle.swap")
                                        : "plus.circle"
                                )
                            }
                            .buttonStyle(.bordered)
                            .disabled(managedDepotIDs.contains(selectedSite.id) && selectedSite.id == careerDepotID)
                            .help(managedDepotIDs.contains(selectedSite.id)
                                ? "Basculer la carte et le contexte du parc vers ce dépôt"
                                : "Ajouter ce dépôt régional à l’entreprise et charger ses lignes GTFS")
                        }

                        if selectedSite.hasPlayableContractScope {
                            Label(
                                selectedSite.availability == .operational
                                    ? "Carrière sur cette DSP"
                                    : "Carrière possible · statut du site à vérifier",
                                systemImage: selectedSite.availability == .operational ? "building.2.crop.circle" : "questionmark.circle"
                            )
                            .font(.caption.weight(.medium))
                            .foregroundStyle(selectedSite.availability == .operational ? .green : .orange)
                        } else if selectedSite.availability == .planned {
                            Label("Non jouable actuellement", systemImage: "calendar.badge.clock")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.orange)
                        } else {
                            Label("Consultation · lignes à documenter", systemImage: "eye")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if selectionLocked {
                        Label("La partie gère les dépôts rattachés à son contrat. Les autres sites restent consultables depuis le répertoire.", systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(26)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .task(id: selectedDepotID) {
            await library.loadActiveLineReferences()
        }
    }

    private func loadSelectedSiteServiceAudit(taskID: String) async {
        selectedSiteServiceAudit = nil
        selectedSiteServiceAuditError = nil
        isLoadingSelectedSiteServiceAudit = true
        defer {
            if taskID == selectedSiteServiceAuditTaskID {
                isLoadingSelectedSiteServiceAudit = false
            }
        }

        await library.loadBusRoutes()
        await library.loadActiveLineReferences()
        guard !Task.isCancelled, taskID == selectedSiteServiceAuditTaskID else { return }
        if let busRoutesError = library.busRoutesError {
            selectedSiteServiceAuditError = busRoutesError
            return
        }
        if let lineReferencesError = library.lineReferencesError {
            selectedSiteServiceAuditError = lineReferencesError
            return
        }
        if library.isLoadingBusRoutes || library.isLoadingLineReferences
            || library.busRoutesVersionID != library.catalog.activeVersion?.id
            || (library.catalog.activeLineReferenceVersion != nil
                && library.lineReferenceVersionID != library.catalog.activeLineReferenceVersion?.id) {
            return
        }

        do {
            let audit = try await library.depotGTFSServiceAudit(
                depotID: directorySelectedDepotID,
                serviceDate: serviceDate
            )
            guard !Task.isCancelled, taskID == selectedSiteServiceAuditTaskID else { return }
            selectedSiteServiceAudit = audit
        } catch {
            guard !Task.isCancelled, taskID == selectedSiteServiceAuditTaskID else { return }
            selectedSiteServiceAuditError = error.localizedDescription
        }
    }

    private func depotCoverageMetric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
    }
    private func coverageMetricValue(
        _ value: String,
        isAvailable: Bool,
        isLoading: Bool,
        error: String?,
        hasVersion: Bool
    ) -> String {
        if isAvailable { return value }
        if isLoading { return "Chargement…" }
        if error != nil { return "Indisponible" }
        return hasVersion ? "Non chargé" : "Aucune version"
    }
}

private struct DepotRegionalCoverageAuditRecord: Identifiable {
    let site: DepotLineRosterSite
    let coverage: DepotLineCoverage
    let serviceAudit: DepotGTFSServiceAudit?
    let serviceAuditError: String?
    let confirmedCobLineCount: Int
    let otherCobEvidenceLineCount: Int
    let candidateLineCount: Int

    var id: String { site.id }
}

private struct DepotRegionalCoverageAuditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: NetworkLibrary
    let serviceDate: Date
    let operatedRouteIDsForDepot: (String) -> Set<String>
    let onSelect: (String) -> Void

    @State private var records: [DepotRegionalCoverageAuditRecord] = []
    @State private var searchText = ""
    @State private var currentSiteName: String?
    @State private var completedSiteCount = 0
    @State private var isAuditing = true
    @State private var sourceLoadingError: String?
    @State private var reloadToken = 0

    private var auditInputKey: String {
        let dateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone) ?? -1
        return [
            String(dateKey),
            library.catalog.activeVersion?.id ?? "aucun-gtfs",
            library.catalog.activeLineReferenceVersion?.id ?? "aucune-reference",
            library.catalog.activeGeometryVersion?.id ?? "aucune-geometrie",
            library.catalog.activeLineDocumentVersion?.id ?? "aucun-document"
        ].joined(separator: "|")
    }

    private var sitesToAudit: [DepotLineRosterSite] {
        DepotLineRoster.selectableSites
            .filter { $0.availability != .planned }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var filteredRecords: [DepotRegionalCoverageAuditRecord] {
        guard !searchText.isEmpty else { return records }
        return records.filter {
            $0.site.name.localizedCaseInsensitiveContains(searchText)
                || $0.site.locality.localizedCaseInsensitiveContains(searchText)
                || $0.site.idfmBusContractID?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    private var plannedSiteCount: Int {
        DepotLineRoster.selectableSites.count(where: { $0.availability == .planned })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audit régional des dépôts")
                        .font(.title2.weight(.semibold))
                    Text("Couverture au \(serviceDate.formatted(date: .long, time: .omitted)) · \(sitesToAudit.count) sites hors projets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Fermer") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Le tableau rapproche les lignes recensées, références IDFM, routes GTFS, géométries commerciales, plans et fiches horaires. Les départs ne sont associés qu’après une référence IDFM unique puis par `ID_Line` exact. Une appartenance au contrat ne confirme pas un rattachement au COB.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                sourceVersionSummary

                HStack(spacing: 10) {
                    TextField("Filtrer par dépôt, ville ou DSP", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 360)
                    Spacer()
                    if isAuditing {
                        ProgressView(value: Double(completedSiteCount), total: Double(max(sitesToAudit.count, 1)))
                            .frame(width: 150)
                        Text("\(completedSiteCount)/\(sitesToAudit.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        if let currentSiteName {
                            Text(currentSiteName)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(maxWidth: 220, alignment: .leading)
                        }
                    } else {
                        Button {
                            reloadToken += 1
                        } label: {
                            Label("Relancer", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if let sourceLoadingError {
                    Label(sourceLoadingError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !isAuditing {
                    Text("\(records.count) sites audités · \(plannedSiteCount) projets exclus de l’audit de service")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            Table(filteredRecords) {
                TableColumn("Site") { record in
                    Button {
                        onSelect(record.site.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.site.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(record.site.locality) · \(record.site.availability.shortLabel)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                .width(min: 210, ideal: 250)

                TableColumn("COB documenté") { record in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(record.confirmedCobLineCount) confirmé(s)")
                            .font(.caption.weight(.medium).monospacedDigit())
                        Text("\(record.otherCobEvidenceLineCount) autre(s) preuve(s)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(record.candidateLineCount) candidat(s) de contrat")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 135, ideal: 155)

                TableColumn("ID_Line") { record in
                    let uniqueReferences = max(0, record.coverage.uniqueLineCount
                        - record.coverage.ambiguousReferenceCount
                        - record.coverage.missingReferenceCount)
                    Text(ratio(uniqueReferences, record.coverage.uniqueLineCount, loaded: record.coverage.hasLoadedLineReferenceCatalog))
                        .font(.caption.monospacedDigit())
                }
                .width(min: 80, ideal: 90)

                TableColumn("Routes GTFS") { record in
                    Text(ratio(record.coverage.linesWithGTFS, record.coverage.uniqueLineCount, loaded: record.coverage.hasLoadedLineReferenceCatalog && record.coverage.hasLoadedGTFSRouteCatalog))
                        .font(.caption.monospacedDigit())
                }
                .width(min: 95, ideal: 110)

                TableColumn("Départs · date") { record in
                    Text(serviceSummary(for: record))
                        .font(.caption.monospacedDigit())
                        .help(record.serviceAuditError ?? record.serviceAudit?.availability.summary ?? "Audit en attente")
                }
                .width(min: 120, ideal: 155)

                TableColumn("Tracés") { record in
                    Text(ratio(record.coverage.linesWithOfficialTraces, record.coverage.uniqueLineCount, loaded: record.coverage.hasLoadedGTFSRouteCatalog && record.coverage.hasLoadedRouteGeometryCatalog))
                        .font(.caption.monospacedDigit())
                }
                .width(min: 75, ideal: 90)

                TableColumn("Plans PDF") { record in
                    Text(ratio(record.coverage.linesWithPlans, record.coverage.uniqueLineCount, loaded: record.coverage.hasLoadedLineReferenceCatalog && record.coverage.hasLoadedLineDocumentCatalog))
                        .font(.caption.monospacedDigit())
                }
                .width(min: 80, ideal: 95)

                TableColumn("Fiches horaires") { record in
                    Text(ratio(record.coverage.linesWithTimetables, record.coverage.uniqueLineCount, loaded: record.coverage.hasLoadedLineReferenceCatalog && record.coverage.hasLoadedLineDocumentCatalog))
                        .font(.caption.monospacedDigit())
                }
                .width(min: 105, ideal: 125)
            }
            .overlay {
                if records.isEmpty && !isAuditing {
                    ContentUnavailableView("Aucun résultat", systemImage: "building.2", description: Text("Aucun site ne correspond à cet audit."))
                }
            }
        }
        .frame(minWidth: 1120, minHeight: 680)
        .task(id: "\(auditInputKey)|\(reloadToken)") {
            await runAudit(inputKey: auditInputKey)
        }
    }

    @ViewBuilder
    private var sourceVersionSummary: some View {
        let gtfs = library.catalog.activeVersion?.sourceTitle ?? "GTFS : aucune version active"
        let lineReferences = library.catalog.activeLineReferenceVersion?.sourceTitle ?? "Références IDFM : aucune version active"
        let geometries = library.catalog.activeGeometryVersion?.sourceTitle ?? "Tracés : aucune version active"
        let documents = library.catalog.activeLineDocumentVersion?.sourceTitle ?? "Documents : aucun index actif"
        Text("Sources actives — \(gtfs) · \(lineReferences) · \(geometries) · \(documents)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .textSelection(.enabled)
    }

    private func ratio(_ numerator: Int, _ denominator: Int, loaded: Bool) -> String {
        guard loaded else { return "Inconnu" }
        guard denominator > 0 else { return "Aucune ligne" }
        return "\(numerator)/\(denominator)"
    }

    private func serviceSummary(for record: DepotRegionalCoverageAuditRecord) -> String {
        guard let audit = record.serviceAudit else {
            return record.serviceAuditError == nil ? "En attente" : "Erreur"
        }
        guard audit.availability == .ready else { return audit.availability.summary }
        guard !audit.entries.isEmpty else { return "Aucune ligne" }
        return "\(audit.totalScheduledDepartures.formatted()) · \(audit.linesWithScheduledService) lignes"
    }

    private func runAudit(inputKey: String) async {
        records = []
        completedSiteCount = 0
        currentSiteName = "Chargement des catalogues…"
        sourceLoadingError = nil
        isAuditing = true
        defer {
            if !Task.isCancelled, inputKey == auditInputKey {
                currentSiteName = nil
                isAuditing = false
            }
        }

        await library.loadBusRoutes()
        await library.loadActiveLineReferences()
        await library.loadActiveRouteGeometries()
        await library.loadActiveLineDocuments()

        while library.isLoadingBusRoutes || library.isLoadingLineReferences
            || library.isLoadingRouteGeometries || library.isLoadingLineDocuments {
            guard !Task.isCancelled, inputKey == auditInputKey else { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        guard !Task.isCancelled, inputKey == auditInputKey else { return }

        let loadErrors = [
            library.busRoutesError.map { "GTFS : \($0)" },
            library.lineReferencesError.map { "Références IDFM : \($0)" },
            library.routeGeometriesError.map { "Tracés : \($0)" },
            library.lineDocumentsError.map { "Documents : \($0)" }
        ].compactMap { $0 }
        if !loadErrors.isEmpty {
            sourceLoadingError = "Une ou plusieurs sources sont indisponibles; leurs cellules restent inconnues. " + loadErrors.joined(separator: " · ")
        }

        let sites = sitesToAudit
        currentSiteName = "Lecture de l’index GTFS partagé…"
        var serviceAudits: [String: DepotGTFSServiceAudit] = [:]
        var sharedServiceAuditError: String?
        do {
            serviceAudits = try await library.depotGTFSServiceAudits(
                depotIDs: sites.map(\.id),
                serviceDate: serviceDate
            )
        } catch {
            sharedServiceAuditError = error.localizedDescription
        }
        guard !Task.isCancelled, inputKey == auditInputKey else { return }

        for (index, site) in sites.enumerated() {
            guard !Task.isCancelled, inputKey == auditInputKey else { return }
            currentSiteName = site.name

            let documentedRows = DepotLineRoster.rows.filter {
                $0.isVisible(atSite: site.id, on: serviceDate)
            }
            let candidateRows = library.lineReferenceVersionID == library.catalog.activeLineReferenceVersion?.id
                && library.lineReferencesError == nil
                ? DepotContractLineScope.candidateRows(
                    for: site,
                    references: library.lineReferences,
                    serviceDate: serviceDate,
                    excluding: documentedRows
                )
                : []
            let rows = documentedRows + candidateRows
            let confirmedLineIDs = Set(rows.compactMap { row -> String? in
                guard row.evidenceStatus(on: serviceDate) == .confirmed else { return nil }
                return row.canonicalLineID ?? row.id
            })
            let candidateLineIDs = Set(rows.compactMap { row -> String? in
                guard row.evidenceStatus(on: serviceDate) == .candidate else { return nil }
                return row.canonicalLineID ?? row.id
            })
            let otherCobEvidenceLineIDs = Set(rows.compactMap { row -> String? in
                switch row.evidenceStatus(on: serviceDate) {
                case .shared, .partial, .observedPool, .conflict:
                    row.canonicalLineID ?? row.id
                case .confirmed, .candidate, .unresolved, .planned:
                    nil
                }
            })
            let coverage = library.depotLineCoverage(
                depotID: site.id,
                serviceDate: serviceDate,
                operatedRouteIDs: operatedRouteIDsForDepot(site.id)
            )
            let serviceAudit = serviceAudits[site.id]
            let serviceAuditError = sharedServiceAuditError
            guard !Task.isCancelled, inputKey == auditInputKey else { return }

            records.append(DepotRegionalCoverageAuditRecord(
                site: site,
                coverage: coverage,
                serviceAudit: serviceAudit,
                serviceAuditError: serviceAuditError,
                confirmedCobLineCount: confirmedLineIDs.count,
                otherCobEvidenceLineCount: otherCobEvidenceLineIDs.count,
                candidateLineCount: candidateLineIDs.count
            ))
            completedSiteCount = index + 1
            await Task.yield()
        }
    }
}

private struct DepotLineRosterPreview: PreviewProvider {
    static var previews: some View {
        DepotLineRosterView(
            initialDepotID: "saint-maur",
            scenario: .bordsDeMarne,
            library: NetworkLibrary(),
            initialServiceDate: .now
        )
        .frame(width: 1120, height: 850)
    }
}
