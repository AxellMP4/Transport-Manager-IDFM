import CryptoKit
import Foundation

indirect enum ContractJSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([ContractJSONValue])
    case object([String: ContractJSONValue])
    case null

    var textValue: String? {
        switch self {
        case let .string(value): value
        case let .number(value):
            if value.rounded() == value,
               value >= Double(Int64.min),
               value < Double(Int64.max) {
                String(Int64(value))
            } else {
                String(value)
            }
        case let .bool(value): String(value)
        case .array, .object, .null: nil
        }
    }

    var searchableText: String {
        switch self {
        case let .string(value): value
        case let .number(value): textValue ?? String(value)
        case let .bool(value): String(value)
        case let .array(values): values.map(\.searchableText).joined(separator: " ")
        case let .object(values): values.values.map(\.searchableText).joined(separator: " ")
        case .null: ""
        }
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() {
            self = .null
        } else if let string = try? value.decode(String.self) {
            self = .string(string)
        } else if let bool = try? value.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? value.decode(Double.self) {
            self = .number(number)
        } else if let array = try? value.decode([ContractJSONValue].self) {
            self = .array(array)
        } else if let object = try? value.decode([String: ContractJSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: value, debugDescription: "Valeur JSON de propriété non reconnue")
        }
    }

    func encode(to encoder: Encoder) throws {
        var value = encoder.singleValueContainer()
        switch self {
        case let .string(string): try value.encode(string)
        case let .number(number): try value.encode(number)
        case let .bool(bool): try value.encode(bool)
        case let .array(array): try value.encode(array)
        case let .object(object): try value.encode(object)
        case .null: try value.encodeNil()
        }
    }
}

struct ContractGeometryImportResult: Sendable {
    let catalog: NetworkCatalog
    let features: [NetworkContractFeature]
}

enum ContractGeometryImportError: LocalizedError {
    case unreadableGeoJSON
    case unsupportedGeometry(String)
    case invalidCoordinates
    case noContractFeatures

    var errorDescription: String? {
        switch self {
        case .unreadableGeoJSON:
            "Le fichier doit être un GeoJSON de contours exporté depuis le portail IDFM."
        case let .unsupportedGeometry(type):
            "Le contour utilise une géométrie GeoJSON non prise en charge : \(type)."
        case .invalidCoordinates:
            "Un contour contient des coordonnées invalides."
        case .noContractFeatures:
            "Aucun contour de contrat de bus n’a été trouvé dans ce fichier."
        }
    }
}

enum ContractGeometryStore {
    private static let datasetID = "contours-des-contrats"
    private static let datasetTitle = "Contours des contrats d’exploitation bus"
    private static let datasetURL = "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/contours-des-contrats"
    static let sourceMetadataURL = URL(string: "https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/contours-des-contrats")!
    static let latestGeoJSONExportURL = URL(string: "https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/contours-des-contrats/exports/geojson?lang=fr&timezone=Europe%2FParis")!

    static func sourceDataProcessedAt(from metadataData: Data) -> Date? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ContractDatasetMetadata.self, from: metadataData).metas.defaults.dataProcessed
    }

    static func importGeoJSON(from sourceURL: URL) throws -> ContractGeometryImportResult {
        let sourceData = try Data(contentsOf: sourceURL)
        return try importGeoJSON(data: sourceData, originalFilename: sourceURL.lastPathComponent)
    }

    static func importGeoJSON(
        data sourceData: Data,
        originalFilename: String,
        sourceDataProcessedAt: Date? = nil
    ) throws -> ContractGeometryImportResult {
        let collection: ContractFeatureCollection
        do {
            collection = try JSONDecoder().decode(ContractFeatureCollection.self, from: sourceData)
        } catch let error as ContractGeometryImportError {
            throw error
        } catch {
            throw ContractGeometryImportError.unreadableGeoJSON
        }
        guard collection.type == "FeatureCollection", !collection.features.isEmpty else {
            throw ContractGeometryImportError.noContractFeatures
        }

        let digest = SHA256.hash(data: sourceData).map { String(format: "%02x", $0) }.joined()
        let features = try collection.features.enumerated().map { index, feature in
            try makeFeature(feature, index: index, digest: digest)
        }
        let unresolvedCount = features.filter { $0.contractID == nil }.count
        let folder = String(digest.prefix(20))
        let relativePath = "contracts/\(folder)/idfm-contract-contours.geojson"
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(path: "contracts/\(folder)", directoryHint: .isDirectory)
        let storedSource = root.appending(path: relativePath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: storedSource.path) {
            try sourceData.write(to: storedSource, options: .atomic)
        }

        let indexEncoder = JSONEncoder()
        indexEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try indexEncoder.encode(features).write(
            to: directory.appending(path: "contract-features.json"),
            options: .atomic
        )

        let version = NetworkContractVersion(
            id: digest,
            importedAt: Date(),
            sourceDataProcessedAt: sourceDataProcessedAt,
            sourceDatasetID: datasetID,
            sourceTitle: datasetTitle,
            sourceURL: datasetURL,
            license: "Licence Ouverte v2.0 (Etalab)",
            licenseURL: "https://prim.iledefrance-mobilites.fr/fr/licences",
            attribution: "Île-de-France Mobilités • contours établis à partir de la BD TOPO IGN",
            originalFilename: originalFilename,
            archiveRelativePath: relativePath,
            sha256: digest,
            featureCount: features.count,
            unresolvedFeatureCount: unresolvedCount
        )

        var catalog = try NetworkVersionStore.loadCatalog()
        catalog.contractVersions.removeAll { $0.id == digest }
        catalog.contractVersions.append(version)
        catalog.contractVersions.sort { $0.importedAt < $1.importedAt }
        catalog.activeContractVersionID = digest
        catalog.sources = catalog.sources.map { source in
            var updated = source
            if source.id == "contracts" {
                // The polygon layer contains commune aggregates, not line-to-contract or
                // contract-to-depot assignments. Keep that relationship gate explicit.
                updated.state = .needsReview
            }
            return updated
        }
        try NetworkVersionStore.saveCatalog(catalog)

        let manifestEncoder = JSONEncoder()
        manifestEncoder.dateEncodingStrategy = .iso8601
        manifestEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try manifestEncoder.encode(version).write(to: directory.appending(path: "manifest.json"), options: .atomic)
        return ContractGeometryImportResult(catalog: catalog, features: features)
    }

    static func loadFeatures(for version: NetworkContractVersion) throws -> [NetworkContractFeature] {
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(path: "contracts/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let indexURL = directory.appending(path: "contract-features.json")
        return try JSONDecoder().decode([NetworkContractFeature].self, from: Data(contentsOf: indexURL))
    }

    private static func makeFeature(
        _ feature: ContractGeoJSONFeature,
        index: Int,
        digest: String
    ) throws -> NetworkContractFeature {
        let outlines = try feature.geometry.rings.map { ring -> [GeographicCoordinate] in
            let points = try ring.map { position -> GeographicCoordinate in
                guard position.count >= 2 else { throw ContractGeometryImportError.invalidCoordinates }
                let longitude = position[0]
                let latitude = position[1]
                guard latitude.isFinite, longitude.isFinite,
                      (-90...90).contains(latitude), (-180...180).contains(longitude) else {
                    throw ContractGeometryImportError.invalidCoordinates
                }
                return GeographicCoordinate(latitude: latitude, longitude: longitude)
            }
            guard points.count >= 4 else { throw ContractGeometryImportError.invalidCoordinates }
            return points
        }
        guard !outlines.isEmpty else { throw ContractGeometryImportError.invalidCoordinates }

        let contractID = propertyValue(in: feature.properties, matching: [
            "idcontrat", "identifiantcontrat", "numerocontrat", "numcontrat",
            "codecontrat", "codcontrat", "contractid", "contractcode", "idcontract"
        ])
        let name = propertyValue(in: feature.properties, matching: [
            "nomcontrat", "libellecontrat", "intitulecontrat", "contractname", "name", "nom"
        ])
        let operatorName = propertyValue(in: feature.properties, matching: [
            "nomexploitant", "exploitant", "nomoperateur", "operateur", "operatorname", "operator"
        ])

        return NetworkContractFeature(
            id: "\(String(digest.prefix(16)))-\(index)",
            contractID: contractID,
            name: name,
            operatorName: operatorName,
            attributes: feature.properties,
            outlines: outlines
        )
    }

    private static func propertyValue(in properties: [String: ContractJSONValue], matching candidates: [String]) -> String? {
        for candidate in candidates {
            for key in properties.keys.sorted() where normalized(key) == candidate {
                if let text = properties[key]?.textValue?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                    return text
                }
            }
        }
        return nil
    }

    private static func normalized(_ key: String) -> String {
        key.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}

private struct ContractFeatureCollection: Decodable {
    let type: String
    let features: [ContractGeoJSONFeature]
}

private struct ContractDatasetMetadata: Decodable {
    let metas: Metas

    struct Metas: Decodable {
        let defaults: Defaults

        enum CodingKeys: String, CodingKey {
            case defaults = "default"
        }
    }

    struct Defaults: Decodable {
        let dataProcessed: Date?

        enum CodingKeys: String, CodingKey {
            case dataProcessed = "data_processed"
        }
    }
}

private struct ContractGeoJSONFeature: Decodable {
    let geometry: ContractGeoJSONGeometry
    let properties: [String: ContractJSONValue]
}

private struct ContractGeoJSONGeometry: Decodable {
    let rings: [[[Double]]]

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "Polygon":
            rings = try values.decode([[[Double]]].self, forKey: .coordinates)
        case "MultiPolygon":
            rings = try values.decode([[[[Double]]]].self, forKey: .coordinates).flatMap { $0 }
        default:
            throw ContractGeometryImportError.unsupportedGeometry(type)
        }
    }
}
