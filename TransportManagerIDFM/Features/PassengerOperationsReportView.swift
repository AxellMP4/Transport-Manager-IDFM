import SwiftUI

struct PassengerOperationsReportView: View {
    let session: SimulationSession

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedRouteID = ""
    @State private var selectedVehicleID = ""
    @State private var grouping: PassengerAnalyticsGrouping = .line

    init(session: SimulationSession) {
        self.session = session
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        let lastDay = calendar.startOfDay(for: session.simulatedAt)
        _endDate = State(initialValue: lastDay)
        _startDate = State(initialValue: calendar.date(byAdding: .day, value: -6, to: lastDay) ?? lastDay)
    }

    private var routeIDs: [String] {
        Array(Set((session.passengerExchangeRecords ?? []).map(\.exchange.routeID))).sorted()
    }

    private var vehicleIDs: [String] {
        Array(Set((session.passengerExchangeRecords ?? []).map(\.exchange.vehicleID))).sorted()
    }

    private var analyticsFilter: PassengerAnalyticsFilter {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        let start = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        let end = calendar.date(byAdding: .day, value: 1, to: endDay)?.addingTimeInterval(-0.001) ?? endDay
        return PassengerAnalyticsFilter(
            startAt: start,
            endAt: end,
            routeID: selectedRouteID,
            vehicleID: selectedVehicleID
        )
    }

    private var snapshot: PassengerAnalyticsSnapshot {
        PassengerAnalytics.snapshot(
            exchanges: (session.passengerExchangeRecords ?? []).map(\.exchange),
            incidents: session.vehicleIncidents ?? [],
            events: session.eventHistory,
            pendingTransfers: session.passengerTransferQueueEntries ?? [],
            filter: analyticsFilter,
            grouping: grouping
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Les volumes sont des estimations déterministes de la simulation. Le taux de validation est calculé sur les montées dont le détail de validation est conservé. Les titres validés ne sont pas des recettes de l’exploitant.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    filters

                    satisfactionSection

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), alignment: .leading)], alignment: .leading, spacing: 10) {
                        metric("Montées estimées", value: snapshot.boardings.formatted(), symbol: "person.2.fill", color: .teal)
                        metric("Validations", value: snapshot.validations.formatted(), symbol: "checkmark.seal.fill", color: .green)
                        metric("Taux de validation", value: percent(snapshot.validationRate), symbol: "percent", color: .blue)
                        metric("Montées sans validation", value: snapshot.unvalidatedBoardings.formatted(), symbol: "person.crop.circle.badge.questionmark", color: .orange)
                        metric("Pic de remplissage", value: snapshot.maximumOccupancyPercent.map { "\($0) %" } ?? "—", symbol: "bus.fill", color: .purple)
                        metric("Données avec ventilation", value: snapshot.validationDataBoardings.formatted(), symbol: "chart.pie.fill", color: .indigo)
                    }

                    GroupBox("Titres validés · estimations de jeu") {
                        VStack(spacing: 9) {
                            ForEach(PassengerValidationType.allCases) { type in
                                titleRow(type)
                            }
                        }
                        .padding(.top, 5)
                    }

                    GroupBox("Effets voyageurs des perturbations") {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 0) {
                                metric("Redirigés", value: snapshot.redirectedPassengerCount.formatted(), symbol: "arrow.trianglehead.branch", color: .teal)
                                Divider().frame(height: 48)
                                metric("Laissés à quai", value: snapshot.leftBehindPassengerCount.formatted(), symbol: "person.crop.circle.badge.exclamationmark", color: .orange)
                                Divider().frame(height: 48)
                                metric("Déplacés / bloqués", value: snapshot.displacedPassengerCount.formatted(), symbol: "figure.walk.motion", color: .red)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                metric("Redirigés", value: snapshot.redirectedPassengerCount.formatted(), symbol: "arrow.trianglehead.branch", color: .teal)
                                Divider()
                                metric("Laissés à quai", value: snapshot.leftBehindPassengerCount.formatted(), symbol: "person.crop.circle.badge.exclamationmark", color: .orange)
                                Divider()
                                metric("Déplacés / bloqués", value: snapshot.displacedPassengerCount.formatted(), symbol: "figure.walk.motion", color: .red)
                            }
                        }
                        .padding(.top, 5)
                    }

                    HStack {
                        Text("Détail")
                            .font(.headline)
                        Spacer()
                        Picker("Regrouper par", selection: $grouping) {
                            ForEach(PassengerAnalyticsGrouping.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .accessibilityLabel("Regrouper les données voyageurs par")
                    }

                    if snapshot.rows.isEmpty {
                        ContentUnavailableView(
                            "Aucune donnée voyageurs",
                            systemImage: "person.2",
                            description: Text("Les montées et validations apparaîtront après le passage d’un bus en service.")
                        )
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(snapshot.rows) { row in
                                rowView(row)
                                if row.id != snapshot.rows.last?.id { Divider() }
                            }
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20)
                .frame(maxWidth: 900, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Voyageurs")
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    private var filters: some View {
        GroupBox("Période et périmètre") {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) { filterControls }
                VStack(alignment: .leading, spacing: 9) { filterControls }
            }
            .padding(.top, 5)
        }
    }

    private var satisfactionSection: some View {
        let satisfaction = snapshot.satisfaction
        return GroupBox("Satisfaction voyageurs · estimation") {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        satisfactionScore(satisfaction.score)
                        Text(satisfactionCoverage(satisfaction.coveredComponentCount))
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        satisfactionScore(satisfaction.score)
                        Text(satisfactionCoverage(satisfaction.coveredComponentCount))
                            .foregroundStyle(.secondary)
                    }
                }

                satisfactionComponentRow(
                    title: "Accès à bord",
                    score: satisfaction.access.score,
                    detail: "\(satisfaction.access.boardedArrivals.formatted()) montées / \(satisfaction.access.observedArrivalCount.formatted()) arrivées documentées · \(satisfaction.access.sampleCount.formatted()) arrêts · montées ÷ (montées + laissés à quai)"
                )
                satisfactionComponentRow(
                    title: "Confort de charge",
                    score: satisfaction.comfort.score,
                    detail: "\(satisfaction.comfort.sampleCount.formatted()) échanges · \(satisfaction.comfort.estimatedCapacitySampleCount.formatted()) capacités estimées · normal 100, chargé 50, complet 0"
                )
                satisfactionComponentRow(
                    title: "Correspondances",
                    score: satisfaction.connections.score,
                    detail: "\(satisfaction.connections.boardedPassengerCount.formatted()) / \(satisfaction.connections.attemptedPassengerCount.formatted()) voyageurs montés sur la course visée · \(satisfaction.connections.missedPassengerCount.formatted()) manqués · \(satisfaction.connections.pendingGroupCount.formatted()) groupes (\(satisfaction.connections.pendingPassengerCount.formatted()) voyageurs) en attente, exclus du score"
                )

                if satisfaction.coveredComponentCount == 0 {
                    Text("L’indice apparaîtra après des échanges voyageurs et des correspondances ciblées. Les données manquantes des anciennes sauvegardes ne sont pas reconstituées.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Estimation de la simulation, pas enquête de satisfaction réelle. Les échanges historiques sans mesure précise restent hors des composantes concernées.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 5)
            .accessibilityElement(children: .contain)
        }
    }

    private func satisfactionScore(_ score: Int?) -> some View {
        Text(score.map { "\($0) / 100" } ?? "Indisponible")
            .font(.title2.monospacedDigit().weight(.semibold))
            .accessibilityLabel(score.map { "Indice moyen estimé, \($0) sur 100" } ?? "Indice moyen estimé indisponible")
    }

    private func satisfactionComponentRow(title: String, score: Int?, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 4)
                Text(score.map { "\($0) / 100" } ?? "Indisponible")
                    .font(.subheadline.monospacedDigit().weight(.medium))
            }
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(score.map { "\($0) sur 100" } ?? "indisponible"), \(detail)")
    }

    private func satisfactionCoverage(_ componentCount: Int) -> String {
        "\(componentCount) composante\(componentCount == 1 ? "" : "s") sur 3 · données \(componentCount == 3 ? "complètes" : "partielles")"
    }

    @ViewBuilder
    private var filterControls: some View {
        DatePicker("Du", selection: $startDate, displayedComponents: .date)
            .datePickerStyle(.compact)
        DatePicker("Au", selection: $endDate, displayedComponents: .date)
            .datePickerStyle(.compact)
        Picker("Ligne", selection: $selectedRouteID) {
            Text("Toutes").tag("")
            ForEach(routeIDs, id: \.self) { routeID in Text(routeID).tag(routeID) }
        }
        .frame(minWidth: 115)
        Picker("Bus", selection: $selectedVehicleID) {
            Text("Tous").tag("")
            ForEach(vehicleIDs, id: \.self) { vehicleID in Text(vehicleID).tag(vehicleID) }
        }
        .frame(minWidth: 115)
    }

    private func titleRow(_ type: PassengerValidationType) -> some View {
        let count = snapshot.validationCount(for: type)
        let fraction = snapshot.validations > 0 ? Double(count) / Double(snapshot.validations) : 0
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                Text(type.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ProgressView(value: fraction)
                    .frame(width: 90)
                    .tint(.accentColor)
                    .accessibilityHidden(true)
                titleDistributionValue(count: count, fraction: fraction)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(type.title)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    ProgressView(value: fraction)
                        .frame(width: 90)
                        .tint(.accentColor)
                        .accessibilityHidden(true)
                    Spacer(minLength: 4)
                    titleDistributionValue(count: count, fraction: fraction)
                }
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func titleDistributionValue(count: Int, fraction: Double) -> some View {
        Text("\(count.formatted()) · \(percent(fraction))")
            .font(.caption.monospacedDigit().weight(.semibold))
            .frame(minWidth: 90, alignment: .trailing)
    }

    private func rowView(_ row: PassengerAnalyticsRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.label)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("\(row.totals.boardings.formatted()) montées · \(row.totals.validations.formatted()) validations · taux \(percent(row.totals.validationRate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let satisfaction = compactSatisfaction(row.totals.satisfaction) {
                    Text(satisfaction)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let occupancy = row.totals.maximumOccupancyPercent {
                Text("\(occupancy) % max")
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(occupancy >= 100 ? .red : (occupancy >= 80 ? .orange : .secondary))
            }
        }
        .padding(.vertical, 10)
    }

    private func compactSatisfaction(_ satisfaction: PassengerSatisfactionSummary) -> String? {
        let components: [String] = [
            satisfaction.access.score.map { "accès \($0) %" },
            satisfaction.comfort.score.map { "confort \($0) %" },
            satisfaction.connections.score.map { "correspondances \($0) %" }
        ].compactMap { $0 }
        guard !components.isEmpty else { return nil }
        let score = satisfaction.score.map { "\($0) / 100" } ?? "partiel"
        return "Satisfaction estimée \(score) · \(components.joined(separator: " · "))"
    }

    private func metric(_ title: String, value: String, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private func percent(_ rate: Double?) -> String {
        guard let rate else { return "—" }
        return "\(Int((rate * 100).rounded())) %"
    }

    private func percent(_ rate: Double) -> String {
        "\(Int((rate * 100).rounded())) %"
    }
}
