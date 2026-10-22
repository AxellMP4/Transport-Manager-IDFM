import CryptoKit
import Foundation

struct RouteGeometryImportResult: Sendable {
    let catalog: NetworkCatalog
    let geometries: [NetworkRouteGeometry]
}

enum RouteGeometryImportError: LocalizedError {
    case unreadableGeoJSON
    case unsupportedGeometry(String)
    case invalidCoordinates(String)
    case noLineFeatures

    var errorDescription: String? {
        switch self {
        case .unreadableGeoJSON:
            "Le fichier doit être un GeoJSON de lignes exporté depuis le portail IDFM."
        case let .unsupportedGeometry(type):
            "Le tracé utilise une géométrie GeoJSON non prise en charge : \(type)."
        case let .invalidCoordinates(lineID):
            "Le tracé de la ligne \(lineID) contient des coordonnées invalides."
        case .noLineFeatures:
            "Aucun tracé de ligne IDFM exploitable n’a été trouvé dans ce fichier."
        }
    }
}

enum RouteGeometryStore {
    private static let datasetID = "traces-des-lignes-regulieres-de-bus-en-ile-de-france"
    private static let datasetTitle = "Tracés des lignes régulières commerciales de bus en Île-de-France"
    private static let datasetURL = "https://data.iledefrance-mobilites.fr/explore/dataset/traces-des-lignes-regulieres-de-bus-en-ile-de-france/"
    static let latestGeoJSONExportURL = URL(string: "https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/traces-des-lignes-regulieres-de-bus-en-ile-de-france/exports/geojson?lang=fr&timezone=Europe%2FParis&main_geo_field=geo_shape")!

    static func importGeoJSON(from sourceURL: URL) throws -> RouteGeometryImportResult {
        try importGeoJSON(data: Data(contentsOf: sourceURL), originalFilename: sourceURL.lastPathComponent)
    }

    static func importGeoJSON(data sourceData: Data, originalFilename: String) throws -> RouteGeometryImportResult {
        let collection: GeoJSONFeatureCollection
        do {
            collection = try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: sourceData)
        } catch {
            throw RouteGeometryImportError.unreadableGeoJSON
        }

        guard collection.type == "FeatureCollection" else {
            throw RouteGeometryImportError.unreadableGeoJSON
        }

        let geometries = try collection.features.enumerated().map { index, feature in
            try makeGeometry(from: feature, index: index)
        }
        guard !geometries.isEmpty else { throw RouteGeometryImportError.noLineFeatures }

        let digest = SHA256.hash(data: sourceData).map { String(format: "%02x", $0) }.joined()
        let folder = String(digest.prefix(20))
        let relativePath = "geometries/\(folder)/idfm-bus-lines.geojson"
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(path: "geometries/\(folder)", directoryHint: .isDirectory)
        let storedSource = root.appending(path: relativePath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: storedSource.path) {
            try sourceData.write(to: storedSource, options: .atomic)
        }

        let indexEncoder = JSONEncoder()
        indexEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try indexEncoder.encode(geometries).write(
            to: directory.appending(path: "route-geometries.json"),
            options: .atomic
        )

        let version = NetworkGeometryVersion(
            id: digest,
            importedAt: Date(),
            sourceDatasetID: datasetID,
            sourceTitle: datasetTitle,
            sourceURL: datasetURL,
            license: "ODbL",
            licenseURL: datasetURL,
            attribution: "© les contributeurs OpenStreetMap",
            originalFilename: originalFilename,
            archiveRelativePath: relativePath,
            sha256: digest,
            featureCount: geometries.count
        )

        var catalog = try NetworkVersionStore.loadCatalog()
        catalog.geometryVersions.removeAll { $0.id == digest }
        catalog.geometryVersions.append(version)
        catalog.geometryVersions.sort { $0.importedAt < $1.importedAt }
        catalog.activeGeometryVersionID = digest
        catalog.sources = catalog.sources.map { source in
            var updated = source
            if source.id == "routes" { updated.state = .imported }
            return updated
        }
        try NetworkVersionStore.saveCatalog(catalog)

        let manifestEncoder = JSONEncoder()
        manifestEncoder.dateEncodingStrategy = .iso8601
        manifestEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try manifestEncoder.encode(version).write(to: directory.appending(path: "manifest.json"), options: .atomic)
        return RouteGeometryImportResult(catalog: catalog, geometries: geometries)
    }

    static func loadGeometries(for version: NetworkGeometryVersion) throws -> [NetworkRouteGeometry] {
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(path: "geometries/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let indexURL = directory.appending(path: "route-geometries.json")
        return try JSONDecoder().decode([NetworkRouteGeometry].self, from: Data(contentsOf: indexURL))
    }

    private static func makeGeometry(from feature: GeoJSONFeature, index: Int) throws -> NetworkRouteGeometry {
        let lineID = feature.properties.lineID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lineID.isEmpty else { throw RouteGeometryImportError.noLineFeatures }

        let paths = try feature.geometry.paths.map { rawPath -> [GeographicCoordinate] in
            let points = try rawPath.map { rawPosition -> GeographicCoordinate in
                guard rawPosition.count >= 2 else {
                    throw RouteGeometryImportError.invalidCoordinates(lineID)
                }
                let longitude = rawPosition[0]
                let latitude = rawPosition[1]
                guard latitude.isFinite, longitude.isFinite,
                      (-90...90).contains(latitude), (-180...180).contains(longitude) else {
                    throw RouteGeometryImportError.invalidCoordinates(lineID)
                }
                return GeographicCoordinate(latitude: latitude, longitude: longitude)
            }
            guard points.count >= 2 else { throw RouteGeometryImportError.invalidCoordinates(lineID) }
            return points
        }

        guard !paths.isEmpty else { throw RouteGeometryImportError.invalidCoordinates(lineID) }
        return NetworkRouteGeometry(
            id: "\(lineID)#\(index)",
            lineID: lineID,
            shortName: feature.properties.shortName,
            longName: feature.properties.longName,
            operatorName: feature.properties.operatorName,
            color: feature.properties.color,
            updated: feature.properties.updated,
            paths: paths
        )
    }
}

private struct GeoJSONFeatureCollection: Decodable {
    let type: String
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONGeometry
    let properties: GeoJSONLineProperties
}

private struct GeoJSONLineProperties: Decodable {
    let lineID: String
    let shortName: String
    let longName: String
    let operatorName: String
    let color: String
    let updated: String

    private enum CodingKeys: String, CodingKey {
        case lineID = "lineid"
        case shortName = "lineshortn"
        case longName = "linename"
        case operatorName = "operatorid"
        case color = "linecolor"
        case updated
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lineID = try values.decodeIfPresent(String.self, forKey: .lineID) ?? ""
        shortName = try values.decodeIfPresent(String.self, forKey: .shortName) ?? ""
        longName = try values.decodeIfPresent(String.self, forKey: .longName) ?? ""
        operatorName = try values.decodeIfPresent(String.self, forKey: .operatorName) ?? ""
        color = try values.decodeIfPresent(String.self, forKey: .color) ?? ""
        updated = try values.decodeIfPresent(String.self, forKey: .updated) ?? ""
    }
}

private struct GeoJSONGeometry: Decodable {
    let paths: [[[Double]]]

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "LineString":
            paths = [try values.decode([[Double]].self, forKey: .coordinates)]
        case "MultiLineString":
            paths = try values.decode([[[Double]]].self, forKey: .coordinates)
        default:
            throw RouteGeometryImportError.unsupportedGeometry(type)
        }
    }
}
