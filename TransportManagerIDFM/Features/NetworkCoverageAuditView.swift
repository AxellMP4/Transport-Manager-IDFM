import SwiftUI

struct NetworkCoverageAuditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: NetworkLibrary
    var showsCloseButton = true

    let scenarioID: String
    let idfmBusContractID: String
    let depots: [DepotReference]

    @State private var selectedDate: Date
    @State private var activeRouteIDs: Set<String>?
    @State private var loadedActivityKey: String?
    @State private var activityError: String?
    @State private var isLoadingActivity = false
    @State private var idfmToGTFSFilter = ""
    @State private var idfmToGTFSVisibleLimit = 100

    init(library: NetworkLibrary, scenario: ScenarioDefinition, initialDate: Date, showsCloseButton: Bool = true) {
        _library = ObservedObject(wrappedValue: library)
        self.showsCloseButton = showsCloseButton
        scenarioID = scenario.id
        idfmBusContractID = scenario.idfmBusContractID
        depots = scenario.referenceDepots
        _selectedDate = State(initialValue: initialDate)
    }

    private var activeVersion: NetworkVersion? { library.catalog.activeVersion }

    private var selectedDateRange: ClosedRange<Date>? {
        guard let version = activeVersion,
              let validFrom = version.validFrom,
              let validThrough = version.validThrough else { return nil }
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let firstDay = calendar.startOfDay(for: validFrom)
        let lastDay = calendar.startOfDay(for: validThrough)
        guard firstDay <= lastDay else { return nil }
        return firstDay...lastDay
    }

    private func clampedServiceDate(_ date: Date, to range: ClosedRange<Date>) -> Date {
        let day = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: date)
        return min(max(day, range.lowerBound), range.upperBound)
    }

    private var activityTaskID: String {
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dateKey = GTFSServiceDate.key(for: dayStart, timeZone: GTFSServiceDate.parisTimeZone) ?? -1
        return "\(activeVersion?.id ?? "aucune")|\(dateKey)|\(library.busRoutes.count)"
    }

    private var selectedDateCoverageMessage: String? {
        guard let version = activeVersion else { return "Aucune version GTFS active ; activité inconnue." }
        guard let validFrom = version.validFrom, let validThrough = version.validThrough else {
            return "La période de validité du GTFS n’est pas renseignée ; activité non évaluée."
        }
        guard
              let firstDate = GTFSServiceDate.key(
                for: validFrom,
                timeZone: TimeZone(secondsFromGMT: 0) ?? .current
              ),
              let lastDate = GTFSServiceDate.key(
                for: validThrough,
                timeZone: TimeZone(secondsFromGMT: 0) ?? .current
              ),
              let selectedDateKey = GTFSServiceDate.key(
                for: GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: selectedDate),
                timeZone: GTFSServiceDate.parisTimeZone
              ), firstDate <= lastDate else {
            return "La période de validité du GTFS ne peut pas être interprétée ; activité non évaluée."
        }
        guard (firstDate...lastDate).contains(selectedDateKey) else {
            return "Date hors de la période de validité du GTFS ; activité non évaluée."
        }
        return nil
    }

    private var selectedDateIsInVersion: Bool {
        selectedDateCoverageMessage == nil
    }

    private var loadedReferences: [NetworkLineReference]? {
        guard library.catalog.activeLineReferenceVersion != nil,
              library.lineReferenceImportState == .imported else { return nil }
        return library.lineReferences
    }

    private var loadedBusRoutes: [GTFSRouteSummary]? {
        guard activeVersion != nil,
              !library.isLoadingBusRoutes,
              library.busRoutesError == nil,
              !library.busRoutes.isEmpty else { return nil }
        return library.busRoutes
    }

    private var idfmToGTFSAudit: NetworkCoverageIDFMAudit {
        NetworkCoverageAudit.buildIDFMToGTFS(
            references: loadedReferences,
            routes: loadedBusRoutes,
            activeRouteIDs: loadedActivityRouteIDs,
            canConfirmNoCourses: activeVersion?.gtfsQuality?.containsFrequenciesFile == false,
            selectedDate: selectedDate
        )
    }

    private var loadedActivityRouteIDs: Set<String>? {
        guard selectedDateIsInVersion,
              !isLoadingActivity,
              loadedActivityKey == activityTaskID,
              activityError == nil else { return nil }
        return activeRouteIDs
    }

    private var filteredIDFMToGTFSEntries: [NetworkCoverageIDFMEntry] {
        let query = idfmToGTFSFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return idfmToGTFSAudit.entries }
        return idfmToGTFSAudit.entries.filter { entry in
            entry.reference.idLine.localizedCaseInsensitiveContains(query)
                || entry.reference.displayName.localizedCaseInsensitiveContains(query)
                || entry.reference.nameLine.localizedCaseInsensitiveContains(query)
                || entry.reference.networkName.localizedCaseInsensitiveContains(query)
                || entry.reference.operatorName.localizedCaseInsensitiveContains(query)
                || entry.matchingRoutes.contains {
                    $0.routeID.localizedCaseInsensitiveContains(query)
                        || $0.displayName.localizedCaseInsensitiveContains(query)
                }
        }
    }

    private var activeIDFMToGTFSEntries: [NetworkCoverageIDFMEntry] {
        filteredIDFMToGTFSEntries.filter { $0.serviceStatus == .active }
    }

    private var upcomingIDFMToGTFSEntries: [NetworkCoverageIDFMEntry] {
        filteredIDFMToGTFSEntries.filter { $0.serviceStatus == .upcoming }
    }

    private var filteredActiveGTFSRoutesWithoutIDFMReference: [GTFSRouteSummary]? {
        guard let routes = idfmToGTFSAudit.activeGTFSRoutesWithoutEligibleIDFMReference else { return nil }
        let query = idfmToGTFSFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return routes }
        return routes.filter {
            $0.routeID.localizedCaseInsensitiveContains(query)
                || $0.displayName.localizedCaseInsensitiveContains(query)
                || $0.longName.localizedCaseInsensitiveContains(query)
        }
    }

    private var activeGTFSReverseCoverageUnavailableReason: String {
        if loadedReferences == nil { return "Le référentiel IDFM n’est pas chargé." }
        if loadedBusRoutes == nil { return "Les routes de la version GTFS ne sont pas chargées." }
        if !selectedDateIsInVersion {
            return selectedDateCoverageMessage ?? "La date GTFS sélectionnée ne peut pas être évaluée."
        }
        if isLoadingActivity || loadedActivityKey != activityTaskID {
            return "L’activité GTFS de cette date est en cours de lecture."
        }
        if let activityError { return "L’activité GTFS n’a pas pu être lue : \(activityError)" }
        return "L’activité GTFS de cette date n’est pas disponible."
    }

    private var loadedDocuments: [NetworkLineDocument]? {
        guard library.catalog.activeLineDocumentVersion != nil,
              library.lineDocumentImportState == .imported else { return nil }
        return library.lineDocuments
    }

    private var entries: [NetworkCoverageAuditEntry] {
        NetworkCoverageAudit.build(
            routes: library.busRoutes,
            activeRouteIDs: loadedActivityKey == activityTaskID ? activeRouteIDs : nil,
            references: loadedReferences,
            documents: loadedDocuments,
            assignments: library.depotAssignments,
            contracts: library.contractFeatures,
            scenarioID: scenarioID,
            scenarioContractID: idfmBusContractID,
            depots: depots,
            activeGTFSVersionID: library.catalog.activeVersion?.id,
            activeContractVersionID: library.catalog.activeContractVersion?.id
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audit réseau")
                        .font(.title2.weight(.semibold))
                    Text("Routes, référentiel, documents et rattachements enregistrés")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 16)
                DatePicker(
                    "Date de service",
                    selection: $selectedDate,
                    in: selectedDateRange ?? Date.distantPast...Date.distantFuture,
                    displayedComponents: .date
                )
                    .datePickerStyle(.field)
                    .frame(maxWidth: 250)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sourceSummary

                    GTFSTripQualityAuditSection(version: activeVersion, routes: library.busRoutes)

                    idfmToGTFSSection

                    if library.busRoutes.isEmpty {
                        ContentUnavailableView(
                            "Aucune route GTFS chargée",
                            systemImage: "bus",
                            description: Text(library.catalog.activeVersion == nil
                                ? "Importez une archive GTFS pour établir la liste des routes."
                                : "Le catalogue de cette version ne contient pas de route bus chargée.")
                        )
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(entries) { entry in
                                NetworkCoverageRouteRow(entry: entry, depots: depots)
                            }
                        }
                    }

                    Text("Le GTFS décrit les routes et départs de son archive. Les correspondances, documents et rattachements sont affichés séparément. Un départ, un nom, un contour ou l’absence d’un enregistrement ne prouve pas l’appartenance à un contrat ni l’affectation à un COB.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .frame(minWidth: 860, minHeight: 620)
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .task {
            await library.seedBundledIDFMSnapshotsIfNeeded()
            await library.loadBusRoutes()
            await library.loadActiveLineReferences()
            await library.loadActiveLineDocuments()
            await library.loadActiveContracts()
            if let selectedDateRange {
                selectedDate = clampedServiceDate(selectedDate, to: selectedDateRange)
            }
        }
        .onChange(of: selectedDateRange) { _, newRange in
            guard let newRange else { return }
            selectedDate = clampedServiceDate(selectedDate, to: newRange)
        }
        .onChange(of: selectedDate) { _, _ in
            idfmToGTFSVisibleLimit = 100
        }
        .onChange(of: idfmToGTFSFilter) { _, _ in
            idfmToGTFSVisibleLimit = 100
        }
        .task(id: activityTaskID) {
            await refreshActivity(for: activityTaskID)
        }
    }

    @ViewBuilder
    private var sourceSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let version = activeVersion {
                Label("GTFS actif · \(version.id)", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.caption.weight(.medium))
                if !selectedDateIsInVersion {
                    Label(selectedDateCoverageMessage ?? "Activité inconnue.", systemImage: "calendar.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if isLoadingActivity || loadedActivityKey != activityTaskID {
                    ProgressView("Lecture des départs du \(selectedDate.formatted(date: .abbreviated, time: .omitted))…")
                        .font(.caption)
                } else if let activityError {
                    Text("Activité GTFS non évaluée : \(activityError)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let activeRouteIDs {
                    Text("\(activeRouteIDs.count) route(s) avec au moins un départ dans le GTFS ce jour-là · \(library.busRoutes.count) route(s) cataloguée(s).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Aucune version GTFS active · activité inconnue", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                sourceState(
                    title: "Référentiel IDFM",
                    versionID: library.catalog.activeLineReferenceVersion?.id,
                    isLoaded: loadedReferences != nil,
                    count: loadedReferences?.count,
                    isLoading: library.isLoadingLineReferences,
                    error: library.lineReferencesError
                )
                sourceState(
                    title: "Plans et fiches horaires",
                    versionID: library.catalog.activeLineDocumentVersion?.id,
                    isLoaded: loadedDocuments != nil,
                    count: loadedDocuments?.count,
                    isLoading: library.isLoadingLineDocuments,
                    error: library.lineDocumentsError
                )
                Label("Rattachements enregistrés · \(library.depotAssignments.filter { $0.scenarioID == scenarioID }.count)", systemImage: "pin")
                    .font(.caption)
            }

            contractRoster
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var idfmToGTFSSection: some View {
        let audit = idfmToGTFSAudit
        let activeCount = audit.entries.filter { $0.serviceStatus == .active }.count
        let upcomingCount = audit.entries.filter { $0.serviceStatus == .upcoming }.count
        let uniqueCount = audit.entries.filter { $0.routeStatus == .unique }.count
        let absentCount = audit.entries.filter { $0.routeStatus == .absent }.count
        let ambiguousCount = audit.entries.filter { $0.routeStatus == .ambiguous }.count
        let unavailableCount = audit.entries.filter { $0.routeStatus == .unavailable }.count
        let reverseCoverageCount = audit.activeGTFSRoutesWithoutEligibleIDFMReference?.count

        DisclosureGroup {
            VStack(alignment: .leading, spacing: 9) {
                Text("Références IDFM de mode bus au statut source « active » ou « prochainement active », dont la validité couvre la date sélectionnée. Les statuts sont présentés séparément. La correspondance est un identifiant canonique exact ; elle ne déduit ni contrat ni COB.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !audit.referencesAvailable {
                    Label(
                        library.isLoadingLineReferences ? "Chargement du référentiel IDFM…" : "Référentiel IDFM non chargé ; l’inventaire actif et le rapprochement sont indisponibles.",
                        systemImage: library.isLoadingLineReferences ? "arrow.triangle.2.circlepath" : "questionmark.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                } else {
                    HStack(spacing: 12) {
                        Text("Active(s) · \(activeCount)")
                        Text("Statut « prochainement active » · \(upcomingCount)")
                        if audit.routesAvailable {
                            Text("GTFS unique · \(uniqueCount)")
                            Text("absente · \(absentCount)")
                            Text("ambiguë · \(ambiguousCount)")
                        } else {
                            Text("GTFS non chargé · \(unavailableCount) rapprochement(s) indisponible(s)")
                                .foregroundStyle(.orange)
                        }
                        if let reverseCoverageCount {
                            Text("Routes GTFS actives sans référence IDFM admissible · \(reverseCoverageCount)")
                        } else {
                            Text("Routes GTFS actives à qualifier · non évaluées")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                    if let unknownDateCount = audit.unknownDateReferenceCount, unknownDateCount > 0 {
                        Text("\(unknownDateCount) référence(s) de bus au statut « active » ou « prochainement active » ont une date de validité manquante ou illisible et sont exclues de la liste.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let notYetValidCount = audit.notYetValidReferenceCount, notYetValidCount > 0 {
                        Text("\(notYetValidCount) référence(s) dont la validité commence après la date sélectionnée ne sont pas encore incluses.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let excludedCount = audit.excludedOutsideStatusScopeCount, excludedCount > 0 {
                        Text("\(excludedCount) autres enregistrements sont hors de cet audit car leur mode n’est pas bus ou leur statut source n’est ni « active » ni « prochainement active ».")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if audit.entries.isEmpty {
                        Text("Aucune référence bus de statut « active » ou « prochainement active » dont la validité couvre cette date.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        TextField("Filtrer par ID_Line, ligne, réseau, exploitant ou route GTFS", text: $idfmToGTFSFilter)
                            .textFieldStyle(.roundedBorder)

                        let visibleActiveEntries = Array(activeIDFMToGTFSEntries.prefix(idfmToGTFSVisibleLimit))
                        let visibleUpcomingEntries = Array(upcomingIDFMToGTFSEntries.prefix(idfmToGTFSVisibleLimit))
                        let visibleCount = visibleActiveEntries.count + visibleUpcomingEntries.count
                        if visibleCount == 0 {
                            Text("Aucun résultat pour ce filtre.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                if !activeIDFMToGTFSEntries.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Lignes actives à cette date · \(activeIDFMToGTFSEntries.count)")
                                            .font(.caption.weight(.semibold))
                                        LazyVStack(spacing: 5) {
                                            ForEach(visibleActiveEntries) { entry in
                                                NetworkCoverageIDFMToGTFSRow(
                                                    entry: entry,
                                                    serviceDate: selectedDate,
                                                    gtfsVersion: activeVersion,
                                                    isServiceActivityLoaded: loadedActivityRouteIDs != nil
                                                )
                                            }
                                        }
                                    }
                                }

                                if !upcomingIDFMToGTFSEntries.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Statut IDFM « prochainement active » · validité atteinte · \(upcomingIDFMToGTFSEntries.count)")
                                            .font(.caption.weight(.semibold))
                                        LazyVStack(spacing: 5) {
                                            ForEach(visibleUpcomingEntries) { entry in
                                                NetworkCoverageIDFMToGTFSRow(
                                                    entry: entry,
                                                    serviceDate: selectedDate,
                                                    gtfsVersion: activeVersion,
                                                    isServiceActivityLoaded: loadedActivityRouteIDs != nil
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            if filteredIDFMToGTFSEntries.count > visibleCount {
                                HStack {
                                    Text("Affichage de \(visibleCount) sur \(filteredIDFMToGTFSEntries.count) résultats.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Afficher 100 de plus") {
                                        idfmToGTFSVisibleLimit += 100
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                    }
                }

                activeGTFSRoutesWithoutIDFMReferenceSection

                if !audit.routesAvailable {
                    Text(library.busRoutesError.map { "Erreur de lecture du GTFS : \($0)" }
                        ?? (library.isLoadingBusRoutes ? "Les routes GTFS sont en cours de chargement." : "Importez une version GTFS et chargez ses routes pour calculer le rapprochement."))
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)
        } label: {
            Label(
                "IDFM → routes GTFS · \(audit.referencesAvailable ? "\(audit.entries.count) références à la date" : "référentiel indisponible")",
                systemImage: "arrow.left.arrow.right"
            )
            .font(.caption.weight(.semibold))
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var contractRoster: some View {
        let normalizedContractID = canonicalContractID(idfmBusContractID)
        let contractLines = (loadedReferences ?? [])
            .filter { canonicalContractID($0.busContractID) == normalizedContractID }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        let contour = library.contractFeatures.first {
            canonicalContractID($0.contractID) == normalizedContractID
        }

        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Text("IDFM documente ID_Bus_Contrat comme identifiant de contrat bus pour les DSP de 2e génération ; un champ vide ne prouve pas qu’une ligne est hors contrat. Le rapprochement utilise ID_Bus_Contrat = id_contrat. objectid identifie une entité GeoJSON et ne sert pas de clé contractuelle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if loadedReferences == nil {
                    Text("Importez ou téléchargez le référentiel IDFM pour afficher les lignes portant ce contrat.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if contractLines.isEmpty {
                    Text("Aucune ligne ne porte l’identifiant de contrat \(idfmBusContractID) dans cette version du référentiel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(contractLines) { reference in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(reference.displayName)
                                    .font(.caption.weight(.semibold))
                                Spacer(minLength: 8)
                                Text(reference.status.isEmpty ? "statut non renseigné" : reference.status)
                                    .font(.caption2)
                                    .foregroundStyle(reference.status.localizedCaseInsensitiveContains("prochain") ? .orange : .secondary)
                            }
                            Text("\(reference.idLine) · valable du \(reference.validFrom.isEmpty ? "inconnu" : reference.validFrom) au \(reference.validTo.isEmpty ? "sans date de fin" : reference.validTo)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                            if !reference.operatorName.isEmpty || !reference.networkName.isEmpty {
                                Text([reference.operatorName, reference.networkName].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 5)
                        if reference.id != contractLines.last?.id { Divider() }
                    }
                }

                if let version = library.catalog.activeLineReferenceVersion {
                    Text("Référentiel IDFM · importé le \(version.importedAt.formatted(date: .abbreviated, time: .shortened)) · traitement source \(version.sourceDataProcessedAt?.formatted(date: .abbreviated, time: .shortened) ?? "non disponible") · SHA-256 \(version.sha256)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }

                if let contour {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Contour IDFM · \(contour.displayName) · id_contrat \(contour.contractID ?? "inconnu") · objectid (identifiant de feature) \(contour.sourceObjectID ?? "inconnu")")
                            .font(.caption)
                        if let version = library.catalog.activeContractVersion {
                            Text("Importé le \(version.importedAt.formatted(date: .abbreviated, time: .shortened)) · traitement source \(version.sourceDataProcessedAt?.formatted(date: .abbreviated, time: .shortened) ?? "non disponible") · SHA-256 \(version.sha256)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                    }
                } else if library.catalog.activeContractVersion == nil {
                    Text("Aucun contour de contrat importé ; le roster de lignes reste consultable sans contour.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Aucun contour avec id_contrat \(idfmBusContractID) dans la version chargée.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Link("Référentiel officiel des lignes IDFM", destination: URL(string: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/referentiel-des-lignes")!)
                    .font(.caption)
                Link("Contours officiels des contrats IDFM", destination: URL(string: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/contours-des-contrats")!)
                    .font(.caption)
            }
            .padding(.top, 8)
        } label: {
            Label("Contrat bus IDFM \(idfmBusContractID) · \(loadedReferences == nil ? "roster non chargé" : "\(contractLines.count) lignes du référentiel")", systemImage: "list.bullet.rectangle")
                .font(.caption.weight(.semibold))
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func canonicalContractID(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.allSatisfy(\.isNumber), let number = Int(trimmed) { return String(number) }
        return trimmed.uppercased()
    }

    private func sourceState(
        title: String,
        versionID: String?,
        isLoaded: Bool,
        count: Int?,
        isLoading: Bool,
        error: String?
    ) -> some View {
        let state: String
        if isLoading {
            state = "chargement…"
        } else if let error {
            state = "erreur · \(error)"
        } else if let versionID, isLoaded {
            state = "\(versionID) · \(count ?? 0)"
        } else if let versionID {
            state = "\(versionID) · non chargé"
        } else {
            state = "non importé"
        }
        return Label("\(title) · \(state)", systemImage: "doc.text.magnifyingglass")
            .font(.caption)
            .foregroundStyle(isLoaded ? Color.secondary : Color.orange)
            .lineLimit(2)
    }

    private func refreshActivity(for taskID: String) async {
        guard let version = activeVersion,
              selectedDateIsInVersion,
              !library.busRoutes.isEmpty else {
            activeRouteIDs = nil
            loadedActivityKey = taskID
            activityError = nil
            isLoadingActivity = false
            return
        }

        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let serviceDayStart = calendar.startOfDay(for: selectedDate)
        guard let serviceDayEnd = calendar.date(byAdding: .day, value: 1, to: serviceDayStart) else {
            activeRouteIDs = nil
            loadedActivityKey = taskID
            activityError = "La date de service sélectionnée est invalide."
            isLoadingActivity = false
            return
        }

        isLoadingActivity = true
        activityError = nil
        defer {
            if taskID == activityTaskID { isLoadingActivity = false }
        }

        do {
            let departures = try await library.loadScheduledDepartures(
                gtfsVersionID: version.id,
                routeIDs: Set(library.busRoutes.map(\.routeID)),
                from: serviceDayStart,
                through: serviceDayEnd
            )
            guard !Task.isCancelled, taskID == activityTaskID else { return }
            activeRouteIDs = Set(departures.map(\.routeID))
            loadedActivityKey = taskID
            activityError = nil
        } catch {
            guard taskID == activityTaskID else { return }
            activeRouteIDs = nil
            loadedActivityKey = taskID
            activityError = error.localizedDescription
        }
    }

    @ViewBuilder
    private var activeGTFSRoutesWithoutIDFMReferenceSection: some View {
        let audit = idfmToGTFSAudit
        VStack(alignment: .leading, spacing: 7) {
            Text("Routes GTFS avec départs sans référence IDFM bus admissible · \(audit.activeGTFSRoutesWithoutEligibleIDFMReference.map { String($0.count) } ?? "—")")
                .font(.caption.weight(.semibold))
            Text("Liste inverse : routes ayant au moins un départ GTFS à la date choisie sans ID_Line bus de statut actif ou prochainement actif et valide à cette date. Rapprochement par identifiant canonique uniquement ; aucune appartenance contractuelle ni affectation COB n’est déduite.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let routes = filteredActiveGTFSRoutesWithoutIDFMReference {
                if audit.entries.isEmpty {
                    TextField("Filtrer les routes GTFS à qualifier", text: $idfmToGTFSFilter)
                        .textFieldStyle(.roundedBorder)
                }
                if audit.activeGTFSRoutesWithoutEligibleIDFMReference?.isEmpty == true {
                    Text("Toutes les routes avec départs GTFS disposent d’une référence IDFM bus admissible dans le référentiel chargé à cette date.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if routes.isEmpty {
                    Text("Aucune route à qualifier ne correspond à ce filtre.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 5) {
                        ForEach(Array(routes.prefix(idfmToGTFSVisibleLimit))) { route in
                            NetworkCoverageGTFSRouteWithoutIDFMReferenceRow(
                                route: route,
                                serviceDate: selectedDate,
                                gtfsVersion: activeVersion
                            )
                        }
                    }

                    if routes.count > idfmToGTFSVisibleLimit {
                        HStack {
                            Text("Affichage de \(idfmToGTFSVisibleLimit) sur \(routes.count) routes.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Afficher 100 de plus") {
                                idfmToGTFSVisibleLimit += 100
                            }
                            .font(.caption)
                        }
                    }
                }
            } else {
                Label(activeGTFSReverseCoverageUnavailableReason, systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct NetworkCoverageGTFSRouteWithoutIDFMReferenceRow: View {
    let route: GTFSRouteSummary
    let serviceDate: Date
    let gtfsVersion: NetworkVersion?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(route.displayName)
                        .font(.caption.weight(.semibold))
                    Text(route.routeID)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text("à qualifier")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                }
                if let secondaryName = route.secondaryName {
                    Text(secondaryName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("Départs GTFS le \(serviceDate.formatted(date: .abbreviated, time: .omitted)) · \(gtfsVersion?.id ?? "version inconnue")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))
    }
}

private struct NetworkCoverageIDFMToGTFSRow: View {
    let entry: NetworkCoverageIDFMEntry
    let serviceDate: Date
    let gtfsVersion: NetworkVersion?
    let isServiceActivityLoaded: Bool

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 4) {
                Text("ID_Line · \(entry.reference.idLine) · \(entry.reference.displayName)")
                    .font(.caption.monospaced())
                Text("Mode · \(entry.reference.transportMode) · statut · \(entry.reference.status)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Réseau · \(referenceValue(entry.reference.networkName))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Exploitant · \(referenceValue(entry.reference.operatorName))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Validité source · du \(entry.reference.validFrom.isEmpty ? "inconnu" : entry.reference.validFrom) au \(entry.reference.validTo.isEmpty ? "sans date de fin renseignée" : entry.reference.validTo)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Service GTFS du \(serviceDate.formatted(date: .long, time: .omitted)) · \(serviceActivityTitle)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(serviceActivityColor)
                if let serviceActivityExplanation {
                    Text(serviceActivityExplanation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let gtfsVersion {
                    Text("Version \(gtfsVersion.id) · validité du \(gtfsVersion.validFrom?.formatted(date: .abbreviated, time: .omitted) ?? "inconnue") au \(gtfsVersion.validThrough?.formatted(date: .abbreviated, time: .omitted) ?? "inconnue")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                switch entry.routeStatus {
                case .unavailable:
                    Text("Aucune conclusion : les routes GTFS ne sont pas chargées.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                case .absent:
                    if entry.serviceStatus == .upcoming {
                        Text("La référence IDFM est marquée « prochainement active » et valable à partir du \(entry.reference.validFrom). La version GTFS chargée ne contient aucune route bus pour l’ID_Line canonique \(entry.reference.idLine) ; le service du jour reste non évaluable et aucun horaire n’est déduit.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Aucune route bus GTFS ne possède cet ID_Line canonique dans la version chargée ; le service du jour reste non évaluable.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                case .unique:
                    if let route = entry.matchingRoutes.first {
                        Text("Route GTFS unique · \(route.routeID) · \(route.displayName)")
                            .font(.caption)
                    }
                case .ambiguous:
                    Text("\(entry.routeMatchCount) routes bus GTFS ont cet ID_Line canonique : \(entry.matchingRoutes.map(\.routeID).joined(separator: ", ")). Le service du jour n’est pas attribué à une route unique.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.top, 5)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.reference.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(entry.reference.idLine)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if entry.serviceStatus == .upcoming {
                        Text("prévue · validité atteinte")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    statusLabel
                }
                serviceActivityLabel
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))
    }

    private func referenceValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "non renseigné" : trimmed
    }

    private var statusLabel: some View {
        let title: String
        let color: Color
        let symbol: String
        switch entry.routeStatus {
        case .unavailable:
            title = "GTFS indisponible"
            color = .orange
            symbol = "questionmark.circle"
        case .absent:
            title = "route absente"
            color = .orange
            symbol = "minus.circle"
        case .unique:
            title = "route unique"
            color = .green
            symbol = "checkmark.circle"
        case .ambiguous:
            title = "\(entry.routeMatchCount) routes ambiguës"
            color = .orange
            symbol = "exclamationmark.circle"
        }
        return Label(title, systemImage: symbol)
            .font(.caption2)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var serviceActivityTitle: String {
        switch entry.serviceActivityStatus {
        case .departuresPresent: "départs GTFS présents"
        case .noCourses: "aucune course ce jour-là dans le GTFS"
        case .notEvaluable: "service non évaluable"
        }
    }

    private var serviceActivityColor: Color {
        switch entry.serviceActivityStatus {
        case .departuresPresent: .green
        case .noCourses: .orange
        case .notEvaluable: .secondary
        }
    }

    private var serviceActivityLabel: some View {
        let symbol: String
        switch entry.serviceActivityStatus {
        case .departuresPresent: symbol = "checkmark.circle"
        case .noCourses: symbol = "calendar.badge.exclamationmark"
        case .notEvaluable: symbol = "questionmark.circle"
        }
        return Label(serviceActivityTitle, systemImage: symbol)
            .font(.caption2)
            .foregroundStyle(serviceActivityColor)
            .lineLimit(1)
    }

    private var serviceActivityExplanation: String? {
        switch entry.serviceActivityStatus {
        case .departuresPresent:
            return "Au moins un départ est indexé pour cette route unique à cette date. Cet audit ne génère pas d’horaire."
        case .noCourses:
            return "La route est présente dans le catalogue, mais aucun départ n’est trouvé pour cette date dans cette version. Le flux ne contient pas de fichier frequencies.txt non indexé."
        case .notEvaluable:
            guard entry.routeStatus == .unique else { return nil }
            if !isServiceActivityLoaded {
                return "La route est trouvée, mais l’activité n’est pas évaluée : date hors validité du GTFS, lecture en cours ou erreur d’index."
            }
            return "Aucun départ n’est indexé, mais l’absence de service n’est pas concluante : cette version ne confirme pas que les fréquences sont absentes ou prises en charge."
        }
    }
}

private struct NetworkCoverageRouteRow: View {
    let entry: NetworkCoverageAuditEntry
    let depots: [DepotReference]

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                referenceDetails
                documentDetails
                assignmentDetails
            }
            .padding(.top, 8)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.route.displayName)
                        .font(.headline)
                    Spacer(minLength: 12)
                    activityLabel
                }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("GTFS · \(entry.route.routeID)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    referenceBadge
                    documentBadge
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary, lineWidth: 1))
    }

    private var activityLabel: some View {
        let title: String
        let color: Color
        switch entry.isActiveOnDate {
        case true:
            title = "Départ GTFS ce jour"
            color = .green
        case false:
            title = "Aucun départ GTFS ce jour"
            color = .secondary
        case nil:
            title = "Activité inconnue"
            color = .orange
        }
        return Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
    }

    private var referenceBadge: some View {
        let title: String
        switch entry.referenceStatus {
        case .unavailable: title = "ID_Line non chargé"
        case .absent: title = "ID_Line absent"
        case .unique: title = "ID_Line unique"
        case .ambiguous: title = "ID_Line ambigu · \(entry.referenceMatchCount)"
        }
        return Label(title, systemImage: entry.referenceStatus == .unique ? "checkmark.circle" : "questionmark.circle")
            .font(.caption)
            .foregroundStyle(entry.referenceStatus == .unique ? Color.secondary : Color.orange)
    }

    private var documentBadge: some View {
        let title: String
        switch entry.documentStatus {
        case .unavailable: title = "documents non chargés"
        case .blockedByReference: title = "documents non rapprochés"
        case .none: title = "0 document exact"
        case .available: title = "\(entry.documents.count) document(s)"
        }
        return Label(title, systemImage: "doc.text")
            .font(.caption)
            .foregroundStyle(entry.documentStatus == .available ? Color.secondary : Color.orange)
    }

    @ViewBuilder
    private var referenceDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Référentiel IDFM")
                .font(.subheadline.weight(.semibold))
            switch entry.referenceStatus {
            case .unavailable:
                Text("Le référentiel actif n’est pas chargé ; la correspondance reste inconnue.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .absent:
                Text("Aucune correspondance trouvée par identifiant canonique exact. Cela ne signifie pas que la route est hors contrat.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .unique:
                if let reference = entry.reference {
                    Text("\(reference.idLine) · \(reference.displayName)")
                        .font(.caption.monospaced())
                    if !reference.operatorName.isEmpty || !reference.networkName.isEmpty {
                        Text([reference.operatorName, reference.networkName].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            case .ambiguous:
                Text("\(entry.referenceMatchCount) lignes du référentiel ont le même identifiant canonique. Aucun rapprochement unique n’est retenu.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var documentDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Plans et fiches horaires")
                .font(.subheadline.weight(.semibold))
            switch entry.documentStatus {
            case .unavailable:
                Text("Le CSV de documents ou le référentiel IDFM n’est pas chargé.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .blockedByReference:
                Text("Aucun document n’est associé par nom. Il faut d’abord une correspondance ID_Line unique.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .none:
                Text("Aucun document lié à cet ID_Line exact dans la version chargée.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .available:
                ForEach(entry.documents) { document in
                    HStack(spacing: 6) {
                        Text(document.typeLabel)
                            .foregroundStyle(.secondary)
                        if let destination = document.destination {
                            Link(document.documentName, destination: destination)
                        } else {
                            Text(document.documentName)
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var assignmentDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rattachements de dépôt enregistrés")
                .font(.subheadline.weight(.semibold))
            ForEach(depots) { depot in
                let depotAssignments = entry.assignments.filter { $0.assignment.depotID == depot.id }
                VStack(alignment: .leading, spacing: 6) {
                    Text(depot.name)
                        .font(.caption.weight(.semibold))
                    if depotAssignments.isEmpty {
                        Text("Aucune affectation enregistrée · à documenter. L’absence d’enregistrement ne signifie pas hors lot.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(depotAssignments) { item in
                            NetworkCoverageAssignmentView(item: item)
                        }
                    }
                }
                .padding(.leading, 8)
            }

            let otherAssignments = entry.assignments.filter { item in
                !depots.contains(where: { $0.id == item.assignment.depotID })
            }
            if !otherAssignments.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Autres COB saisis")
                        .font(.caption.weight(.semibold))
                    ForEach(otherAssignments) { item in
                        NetworkCoverageAssignmentView(item: item)
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}

private struct NetworkCoverageAssignmentView: View {
    let item: NetworkCoverageAssignment

    private var assignment: DepotLineAssignment { item.assignment }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(item.depotName) · contrat saisi : \(assignment.contractID)\(item.contractName.map { " · \($0)" } ?? "")")
                .font(.caption)
            HStack(spacing: 6) {
                Text(assignment.evidenceStatus.title)
                Text("·")
                Text(versionScopeTitle)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text("Preuve · \(assignment.evidenceDateSummary) · \(assignment.evidenceTitle)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Versions saisies · GTFS : \(assignment.gtfsVersionID) · contrat : \(assignment.contractVersionID)")
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
            HStack(spacing: 8) {
                if let url = URL(string: assignment.evidenceURL) {
                    Link("Source principale", destination: url)
                }
                ForEach(Array(assignment.additionalEvidenceURLs.enumerated()), id: \.offset) { index, value in
                    if let url = URL(string: value) {
                        Link("Source \(index + 2)", destination: url)
                    }
                }
            }
            .font(.caption2)
            if !assignment.notes.isEmpty {
                Text(assignment.notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 7))
    }

    private var versionScopeTitle: String {
        switch item.versionStatus {
        case .unavailable: "versions actives inconnues"
        case .activeVersions: "versions GTFS et contrat actives"
        case .differentVersions: "autres versions · enregistrement conservé"
        }
    }
}

private struct GTFSTripQualityAuditSection: View {
    let version: NetworkVersion?
    let routes: [GTFSRouteSummary]

    @State private var isExpanded = false
    @State private var selectedIssueKind: GTFSImportTripIssueKind?
    @State private var query = ""
    @State private var visibleIssueLimit = 100

    private var quality: GTFSImportQuality? { version?.gtfsQuality }

    private var filteredIssues: [GTFSImportTripIssue] {
        guard let issues = quality?.tripIssues else { return [] }
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return issues.filter { issue in
            if let selectedIssueKind, !issue.issueKinds.contains(selectedIssueKind) { return false }
            guard !search.isEmpty else { return true }
            let stopIDs = (issue.stopIDsWithoutCoordinates ?? []) + (issue.stopIDsNotMatchedToShape ?? [])
            return issue.routeID.localizedCaseInsensitiveContains(search)
                || issue.tripID.localizedCaseInsensitiveContains(search)
                || (issue.shapeID ?? "").localizedCaseInsensitiveContains(search)
                || stopIDs.contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if let quality {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        GTFSQualityMetricRow(title: "Courses sans référence de forme", value: quality.tripsWithoutShapeReference)
                        GTFSQualityMetricRow(title: "Courses avec forme absente ou invalide", value: quality.tripsWithUnavailableShape)
                        GTFSQualityMetricRow(title: "Formes invalides rejetées à l’import", value: quality.invalidShapeCount)
                        GTFSQualityMetricRow(title: "Courses avec arrêts non projetables", value: quality.tripsWithUnmatchedShapeStops ?? 0)
                        GTFSQualityMetricRow(title: "Courses avec arrêts sans coordonnées", value: quality.tripsWithMissingStopCoordinates)
                        GTFSQualityMetricRow(title: "Lignes stop_times sans stop_id", value: quality.missingStopIDRowCount ?? 0)
                    }

                    if let invalidShapeIDs = quality.invalidShapeIDs, !invalidShapeIDs.isEmpty {
                        Text("Identifiants des formes rejetées · \(invalidShapeIDs.prefix(20).joined(separator: ", "))\(invalidShapeIDs.count > 20 ? " · +\(invalidShapeIDs.count - 20)" : "")")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    Text("Ces indicateurs sont des diagnostics structurels calculés à l’import. Une forme absente, invalide ou un arrêt non projetable doit être examiné avec le tracé et la carte; ce résultat ne prouve pas à lui seul que l’itinéraire réel est erroné.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let issues = quality.tripIssues {
                        if issues.isEmpty {
                            Text("Aucune course ne comporte d’anomalie enregistrée pour cette version.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            issueList(issues)
                        }
                    } else {
                        Label("Cette archive précède le stockage des diagnostics par course. Réimportez-la pour les consulter.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 8)
            } else {
                Label("Aucun relevé de qualité n’est disponible pour cette version GTFS.", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text("Qualité des formes et séquences d’arrêts")
                    .font(.subheadline.weight(.semibold))
                if let quality {
                    Text("\(quality.tripIssues?.count.formatted() ?? "—") courses signalées · \(quality.invalidShapeCount) formes invalides · GTFS \(version?.id ?? "inconnu")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Diagnostics indisponibles pour l’archive active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .onChange(of: selectedIssueKind) { _, _ in visibleIssueLimit = 100 }
        .onChange(of: query) { _, _ in visibleIssueLimit = 100 }
    }

    @ViewBuilder
    private func issueList(_ issues: [GTFSImportTripIssue]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Picker("Type d’anomalie", selection: $selectedIssueKind) {
                    Text("Tous les types").tag(Optional<GTFSImportTripIssueKind>.none)
                    ForEach(GTFSImportTripIssueKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(Optional(kind))
                    }
                }
                .pickerStyle(.menu)

                TextField("Filtrer ligne, course, forme ou arrêt", text: $query)
                    .textFieldStyle(.roundedBorder)
            }

            if filteredIssues.isEmpty {
                Text("Aucune course ne correspond au filtre.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let routeNamesByID = Dictionary(
                    routes.map { ($0.routeID, $0.displayName) },
                    uniquingKeysWith: { first, _ in first }
                )
                LazyVStack(spacing: 6) {
                    ForEach(Array(filteredIssues.prefix(visibleIssueLimit))) { issue in
                        GTFSTripQualityAuditRow(issue: issue, routeName: routeNamesByID[issue.routeID])
                    }
                }

                HStack {
                    Text("Affichage de \(min(visibleIssueLimit, filteredIssues.count)) sur \(filteredIssues.count) courses filtrées.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if filteredIssues.count > visibleIssueLimit {
                        Button("Afficher 100 de plus") { visibleIssueLimit += 100 }
                            .font(.caption)
                    }
                }
            }
        }
    }
}

private struct GTFSQualityMetricRow: View {
    let title: String
    let value: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value.formatted())
                .font(.caption.monospacedDigit().weight(.semibold))
        }
    }
}

private struct GTFSTripQualityAuditRow: View {
    let issue: GTFSImportTripIssue
    let routeName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(routeName.map { "\($0) · \(issue.routeID)" } ?? issue.routeID)
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 8)
                Text(issue.tripID)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
            }
            Text(issue.summary)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("shape_id · \(issue.shapeID ?? "absent")")
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
            if let stopIDs = issue.stopIDsNotMatchedToShape, !stopIDs.isEmpty {
                Text("Arrêts non projetés · \(stopIDs.prefix(8).joined(separator: ", "))\(stopIDs.count > 8 ? " · +\(stopIDs.count - 8)" : "")")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            if let stopIDs = issue.stopIDsWithoutCoordinates, !stopIDs.isEmpty {
                Text("Arrêts sans coordonnées · \(stopIDs.prefix(8).joined(separator: ", "))\(stopIDs.count > 8 ? " · +\(stopIDs.count - 8)" : "")")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))
    }
}
