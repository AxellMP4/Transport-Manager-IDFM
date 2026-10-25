import SwiftUI

struct GTFSRouteTimetableGridView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: NetworkLibrary
    let route: GTFSRouteSummary
    let version: NetworkVersion
    let documents: [NetworkLineDocument]
    @State private var serviceDate: Date
    @State private var timetable: GTFSRouteTimetable?
    @State private var loadError: String?
    @State private var isLoading = false

    init(
        library: NetworkLibrary,
        route: GTFSRouteSummary,
        version: NetworkVersion,
        documents: [NetworkLineDocument],
        initialServiceDate: Date
    ) {
        _library = ObservedObject(wrappedValue: library)
        self.route = route
        self.version = version
        self.documents = documents
        _serviceDate = State(initialValue: Self.clampToServiceDate(initialServiceDate, range: Self.serviceDateRange(for: version)))
    }

    private static func serviceDateRange(for version: NetworkVersion) -> ClosedRange<Date>? {
        guard let validFrom = version.validFrom, let validThrough = version.validThrough else { return nil }
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let firstDay = calendar.startOfDay(for: validFrom)
        let lastDay = calendar.startOfDay(for: validThrough)
        guard firstDay <= lastDay else { return nil }
        return firstDay...lastDay
    }

    private static func clampToServiceDate(_ date: Date, range: ClosedRange<Date>?) -> Date {
        let day = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: date)
        guard let range else { return day }
        return min(max(day, range.lowerBound), range.upperBound)
    }

    private var serviceDateKey: Int {
        GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone) ?? 0
    }

    private var dateIsCovered: Bool {
        guard let range = Self.serviceDateRange(for: version) else { return false }
        let selectedDay = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone).startOfDay(for: serviceDate)
        return range.contains(selectedDay)
    }

    private var tripGroups: [GTFSRouteTripGroup] {
        guard let timetable else { return [] }
        let grouped = Dictionary(grouping: timetable.trips) { trip in
            [trip.directionID, trip.headsign, trip.stops.map(\.stopID).joined(separator: ",")].joined(separator: "|")
        }
        return grouped.map { key, trips in
            GTFSRouteTripGroup(key: key, trips: trips.sorted(by: Self.tripOrder))
        }.sorted { lhs, rhs in
            let lhsStart = lhs.trips.first?.stops.first?.scheduledAt ?? .distantFuture
            let rhsStart = rhs.trips.first?.stops.first?.scheduledAt ?? .distantFuture
            return lhsStart < rhsStart
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Grille théorique · ligne \(route.shortName)")
                        .font(.title2.weight(.semibold))
                    Text("Route GTFS \(route.routeID) · \(version.displaySourceTitle)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                DatePicker(
                    "Date de service",
                    selection: $serviceDate,
                    in: Self.serviceDateRange(for: version) ?? Date.distantPast...Date.distantFuture,
                    displayedComponents: .date
                )
                    #if os(macOS)
                    .datePickerStyle(.field)
                    #else
                    .datePickerStyle(.compact)
                    #endif
                    .frame(maxWidth: 250)
                Button("Fermer") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Horaire théorique GTFS, pas un horaire garanti d’exploitation. Les courses sont groupées par direction, destination et séquence exacte d’arrêts.", systemImage: "info.circle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let validFrom = version.validFrom, let validThrough = version.validThrough {
                        Text("Flux valide du \(validFrom.formatted(date: .abbreviated, time: .omitted)) au \(validThrough.formatted(date: .abbreviated, time: .omitted)) · importé le \(version.importedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !dateIsCovered {
                        ContentUnavailableView(
                            Self.serviceDateRange(for: version) == nil ? "Validité du flux non disponible" : "Date hors validité du flux",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text(Self.serviceDateRange(for: version) == nil
                                ? "Cette version ne fournit pas deux bornes de validité interprétables ; aucune grille de service ne peut être évaluée."
                                : "Choisissez une date comprise dans la période couverte par cette version GTFS.")
                        )
                    } else if isLoading {
                        ProgressView("Chargement des courses, horaires et arrêts…")
                            .frame(maxWidth: .infinity, minHeight: 160)
                    } else if let loadError {
                        ContentUnavailableView("Grille indisponible", systemImage: "exclamationmark.triangle", description: Text(loadError))
                    } else if let timetable, timetable.trips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ContentUnavailableView("Aucune course active", systemImage: "bus", description: Text("Le calendrier GTFS de cette route ne prévoit aucune course à la date choisie."))

                            if let notice = PublishedServiceDiscrepancy.forRoute(
                                shortName: route.shortName,
                                routeID: route.routeID,
                                serviceDateKey: serviceDateKey,
                                scheduledTripCount: timetable.trips.count
                            ) {
                                PublishedServiceDiscrepancyCard(notice: notice)
                            }
                        }
                    } else if let timetable {
                        if timetable.unusableTripCount > 0 {
                            Label("\(timetable.unusableTripCount) courses ignorées : horaire incomplet, arrêt absent ou heures dans un ordre invalide.", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        ForEach(tripGroups) { group in
                            tripGroupView(group)
                        }
                    }

                    if !documents.isEmpty {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Documents officiels de cette ligne")
                                .font(.headline)
                            ForEach(documents) { document in
                                if let destination = document.destination {
                                    Link(destination: destination) {
                                        Label(document.documentName, systemImage: "arrow.up.right.square")
                                            .font(.callout)
                                    }
                                    Text(document.typeLabel)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(18)
            }
        }
        .frame(minWidth: 760, minHeight: 540)
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
        .task(id: serviceDateKey) {
            await loadTimetable()
        }
    }

    @ViewBuilder
    private func tripGroupView(_ group: GTFSRouteTripGroup) -> some View {
        let stopVisits = group.trips.first?.stops ?? []
        let first = group.trips.first?.stops.first?.scheduledAt
        let last = group.trips.last?.stops.first?.scheduledAt
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.title)
                        .font(.headline)
                    Text("\(group.trips.count) courses · \(group.trips.first?.stops.count ?? 0) arrêts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let first, let last {
                    Text("Premier départ \(serviceTime(first)) · dernier \(serviceTime(last))")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Course")
                            .font(.caption.weight(.semibold))
                            .frame(width: 100, alignment: .leading)
                        ForEach(Array(stopVisits.enumerated()), id: \.offset) { _, visit in
                            Text(visit.stopName)
                                .font(.caption.weight(.semibold))
                                .lineLimit(2)
                                .frame(width: 112, height: 42, alignment: .leading)
                                .padding(.trailing, 6)
                        }
                    }
                    .padding(.horizontal, 9)
                    .background(.quaternary)

                    ForEach(group.trips) { trip in
                        HStack(spacing: 0) {
                            Text(String(trip.tripID.suffix(12)))
                                .font(.caption2.monospaced())
                                .lineLimit(1)
                                .frame(width: 100, alignment: .leading)
                            ForEach(Array(trip.stops.enumerated()), id: \.offset) { _, visit in
                                Text(serviceTime(visit.scheduledAt))
                                    .font(.caption.monospaced())
                                    .frame(width: 112, alignment: .leading)
                                    .padding(.trailing, 6)
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(trip.id == group.trips.first?.id ? Color.accentColor.opacity(0.035) : .clear)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary, lineWidth: 1))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
    }

    private func serviceTime(_ date: Date) -> String {
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let serviceDay = calendar.startOfDay(for: serviceDate)
        let dateDay = calendar.startOfDay(for: date)
        let dayOffset = max(0, calendar.dateComponents([.day], from: serviceDay, to: dateDay).day ?? 0)
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hours = (parts.hour ?? 0) + (dayOffset * 24)
        return String(format: "%02d:%02d", hours, parts.minute ?? 0)
    }

    private func loadTimetable() async {
        guard dateIsCovered, serviceDateKey > 0 else {
            timetable = nil
            loadError = nil
            isLoading = false
            return
        }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            timetable = try await library.loadRouteTimetable(
                gtfsVersionID: version.id,
                routeID: route.routeID,
                serviceDateKey: serviceDateKey
            )
        } catch {
            timetable = nil
            loadError = error.localizedDescription
        }
    }

    private static func tripOrder(_ lhs: GTFSRouteServiceTrip, _ rhs: GTFSRouteServiceTrip) -> Bool {
        let left = lhs.stops.first?.scheduledAt ?? .distantFuture
        let right = rhs.stops.first?.scheduledAt ?? .distantFuture
        if left != right { return left < right }
        return lhs.tripID < rhs.tripID
    }
}

private struct GTFSRouteTripGroup: Identifiable {
    let key: String
    let trips: [GTFSRouteServiceTrip]

    var id: String { key }
    var title: String {
        let trip = trips.first
        let destination = trip?.headsign.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let direction = trip?.directionID.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !destination.isEmpty { return "Direction · \(destination)" }
        if !direction.isEmpty { return "Direction \(direction)" }
        return "Direction non renseignée"
    }
}
