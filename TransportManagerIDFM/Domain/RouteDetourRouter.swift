import CoreLocation
import MapKit

struct RouteDetourCandidate: Identifiable, Hashable, Sendable {
    let id: String
    let routeDistanceMeters: Double
    let expectedTravelSeconds: TimeInterval
    let coordinates: [BusMovementCoordinate]
}

private enum RouteDetourRouterError: LocalizedError {
    case invalidStops
    case noValidAlternative

    var errorDescription: String? {
        switch self {
        case .invalidStops:
            "Les coordonnées des deux arrêts ne permettent pas de calculer une déviation."
        case .noValidAlternative:
            "Apple Plans n’a fourni aucun itinéraire automobile alternatif exploitable entre ces arrêts."
        }
    }
}

@MainActor
enum RouteDetourRouter {
    static func alternatives(
        from start: ScheduledTripStopVisit,
        to end: ScheduledTripStopVisit,
        departureAt: Date
    ) async throws -> [RouteDetourCandidate] {
        let origin = CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)
        let destination = CLLocationCoordinate2D(latitude: end.latitude, longitude: end.longitude)
        guard isValid(origin), isValid(destination), departureAt.timeIntervalSince1970.isFinite else {
            throw RouteDetourRouterError.invalidStops
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        request.departureDate = departureAt

        let response = try await MKDirections(request: request).calculate()
        let candidates = response.routes.enumerated().compactMap { index, route -> RouteDetourCandidate? in
            guard route.distance.isFinite,
                  route.distance > 0,
                  route.expectedTravelTime.isFinite,
                  route.expectedTravelTime > 0,
                  let coordinates = coordinates(
                      for: route.polyline,
                      startingAt: origin,
                      endingAt: destination
                  ),
                  pathDistance(coordinates) > 0 else { return nil }
            return RouteDetourCandidate(
                id: "\(index)-\(Int(route.distance.rounded()))-\(Int(route.expectedTravelTime.rounded()))",
                routeDistanceMeters: route.distance,
                expectedTravelSeconds: route.expectedTravelTime,
                coordinates: coordinates
            )
        }
        let orderedCandidates = candidates.sorted {
            if $0.expectedTravelSeconds != $1.expectedTravelSeconds {
                return $0.expectedTravelSeconds < $1.expectedTravelSeconds
            }
            if $0.routeDistanceMeters != $1.routeDistanceMeters {
                return $0.routeDistanceMeters < $1.routeDistanceMeters
            }
            return $0.id < $1.id
        }
        guard !orderedCandidates.isEmpty else { throw RouteDetourRouterError.noValidAlternative }
        return orderedCandidates
    }

    private static func coordinates(
        for polyline: MKPolyline,
        startingAt origin: CLLocationCoordinate2D,
        endingAt destination: CLLocationCoordinate2D
    ) -> [BusMovementCoordinate]? {
        guard polyline.pointCount >= 2 else { return nil }
        var points = Array(repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
        polyline.getCoordinates(&points, range: NSRange(location: 0, length: polyline.pointCount))
        guard points.allSatisfy(isValid) else { return nil }

        var coordinates = points.map {
            BusMovementCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
        coordinates[0] = BusMovementCoordinate(latitude: origin.latitude, longitude: origin.longitude)
        coordinates[coordinates.count - 1] = BusMovementCoordinate(
            latitude: destination.latitude,
            longitude: destination.longitude
        )
        return coordinates
    }

    private static func isValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude.isFinite
            && coordinate.longitude.isFinite
            && (-90...90).contains(coordinate.latitude)
            && (-180...180).contains(coordinate.longitude)
    }

    private static func pathDistance(_ coordinates: [BusMovementCoordinate]) -> Double {
        zip(coordinates, coordinates.dropFirst()).reduce(into: 0.0) { distance, segment in
            distance += CLLocation(
                latitude: segment.0.latitude,
                longitude: segment.0.longitude
            ).distance(from: CLLocation(
                latitude: segment.1.latitude,
                longitude: segment.1.longitude
            ))
        }
    }
}
