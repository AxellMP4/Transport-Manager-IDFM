import SwiftUI

struct GameLaunchScenarioChoice: Identifiable, Hashable, Sendable {
    let id: String
    let depotID: String
    let title: String
    let subtitle: String
}

struct GameLaunchMenuView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private enum Page {
        case home
        case scenarios
        case savedCareers
        case options
        case guide
    }

    @Binding var breakdownFrequency: VehicleIncidentFrequency
    @Binding var trafficDisruptionFrequency: TrafficDisruptionFrequency
    let activeCareer: SavedCareerSummary?
    let savedCareers: [SavedCareerSummary]
    let savedCareerNotice: String?
    let scenarios: [GameLaunchScenarioChoice]
    let networkLineCount: Int
    let isSynchronizing: Bool
    let syncStatus: String
    let hasSyncConflict: Bool
    let onContinue: () -> Void
    let onNewCareer: () -> Void
    let onChooseScenario: (GameLaunchScenarioChoice) -> Void
    let onSelectCareer: (SavedCareerSummary) -> Void
    let onImportCareer: () -> Void
    let onExportCareer: () -> Void
    let onSaveCareer: () -> Void
    let onSynchronize: () -> Void
    let onOpenGuideDestination: (CareerGuideDestination) -> Void

    @State private var page: Page = .home
    @State private var searchText = ""

    private var filteredScenarios: [GameLaunchScenarioChoice] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return scenarios }
        return scenarios.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private var isCareerRestorePending: Bool {
        isSynchronizing || syncStatus == "iCloud non vérifié"
    }

    private var isCareerActionBlocked: Bool {
        isCareerRestorePending
    }

    private var isCompactLayout: Bool { horizontalSizeClass == .compact }

    var body: some View {
        Group {
            if isCompactLayout {
                compactLayout
            } else {
                desktopLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlatformColors.windowBackground.opacity(0.98))
        .accessibilityIdentifier("gameLaunchMenu")
    }

    private var desktopLayout: some View {
        HStack(spacing: 28) {
            identityPanel
                .frame(width: 330)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1)

            pageContent
                .frame(maxWidth: 650, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(32)
        .frame(maxWidth: 1_080, maxHeight: 720)
        .background(PlatformColors.windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 24, y: 12)
        .padding(24)
    }

    private var compactLayout: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.tint)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Transport Manager")
                        .font(.headline)
                        .lineLimit(1)
                    Text(page == .home
                        ? "IDFM · \(networkLineCount.formatted()) lignes · \(scenarios.count.formatted()) centres"
                        : compactPageTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                if page != .home {
                    Button {
                        page = .home
                        searchText = ""
                    } label: {
                        Image(systemName: "chevron.backward")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Retour au menu principal")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            Group {
                if page == .options {
                    ScrollView { optionsPage }
                        .scrollIndicators(.visible)
                } else {
                    pageContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
        }
        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .topLeading)
        .background(PlatformColors.windowBackground)
    }

    private var compactPageTitle: String {
        switch page {
        case .home: "Transport Manager"
        case .scenarios: "Choisir un scénario"
        case .savedCareers: "Carrières sauvegardées"
        case .options: "Options"
        case .guide: "Guide de prise en main"
        }
    }

    private var identityPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "bus.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.tint)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                Text("IDFM · GESTION DU RÉSEAU")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 18)

            TransitRouteMotif()
                .frame(height: 195)
                .accessibilityHidden(true)

            Spacer(minLength: 14)

            Text("Transport\nManager")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .tracking(-1.4)
                .fixedSize(horizontal: false, vertical: true)
            Text("Prends les commandes du réseau de bus francilien.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 9) {
                Label("\(networkLineCount.formatted()) lignes dans le catalogue local", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                Label("\(scenarios.count.formatted()) choix de centre de départ", systemImage: "building.2")
            }
            .font(.callout.weight(.medium))
            .foregroundStyle(.secondary)

            if let activeCareer {
                Divider().padding(.vertical, 17)
                VStack(alignment: .leading, spacing: 5) {
                    Text("CARRIÈRE DISPONIBLE")
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                    Text(depotName(for: activeCareer))
                        .font(.headline)
                    Text("Dernière sauvegarde · \(activeCareer.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .home:
            homePage
        case .scenarios:
            scenariosPage
        case .savedCareers:
            savedCareersPage
        case .options:
            optionsPage
        case .guide:
            CareerGuideView(
                onClose: { page = .home },
                onOpenDestination: onOpenGuideDestination
            )
        }
    }

    private var homePage: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(activeCareer == nil ? "Bienvenue" : "Reprendre la gestion")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(activeCareer == nil
                ? "Choisis un scénario, puis sélectionne le centre et les lignes que tu veux exploiter."
                : "Reprends ta partie ou prépare une nouvelle carrière. Les sauvegardes restent accessibles séparément.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(syncStatus.localizedCaseInsensitiveContains("sauvegarde locale")
                ? "Cette configuration de développement garde les carrières sur cet iPhone. Les versions App Store signées avec l’équipe iCloud pourront les synchroniser; les fichiers JSON restent disponibles pour les transferts manuels."
                : "Quand iCloud est configuré, ta carrière peut être retrouvée sur tes autres appareils connectés au même compte iCloud. Les fichiers JSON restent disponibles pour un transfert manuel.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if isCareerRestorePending {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(isSynchronizing ? "Vérification de la carrière iCloud…" : "Préparation de la récupération iCloud…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            }

            if hasSyncConflict {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Choix de version requis", systemImage: "exclamationmark.icloud")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("Reprends la partie locale, puis ouvre le menu iCloud dans la barre supérieure du tableau de bord pour choisir la version à continuer.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
            }

            ScrollView {
                VStack(spacing: 9) {
                    if let activeCareer {
                        actionRow(
                            title: hasSyncConflict ? "Ouvrir la partie locale" : "Continuer la carrière",
                            detail: hasSyncConflict
                                ? "Reprendre, puis choisir une version dans le menu iCloud"
                                : "Reprendre à \(activeCareer.simulatedAt.formatted(date: .abbreviated, time: .shortened))",
                            symbol: "play.fill",
                            prominent: true,
                            disabled: isCareerRestorePending,
                            action: onContinue
                        )
                    }
                    actionRow(
                        title: "Nouvelle carrière",
                        detail: "Choisir un centre et préparer le réseau",
                        symbol: "plus.circle",
                        prominent: activeCareer == nil,
                        disabled: isCareerActionBlocked,
                        action: onNewCareer
                    )
                    actionRow(
                        title: "Choisir un scénario",
                        detail: "Parcourir les centres et contrats disponibles",
                        symbol: "map",
                        disabled: isCareerActionBlocked,
                        action: { page = .scenarios; searchText = "" }
                    )
                    actionRow(
                        title: "Carrières sauvegardées",
                        detail: savedCareers.isEmpty ? "Aucune sauvegarde locale trouvée" : "\(savedCareers.count) carrière(s) disponible(s)",
                        symbol: "tray.full",
                        disabled: isCareerActionBlocked,
                        action: { page = .savedCareers }
                    )
                    actionRow(
                        title: "Importer une carrière…",
                        detail: "Ouvrir un fichier JSON de sauvegarde",
                        symbol: "square.and.arrow.down",
                        disabled: isCareerActionBlocked,
                        action: onImportCareer
                    )
                    actionRow(
                        title: "Options",
                        detail: "Fréquence des pannes et synchronisation iCloud",
                        symbol: "gearshape",
                        action: { page = .options }
                    )
                    actionRow(
                        title: "Guide de prise en main",
                        detail: "Quatre étapes pour lancer et suivre une carrière",
                        symbol: "book",
                        action: { page = .guide }
                    )
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.visible)

            HStack(spacing: 8) {
                Image(systemName: hasSyncConflict ? "exclamationmark.icloud" : "icloud")
                    .foregroundStyle(hasSyncConflict ? Color.orange : Color.secondary)
                Text(syncStatus)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Button(syncStatus.localizedCaseInsensitiveContains("sauvegarde locale") ? "Sur cet iPhone" : "Synchroniser") {
                    onSynchronize()
                }
                .disabled(isCareerRestorePending || syncStatus.localizedCaseInsensitiveContains("iCloud indisponible"))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var scenariosPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            pageHeader("Choisir un scénario", subtitle: "Sélectionne le centre de départ. Les lignes candidates restent à valider dans la préparation de carrière.")
            TextField("Rechercher un centre ou un contrat", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Rechercher un centre ou un contrat")
            if filteredScenarios.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredScenarios) { choice in
                            Button {
                                onChooseScenario(choice)
                            } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: "building.2.fill")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                        .frame(width: 42, height: 42)
                                        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 11))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(choice.title).font(.headline)
                                        Text(choice.subtitle).font(.callout).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .contentShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .disabled(isCareerActionBlocked)
                            .accessibilityHint("Ouvre la préparation de carrière pour ce centre")
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var savedCareersPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            pageHeader("Carrières sauvegardées", subtitle: "Chaque carrière est enregistrée séparément. Choisis celle à reprendre.")
            if let savedCareerNotice {
                Label(savedCareerNotice, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if savedCareers.isEmpty {
                ContentUnavailableView(
                    "Aucune carrière sauvegardée",
                    systemImage: "tray",
                    description: Text("Commence une carrière ou importe un fichier JSON pour la retrouver ici.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(savedCareers) { career in
                            Button {
                                onSelectCareer(career)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(depotName(for: career))
                                            .font(.headline)
                                            .lineLimit(1)
                                        Spacer(minLength: 8)
                                        if career.id == activeCareer?.id {
                                            Text("ACTIVE")
                                                .font(.caption2.weight(.bold))
                                                .tracking(0.6)
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                    Text(ScenarioDefinition.forDepot(career.depotID).name)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    careerMetadata(for: career)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(13)
                                .contentShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .disabled(isSynchronizing)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var optionsPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            pageHeader("Options", subtitle: "Ces réglages s’appliquent aux nouvelles carrières.")
            GroupBox("Fréquence des pannes") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Fréquence", selection: $breakdownFrequency) {
                        ForEach(VehicleIncidentFrequency.allCases) { frequency in
                            Text(frequency.title).tag(frequency)
                        }
                    }
#if os(macOS)
                    .pickerStyle(.radioGroup)
#else
                    .pickerStyle(.menu)
#endif
                    Text(breakdownFrequency.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Congestion routière simulée") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Fréquence", selection: $trafficDisruptionFrequency) {
                        ForEach(TrafficDisruptionFrequency.allCases) { frequency in
                            Text(frequency.title).tag(frequency)
                        }
                    }
#if os(macOS)
                    .pickerStyle(.radioGroup)
#else
                    .pickerStyle(.menu)
#endif
                    Text(trafficDisruptionFrequency.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Carrière et synchronisation") {
                VStack(alignment: .leading, spacing: 10) {
                    Label(syncStatus, systemImage: hasSyncConflict ? "exclamationmark.icloud" : "icloud")
                        .foregroundStyle(hasSyncConflict ? Color.orange : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if hasSyncConflict {
                        Text("Les deux versions sont conservées. Pour choisir, reprends la partie locale puis ouvre le menu iCloud dans la barre supérieure du tableau de bord.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if isCompactLayout {
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Synchroniser maintenant", action: onSynchronize)
                                .disabled(isCareerRestorePending)
                            if activeCareer != nil {
                                Button("Sauvegarder maintenant", action: onSaveCareer)
                                Button("Exporter…", action: onExportCareer)
                            }
                        }
                    } else {
                        HStack {
                            Button("Synchroniser maintenant", action: onSynchronize)
                                .disabled(isCareerRestorePending)
                            Spacer()
                            if activeCareer != nil {
                                Button("Sauvegarder maintenant", action: onSaveCareer)
                                Button("Exporter…", action: onExportCareer)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func pageHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !isCompactLayout {
                Button {
                    page = .home
                    searchText = ""
                } label: {
                    Label("Menu principal", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                .help("Retour au menu principal")
            }
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func actionRow(
        title: String,
        detail: String,
        symbol: String,
        prominent: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        if prominent {
            actionButton(title: title, detail: detail, symbol: symbol, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(disabled)
                .accessibilityHint(detail)
        } else {
            actionButton(title: title, detail: detail, symbol: symbol, action: action)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(disabled)
                .accessibilityHint(detail)
        }
    }

    private func actionButton(
        title: String,
        detail: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 11))
        }
    }

    private func depotName(for career: SavedCareerSummary) -> String {
        DepotCareerScope.depotReference(for: career.depotID)?.name
            ?? DepotLineRoster.selectableSites.first(where: { $0.id == career.depotID })?.name
            ?? career.depotID
    }

    @ViewBuilder
    private func careerMetadata(for career: SavedCareerSummary) -> some View {
        if isCompactLayout {
            VStack(alignment: .leading, spacing: 5) {
                Label(career.updatedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                if let cashBalance = career.cashBalance {
                    Label("\(cashBalance.formatted()) €", systemImage: "eurosign.circle")
                }
                Label("Partie · \(career.simulatedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "play.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 14) {
                Label(career.updatedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                if let cashBalance = career.cashBalance {
                    Label("\(cashBalance.formatted()) €", systemImage: "eurosign.circle")
                }
                Text("Partie · \(career.simulatedAt.formatted(date: .abbreviated, time: .shortened))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

struct CareerGuideView: View {
    let onClose: () -> Void
    let onOpenDestination: (CareerGuideDestination) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Les bases d’une carrière")
                        .font(.title2.weight(.bold))
                    Text("Ce guide est facultatif. Tu peux le fermer à tout moment et le rouvrir depuis le menu ou l’onglet Carrière.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(CareerGuideChapter.all) { chapter in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 11) {
                                Text(chapter.summary)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                ForEach(chapter.destinations) { destination in
                                    Button {
                                        onOpenDestination(destination)
                                    } label: {
                                        Label(destination.title, systemImage: destination.systemImage)
                                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Label(chapter.title, systemImage: "\(chapter.id).circle.fill")
                                .font(.headline)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Guide")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", action: onClose)
                }
            }
        }
    }
}

private struct TransitRouteMotif: View {
    var body: some View {
        Canvas { context, size in
            let primary = Color.accentColor
            let secondary = Color.blue
            let tertiary = Color.orange
            var main = Path()
            main.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.76))
            main.addLine(to: CGPoint(x: size.width * 0.31, y: size.height * 0.76))
            main.addQuadCurve(to: CGPoint(x: size.width * 0.48, y: size.height * 0.52), control: CGPoint(x: size.width * 0.42, y: size.height * 0.76))
            main.addLine(to: CGPoint(x: size.width * 0.82, y: size.height * 0.52))
            context.stroke(main, with: .color(primary.opacity(0.82)), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))

            var branch = Path()
            branch.move(to: CGPoint(x: size.width * 0.31, y: size.height * 0.76))
            branch.addLine(to: CGPoint(x: size.width * 0.31, y: size.height * 0.25))
            branch.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.25))
            context.stroke(branch, with: .color(secondary.opacity(0.8)), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

            var connector = Path()
            connector.move(to: CGPoint(x: size.width * 0.62, y: size.height * 0.25))
            connector.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.25))
            connector.addLine(to: CGPoint(x: size.width * 0.84, y: size.height * 0.52))
            context.stroke(connector, with: .color(tertiary.opacity(0.85)), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

            let stations: [(CGFloat, CGFloat, CGFloat)] = [
                (0.08, 0.76, 10), (0.31, 0.76, 13), (0.31, 0.25, 10),
                (0.62, 0.25, 13), (0.84, 0.25, 10), (0.84, 0.52, 13), (0.48, 0.52, 10)
            ]
            for (x, y, diameter) in stations {
                let rect = CGRect(
                    x: size.width * x - diameter / 2,
                    y: size.height * y - diameter / 2,
                    width: diameter,
                    height: diameter
                )
                context.fill(Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)), with: .color(PlatformColors.windowBackground))
                context.fill(Path(ellipseIn: rect), with: .color(.primary))
            }
        }
    }
}
