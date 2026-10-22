import CryptoKit
import Foundation

struct LineDocumentImportResult: Sendable {
    let catalog: NetworkCatalog
    let documents: [NetworkLineDocument]
}

enum LineDocumentImportError: LocalizedError {
    case unreadableCSV
    case missingIdentifierColumn
    case missingDocumentColumn

    var errorDescription: String? {
        switch self {
        case .unreadableCSV:
            "Le fichier doit être le CSV IDFM des plans et fiches horaires."
        case .missingIdentifierColumn:
            "Le CSV ne contient pas la colonne ID_Line."
        case .missingDocumentColumn:
            "Le CSV ne contient pas les colonnes Document_Name et URL."
        }
    }
}

private enum ParsedDocumentRow {
    case document(NetworkLineDocument)
    case issue(NetworkLineDocumentImportIssue)
}

enum LineDocumentStore {
    private static let datasetID = "fiches-horaires-et-plans"
    private static let datasetTitle = "Liens fiches horaires et plans des lignes de transport en commun d’Île-de-France"
    private static let datasetURL = "https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/"
    private static let licenseURL = "https://www.etalab.gouv.fr/licence-ouverte-open-licence"
    static let latestCSVExportURL = URL(string: "https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets/fiches-horaires-et-plans/exports/csv?lang=fr&timezone=Europe%2FParis")!

    static func importCSV(from sourceURL: URL) throws -> LineDocumentImportResult {
        try importCSV(data: Data(contentsOf: sourceURL), originalFilename: sourceURL.lastPathComponent)
    }

    static func importCSV(data sourceData: Data, originalFilename: String) throws -> LineDocumentImportResult {
        var documents: [NetworkLineDocument] = []
        var issues: [NetworkLineDocumentImportIssue] = []
        var sourceRecordNumber = 0
        let table = CSVTableReader(columnsOfInterest: [], captureAllColumns: true) { row in
            sourceRecordNumber += 1
            switch parseDocument(row, sourceRecordNumber: sourceRecordNumber) {
            case .document(let document):
                documents.append(document)
            case .issue(let issue):
                issues.append(issue)
            }
        }
        do {
            try table.consume(sourceData)
            table.finish()
        } catch {
            throw LineDocumentImportError.unreadableCSV
        }

        guard table.hasColumn("id_line") || table.hasColumn("idline") else {
            throw LineDocumentImportError.missingIdentifierColumn
        }
        guard (table.hasColumn("document_name") || table.hasColumn("documentname"))
                && table.hasColumn("url") else {
            throw LineDocumentImportError.missingDocumentColumn
        }
        let digest = SHA256.hash(data: sourceData).map { String(format: "%02x", $0) }.joined()
        let versionFolder = String(digest.prefix(20))
        let relativePath = "line-documents/\(versionFolder)/idfm-line-documents.csv"
        let issuesRelativePath = "line-documents/\(versionFolder)/line-document-import-issues.json"
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(path: "line-documents/\(versionFolder)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storedSource = root.appending(path: relativePath)
        if !FileManager.default.fileExists(atPath: storedSource.path) {
            try sourceData.write(to: storedSource, options: .atomic)
        }

        let indexEncoder = JSONEncoder()
        indexEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try indexEncoder.encode(documents).write(
            to: directory.appending(path: "line-documents.json"),
            options: .atomic
        )
        try indexEncoder.encode(issues).write(
            to: directory.appending(path: "line-document-import-issues.json"),
            options: .atomic
        )

        var catalog = try NetworkVersionStore.loadCatalog()
        let version = NetworkLineDocumentVersion(
            id: digest,
            importedAt: Date(),
            sourceDatasetID: datasetID,
            sourceTitle: datasetTitle,
            sourceURL: datasetURL,
            license: "Licence Ouverte v2.0 (Etalab)",
            licenseURL: licenseURL,
            attribution: "Île-de-France Mobilités",
            originalFilename: originalFilename,
            archiveRelativePath: relativePath,
            sha256: digest,
            recordCount: documents.count,
            skippedRecordCount: issues.count,
            importIssuesRelativePath: issuesRelativePath
        )
        catalog.lineDocumentVersions.removeAll { $0.id == digest }
        catalog.lineDocumentVersions.append(version)
        catalog.lineDocumentVersions.sort { $0.importedAt < $1.importedAt }
        catalog.activeLineDocumentVersionID = digest
        catalog.sources = catalog.sources.map { source in
            guard source.id == "plans" else { return source }
            var updated = source
            updated.state = issues.isEmpty ? .imported : .needsReview
            return updated
        }
        try NetworkVersionStore.saveCatalog(catalog)
        return LineDocumentImportResult(catalog: catalog, documents: documents)
    }

    static func loadDocuments(for version: NetworkLineDocumentVersion) throws -> [NetworkLineDocument] {
        let root = try NetworkVersionStore.rootDirectory()
        let directory = root.appending(
            path: "line-documents/\(String(version.sha256.prefix(20)))",
            directoryHint: .isDirectory
        )
        return try JSONDecoder().decode(
            [NetworkLineDocument].self,
            from: Data(contentsOf: directory.appending(path: "line-documents.json"))
        )
    }

    static func loadImportIssues(for version: NetworkLineDocumentVersion) throws -> [NetworkLineDocumentImportIssue] {
        guard let relativePath = version.importIssuesRelativePath else { return [] }
        let root = try NetworkVersionStore.rootDirectory()
        return try JSONDecoder().decode(
            [NetworkLineDocumentImportIssue].self,
            from: Data(contentsOf: root.appending(path: relativePath))
        )
    }

    private static func parseDocument(_ row: [String: String], sourceRecordNumber: Int) -> ParsedDocumentRow {
        let keyed = Dictionary(row.map { (normalized($0.key), $0.value) }, uniquingKeysWith: { first, _ in first })
        let idLine = value(in: keyed, matching: ["idline"])
        let documentName = value(in: keyed, matching: ["documentname"])
        let rawURL = value(in: keyed, matching: ["url"])
        let reason: String?
        if idLine == nil {
            reason = "ID_Line absent ou vide"
        } else if documentName == nil {
            reason = "Document_Name absent ou vide"
        } else if rawURL == nil {
            reason = "URL absente ou vide"
        } else if let rawURL,
                  let url = URL(string: rawURL),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  url.host != nil {
            reason = nil
        } else {
            reason = "URL invalide ou hors HTTP/HTTPS"
        }

        if let reason {
            return .issue(NetworkLineDocumentImportIssue(
                sourceRecordNumber: sourceRecordNumber,
                reason: reason,
                idLine: idLine,
                documentName: documentName,
                documentURL: rawURL,
                attributes: row
            ))
        }

        guard let idLine, let documentName, let rawURL else {
            return .issue(NetworkLineDocumentImportIssue(
                sourceRecordNumber: sourceRecordNumber,
                reason: "Champs document incomplets",
                idLine: idLine,
                documentName: documentName,
                documentURL: rawURL,
                attributes: row
            ))
        }

        return .document(NetworkLineDocument(
            id: "\(idLine)#\(sourceRecordNumber - 1)",
            idLine: idLine,
            documentName: documentName,
            documentURL: rawURL,
            documentType: value(in: keyed, matching: ["type"]) ?? "",
            lineName: value(in: keyed, matching: ["nameline", "shortnameline"]) ?? "",
            attributes: row
        ))
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
