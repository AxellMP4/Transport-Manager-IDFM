import MapKit
import SwiftUI

struct StopClosureEditorView: View {
    let stop: GTFSStopSummary
    let routeID: String
    @ObservedObject var library: NetworkLibrary
    @ObservedObject var simulation: SimulationEngine

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReplacementStopID = ""
    @State private var durationHours = 2
    @State private var suspendsWholeLine = false
    @State private var passengerInformationMessage = ""
    @State private var walkingRoute: StopReplacementWalkingRoute?
    @State private var walkingRouteForReplacementStopID: String?
    @State private var isCalculatingRoute = false
    @State private var routingRequestID = UUID()
    @State private var routingError: String?
    @State private var saveError: String?

    private var routeName: String {
        library.busRoutes.first(where: { $0.routeID == routeID })?.displayName ?? routeID
    }

    private var candidates: [GTFSStopSummary] {
        library.busStops
            .filter { $0.stopID != stop.stopID && $0.routeIDs.contains(routeID) }
            .sorted {
                let nameOrder = $0.name.localizedStandardCompare($1.name)
                return nameOrder == .orderedSame ? $0.stopID < $1.stopID : nameOrder == .orderedAscending
            }
    }

    private var selectedReplacementStop: GTFSStopSummary? {
        candidates.first { $0.stopID == selectedReplacementStopID }
    }

    private var canSave: Bool {
        guard simulation.session != nil else { return false }
        if suspendsWholeLine { return true }
        return selectedReplacementStop != nil
            && walkingRoute != nil
            && walkingRouteForReplacementStopID == selectedReplacementStopID
            && !isCalculatingRoute
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Arrêt et ligne concernés") {
                    LabeledContent("Arrêt fermé", value: "\(stop.name) · \(stop.stopID)")
                    LabeledContent("Ligne", value: "\(routeName) · \(routeID)")
                    Toggle("Suspendre toute la ligne", isOn: $suspendsWholeLine)
                    if suspendsWholeLine {
                        Label {
                            Text("Aucun nouveau départ pendant la durée choisie. Les courses déjà parties ou dont l’acheminement a commencé vont à leur terminus. Une course affectée mais pas encore partie sera suspendue et comptée comme non assurée. Les voyageurs restent aux arrêts; aucune correspondance n’est créée automatiquement.")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                    } else if candidates.isEmpty {
                        ContentUnavailableView(
                            "Aucun arrêt de remplacement",
                            systemImage: "figure.walk",
                            description: Text("Cette version GTFS ne contient aucun autre arrêt desservi par cette ligne.")
                        )
                    } else {
                        Picker("Arrêt de remplacement", selection: Binding(
                            get: { selectedReplacementStopID },
                            set: { replacementStopID in
                                guard replacementStopID != selectedReplacementStopID else { return }
                                selectedReplacementStopID = replacementStopID
                                walkingRoute = nil
                                walkingRouteForReplacementStopID = nil
                                routingError = nil
                            }
                        )) {
                            ForEach(candidates) { candidate in
                                Text("\(candidate.name) · \(candidate.stopID)").tag(candidate.stopID)
                            }
                        }
                    }
                    Stepper("Durée : \(durationHours) h", value: $durationHours, in: 1...24)
                }

                if !suspendsWholeLine {
                    Section("Message aux voyageurs") {
                    TextEditor(text: $passengerInformationMessage)
                        .frame(minHeight: 78)
                        .accessibilityLabel("Message d’information voyageurs pour l’arrêt fermé")
                    Text("Règle de jeu : les personnes déjà en attente sont déplacées à l’ouverture de la fermeture. Ensuite, si ce message est renseigné, les arrivants estimés suivent l’arrêt de remplacement; sans message, ils sont comptés comme laissés à quai.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !suspendsWholeLine {
                    Section("Trajet piéton estimé") {
                    if isCalculatingRoute {
                        ProgressView("Calcul du trajet par Apple Plans…")
                    } else if let walkingRoute,
                              walkingRouteForReplacementStopID == selectedReplacementStopID {
                        Map(position: .constant(previewRegion(for: walkingRoute))) {
                            MapPolyline(coordinates: walkingRoute.coordinates.map {
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            })
                            .stroke(.teal, style: StrokeStyle(lineWidth: 5, dash: [7, 5]))
                            Annotation("Arrêt fermé", coordinate: CLLocationCoordinate2D(
                                latitude: stop.latitude,
                                longitude: stop.longitude
                            )) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                            if let replacement = selectedReplacementStop {
                                Annotation("Arrêt de remplacement", coordinate: CLLocationCoordinate2D(
                                    latitude: replacement.latitude,
                                    longitude: replacement.longitude
                                )) {
                                    Image(systemName: "figure.walk.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                        .mapStyle(.standard(elevation: .flat))
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        LabeledContent("Distance", value: distanceLabel(walkingRoute.distanceMeters))
                        LabeledContent("Durée estimée", value: durationLabel(walkingRoute.expectedWalkingSeconds))
                        Label("Accessibilité du chemin non vérifiée", systemImage: "figure.roll")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Itinéraire piéton calculé à la demande par Apple Plans. Il ne remplace pas le tracé du bus et ne prouve pas l’accessibilité du chemin.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            Task { await calculateWalkingRoute() }
                        } label: {
                            Label("Calculer le trajet piéton", systemImage: "figure.walk")
                        }
                        .disabled(selectedReplacementStop == nil || isCalculatingRoute)
                    }

                    if let routingError {
                        Text(routingError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if walkingRoute != nil {
                        Button("Recalculer le trajet") {
                            Task { await calculateWalkingRoute() }
                        }
                        .disabled(selectedReplacementStop == nil || isCalculatingRoute)
                    }
                    }
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
            .navigationTitle(suspendsWholeLine ? "Suspendre la ligne · \(routeName)" : "Fermer un arrêt · \(routeName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(suspendsWholeLine ? "Suspendre la ligne" : "Fermer et rediriger") { saveClosure() }
                        .disabled(!canSave)
                }
            }
        }
        .task {
            if selectedReplacementStopID.isEmpty {
                selectedReplacementStopID = candidates.first?.stopID ?? ""
            }
        }
        .task(id: "\(selectedReplacementStopID)-\(suspendsWholeLine)") {
            guard !suspendsWholeLine, !selectedReplacementStopID.isEmpty else { return }
            await calculateWalkingRoute()
        }
        .alert("Fermeture impossible", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Une erreur est survenue.")
        }
        .environment(\.timeZone, GTFSServiceDate.parisTimeZone)
    }

    @MainActor
    private func calculateWalkingRoute() async {
        guard let replacement = selectedReplacementStop else { return }
        let requestedStopID = replacement.stopID
        let requestID = UUID()
        routingRequestID = requestID
        isCalculatingRoute = true
        walkingRoute = nil
        walkingRouteForReplacementStopID = nil
        routingError = nil
        do {
            let route = try await StopReplacementRouter.walkingRoute(from: stop, to: replacement)
            guard !Task.isCancelled,
                  routingRequestID == requestID,
                  selectedReplacementStopID == requestedStopID else { return }
            walkingRoute = route
            walkingRouteForReplacementStopID = requestedStopID
        } catch {
            guard !Task.isCancelled,
                  routingRequestID == requestID,
                  selectedReplacementStopID == requestedStopID else { return }
            walkingRoute = nil
            walkingRouteForReplacementStopID = nil
            routingError = error.localizedDescription
        }
        if routingRequestID == requestID {
            isCalculatingRoute = false
        }
    }

    private func saveClosure() {
        if suspendsWholeLine {
            do {
                try simulation.suspendRoute(
                    routeID: routeID,
                    routeName: routeName,
                    for: TimeInterval(durationHours * 60 * 60)
                )
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
            return
        }
        guard let replacement = selectedReplacementStop,
              let walkingRoute,
              walkingRouteForReplacementStopID == replacement.stopID else { return }
        let guide = StopClosureReplacementGuide(
            routeID: routeID,
            replacementStopID: replacement.stopID,
            replacementStopName: replacement.name,
            closedStopLatitude: stop.latitude,
            closedStopLongitude: stop.longitude,
            latitude: replacement.latitude,
            longitude: replacement.longitude,
            walkingCoordinates: walkingRoute.coordinates,
            walkingDistanceMeters: walkingRoute.distanceMeters,
            expectedWalkingSeconds: walkingRoute.expectedWalkingSeconds,
            accessibilityEvidence: .unknown
        )
        do {
            try simulation.closeStop(
                stopID: stop.stopID,
                stopName: stop.name,
                routeIDs: [routeID],
                for: TimeInterval(durationHours * 60 * 60),
                replacementGuidesByRouteID: [routeID: guide],
                passengerInformationMessage: passengerInformationMessage
            )
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func previewRegion(for route: StopReplacementWalkingRoute) -> MapCameraPosition {
        let latitudes = route.coordinates.map(\.latitude)
        let longitudes = route.coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? stop.latitude
        let maxLatitude = latitudes.max() ?? stop.latitude
        let minLongitude = longitudes.min() ?? stop.longitude
        let maxLongitude = longitudes.max() ?? stop.longitude
        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.008, (maxLatitude - minLatitude) * 1.7),
                longitudeDelta: max(0.008, (maxLongitude - minLongitude) * 1.7)
            )
        ))
    }

    private func distanceLabel(_ meters: Double) -> String {
        if meters >= 1_000 {
            return "\((meters / 1_000).formatted(.number.precision(.fractionLength(1)))) km"
        }
        return "\(Int(meters.rounded())) m"
    }

    private func durationLabel(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int((seconds / 60).rounded()))
        if minutes >= 60 { return "\(minutes / 60) h \(minutes % 60) min" }
        return "Environ \(minutes) min"
    }
}
