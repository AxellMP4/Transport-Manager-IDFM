import SwiftUI

struct DepotLineCatalogCard: View {
    let row: DepotLineRosterRow
    let serviceDate: Date
    @ObservedObject var library: NetworkLibrary
    let onShowTimetable: (GTFSRouteSummary) -> Void
    let onPrepareAssignment: ((DepotLineRosterRow, GTFSRouteSummary) -> Void)?

    private var exactLineReferences: [NetworkLineReference] {
        let activeReferences = library.lineReferences.filter { $0.isActive(on: serviceDate) == true }
        if let canonicalLineID = row.canonicalLineID {
            return activeReferences.filter {
                LineReferenceMatcher.canonicalIdentifier($0.idLine) == canonicalLineID
            }
        }

        let normalizedName = row.line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let matches = activeReferences.filter {
            $0.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == normalizedName
        }
        let uniqueIDs = Set(matches.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) })
        guard uniqueIDs.count == 1, let id = uniqueIDs.first else { return [] }
        return matches.filter { LineReferenceMatcher.canonicalIdentifier($0.idLine) == id }
    }

    private var matchedReference: NetworkLineReference? {
        guard let first = exactLineReferences.first,
              Set(exactLineReferences.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) }).count == 1 else { return nil }
        return first
    }

    private var matchingRoutes: [GTFSRouteSummary] {
        guard let matchedReference else { return [] }
        let referenceID = LineReferenceMatcher.canonicalIdentifier(matchedReference.idLine)
        return library.busRoutes.filter {
            LineReferenceMatcher.canonicalIdentifier($0.routeID) == referenceID
        }.sorted {
            if $0.shortName != $1.shortName { return $0.shortName.localizedStandardCompare($1.shortName) == .orderedAscending }
            return $0.routeID.localizedStandardCompare($1.routeID) == .orderedAscending
        }
    }

    private var importedDocuments: [NetworkLineDocument] {
        guard let matchedReference else { return [] }
        let id = LineReferenceMatcher.canonicalIdentifier(matchedReference.idLine)
        return library.lineDocuments.filter {
            LineReferenceMatcher.canonicalIdentifier($0.idLine) == id
        }.sorted {
            if $0.documentType != $1.documentType { return $0.documentType.localizedStandardCompare($1.documentType) == .orderedAscending }
            return $0.documentName.localizedStandardCompare($1.documentName) == .orderedAscending
        }
    }

    private var importedDocumentsByURL: Set<String> {
        Set(importedDocuments.map(\.documentURL))
    }

    private var currentEvidenceStatus: DepotLineEvidenceStatus {
        row.evidenceStatus(on: serviceDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 11) {
                Text(row.line)
                    .font(.headline.monospaced())
                    .frame(minWidth: 54, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(row.category)
                            .font(.subheadline.weight(.semibold))
                        Label(currentEvidenceStatus.rawValue, systemImage: currentEvidenceStatus.systemImage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(tint)
                    }
                    Text(row.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if !row.claims.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("AFFIRMATIONS ET SOURCES")
                        .font(.caption.weight(.semibold))
                        .tracking(0.4)
                        .foregroundStyle(.secondary)
                    ForEach(row.claims) { claim in
                        claimCard(claim)
                    }
                }
            }

            if let matchedReference {
                Text("Référentiel IDFM · ID_Line \(matchedReference.idLine) · \(matchedReference.operatorName)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            } else if library.lineReferences.isEmpty {
                Label("Référentiel des lignes à importer pour relier cette ligne au GTFS", systemImage: "arrow.down.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if exactLineReferences.isEmpty {
                Label("Aucune correspondance exacte dans le référentiel IDFM chargé", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Label("Plusieurs ID_Line portent ce numéro : liaison GTFS laissée vide", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if !matchingRoutes.isEmpty {
                ForEach(matchingRoutes) { route in
                    routeRow(route)
                }
            } else if matchedReference != nil {
                Label("Aucune route GTFS exacte pour l’ID_Line \(matchedReference!.idLine)", systemImage: "bus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let curatedDocuments = row.publicDocuments.filter { !importedDocumentsByURL.contains($0.url.absoluteString) }
            if !curatedDocuments.isEmpty || !importedDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Documents publics")
                        .font(.caption.weight(.semibold))
                    ForEach(curatedDocuments) { document in
                        documentLink(document)
                    }
                    ForEach(importedDocuments) { document in
                        if let destination = document.destination {
                            Link(destination: destination) {
                                Label(document.documentName, systemImage: "arrow.up.right.square")
                                    .font(.caption)
                            }
                            Text("\(document.typeLabel) · catalogue IDFM importé · validité à consulter dans le document")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Label("Documents directs en attente de synchronisation du catalogue IDFM", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.quaternary, lineWidth: 1))
    }

    @ViewBuilder
    private func routeRow(_ route: GTFSRouteSummary) -> some View {
        HStack(alignment: .center, spacing: 9) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Variante GTFS · \(route.routeID)")
                    .font(.caption.weight(.semibold).monospaced())
                if let secondaryName = route.secondaryName {
                    Text(secondaryName).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Button {
                    onShowTimetable(route)
                } label: {
                    Label("Grille GTFS", systemImage: "tablecells")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(library.catalog.activeVersion == nil)

                if let onPrepareAssignment {
                    Button {
                        onPrepareAssignment(row, route)
                    } label: {
                        Label("Affecter…", systemImage: "checkmark.seal")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .help("Préremplit le registre du scénario ; vous devrez vérifier les sources et confirmer l’affectation.")
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func documentLink(_ document: DepotLineDocumentLink) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Link(destination: document.url) {
                Label(document.title, systemImage: documentSymbol(for: document.type))
                    .font(.caption)
            }
            Text("\(document.type) · \(document.validity)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let note = document.note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func documentSymbol(for type: String) -> String {
        if type.localizedCaseInsensitiveContains("plan") { return "map" }
        if type.localizedCaseInsensitiveContains("horaire") || type.localizedCaseInsensitiveContains("grille") { return "clock" }
        return "doc.text"
    }

    private func claimCard(_ claim: DepotLineRosterClaim) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(claim.kind.rawValue, systemImage: claim.kind.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let siteID = claim.siteID,
               let site = DepotLineRoster.selectableSites.first(where: { $0.id == siteID }) {
                Text("Site concerné · \(site.name)")
                    .font(.caption)
            }
            if let centerLabel = claim.centerLabel {
                Text("Centre cité · \(centerLabel)")
                    .font(.caption)
            }

            Label(claim.sourceDateSummary, systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            Label(claim.validitySummary, systemImage: claim.validFromKey == nil && claim.validThroughKey == nil ? "questionmark.circle" : "calendar.badge.clock")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let note = claim.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let sourceURL = claim.sourceURL {
                Link(destination: sourceURL) {
                    Label(claim.sourceTitle, systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
            } else {
                Text(claim.sourceTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .textSelection(.enabled)
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
    }

    private var tint: Color {
        switch currentEvidenceStatus {
        case .confirmed: .green
        case .shared, .partial, .observedPool: .blue
        case .candidate: .orange
        case .unresolved: .secondary
        case .conflict: .red
        case .planned: .purple
        }
    }
}

struct DepotLinesWorkspaceView: View {
    @ObservedObject var library: NetworkLibrary
    let depotID: String
    let serviceDate: Date
    @Binding var selectedLineID: String?
    var showsMapNavigation = true
    var operatedRouteIDs: Set<String> = []
    var isPreparingTimetable = false
    var onOperateLine: ((DepotLineRosterRow) -> Void)? = nil
    let onShowOnMap: (DepotLineRosterRow) -> Void

    @State private var searchText = ""
    @State private var timetableRoute: GTFSRouteSummary?

    private var selectedSite: DepotLineRosterSite? {
        DepotLineRoster.selectableSites.first { $0.id == depotID }
    }

    private var depotRows: [DepotLineRosterRow] {
        DepotLineRoster.rows.filter { $0.isVisible(atSite: depotID, on: serviceDate) }
    }

    private var lineRows: [DepotLineRosterRow] {
        let candidates = DepotContractLineScope.candidateRows(
            for: selectedSite,
            references: library.lineReferences,
            serviceDate: serviceDate,
            excluding: depotRows
        )
        let combined = (depotRows + candidates).sorted {
            $0.line.localizedStandardCompare($1.line) == .orderedAscending
        }
        guard !searchText.isEmpty else { return combined }
        return combined.filter { row in
            row.line.localizedCaseInsensitiveContains(searchText)
                || row.category.localizedCaseInsensitiveContains(searchText)
                || row.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var activeLineIDs: [String] { lineRows.map(\.id) }

    private var selectedLine: DepotLineRosterRow? {
        if let selectedLineID, let match = lineRows.first(where: { $0.id == selectedLineID }) {
            return match
        }
        return lineRows.first
    }

    private var selectedLineIDFM: String? {
        guard let selectedLine else { return nil }
        if let canonicalLineID = selectedLine.canonicalLineID {
            return LineReferenceMatcher.canonicalIdentifier(canonicalLineID)
        }
        let normalizedName = selectedLine.line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let matches = library.lineReferences.filter {
            $0.isActive(on: serviceDate) == true
                && $0.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == normalizedName
        }
        let ids = Set(matches.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) })
        return ids.count == 1 ? ids.first : nil
    }

    private var selectedRoutes: [GTFSRouteSummary] {
        guard let selectedLineIDFM else { return [] }
        return library.busRoutes.filter {
            LineReferenceMatcher.canonicalIdentifier($0.routeID) == selectedLineIDFM
        }.sorted { $0.routeID.localizedStandardCompare($1.routeID) == .orderedAscending }
    }

    private var isSelectedLineOperatedHere: Bool {
        !selectedRoutes.isEmpty && selectedRoutes.allSatisfy { operatedRouteIDs.contains($0.routeID) }
    }

    private var selectedDocuments: [NetworkLineDocument] {
        guard let selectedLineIDFM else { return [] }
        return library.lineDocuments.filter {
            LineReferenceMatcher.canonicalIdentifier($0.idLine) == selectedLineIDFM
        }.sorted {
            if $0.documentType != $1.documentType {
                return $0.documentType.localizedStandardCompare($1.documentType) == .orderedAscending
            }
            return $0.documentName.localizedStandardCompare($1.documentName) == .orderedAscending
        }
    }

    private var selectedEvidenceStatus: DepotLineEvidenceStatus? {
        selectedLine?.evidenceStatus(on: serviceDate)
    }

    private var selectedManifestEntries: [DepotLineRosterManifestEntry] {
        guard let selectedLine else { return [] }
        return DepotLineRosterManifestCatalog.state.entries.filter {
            $0.line.localizedCaseInsensitiveCompare(selectedLine.line) == .orderedSame
        }
    }

    var body: some View {
        Group {
            if lineRows.isEmpty {
                ContentUnavailableView {
                    Label("Aucune ligne recensée pour ce dépôt", systemImage: "bus")
                } description: {
                    Text("\(emptyStateDescription) Tu peux choisir un autre site dans l’onglet Dépôts.")
                }
            } else {
                HStack(spacing: 0) {
                    lineSidebar
                    Divider()
                    lineDetail
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: activeLineIDs) { _, ids in
            if !ids.contains(selectedLineID ?? "") {
                selectedLineID = ids.first
            }
        }
        .task {
            await library.loadBusRoutes()
            await library.loadActiveLineReferences()
            await library.loadActiveLineDocuments()
            await library.loadServiceCalendars()
        }
        .sheet(item: $timetableRoute) { route in
            if let version = library.catalog.activeVersion {
                GTFSRouteTimetableGridView(
                    library: library,
                    route: route,
                    version: version,
                    documents: library.documents(for: route),
                    initialServiceDate: serviceDate
                )
            } else {
                ContentUnavailableView(
                    "Horaires indisponibles",
                    systemImage: "clock.badge.exclamationmark",
                    description: Text("Aucune version GTFS n’est chargée pour cette date.")
                )
                .frame(minWidth: 600, minHeight: 280)
            }
        }
    }

    private var lineSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lignes de \(selectedSite?.name ?? "ce dépôt")")
                    .font(.headline)
                    .lineLimit(2)
                Text("\(lineRows.count) lignes · données du \(serviceDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            if let rosterNote = DepotContractLineScope.publicRosterNote(for: selectedSite, serviceDate: serviceDate) {
                Text(rosterNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 9)
            }

            TextField("Rechercher une ligne", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.bottom, 9)

            Divider()
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(lineRows) { row in
                        Button {
                            selectedLineID = row.id
                        } label: {
                            lineListRow(row)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 270)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func lineListRow(_ row: DepotLineRosterRow) -> some View {
        let isSelected = selectedLine?.id == row.id
        let status = row.evidenceStatus(on: serviceDate)
        return HStack(spacing: 10) {
            Text(row.line)
                .font(.system(size: 17, weight: .bold, design: .rounded).monospaced())
                .frame(minWidth: 48, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.category)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(status.rawValue)
                    .font(.caption2)
                    .foregroundStyle(evidenceColor(status))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.13) : Color.clear, in: RoundedRectangle(cornerRadius: 9))
        .contentShape(RoundedRectangle(cornerRadius: 9))
    }

    private var lineDetail: some View {
        ScrollView {
            if let selectedLine {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(selectedLine.line)
                                .font(.system(size: 34, weight: .bold, design: .rounded).monospaced())
                            Text(selectedLine.category)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let selectedEvidenceStatus {
                            Label(selectedEvidenceStatus.rawValue, systemImage: selectedEvidenceStatus.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(evidenceColor(selectedEvidenceStatus))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(evidenceColor(selectedEvidenceStatus).opacity(0.11), in: Capsule())
                        }
                    }

                    if selectedEvidenceStatus == .candidate,
                       selectedLine.note.hasPrefix("Le référentiel IDFM associe") {
                        Label("Ligne réelle du contrat · COB à confirmer", systemImage: "questionmark.circle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)
                        Text("Les horaires, tracés et plans sont ceux de la vraie ligne. IDFM rattache la ligne au contrat, mais les sources publiques ne précisent pas toujours quel dépôt l’exploite.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if !selectedLine.note.isEmpty {
                        Text(selectedLine.note)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !selectedManifestEntries.isEmpty {
                        manifestSection(selectedManifestEntries)
                    }

                    HStack(spacing: 9) {
                        Label("\(selectedRoutes.count) variante(s) GTFS", systemImage: "arrow.triangle.branch")
                        Spacer()
                        if onOperateLine != nil, !selectedRoutes.isEmpty {
                            if isSelectedLineOperatedHere {
                                Label("En exploitation ici", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.green)
                            } else {
                                Button {
                                    onOperateLine?(selectedLine)
                                } label: {
                                    Label("Affecter à ce dépôt", systemImage: "arrow.down.left.and.arrow.up.right")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isPreparingTimetable)
                                .help("Affecte toutes les variantes GTFS à ce dépôt. Une variante déjà affectée à un autre dépôt de la carrière en sera retirée.")
                            }
                        }
                        if showsMapNavigation {
                            Button {
                                onShowOnMap(selectedLine)
                            } label: {
                                Label("Voir sur la carte", systemImage: "map")
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Label("Consultation", systemImage: "eye")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)

                    if selectedRoutes.isEmpty {
                        Label("Aucune variante GTFS exacte trouvée pour cette ligne à la date choisie.", systemImage: "exclamationmark.circle")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    } else {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Horaires")
                                .font(.headline)
                            ForEach(selectedRoutes) { route in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(route.displayName)
                                            .font(.subheadline.weight(.semibold))
                                        Text("ID GTFS · \(route.routeID)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        timetableRoute = route
                                    } label: {
                                        Label("Grille horaire", systemImage: "tablecells")
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(library.catalog.activeVersion == nil)
                                }
                                .padding(11)
                                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    documentSection("Plans PDF", types: ["PLAN"])
                    documentSection("Fiches horaires PDF", types: ["HORAIRE", "FICHE HORAIRE"])
                    documentSection("Horaires en ligne · RATP", types: ["HORAIRE_WEB"], showsEmptyState: false)

                    DisclosureGroup("Rattachement et sources") {
                        VStack(alignment: .leading, spacing: 9) {
                            Text(selectedLine.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(selectedLine.claims) { claim in
                                VStack(alignment: .leading, spacing: 4) {
                                    Label(claim.kind.rawValue, systemImage: claim.kind.systemImage)
                                        .font(.caption.weight(.semibold))
                                    Text("\(claim.sourceDateSummary) · \(claim.validitySummary)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    if let sourceURL = claim.sourceURL {
                                        Link(claim.sourceTitle, destination: sourceURL)
                                            .font(.caption)
                                    }
                                }
                                .padding(9)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.subheadline.weight(.medium))
                }
                .padding(26)
                .frame(maxWidth: 850, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder
    private func documentSection(
        _ title: String,
        types: Set<String>,
        showsEmptyState: Bool = true
    ) -> some View {
        let curatedDocuments = (selectedLine?.publicDocuments ?? []).filter {
            types.contains($0.type.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        }
        let curatedURLs = Set(curatedDocuments.map { $0.url.absoluteString })
        let importedDocuments = selectedDocuments.filter {
            types.contains($0.documentType.trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
                && !curatedURLs.contains($0.documentURL)
        }

        if showsEmptyState || !curatedDocuments.isEmpty || !importedDocuments.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                if curatedDocuments.isEmpty && importedDocuments.isEmpty {
                    Text("Aucun document de ce type n’est relié à cette ligne dans le catalogue chargé.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(curatedDocuments) { document in
                        VStack(alignment: .leading, spacing: 3) {
                            Link(destination: document.url) {
                                Label(document.title, systemImage: "arrow.up.right.square")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.callout)
                            Text("\(document.type) · \(document.validity)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if let note = document.note {
                                Text(note)
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    ForEach(importedDocuments) { document in
                        if let destination = document.destination {
                            VStack(alignment: .leading, spacing: 3) {
                                Link(destination: destination) {
                                    Label(document.documentName, systemImage: "doc.text")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.callout)
                                Text("Catalogue IDFM · validité à consulter dans le PDF")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 11))
        }
    }

    @ViewBuilder
    private func manifestSection(_ entries: [DepotLineRosterManifestEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registre daté DSP 45")
                .font(.headline)
            Text("Les libellés de centre et les identifiants de site du registre décrivent le contexte de la ligne. Ils ne confirment pas à eux seuls son affectation opérationnelle à un COB.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(entry.category) · \(entry.serviceStartKey.map(String.init) ?? "date non précisée") – \(entry.serviceEndKey.map(String.init) ?? "en cours")")
                        .font(.caption.weight(.semibold))
                    Text(entry.evidenceStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link(entry.evidenceTitle, destination: entry.evidenceURL)
                        .font(.caption)

                    if let secondaryTitle = entry.secondaryEvidenceTitle {
                        if let secondaryURL = entry.secondaryEvidenceURL {
                            Link(secondaryTitle, destination: secondaryURL)
                                .font(.caption)
                        } else {
                            Text(secondaryTitle)
                                .font(.caption)
                        }
                    }
                    if !entry.sourceCenterLabel.isEmpty {
                        Label("Centre cité dans la source : \(entry.sourceCenterLabel)", systemImage: "building.2")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !entry.siteIDs.isEmpty {
                        Text("Sites référencés : \(entry.siteIDs.joined(separator: ", ")) · à vérifier séparément")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let announcedTitle = entry.announcedServiceTitle {
                        if let url = entry.announcedServiceURL {
                            Link("Annonce de service : \(announcedTitle)", destination: url)
                                .font(.caption)
                        } else {
                            Text("Annonce de service : \(announcedTitle)")
                                .font(.caption)
                        }
                    }
                    if !entry.documentValidity.isEmpty {
                        Text("Validité et état des documents : \(entry.documentValidity)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entry.documents) { document in
                        VStack(alignment: .leading, spacing: 2) {
                            Link(document.title ?? "\(document.kind) · ouvrir le document", destination: document.url)
                                .font(.caption)
                            if let validity = document.validity, !validity.isEmpty {
                                Text(validity)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Text(entry.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 11))
    }

    private var emptyStateDescription: String {
        if library.isLoadingLineReferences || library.isLoadingBusRoutes {
            return "Le catalogue des lignes réelles est en cours de chargement."
        }
        if let contractID = selectedSite?.idfmBusContractID {
            return "Aucune ligne IDFM active du contrat DSP \(contractID) ne correspond à cette date."
        }
        return "Ce site reste consultable. Les sources publiques chargées ne confirment pas de lignes pour ce dépôt."
    }

    private func evidenceColor(_ status: DepotLineEvidenceStatus) -> Color {
        switch status {
        case .confirmed: .green
        case .shared, .partial, .observedPool: .blue
        case .candidate: .orange
        case .unresolved: .secondary
        case .conflict: .red
        case .planned: .purple
        }
    }
}
