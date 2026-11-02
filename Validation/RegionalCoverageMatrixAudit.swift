import CryptoKit
import Foundation

private struct RegionalCoverageSourceFile: Codable, Sendable {
    let name: String
    let sha256: String
    let byteCount: Int
    let dataset: String
    let sourceURL: String
    let snapshotDate: String
    let processedAt: String?
    let sourceObservation: String
    let provenance: String
}

private struct RegionalCoverageReportSources: Codable, Sendable {
    let gtfs: RegionalCoverageSourceFile
    let lineReferences: RegionalCoverageSourceFile
    let lineDocuments: RegionalCoverageSourceFile
    let commercialGeometryArchive: RegionalCoverageSourceFile
    let commercialGeometryGeoJSON: RegionalCoverageSourceFile
}

private struct RegionalCoverageReport: Codable, Sendable {
    let schemaVersion: Int
    let serviceDate: String
    let sources: RegionalCoverageReportSources
    let matrix: RegionalCoverageMatrix
    let limitations: [String]
}

@main
struct RegionalCoverageMatrixAudit {
    static func main() throws {
        guard CommandLine.arguments.count == 8 else {
            fputs(
                "Usage: RegionalCoverageMatrixAudit <gtfs.zip> <idfm-lines.csv> <line-documents.csv> <commercial-geometry.geojson> <commercial-geometry.zip> <output.json> <YYYY-MM-DD>\n",
                stderr
            )
            exit(2)
        }

        let gtfsURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let lineReferencesURL = URL(fileURLWithPath: CommandLine.arguments[2])
        let lineDocumentsURL = URL(fileURLWithPath: CommandLine.arguments[3])
        let geometryURL = URL(fileURLWithPath: CommandLine.arguments[4])
        let geometryArchiveURL = URL(fileURLWithPath: CommandLine.arguments[5])
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[6])
        let serviceDateText = CommandLine.arguments[7]
        let compactDate = serviceDateText.replacingOccurrences(of: "-", with: "")
        guard compactDate.count == 8,
              let serviceDate = GTFSServiceDate.date(from: compactDate),
              isoDate(serviceDate) == serviceDateText else {
            fputs("Invalid service date: \(serviceDateText)\n", stderr)
            exit(2)
        }

        let gtfsData = try Data(contentsOf: gtfsURL, options: .mappedIfSafe)
        let lineReferencesData = try Data(contentsOf: lineReferencesURL, options: .mappedIfSafe)
        let lineDocumentsData = try Data(contentsOf: lineDocumentsURL, options: .mappedIfSafe)
        let geometryData = try Data(contentsOf: geometryURL, options: .mappedIfSafe)
        let geometryArchiveData = try Data(contentsOf: geometryArchiveURL, options: .mappedIfSafe)

        let references = try LineReferenceStore.parseCSV(data: lineReferencesData)
        let documentParse = try LineDocumentStore.parseCSV(data: lineDocumentsData)
        let geometries = try RouteGeometryStore.parseGeoJSON(data: geometryData)
        print("STAGE Inspecting the date-pinned regional GTFS feed")
        fflush(stdout)
        let inspection = try GTFSFeedInspector.inspect(gtfsURL) { progress in
            if progress.stage != .tripDiagnostics {
                print("STAGE \(progress.stage.title)")
                fflush(stdout)
            }
        }
        let matrix = RegionalCoverageMatrixBuilder.build(
            serviceDate: serviceDate,
            references: references,
            inspection: inspection,
            documents: documentParse,
            geometries: geometries
        )

        let sources = RegionalCoverageReportSources(
            gtfs: sourceFile(
                name: "idfm-gtfs-2026-10-31.zip",
                data: gtfsData,
                dataset: "Offre horaires TC GTFS IDFM (ressource PAN 80921)",
                sourceURL: "https://transport.data.gouv.fr/resources/80921",
                snapshotDate: "2026-10-31",
                processedAt: nil,
                sourceObservation: "La fiche PAN 80921 affichait une validation le 31 octobre à 07:37, heure de Paris",
                provenance: "Miroir public IDFM; archive non obtenue par export PRIM authentifié"
            ),
            lineReferences: sourceFile(
                name: lineReferencesURL.lastPathComponent,
                data: lineReferencesData,
                dataset: "Référentiel des lignes de transport en commun d’Île-de-France",
                sourceURL: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/referentiel-des-lignes",
                snapshotDate: "2026-10-20",
                processedAt: "2026-10-17T12:21:00+02:00",
                sourceObservation: "Instantané local du 20 octobre; le traitement source indiqué sur PRIM date du 17 octobre",
                provenance: "Export local du catalogue public IDFM; instantané conservé le 20 octobre"
            ),
            lineDocuments: sourceFile(
                name: lineDocumentsURL.lastPathComponent,
                data: lineDocumentsData,
                dataset: "Fiches horaires et plans des lignes de transport en commun d’Île-de-France",
                sourceURL: "https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/",
                snapshotDate: "2026-10-20",
                processedAt: "2026-10-20T09:35:00+02:00",
                sourceObservation: "Traitement du catalogue indiqué le 20 octobre à 09:35, heure de Paris",
                provenance: "Export local du catalogue public IDFM; deux fiches horaires 214/314 datées du 1er novembre sont ajoutées par le catalogue de l’application"
            ),
            commercialGeometryArchive: sourceFile(
                name: geometryArchiveURL.lastPathComponent,
                data: geometryArchiveData,
                dataset: "Tracés des lignes régulières commerciales de bus en Île-de-France",
                sourceURL: "https://data.iledefrance-mobilites.fr/explore/dataset/traces-des-lignes-regulieres-de-bus-en-ile-de-france/",
                snapshotDate: "2026-10-20",
                processedAt: nil,
                sourceObservation: "Export intégré le 20 octobre; aucune date de traitement global inscrite dans les objets géographiques",
                provenance: "Archive ZIP source locale; géométries commerciales, distinctes des formes de course GTFS"
            ),
            commercialGeometryGeoJSON: sourceFile(
                name: geometryURL.lastPathComponent,
                data: geometryData,
                dataset: "Tracés des lignes régulières commerciales de bus en Île-de-France",
                sourceURL: "https://data.iledefrance-mobilites.fr/explore/dataset/traces-des-lignes-regulieres-de-bus-en-ile-de-france/",
                snapshotDate: "2026-10-20",
                processedAt: nil,
                sourceObservation: "GeoJSON source inclus dans l’archive intégrée le 20 octobre",
                provenance: "GeoJSON extrait byte pour byte de l’archive ZIP source locale"
            )
        )
        let report = RegionalCoverageReport(
            schemaVersion: 1,
            serviceDate: serviceDateText,
            sources: sources,
            matrix: matrix,
            limitations: [
                "Le GTFS vient du miroir public IDFM et ne remplace pas un export PRIM authentifié.",
                "Le référentiel des lignes a été traité le 17 octobre et les instantanés IDFM sont du 20 octobre 2026.",
                "Les tracés commerciaux décrivent des lignes; ils ne prouvent pas les formes de chaque course ni les voies empruntées.",
                "Aucune preuve de rattachement des lignes aux centres opérationnels bus (COB) n’est incluse dans ces sources."
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let outputData = try encoder.encode(report)
        guard outputData == (try encoder.encode(report)) else {
            throw AuditError.nonDeterministicEncoding
        }
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try outputData.write(to: outputURL, options: .atomic)
        print(
            "AUDIT_COMPLETE serviceDate=\(serviceDateText) lines=\(matrix.summary.candidateBusRecordCount) eligible=\(matrix.summary.eligibleOnServiceDateCount) matched=\(matrix.summary.uniqueGTFSLineCount + matrix.summary.multipleGTFSVariantLineCount) geometry=\(matrix.summary.exactCommercialGeometryLineCount + matrix.summary.shortNameCommercialGeometryLineCount) plans=\(matrix.summary.linesWithPlanLinkCount) timetables=\(matrix.summary.linesWithTimetableLinkCount) output=\(outputURL.path)"
        )
    }

    private static func sourceFile(
        name: String,
        data: Data,
        dataset: String,
        sourceURL: String,
        snapshotDate: String,
        processedAt: String?,
        sourceObservation: String,
        provenance: String
    ) -> RegionalCoverageSourceFile {
        RegionalCoverageSourceFile(
            name: name,
            sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
            byteCount: data.count,
            dataset: dataset,
            sourceURL: sourceURL,
            snapshotDate: snapshotDate,
            processedAt: processedAt,
            sourceObservation: sourceObservation,
            provenance: provenance
        )
    }

    private static func isoDate(_ date: Date) -> String {
        let parts = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
            .dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return "unknown" }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

private enum AuditError: Error {
    case nonDeterministicEncoding
}
