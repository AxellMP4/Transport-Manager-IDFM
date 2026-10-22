import CryptoKit
import Foundation

struct LineReferenceImportResult: Sendable {
    let catalog: NetworkCatalog
    let references: [NetworkLineReference]
}

enum LineReferenceImportError: LocalizedError {
    case unreadableCSV
    case missingIdentifierColumn
    case noLineRecords

    var errorDescription: String? {
        switch self {
        case .unreadableCSV:
            "Le fichier doit être le CSV du référentiel des lignes IDFM."
        case .missingIdentifierColumn:
            "Le CSV ne contient pas la colonne ID_Line du référentiel IDFM."
        case .noLineRecords:
            "Aucune ligne exploitable n’a été trouvée dans ce CSV."
        }
    }
}

enum LineReferenceMatcher {
    static func canonicalIdentifier(_ identifier: String) -> String {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let uppercased = trimmed.uppercased()

        if uppercased.hasPrefix("STIF:LINE::") {
            return String(trimmed.dropFirst("STIF:Line::".count))
                .trimmingCharacters(in: CharacterSet(charactersIn: ": "))
                .uppercased()
        }
        if uppercased.hasPrefix("IDFM:") {
            return String(trimmed.dropFirst("IDFM:".count))
                .trimmingCharacters(in: CharacterSet(charactersIn: ": "))
                .uppercased()
        }
        return uppercased
    }

    static func uniqueIndex(for references: [NetworkLineReference]) -> [String: NetworkLineReference] {
        Dictionary(grouping: references, by: { canonicalIdentifier($0.idLine) })
            .compactMapValues { values in values.count == 1 ? values.first : nil }
    }

    static func reference(for route: GTFSRouteSummary, using index: [String: NetworkLineReference]) -> NetworkLineReference? {
        index[canonicalIdentifier(route.routeID)]
    }

    static func reference(for route: GTFSRouteSummary, among references: [NetworkLineReference]) -> NetworkLineReference? {
        reference(for: route, using: uniqueIndex(for: references))
    }

    static func unmatchedRouteIDs(
        for routes: [GTFSRouteSummary],
        among references: [NetworkLineReference]
    ) -> [String] {
        let referencesByID = Dictionary(grouping: references, by: { canonicalIdentifier($0.idLine) })
        return routes.compactMap { route in
            let id = canonicalIdentifier(route.routeID)
            return referencesByID[id]?.count == 1 ? nil : route.routeID
        }.sorted()
    }
}

enum LineReferenceStore {
    private static let datasetID = "referentiel-des-lignes"
    private static let datasetTitle = "Référentiel des lignes de transport en commun d’Île-de-France"
    private static let datasetURL = "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/referentiel-des-lignes"
    private static let licenseURL = "https://prim.iledefrance-mobilites.fr/fr/licences"
    static let sourceMetadataURL = URL(string: "https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/referentiel-des-lignes")!
    static let latestCSVExportURL = URL(string: "https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/referentiel-des-lignes/exports/csv?lang=fr&timezone=Europe%2FParis")!

    static func sourceDataProcessedAt(from metadataData: Data) -> Date? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(LineReferenceDatasetMetadata.self, from: metadataData).metas.defaults.dataProcessed
    }

    static func importCSV(from sourceURL: URL) throws -> LineReferenceImportResult {
        try importCSV(data: Data(contentsOf: sourceURL), originalFilename: sourceURL.lastPathComponent)
    }

    static func importCSV(
        data sourceData: Data,
        originalFilename: String,
        sourceDataProcessedAt: Date? = nil
    ) throws -> LineReferenceImportResult {
        var rows: [[String: String]] = []
        let table = CSVTableReader(columnsOfInterest: [], captureAllColumns: true) {
            rows.append($0)
        }
        do {
            try table.consume(sourceData)
            table.finish()
        } catch {
            throw LineReferenceImportError.unreadableCSV
        }

        guard table.hasColumn("id_line") || table.hasColumn("idline") else {
            throw LineReferenceImportError.missingIdentifierColumn
        }
        let references = rows.enumerated().compactMap { index, row in
            makeReference(row, index: index)
        }
        guard !references.isEmpty else { throw LineReferenceImportError.noLineRecords }

        let digest = SHA256.hash(data: sourceData).map { String(format: "%02x", $0) }.joined()
        let folder = String(digest.prefix(20))
        let relativePath = "line-references/\(folder)/idfm-line-reference.csv"
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(path: "line-references/\(folder)", directoryHint: .isDirectory)
        let storedSource = root.appending(path: relativePath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: storedSource.path) {
            try sourceData.write(to: storedSource, options: .atomic)
        }

        let indexEncoder = JSONEncoder()
        indexEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try indexEncoder.encode(references).write(
            to: directory.appending(path: "line-references.json"),
            options: .atomic
        )

        var catalog = try NetworkVersionStore.loadCatalog()
        let gtfsCoverage: [NetworkLineReferenceCoverage]
        if let gtfsVersion = catalog.activeVersion,
           let gtfsRoutes = try? NetworkVersionStore.loadBusRoutes(for: gtfsVersion) {
            gtfsCoverage = [coverage(for: gtfsRoutes, references: references, gtfsVersionID: gtfsVersion.id)]
        } else {
            gtfsCoverage = []
        }
        let version = NetworkLineReferenceVersion(
            id: digest,
            importedAt: Date(),
            sourceDataProcessedAt: sourceDataProcessedAt,
            sourceDatasetID: datasetID,
            sourceTitle: datasetTitle,
            sourceURL: datasetURL,
            license: "Licence ODbL (version française)",
            licenseURL: licenseURL,
            attribution: "Île-de-France Mobilités",
            originalFilename: originalFilename,
            archiveRelativePath: relativePath,
            sha256: digest,
            lineCount: references.count,
            gtfsCoverage: gtfsCoverage
        )

        let manifestEncoder = JSONEncoder()
        manifestEncoder.dateEncodingStrategy = .iso8601
        manifestEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try manifestEncoder.encode(version).write(
            to: directory.appending(path: "manifest.json"),
            options: .atomic
        )

        catalog.lineReferenceVersions.removeAll { $0.id == digest }
        catalog.lineReferenceVersions.append(version)
        catalog.lineReferenceVersions.sort { $0.importedAt < $1.importedAt }
        catalog.activeLineReferenceVersionID = digest
        setSourceState(
            in: &catalog,
            state: gtfsCoverage.first?.isComplete == true ? .imported : .needsReview
        )
        try NetworkVersionStore.saveCatalog(catalog)
        return LineReferenceImportResult(catalog: catalog, references: references)
    }

    static func loadReferences(for version: NetworkLineReferenceVersion) throws -> [NetworkLineReference] {
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(path: "line-references/\(String(version.sha256.prefix(20)))", directoryHint: .isDirectory)
        let indexURL = directory.appending(path: "line-references.json")
        return try JSONDecoder().decode([NetworkLineReference].self, from: Data(contentsOf: indexURL))
    }

    static func refreshCoverage(
        in catalog: inout NetworkCatalog,
        routes: [GTFSRouteSummary],
        forGTFSVersionID gtfsVersionID: String
    ) {
        guard let activeVersion = catalog.activeLineReferenceVersion else { return }
        guard let references = try? loadReferences(for: activeVersion),
              let versionIndex = catalog.lineReferenceVersions.firstIndex(where: { $0.id == activeVersion.id }) else {
            setSourceState(in: &catalog, state: .needsReview)
            return
        }

        let coverage = coverage(for: routes, references: references, gtfsVersionID: gtfsVersionID)
        var coverages = catalog.lineReferenceVersions[versionIndex].gtfsCoverage
        coverages.removeAll { $0.gtfsVersionID == gtfsVersionID }
        coverages.append(coverage)
        coverages.sort { $0.gtfsVersionID < $1.gtfsVersionID }
        catalog.lineReferenceVersions[versionIndex].gtfsCoverage = coverages
        setSourceState(in: &catalog, state: coverage.isComplete ? .imported : .needsReview)
    }

    private static func coverage(
        for routes: [GTFSRouteSummary],
        references: [NetworkLineReference],
        gtfsVersionID: String
    ) -> NetworkLineReferenceCoverage {
        let unmatchedIDs = LineReferenceMatcher.unmatchedRouteIDs(for: routes, among: references)
        return NetworkLineReferenceCoverage(
            gtfsVersionID: gtfsVersionID,
            matchedRouteCount: routes.count - unmatchedIDs.count,
            unmatchedRouteIDs: unmatchedIDs
        )
    }

    private static func setSourceState(in catalog: inout NetworkCatalog, state: SourceImportState) {
        catalog.sources = catalog.sources.map { source in
            var updated = source
            if source.id == "line-reference" { updated.state = state }
            return updated
        }
    }

    private static func makeReference(_ row: [String: String], index: Int) -> NetworkLineReference? {
        let keyed = Dictionary(row.map { (normalized($0.key), $0.value) }, uniquingKeysWith: { first, _ in first })
        guard let idLine = value(in: keyed, matching: ["idline", "idrefline", "lineid"]), !idLine.isEmpty else {
            return nil
        }

        return NetworkLineReference(
            id: "\(idLine)#\(index)",
            idLine: idLine,
            nameLine: value(in: keyed, matching: ["nameline", "namcommerciale", "nomligne"]) ?? "",
            shortNameLine: value(in: keyed, matching: ["shortnameline", "shortname", "nomcourtligne"]) ?? "",
            transportMode: value(in: keyed, matching: ["transportmode", "mode"]) ?? "",
            transportSubmode: value(in: keyed, matching: ["transportsubmode", "submode"]) ?? "",
            lineType: value(in: keyed, matching: ["type", "linetype"]) ?? "",
            operatorRef: value(in: keyed, matching: ["operatorref", "operatorreference"]) ?? "",
            additionalOperatorsRef: value(in: keyed, matching: ["additionaloperatorsref", "additionaloperatorref"]) ?? "",
            operatorName: value(in: keyed, matching: ["operatorname", "operator", "nomoperateur"]) ?? "",
            networkName: value(in: keyed, matching: ["networkname", "network"]) ?? "",
            webColor: value(in: keyed, matching: ["colourwebhexa", "colorwebhexa", "webcolor"]) ?? "",
            validFrom: value(in: keyed, matching: ["validfromdate", "validfrom"]) ?? "",
            validTo: value(in: keyed, matching: ["validtodate", "validto"]) ?? "",
            status: value(in: keyed, matching: ["status", "linestatus"]) ?? "",
            attributes: row
        )
    }

    private static func value(in keyed: [String: String], matching candidates: [String]) -> String? {
        for candidate in candidates {
            if let value = keyed[candidate]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func normalized(_ key: String) -> String {
        key.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}

private struct LineReferenceDatasetMetadata: Decodable {
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
