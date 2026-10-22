import CoreLocation
import MapKit

struct StopReplacementWalkingRoute: Hashable, Sendable {
    let distanceMeters: Double
    let expectedWalkingSeconds: TimeInterval
    let coordinates: [BusMovementCoordinate]
}

private enum StopReplacementRouterError: LocalizedError {
    case invalidStops
    case noUsableWalkingRoute

    var errorDescription: String? {
        switch self {
        case .invalidStops:
            "Les coordonnées des arrêts ne permettent pas de calculer un trajet piéton."
        case .noUsableWalkingRoute:
            "Apple Plans n’a fourni aucun trajet piéton exploitable entre ces arrêts."
        }
    }
}

@MainActor
enum StopReplacementRouter {
    static func walkingRoute(
        from origin: GTFSStopSummary,
        to destination: GTFSStopSummary
    ) async throws -> StopReplacementWalkingRoute {
        guard origin.stopID != destination.stopID,
              isValid(origin.latitude, origin.longitude),
              isValid(destination.latitude, destination.longitude) else {
            throw StopReplacementRouterError.invalidStops
        }

        let originCoordinate = CLLocationCoordinate2D(
            latitude: origin.latitude,
            longitude: origin.longitude
        )
        let destinationCoordinate = CLLocationCoordinate2D(
            latitude: destination.latitude,
            longitude: destination.longitude
        )
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.transportType = .walking

        let response = try await MKDirections(request: request).calculate()
        let route = response.routes
            .filter {
                $0.distance.isFinite
                    && $0.distance > 0
                    && $0.expectedTravelTime.isFinite
                    && $0.expectedTravelTime > 0
            }
            .min { $0.expectedTravelTime < $1.expectedTravelTime }
        guard let route,
              let coordinates = coordinates(
                  for: route.polyline,
                  startingAt: originCoordinate,
                  endingAt: destinationCoordinate
              ),
              pathDistance(coordinates) > 0 else {
            throw StopReplacementRouterError.noUsableWalkingRoute
        }

        return StopReplacementWalkingRoute(
            distanceMeters: route.distance,
            expectedWalkingSeconds: route.expectedTravelTime,
            coordinates: coordinates
        )
    }

    private static func coordinates(
        for polyline: MKPolyline,
        startingAt origin: CLLocationCoordinate2D,
        endingAt destination: CLLocationCoordinate2D
    ) -> [BusMovementCoordinate]? {
        guard polyline.pointCount >= 2 else { return nil }
        var points = Array(repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
        polyline.getCoordinates(&points, range: NSRange(location: 0, length: polyline.pointCount))
        guard points.allSatisfy({ isValid($0.latitude, $0.longitude) }) else { return nil }
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

    private static func isValid(_ latitude: Double, _ longitude: Double) -> Bool {
        latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
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
