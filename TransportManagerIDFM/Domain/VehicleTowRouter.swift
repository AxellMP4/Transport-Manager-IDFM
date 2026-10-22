import CoreLocation
import MapKit

private enum VehicleTowRouterError: LocalizedError {
    case noDepots
    case noUsableRoute(String?)

    var errorDescription: String? {
        switch self {
        case .noDepots:
            "Aucun dépôt disposant d’une adresse publiée n’est configuré pour ce scénario."
        case let .noUsableRoute(details):
            if let details, !details.isEmpty {
                "Aucun itinéraire automobile de dépêche et de remorquage n’a pu être calculé. \(details)"
            } else {
                "Aucun itinéraire automobile de dépêche et de remorquage n’a pu être calculé."
            }
        }
    }
}

@MainActor
enum VehicleTowRouter {
    static func nearestDepot(
        from incident: CLLocationCoordinate2D,
        depots: [DepotReference],
        teamAvailableAt: Date
    ) async throws -> VehicleTowPlan {
        guard !depots.isEmpty else { throw VehicleTowRouterError.noDepots }
        guard isValid(incident) else { throw VehicleTowRouterError.noUsableRoute("Position de panne invalide.") }

        let searchRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35),
            radius: 100_000,
            identifier: "Île-de-France"
        )
        var plans: [VehicleTowPlan] = []
        var lastError: String?

        for depot in depots {
            try Task.checkCancellation()
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.geocodeAddressString(
                    "\(depot.address), France",
                    in: searchRegion
                )
                guard let placemark = placemarks.first(where: { $0.location != nil }),
                      let location = placemark.location,
                      isValid(location.coordinate) else {
                    lastError = "L’adresse de \(depot.name) n’a pas donné de coordonnées valides."
                    continue
                }

                let dispatchResponse = try await automobileRoute(
                    from: location.coordinate,
                    to: incident
                )
                let towResponse = try await automobileRoute(
                    from: incident,
                    to: location.coordinate
                )
                let dispatchRoutes = dispatchResponse.routes.compactMap { route -> (MKRoute, [BusMovementCoordinate])? in
                    guard route.distance.isFinite,
                          route.distance > 0,
                          route.expectedTravelTime.isFinite,
                          route.expectedTravelTime > 0,
                          let coordinates = coordinates(for: route.polyline, startingAt: location.coordinate, endingAt: incident) else {
                        return nil
                    }
                    return (route, coordinates)
                }
                let towRoutes = towResponse.routes.compactMap { route -> (MKRoute, [BusMovementCoordinate])? in
                    guard route.distance.isFinite,
                          route.distance > 0,
                          route.expectedTravelTime.isFinite,
                          route.expectedTravelTime > 0,
                          let coordinates = coordinates(for: route.polyline, startingAt: incident, endingAt: location.coordinate) else {
                        return nil
                    }
                    return (route, coordinates)
                }

                for (dispatchRoute, dispatchCoordinates) in dispatchRoutes {
                    for (towRoute, towCoordinates) in towRoutes {
                        plans.append(VehicleTowPlan(
                            depotID: depot.id,
                            depotName: depot.name,
                            resolvedDepotAddress: resolvedAddress(for: placemark) ?? depot.address,
                            routeDistanceMeters: towRoute.distance,
                            expectedTravelSeconds: towRoute.expectedTravelTime,
                            destination: BusMovementCoordinate(
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude
                            ),
                            routeCoordinates: towCoordinates,
                            calculatedAt: .now,
                            routingSourceTitle: "Apple Plans · deux trajets automobiles calculés à la demande",
                            recoveryTeamID: VehicleRecoveryRules.teamID(for: depot.id),
                            recoveryTeamName: VehicleRecoveryRules.teamName(for: depot.name),
                            dispatchStartsAt: teamAvailableAt,
                            dispatchRouteDistanceMeters: dispatchRoute.distance,
                            dispatchExpectedTravelSeconds: dispatchRoute.expectedTravelTime,
                            dispatchRouteCoordinates: dispatchCoordinates
                        ))
                    }
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error.localizedDescription
            }
        }

        guard let fastest = plans.min(by: {
            $0.totalServiceDistanceMeters < $1.totalServiceDistanceMeters
        }) else {
            throw VehicleTowRouterError.noUsableRoute(lastError)
        }
        return fastest
    }

    private static func automobileRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKDirections.Response {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        request.departureDate = .now
        return try await MKDirections(request: request).calculate()
    }

    private static func coordinates(
        for polyline: MKPolyline,
        startingAt origin: CLLocationCoordinate2D,
        endingAt destination: CLLocationCoordinate2D
    ) -> [BusMovementCoordinate]? {
        guard polyline.pointCount >= 2 else { return nil }
        var rawCoordinates = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: polyline.pointCount
        )
        polyline.getCoordinates(&rawCoordinates, range: NSRange(location: 0, length: polyline.pointCount))
        guard rawCoordinates.allSatisfy(isValid) else { return nil }

        let strideSize = max(1, rawCoordinates.count / 150)
        var sampled = rawCoordinates.enumerated().compactMap { offset, coordinate in
            offset.isMultiple(of: strideSize)
                ? BusMovementCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                : nil
        }
        if let last = rawCoordinates.last,
           let lastSample = sampled.last,
           (last.latitude != lastSample.latitude || last.longitude != lastSample.longitude) {
            sampled.append(BusMovementCoordinate(latitude: last.latitude, longitude: last.longitude))
        }

        let start = BusMovementCoordinate(latitude: origin.latitude, longitude: origin.longitude)
        let end = BusMovementCoordinate(latitude: destination.latitude, longitude: destination.longitude)
        if sampled.first?.latitude != start.latitude || sampled.first?.longitude != start.longitude {
            sampled.insert(start, at: 0)
        }
        if sampled.last?.latitude != end.latitude || sampled.last?.longitude != end.longitude {
            sampled.append(end)
        }
        return sampled.count >= 2 ? sampled : nil
    }

    private static func resolvedAddress(for placemark: CLPlacemark) -> String? {
        let parts = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.postalCode,
            placemark.locality
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private static func isValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude.isFinite
            && coordinate.longitude.isFinite
            && (-90...90).contains(coordinate.latitude)
            && (-180...180).contains(coordinate.longitude)
    }
}
