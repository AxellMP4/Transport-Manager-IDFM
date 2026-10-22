import CoreLocation
import MapKit

private enum VehicleDeadheadRouterError: LocalizedError {
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case let .unavailable(details):
            "Aucun acheminement routier vers le premier arrêt n’a pu être calculé. \(details)"
        }
    }
}

@MainActor
enum VehicleDeadheadRouter {
    static func routeForImmediateDispatch(
        from depot: DepotReference,
        to stop: ScheduledTripStopVisit,
        earliestDepartureAt: Date
    ) async throws -> VehicleDeadheadPlan {
        try await route(
            from: depot,
            to: stop,
            serviceStartAt: earliestDepartureAt,
            earliestDepartureAt: earliestDepartureAt,
            immediateDispatch: true
        )
    }

    static func route(
        from depot: DepotReference,
        to stop: ScheduledTripStopVisit,
        serviceStartAt: Date,
        earliestDepartureAt: Date,
        immediateDispatch: Bool = false
    ) async throws -> VehicleDeadheadPlan {
        guard immediateDispatch || serviceStartAt > earliestDepartureAt else {
            throw VehicleDeadheadRouterError.unavailable("L’heure de départ du service est déjà passée dans la simulation.")
        }
        guard isValid(CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) else {
            throw VehicleDeadheadRouterError.unavailable("Les coordonnées du premier arrêt sont invalides.")
        }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35),
            radius: 100_000,
            identifier: "Île-de-France"
        )
        let placemarks = try await CLGeocoder().geocodeAddressString(
            "\(depot.address), France",
            in: region
        )
        guard let placemark = placemarks.first(where: { $0.location != nil }),
              let originLocation = placemark.location,
              isValid(originLocation.coordinate) else {
            throw VehicleDeadheadRouterError.unavailable("L’adresse de \(depot.name) n’a pas donné de coordonnées valides.")
        }

        let destination = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: originLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        request.departureDate = .now

        let response = try await MKDirections(request: request).calculate()
        let plans = response.routes.compactMap { route -> VehicleDeadheadPlan? in
            guard route.distance.isFinite,
                  route.distance > 0,
                  route.expectedTravelTime.isFinite,
                  route.expectedTravelTime > 0,
                  let coordinates = coordinates(
                    for: route.polyline,
                    startingAt: originLocation.coordinate,
                    endingAt: destination
                  ) else { return nil }
            return VehicleDeadheadPlan(
                depotID: depot.id,
                depotName: depot.name,
                requestedDepotAddress: depot.address,
                resolvedDepotAddress: resolvedAddress(for: placemark) ?? depot.address,
                stopID: stop.stopID,
                stopName: stop.stopName,
                origin: BusMovementCoordinate(
                    latitude: originLocation.coordinate.latitude,
                    longitude: originLocation.coordinate.longitude
                ),
                destination: BusMovementCoordinate(latitude: stop.latitude, longitude: stop.longitude),
                routeDistanceMeters: route.distance,
                expectedTravelSeconds: route.expectedTravelTime,
                routeCoordinates: coordinates,
                calculatedAt: .now,
                routingSourceTitle: "Apple Plans · trajet automobile calculé à la demande"
            )
        }
        let feasiblePlans = plans.filter {
            immediateDispatch || serviceStartAt.addingTimeInterval(-$0.expectedTravelSeconds) >= earliestDepartureAt
        }
        guard let shortest = feasiblePlans.min(by: { $0.routeDistanceMeters < $1.routeDistanceMeters }) else {
            if !plans.isEmpty {
                throw VehicleDeadheadRouterError.unavailable("Aucun itinéraire MapKit n’arrive à temps au premier arrêt. Choisissez un bus déjà au premier arrêt ou un départ ultérieur.")
            }
            throw VehicleDeadheadRouterError.unavailable("MapKit n’a fourni aucun itinéraire valide.")
        }
        return shortest
    }

    static func routeToDepot(
        from bus: PurchasedBus,
        depot: DepotReference
    ) async throws -> VehicleDepotReturnPlan {
        guard bus.status == .atStop,
              bus.reservedTripKey == nil,
              bus.currentTripID == nil,
              bus.activeMovementLeg == nil,
              let latitude = bus.latitude,
              let longitude = bus.longitude,
              isValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            throw VehicleDeadheadRouterError.unavailable("Le bus doit être immobile à un arrêt et disposer de coordonnées valides.")
        }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35),
            radius: 100_000,
            identifier: "Île-de-France"
        )
        let placemarks = try await CLGeocoder().geocodeAddressString(
            "\(depot.address), France",
            in: region
        )
        guard let placemark = placemarks.first(where: { $0.location != nil }),
              let depotLocation = placemark.location,
              isValid(depotLocation.coordinate) else {
            throw VehicleDeadheadRouterError.unavailable("L’adresse de \(depot.name) n’a pas donné de coordonnées valides.")
        }

        let originCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: depotLocation.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        request.departureDate = .now

        let response = try await MKDirections(request: request).calculate()
        let plans = response.routes.compactMap { route -> VehicleDepotReturnPlan? in
            guard route.distance.isFinite,
                  route.distance > 0,
                  route.expectedTravelTime.isFinite,
                  route.expectedTravelTime > 0,
                  let routeCoordinates = coordinates(
                    for: route.polyline,
                    startingAt: originCoordinate,
                    endingAt: depotLocation.coordinate
                  ) else { return nil }
            return VehicleDepotReturnPlan(
                depotID: depot.id,
                depotName: depot.name,
                requestedDepotAddress: depot.address,
                resolvedDepotAddress: resolvedAddress(for: placemark) ?? depot.address,
                originBusID: bus.id,
                origin: BusMovementCoordinate(latitude: latitude, longitude: longitude),
                destination: BusMovementCoordinate(
                    latitude: depotLocation.coordinate.latitude,
                    longitude: depotLocation.coordinate.longitude
                ),
                routeDistanceMeters: route.distance,
                expectedTravelSeconds: route.expectedTravelTime,
                routeCoordinates: routeCoordinates,
                calculatedAt: .now,
                routingSourceTitle: "Apple Plans · trajet automobile calculé à la demande"
            )
        }
        guard let shortest = plans.min(by: { $0.routeDistanceMeters < $1.routeDistanceMeters }) else {
            throw VehicleDeadheadRouterError.unavailable("MapKit n’a fourni aucun itinéraire routier valide vers le dépôt.")
        }
        return shortest
    }

    private static func coordinates(
        for polyline: MKPolyline,
        startingAt origin: CLLocationCoordinate2D,
        endingAt destination: CLLocationCoordinate2D
    ) -> [BusMovementCoordinate]? {
        guard polyline.pointCount >= 2 else { return nil }
        var points = Array(
            repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            count: polyline.pointCount
        )
        polyline.getCoordinates(&points, range: NSRange(location: 0, length: polyline.pointCount))
        guard points.allSatisfy(isValid) else { return nil }

        let step = max(1, points.count / 150)
        var sampled = points.enumerated().compactMap { index, coordinate in
            index.isMultiple(of: step)
                ? BusMovementCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                : nil
        }
        if let last = points.last,
           sampled.last?.latitude != last.latitude || sampled.last?.longitude != last.longitude {
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
        let parts = [placemark.subThoroughfare, placemark.thoroughfare, placemark.postalCode, placemark.locality]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
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

private enum MachinistTransferRouterError: LocalizedError {
    case unavailable(String)
    case arrivesTooLate

    var errorDescription: String? {
        switch self {
        case let .unavailable(details):
            "Aucun trajet collectif estimé par MapKit depuis \(details)."
        case .arrivesTooLate:
            "Le trajet collectif estimé n’arrive pas à temps à l’arrêt. Choisissez un arrêt plus tardif."
        }
    }
}

@MainActor
enum MachinistTransferRouter {
    static func plan(for request: MachinistTransferRequest) async throws -> MachinistTransferPlan {
        let originCoordinate: CLLocationCoordinate2D
        if let coordinate = request.originCoordinate {
            originCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } else if let address = request.originAddress {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35),
                radius: 100_000,
                identifier: "Île-de-France"
            )
            let placemarks = try await CLGeocoder().geocodeAddressString("\(address), France", in: region)
            guard let location = placemarks.first(where: { $0.location != nil })?.location else {
                throw MachinistTransferRouterError.unavailable(request.originName)
            }
            originCoordinate = location.coordinate
        } else {
            throw MachinistTransferRouterError.unavailable(request.originName)
        }

        let destinationCoordinate = CLLocationCoordinate2D(
            latitude: request.stop.coordinate.latitude,
            longitude: request.stop.coordinate.longitude
        )
        guard isValid(originCoordinate), isValid(destinationCoordinate) else {
            throw MachinistTransferRouterError.unavailable(request.originName)
        }

        let originLocation = CLLocation(latitude: originCoordinate.latitude, longitude: originCoordinate.longitude)
        let destinationLocation = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
        let directDistance = originLocation.distance(from: destinationLocation)
        let expectedTravelSeconds: TimeInterval
        let sourceTitle: String
        if directDistance <= 30 {
            expectedTravelSeconds = 0
            sourceTitle = "Position déjà à l’arrêt"
        } else {
            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
            directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            directionsRequest.transportType = .transit
            directionsRequest.departureDate = .now
            let eta = try await MKDirections(request: directionsRequest).calculateETA()
            guard eta.expectedTravelTime.isFinite, eta.expectedTravelTime > 0 else {
                throw MachinistTransferRouterError.unavailable(request.originName)
            }
            expectedTravelSeconds = eta.expectedTravelTime
            sourceTitle = "Apple Plans · estimation en transports collectifs"
        }

        let expectedArrivalAt = request.earliestDepartureAt.addingTimeInterval(expectedTravelSeconds)
        guard expectedArrivalAt <= request.stop.scheduledAt else {
            throw MachinistTransferRouterError.arrivesTooLate
        }
        return MachinistTransferPlan(
            machinistID: request.machinistID,
            stopEventSequence: request.stop.eventSequence,
            stopID: request.stop.stopID,
            originName: request.originName,
            departureAt: request.earliestDepartureAt,
            expectedArrivalAt: expectedArrivalAt,
            expectedTravelSeconds: expectedTravelSeconds,
            routingSourceTitle: sourceTitle
        )
    }

    private static func isValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude.isFinite
            && coordinate.longitude.isFinite
            && (-90...90).contains(coordinate.latitude)
            && (-180...180).contains(coordinate.longitude)
    }
}
