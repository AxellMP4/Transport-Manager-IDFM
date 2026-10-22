import MapKit
import SwiftUI

private struct RouteDetourSegmentOption: Hashable, Identifiable {
    let id: String
    let routeVisits: [ScheduledTripStopVisit]
    let fromVisit: ScheduledTripStopVisit
    let toVisit: ScheduledTripStopVisit
    let directionTitle: String
    let nextServiceAt: Date

    var title: String {
        "\(directionTitle) · \(fromVisit.stopName) → \(toVisit.stopName) · prochaine course \(nextServiceAt.formatted(date: .omitted, time: .shortened))"
    }
}

struct RouteDetourEditorView: View {
    let stop: GTFSStopSummary?
    let routeID: String
    let sourceObservation: PRIMTrafficObservation?
    @ObservedObject var library: NetworkLibrary
    @ObservedObject var simulation: SimulationEngine

    @Environment(\.dismiss) private var dismiss
    @State private var segmentOptions: [RouteDetourSegmentOption] = []
    @State private var selectedSegmentID: String?
    @State private var alternatives: [RouteDetourCandidate] = []
    @State private var selectedCandidateID: String?
    @State private var candidateSegmentID: String?
    @State private var startsAt = Date.now
    @State private var endsAt = Date.now.addingTimeInterval(60 * 60)
    @State private var additionalDelayMinutes = 10
    @State private var passengerInformationMessage = ""
    @State private var isLoadingSegments = false
    @State private var isCalculatingAlternatives = false
    @State private var loadError: String?
    @State private var routingError: String?
    @State private var saveError: String?
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    private var routeName: String {
        library.busRoutes.first(where: { $0.routeID == routeID })?.displayName ?? routeID
    }

    private var selectedSegment: RouteDetourSegmentOption? {
        segmentOptions.first { $0.id == selectedSegmentID }
    }

    private var selectedCandidate: RouteDetourCandidate? {
        guard candidateSegmentID == selectedSegmentID else { return nil }
        return alternatives.first { $0.id == selectedCandidateID }
    }

    private var canSave: Bool {
        guard let session = simulation.session,
              selectedSegment != nil,
              selectedCandidate != nil else { return false }
        return startsAt >= session.simulatedAt
            && endsAt > startsAt
            && additionalDelayMinutes >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ligne et segment GTFS") {
                    LabeledContent("Ligne", value: "\(routeName) · \(routeID)")
                    if isLoadingSegments {
                        ProgressView("Recherche des prochains segments…")
                    } else if segmentOptions.isEmpty {
                        ContentUnavailableView(
                            "Aucun segment futur",
                            systemImage: "point.3.connected.trianglepath.dotted",
                            description: Text(loadError ?? (stop == nil
                                ? "Aucun segment de cette ligne n’a de course future dans les quatre prochains jours du GTFS épinglé."
                                : "Aucun segment voisin de cet arrêt n’a de course future dans les quatre prochains jours du GTFS épinglé."))
                        )
                    } else {
                        Picker("Segment dirigé", selection: $selectedSegmentID) {
                            ForEach(segmentOptions) { option in
                                Text(option.title).tag(Optional(option.id))
                            }
                        }
                        if let selectedSegment {
                            Text("\(selectedSegment.fromVisit.stopID) · séq. \(selectedSegment.fromVisit.stopSequence) → \(selectedSegment.toVisit.stopID) · séq. \(selectedSegment.toVisit.stopSequence)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let loadError, !segmentOptions.isEmpty {
                        Text(loadError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if let sourceObservation {
                    Section("Observation PRIM · contexte réel") {
                        Text(sourceObservation.report.title)
                            .font(.subheadline.weight(.semibold))
                        Text(sourceObservation.report.message)
                            .fixedSize(horizontal: false, vertical: true)
                        if let updatedAt = sourceObservation.report.updatedAt {
                            LabeledContent("Mise à jour IDFM", value: updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        LabeledContent("Consultée", value: sourceObservation.fetchedAt.formatted(date: .abbreviated, time: .shortened))
                        HStack(spacing: 4) {
                            Text("Ligne IDFM \(sourceObservation.idfmLineID) · \(sourceObservation.license)")
                            Link("Source PRIM", destination: sourceObservation.sourceURL)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Label("Cette observation ne modifie pas le service. Seule l’enregistrement ci-dessous crée une déviation de jeu.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Section("Information voyageurs · simulation") {
                    TextEditor(text: $passengerInformationMessage)
                        .frame(minHeight: 84)
                        .accessibilityLabel("Message d’information voyageurs simulé")
                    Text("Ce texte sera conservé avec la déviation active dans le jeu. Il n’est pas envoyé à IDFM ni à des voyageurs réels.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Pendant la déviation, le message réduit de \(Int((PassengerInformationRules.detourMessageArrivalAvoidanceRate * 100).rounded())) % les nouvelles arrivées estimées sur la ligne. C’est une règle de jeu, non calibrée sur des comportements réels; les voyageurs déjà en attente ne changent pas de file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Période d’application") {
                    DatePicker("Début", selection: $startsAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Fin prévue", selection: $endsAt, displayedComponents: [.date, .hourAndMinute])
                    if let session = simulation.session, startsAt < session.simulatedAt {
                        Label("Le début doit être à l’heure simulée actuelle ou plus tard.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if let reportedEnd = sourceObservation?.report.applicationEnd,
                       let simulatedAt = simulation.session?.simulatedAt,
                       reportedEnd <= simulatedAt {
                        Label("La période PRIM est passée à l’heure de jeu. Choisissez une nouvelle période pour la déviation.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if endsAt <= startsAt {
                        Label("La fin prévue doit suivre le début.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text("La déviation s’applique si l’heure de départ réelle prévue de ce segment tombe dans cette fenêtre.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Tracé routier Apple Plans") {
                    Button {
                        Task { await calculateAlternatives() }
                    } label: {
                        Label(
                            isCalculatingAlternatives ? "Calcul des itinéraires…" : "Calculer les itinéraires automobiles",
                            systemImage: "arrow.triangle.branch"
                        )
                    }
                    .disabled(selectedSegment == nil || isCalculatingAlternatives)

                    if let routingError {
                        Text(routingError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let selectedSegment, candidateSegmentID == selectedSegment.id, !alternatives.isEmpty {
                        Picker("Itinéraire", selection: $selectedCandidateID) {
                            ForEach(alternatives) { candidate in
                                Text(candidateTitle(candidate)).tag(Optional(candidate.id))
                            }
                        }
                    }

                    if let selectedCandidate, let selectedSegment {
                        Map(position: $mapCameraPosition, interactionModes: [.pan, .zoom]) {
                            MapPolyline(coordinates: selectedCandidate.coordinates.map {
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            })
                            .stroke(.pink, style: StrokeStyle(lineWidth: 5, dash: [9, 6]))
                            Annotation("Départ", coordinate: CLLocationCoordinate2D(
                                latitude: selectedSegment.fromVisit.latitude,
                                longitude: selectedSegment.fromVisit.longitude
                            )) {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(.pink)
                            }
                            Annotation("Arrivée", coordinate: CLLocationCoordinate2D(
                                latitude: selectedSegment.toVisit.latitude,
                                longitude: selectedSegment.toVisit.longitude
                            )) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.pink)
                            }
                        }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text("Distance et temps routier calculés par Apple Plans à la demande. Ce tracé n’est pas une géométrie officielle IDFM.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Retard de jeu estimé") {
                    Stepper(
                        "Temps supplémentaire : \(additionalDelayMinutes) min",
                        value: $additionalDelayMinutes,
                        in: 0...180,
                        step: 5
                    )
                    Text("Ce temps s’ajoute à l’arrivée au prochain arrêt et décale ensuite les arrêts, la demande voyageurs, la fin de course et les réservations bus et machiniste.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Les courses déjà affectées gardent leur tracé actuel. La déviation concerne les courses affectées après son enregistrement, selon l’heure de passage prévue sur le segment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Déviation temporaire")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { saveDetour() }
                        .disabled(!canSave)
                }
            }
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
        .task {
            if let simulatedAt = simulation.session?.simulatedAt {
                let proposedStart = sourceObservation?.report.applicationStart ?? simulatedAt
                startsAt = max(simulatedAt, proposedStart)
                let proposedEnd = sourceObservation?.report.applicationEnd
                endsAt = proposedEnd.flatMap { $0 > startsAt ? $0 : nil }
                    ?? startsAt.addingTimeInterval(60 * 60)
            }
            if passengerInformationMessage.isEmpty {
                passengerInformationMessage = sourceObservation?.report.message ?? ""
            }
            await loadSegmentOptions()
        }
    }

    private func loadSegmentOptions() async {
        guard let session = simulation.session else {
            loadError = "Une carrière doit être active pour planifier une déviation."
            return
        }
        isLoadingSegments = true
        loadError = nil
        defer { isLoadingSegments = false }

        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let firstServiceDate = calendar.startOfDay(for: session.simulatedAt)
        let serviceDateKeys = (0...3).compactMap { offset -> Int? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: firstServiceDate) else { return nil }
            return GTFSServiceDate.key(for: date, timeZone: GTFSServiceDate.parisTimeZone)
        }

        var trips: [GTFSRouteServiceTrip] = []
        var lastReadError: String?
        for serviceDateKey in serviceDateKeys {
            do {
                let timetable = try await library.loadRouteTimetable(
                    gtfsVersionID: session.networkVersions.gtfsID,
                    routeID: routeID,
                    serviceDateKey: serviceDateKey
                )
                trips.append(contentsOf: timetable.trips)
            } catch {
                lastReadError = error.localizedDescription
            }
            guard !Task.isCancelled else { return }
        }

        var earliestBySegment: [String: RouteDetourSegmentOption] = [:]
        for trip in trips where trip.routeID == routeID {
            guard trip.stops.count >= 2 else { continue }
            for index in trip.stops.indices.dropLast() {
                let fromVisit = trip.stops[index]
                let toVisit = trip.stops[index + 1]
                let departureAt = fromVisit.departureAt ?? fromVisit.scheduledAt
                if let stop, fromVisit.stopID != stop.stopID && toVisit.stopID != stop.stopID {
                    continue
                }
                guard fromVisit.stopSequence < toVisit.stopSequence,
                      departureAt >= session.simulatedAt,
                      toVisit.scheduledAt > departureAt,
                      validCoordinate(fromVisit.latitude, fromVisit.longitude),
                      validCoordinate(toVisit.latitude, toVisit.longitude) else { continue }

                let directionTitle = trip.headsign.isEmpty ? "Direction GTFS \(trip.directionID)" : trip.headsign
                let optionID = "\(trip.directionID)|\(fromVisit.stopID)|\(fromVisit.stopSequence)|\(toVisit.stopID)|\(toVisit.stopSequence)"
                let option = RouteDetourSegmentOption(
                    id: optionID,
                    routeVisits: trip.stops,
                    fromVisit: fromVisit,
                    toVisit: toVisit,
                    directionTitle: directionTitle,
                    nextServiceAt: departureAt
                )
                if let existing = earliestBySegment[optionID], existing.nextServiceAt <= departureAt {
                    continue
                }
                earliestBySegment[optionID] = option
            }
        }

        segmentOptions = earliestBySegment.values.sorted {
            if $0.nextServiceAt != $1.nextServiceAt { return $0.nextServiceAt < $1.nextServiceAt }
            return $0.id < $1.id
        }
        if let first = segmentOptions.first {
            selectedSegmentID = first.id
        } else {
            let scopeDescription = stop == nil ? "de cette ligne" : "autour de l’arrêt sélectionné"
            loadError = lastReadError
                ?? "Aucune course future \(scopeDescription) ne passe par un segment consécutif dans les quatre prochains jours."
        }
    }

    private func calculateAlternatives() async {
        guard let selectedSegment else { return }
        isCalculatingAlternatives = true
        routingError = nil
        defer { isCalculatingAlternatives = false }
        do {
            let candidates = try await RouteDetourRouter.alternatives(
                from: selectedSegment.fromVisit,
                to: selectedSegment.toVisit,
                departureAt: selectedSegment.nextServiceAt
            )
            guard !Task.isCancelled else { return }
            alternatives = candidates
            candidateSegmentID = selectedSegment.id
            selectedCandidateID = candidates.first?.id
            mapCameraPosition = .automatic
        } catch {
            alternatives = []
            selectedCandidateID = nil
            candidateSegmentID = selectedSegment.id
            routingError = error.localizedDescription
        }
    }

    private func saveDetour() {
        guard let selectedSegment, let selectedCandidate else { return }
        do {
            try simulation.scheduleRouteDetour(
                routeID: routeID,
                orderedRouteVisits: selectedSegment.routeVisits,
                fromVisit: selectedSegment.fromVisit,
                toVisit: selectedSegment.toVisit,
                startsAt: startsAt,
                endsAt: endsAt,
                replacementCoordinates: selectedCandidate.coordinates,
                additionalTravelSeconds: Double(additionalDelayMinutes * 60),
                sourceObservation: sourceObservation,
                passengerInformationMessage: passengerInformationMessage
            )
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func candidateTitle(_ candidate: RouteDetourCandidate) -> String {
        let kilometers = (candidate.routeDistanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))
        let minutes = Int((candidate.expectedTravelSeconds / 60).rounded())
        return "\(kilometers) km · environ \(minutes) min selon MapKit"
    }

    private func validCoordinate(_ latitude: Double, _ longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
}
