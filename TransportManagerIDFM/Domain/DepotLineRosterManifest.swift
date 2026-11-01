import Foundation

struct DepotLineRosterManifestDocument: Hashable, Sendable, Identifiable {
    let kind: String
    let title: String?
    let url: URL
    let validity: String?

    var id: String { "\(kind)|\(url.absoluteString)" }
}

struct DepotLineRosterManifestEntry: Hashable, Sendable, Identifiable {
    let serviceStartKey: Int?
    let serviceEndKey: Int?
    let line: String
    let category: String
    let siteIDs: [String]
    let evidenceStatus: String
    let evidenceTitle: String
    let evidenceURL: URL
    let sourceCenterLabel: String
    let secondaryEvidenceTitle: String?
    let secondaryEvidenceURL: URL?
    let planURLs: [URL]
    let timetableURLs: [URL]
    let documentValidity: String
    let projectDocuments: [DepotLineRosterManifestDocument]
    let legacyContractCenterValidFromKey: Int?
    let legacyContractCenterValidThroughKey: Int?
    let announcedServiceTitle: String?
    let announcedServiceURL: URL?
    let announcedServiceSourceDateKey: Int?
    let announcedServiceValidFromKey: Int?
    let notes: String

    var documents: [DepotLineRosterManifestDocument] {
        return planURLs.map { DepotLineRosterManifestDocument(kind: "Plan", title: nil, url: $0, validity: nil) }
            + timetableURLs.map { DepotLineRosterManifestDocument(kind: "Horaire", title: nil, url: $0, validity: nil) }
            + projectDocuments
    }

    var id: String { "\(serviceStartKey.map { String($0) } ?? "open")|\(line)" }

    func isActive(on date: Date) -> Bool {
        guard ["regular", "night", "new_regular"].contains(category),
              let serviceStartKey else { return false }
        guard let serviceDateKey = GTFSServiceDate.key(for: date, timeZone: GTFSServiceDate.parisTimeZone) else {
            return false
        }
        if serviceDateKey < serviceStartKey { return false }
        if let serviceEndKey, serviceDateKey > serviceEndKey { return false }
        return true
    }
}

struct DepotLineRosterManifestState: Sendable {
    let entries: [DepotLineRosterManifestEntry]
    let rosterRows: [DepotLineRosterRow]
    let errorMessage: String?

    var isValid: Bool { errorMessage == nil }
    var summary: String {
        if let errorMessage { return "Manifeste non validé · \(errorMessage)" }
        let claimCount = rosterRows.reduce(0) { $0 + $1.claims.count }
        return "Manifeste validé · \(entries.count) entrées · \(claimCount) preuves consignées"
    }
}

enum DepotLineRosterManifestCatalog {
    private static let requiredColumns: Set<String> = [
        "service_start", "service_end", "line", "category", "site_ids", "source_center_label",
        "evidence_status", "evidence_title", "evidence_url", "secondary_evidence_title",
        "secondary_evidence_url", "plan_url", "timetable_url", "document_validity", "notes",
        "project_document_urls", "project_document_titles",
        "legacy_contract_center_valid_from", "legacy_contract_center_valid_through",
        "announced_service_title", "announced_service_url", "announced_service_source_date",
        "announced_service_valid_from"
    ]

    private static let allowedCategories: Set<String> = [
        "regular", "night", "historical_conflict", "new_regular", "planned_project"
    ]

    static let state: DepotLineRosterManifestState = {
        do {
            guard let url = Bundle.main.url(forResource: "bords-de-marne-depot-roster", withExtension: "csv") else {
                throw ManifestError.missingResource
            }
            let data = try Data(contentsOf: url)
            let knownSiteIDs = Set(DepotLineRoster.selectableSites.map(\.id))
            let entries = try load(data: data, knownSiteIDs: knownSiteIDs)
            let rosterRowsData = try resourceData(named: "bords-de-marne-depot-roster-rows")
            let claimsData = try resourceData(named: "bords-de-marne-depot-roster-claims")
            let documentsData = try resourceData(named: "bords-de-marne-depot-roster-documents")
            return DepotLineRosterManifestState(
                entries: entries,
                rosterRows: try loadOperationalRows(
                    rowsData: rosterRowsData,
                    claimsData: claimsData,
                    documentsData: documentsData,
                    entries: entries,
                    knownSiteIDs: knownSiteIDs
                ),
                errorMessage: nil
            )
        } catch {
            return DepotLineRosterManifestState(entries: [], rosterRows: [], errorMessage: error.localizedDescription)
        }
    }()

    static func entries(for serviceDate: Date) -> [DepotLineRosterManifestEntry] {
        state.entries.filter { $0.isActive(on: serviceDate) }
    }

    private static func loadOperationalRows(
        rowsData: Data,
        claimsData: Data,
        documentsData: Data,
        entries: [DepotLineRosterManifestEntry],
        knownSiteIDs: Set<String>
    ) throws -> [DepotLineRosterRow] {
        let rowRecords = try records(
            from: rowsData,
            requiring: ["line", "category", "evidence_status", "site_ids", "note"]
        )
        let claimRecords = try records(
            from: claimsData,
            requiring: [
                "line", "ordinal", "kind", "site_id", "center_label", "source_title", "source_url",
                "source_date", "source_date_label", "valid_from", "valid_through", "note"
            ]
        )
        let documentRecords = try records(
            from: documentsData,
            requiring: ["line", "ordinal", "title", "type", "url", "validity", "note"]
        )

        let entryLines = Set(entries.map { $0.line.uppercased() })
        var issues: [String] = []
        var rowByLine: [String: DepotLineRosterRow] = [:]
        for (offset, record) in rowRecords.enumerated() {
            let recordNumber = offset + 2
            let line = value("line", in: record)
            let category = value("category", in: record)
            let rawStatus = value("evidence_status", in: record)
            let siteIDs = value("site_ids", in: record)
                .split(separator: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if line.isEmpty || !entryLines.contains(line.uppercased()) {
                issues.append("lignes runtime \(recordNumber) : entrée « \(line) » absente du manifeste daté")
            }
            if category.isEmpty { issues.append("lignes runtime \(recordNumber) : catégorie absente") }
            guard let evidenceStatus = DepotLineEvidenceStatus(rawValue: rawStatus) else {
                issues.append("lignes runtime \(recordNumber) : état « \(rawStatus) » inconnu")
                continue
            }
            if siteIDs.count != Set(siteIDs).count {
                issues.append("lignes runtime \(recordNumber) : dépôt dupliqué")
            }
            for siteID in siteIDs where !knownSiteIDs.contains(siteID) {
                issues.append("lignes runtime \(recordNumber) : dépôt inconnu « \(siteID) »")
            }
            let key = line.uppercased()
            if rowByLine[key] != nil {
                issues.append("lignes runtime \(recordNumber) : ligne « \(line) » dupliquée")
                continue
            }
            rowByLine[key] = DepotLineRosterRow(
                line: line,
                category: category,
                siteIDs: siteIDs,
                evidenceStatus: evidenceStatus,
                note: value("note", in: record),
                publicDocuments: [],
                claims: []
            )
        }
        let missingRuntimeLines = entryLines.subtracting(rowByLine.keys)
        if !missingRuntimeLines.isEmpty {
            issues.append("lignes runtime absentes : \(missingRuntimeLines.sorted().joined(separator: ", "))")
        }

        var claimsByLine: [String: [Int: DepotLineRosterClaim]] = [:]
        for (offset, record) in claimRecords.enumerated() {
            let recordNumber = offset + 2
            let line = value("line", in: record)
            let key = line.uppercased()
            let ordinal = Int(value("ordinal", in: record))
            guard entryLines.contains(key), rowByLine[key] != nil else {
                issues.append("preuves \(recordNumber) : ligne « \(line) » absente du manifeste")
                continue
            }
            guard let ordinal, ordinal >= 0 else {
                issues.append("preuves \(recordNumber) : ordre invalide")
                continue
            }
            guard let kind = DepotLineRosterClaimKind(rawValue: value("kind", in: record)) else {
                issues.append("preuves \(recordNumber) : type de preuve inconnu")
                continue
            }
            let siteText = value("site_id", in: record)
            let siteID = siteText.isEmpty ? nil : siteText
            if let siteID, !knownSiteIDs.contains(siteID) {
                issues.append("preuves \(recordNumber) : dépôt inconnu « \(siteID) »")
            }
            let sourceURLText = value("source_url", in: record)
            let sourceURL = sourceURLText.isEmpty ? nil : parseURL(sourceURLText)
            if !sourceURLText.isEmpty && sourceURL == nil {
                issues.append("preuves \(recordNumber) : URL source invalide")
            }
            let sourceDateText = value("source_date", in: record)
            let sourceDate = parseDate(sourceDateText)
            if !sourceDateText.isEmpty && sourceDate == nil {
                issues.append("preuves \(recordNumber) : date de source invalide")
            }
            let validFromText = value("valid_from", in: record)
            let validThroughText = value("valid_through", in: record)
            let validFromKey = parseDateKey(validFromText)
            let validThroughKey = parseDateKey(validThroughText)
            if (!validFromText.isEmpty && validFromKey == nil) || (!validThroughText.isEmpty && validThroughKey == nil) {
                issues.append("preuves \(recordNumber) : date de validité invalide")
            }
            if let validFromKey, let validThroughKey, validFromKey > validThroughKey {
                issues.append("preuves \(recordNumber) : période de validité inversée")
            }
            let sourceTitle = value("source_title", in: record)
            if sourceTitle.isEmpty { issues.append("preuves \(recordNumber) : titre de source absent") }
            let claim = DepotLineRosterClaim(
                kind: kind,
                siteID: siteID,
                centerLabel: optionalValue("center_label", in: record),
                sourceTitle: sourceTitle,
                sourceURL: sourceURL,
                sourceDate: sourceDate,
                sourceDateLabel: optionalValue("source_date_label", in: record),
                validFromKey: validFromKey,
                validThroughKey: validThroughKey,
                note: optionalValue("note", in: record)
            )
            if claimsByLine[key]?[ordinal] != nil {
                issues.append("preuves \(recordNumber) : ordre dupliqué pour la ligne \(line)")
            } else {
                claimsByLine[key, default: [:]][ordinal] = claim
            }
        }

        var documentsByLine: [String: [Int: DepotLineDocumentLink]] = [:]
        for (offset, record) in documentRecords.enumerated() {
            let recordNumber = offset + 2
            let line = value("line", in: record)
            let key = line.uppercased()
            guard entryLines.contains(key), rowByLine[key] != nil else {
                issues.append("documents \(recordNumber) : ligne « \(line) » absente du manifeste")
                continue
            }
            guard let ordinal = Int(value("ordinal", in: record)), ordinal >= 0 else {
                issues.append("documents \(recordNumber) : ordre invalide")
                continue
            }
            let title = value("title", in: record)
            let type = value("type", in: record)
            let urlText = value("url", in: record)
            guard let url = parseURL(urlText) else {
                issues.append("documents \(recordNumber) : URL absente ou invalide")
                continue
            }
            if title.isEmpty || type.isEmpty { issues.append("documents \(recordNumber) : titre ou type absent") }
            let document = DepotLineDocumentLink(
                title: title,
                type: type,
                url: url,
                validity: value("validity", in: record),
                note: optionalValue("note", in: record)
            )
            if documentsByLine[key]?[ordinal] != nil {
                issues.append("documents \(recordNumber) : ordre dupliqué pour la ligne \(line)")
            } else {
                documentsByLine[key, default: [:]][ordinal] = document
            }
        }

        for entry in entries {
            let key = entry.line.uppercased()
            let orderedClaims = (claimsByLine[key] ?? [:]).sorted { $0.key < $1.key }
            if orderedClaims.isEmpty {
                issues.append("ligne \(entry.line) : aucune preuve de rattachement enregistrée")
            } else if orderedClaims.map({ $0.key }) != Array(0..<orderedClaims.count) {
                issues.append("ligne \(entry.line) : ordre des preuves non contigu")
            }
            let orderedDocuments = (documentsByLine[key] ?? [:]).sorted { $0.key < $1.key }
            if orderedDocuments.map({ $0.key }) != Array(0..<orderedDocuments.count) {
                issues.append("ligne \(entry.line) : ordre des documents non contigu")
            }
            guard let row = rowByLine[key] else { continue }
            rowByLine[key] = DepotLineRosterRow(
                line: row.line,
                category: row.category,
                siteIDs: row.siteIDs,
                evidenceStatus: row.evidenceStatus,
                note: row.note,
                publicDocuments: orderedDocuments.map { $0.value },
                claims: orderedClaims.map { $0.value }
            )
        }

        guard issues.isEmpty else { throw ManifestError.invalidRows(issues) }
        return entries.compactMap { rowByLine[$0.line.uppercased()] }
    }

    private static func records(from data: Data, requiring columns: Set<String>) throws -> [[String: String]] {
        var rows: [[String: String]] = []
        let table = CSVTableReader(columnsOfInterest: [], captureAllColumns: true) { rows.append($0) }
        do {
            try table.consume(data)
            table.finish()
        } catch {
            throw ManifestError.unreadableCSV
        }
        let missingColumns = columns.filter { !table.hasColumn($0) }.sorted()
        guard missingColumns.isEmpty else { throw ManifestError.missingColumns(missingColumns) }
        guard !rows.isEmpty else { throw ManifestError.emptyRoster }
        return rows
    }

    private static func resourceData(named name: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "csv") else {
            throw ManifestError.missingResource
        }
        return try Data(contentsOf: url)
    }

    static func load(data: Data, knownSiteIDs: Set<String>) throws -> [DepotLineRosterManifestEntry] {
        var rows: [[String: String]] = []
        let table = CSVTableReader(columnsOfInterest: [], captureAllColumns: true) { rows.append($0) }
        do {
            try table.consume(data)
            table.finish()
        } catch {
            throw ManifestError.unreadableCSV
        }

        let missingColumns = requiredColumns.filter { !table.hasColumn($0) }.sorted()
        guard missingColumns.isEmpty else { throw ManifestError.missingColumns(missingColumns) }
        guard !rows.isEmpty else { throw ManifestError.emptyRoster }

        var seenKeys = Set<String>()
        var entries: [DepotLineRosterManifestEntry] = []
        var issues: [String] = []

        for (offset, row) in rows.enumerated() {
            let recordNumber = offset + 2
            let line = value("line", in: row)
            let category = value("category", in: row)
            let evidenceStatus = value("evidence_status", in: row)
            let evidenceTitle = value("evidence_title", in: row)
            let notes = value("notes", in: row)
            let documentValidity = value("document_validity", in: row)
            let startText = value("service_start", in: row)
            let endText = value("service_end", in: row)
            let startKey = parseDateKey(startText)
            let endKey = parseDateKey(endText)
            let key = "\(startText)|\(line.uppercased())"

            if line.isEmpty { issues.append("ligne \(recordNumber) : numéro de ligne absent") }
            if !allowedCategories.contains(category) { issues.append("ligne \(recordNumber) : catégorie « \(category) » inconnue") }
            if evidenceStatus.isEmpty || evidenceTitle.isEmpty || notes.isEmpty {
                issues.append("ligne \(recordNumber) : statut, titre de preuve et note sont requis")
            }
            if !seenKeys.insert(key).inserted { issues.append("ligne \(recordNumber) : entrée dupliquée pour \(line)") }
            if (!startText.isEmpty && startKey == nil) || (!endText.isEmpty && endKey == nil) {
                issues.append("ligne \(recordNumber) : date de service invalide")
            }
            if !startText.isEmpty && endText.isEmpty || startText.isEmpty && !endText.isEmpty {
                issues.append("ligne \(recordNumber) : les deux bornes de service doivent être renseignées ensemble")
            }
            if let startKey, let endKey, startKey > endKey {
                issues.append("ligne \(recordNumber) : la période de service est inversée")
            }
            let legacyStartText = value("legacy_contract_center_valid_from", in: row)
            let legacyEndText = value("legacy_contract_center_valid_through", in: row)
            let legacyStartKey = parseDateKey(legacyStartText)
            let legacyEndKey = parseDateKey(legacyEndText)
            if (!legacyStartText.isEmpty && legacyStartKey == nil) || (!legacyEndText.isEmpty && legacyEndKey == nil) {
                issues.append("ligne \(recordNumber) : date invalide pour l’ancien rattachement au centre")
            }
            if !legacyStartText.isEmpty && legacyEndText.isEmpty || legacyStartText.isEmpty && !legacyEndText.isEmpty {
                issues.append("ligne \(recordNumber) : les deux bornes de l’ancien rattachement au centre doivent être renseignées ensemble")
            }
            if let legacyStartKey, let legacyEndKey, legacyStartKey > legacyEndKey {
                issues.append("ligne \(recordNumber) : période inversée de l’ancien rattachement au centre")
            }

            let siteIDs = value("site_ids", in: row)
                .split(separator: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            for siteID in siteIDs where !knownSiteIDs.contains(siteID) {
                issues.append("ligne \(recordNumber) : dépôt inconnu « \(siteID) »")
            }

            let evidenceURL = parseURL(value("evidence_url", in: row))
            if evidenceURL == nil { issues.append("ligne \(recordNumber) : URL de preuve absente ou invalide") }
            for column in ["secondary_evidence_url", "announced_service_url"] {
                let rawValue = value(column, in: row)
                if !rawValue.isEmpty && parseURL(rawValue) == nil {
                    issues.append("ligne \(recordNumber) : URL invalide dans \(column)")
                }
            }
            let planURLs = parseURLList(value("plan_url", in: row))
            let timetableURLs = parseURLList(value("timetable_url", in: row))
            for (column, raw) in [("plan_url", value("plan_url", in: row)), ("timetable_url", value("timetable_url", in: row))] {
                if !raw.isEmpty && (column == "plan_url" ? planURLs.count : timetableURLs.count) != raw.components(separatedBy: " | ").count {
                    issues.append("ligne \(recordNumber) : URL invalide dans \(column)")
                }
            }
            let projectURLs = value("project_document_urls", in: row)
                .components(separatedBy: " | ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let projectTitles = value("project_document_titles", in: row)
                .components(separatedBy: " | ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if projectURLs.contains(where: { parseURL($0) == nil }) {
                issues.append("ligne \(recordNumber) : URL de document de projet invalide")
            }
            if projectURLs.count != projectTitles.count {
                issues.append("ligne \(recordNumber) : les titres et URL des documents de projet ne correspondent pas")
            }
            for column in [
                "legacy_contract_center_valid_from", "legacy_contract_center_valid_through",
                "announced_service_source_date", "announced_service_valid_from"
            ] {
                let rawValue = value(column, in: row)
                if !rawValue.isEmpty && parseDateKey(rawValue) == nil {
                    issues.append("ligne \(recordNumber) : date invalide dans \(column)")
                }
            }

            if let evidenceURL {
                entries.append(DepotLineRosterManifestEntry(
                    serviceStartKey: startKey,
                    serviceEndKey: endKey,
                    line: line,
                    category: category,
                    siteIDs: siteIDs,
                    evidenceStatus: evidenceStatus,
                    evidenceTitle: evidenceTitle,
                    evidenceURL: evidenceURL,
                    sourceCenterLabel: value("source_center_label", in: row),
                    secondaryEvidenceTitle: optionalValue("secondary_evidence_title", in: row),
                    secondaryEvidenceURL: parseURL(value("secondary_evidence_url", in: row)),
                    planURLs: planURLs,
                    timetableURLs: timetableURLs,
                    documentValidity: documentValidity,
                    projectDocuments: zip(projectTitles, projectURLs).compactMap { title, rawURL in
                        guard let url = parseURL(rawURL) else { return nil }
                        return DepotLineRosterManifestDocument(kind: "Projet", title: title, url: url, validity: nil)
                    },
                    legacyContractCenterValidFromKey: legacyStartKey,
                    legacyContractCenterValidThroughKey: legacyEndKey,
                    announcedServiceTitle: optionalValue("announced_service_title", in: row),
                    announcedServiceURL: parseURL(value("announced_service_url", in: row)),
                    announcedServiceSourceDateKey: parseDateKey(value("announced_service_source_date", in: row)),
                    announcedServiceValidFromKey: parseDateKey(value("announced_service_valid_from", in: row)),
                    notes: notes
                ))
            }
        }

        guard issues.isEmpty else { throw ManifestError.invalidRows(issues) }
        return entries
    }

    private static func value(_ key: String, in row: [String: String]) -> String {
        row[key, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func optionalValue(_ key: String, in row: [String: String]) -> String? {
        let result = value(key, in: row)
        return result.isEmpty ? nil : result
    }

    private static func parseURLList(_ value: String) -> [URL] {
        value.components(separatedBy: " | ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap(parseURL)
    }

    private static func parseDateKey(_ value: String) -> Int? {
        guard value.count == 10 else { return nil }
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        guard let date = components.date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else { return nil }
        return year * 10_000 + month * 100 + day
    }

    private static func parseDate(_ value: String) -> Date? {
        guard let key = parseDateKey(value) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        var components = DateComponents()
        components.year = key / 10_000
        components.month = key / 100 % 100
        components.day = key % 100
        return calendar.date(from: components)
    }

    private static func parseURL(_ value: String) -> URL? {
        guard let url = URL(string: value),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil else { return nil }
        return url
    }

    private enum ManifestError: LocalizedError {
        case missingResource
        case unreadableCSV
        case missingColumns([String])
        case emptyRoster
        case invalidRows([String])

        var errorDescription: String? {
            switch self {
            case .missingResource:
                "Le CSV du roster n’est pas inclus dans l’application."
            case .unreadableCSV:
                "Le fichier du roster n’est pas un CSV lisible."
            case .missingColumns(let columns):
                "Colonnes manquantes : \(columns.joined(separator: ", "))."
            case .emptyRoster:
                "Le CSV ne contient aucune ligne de roster."
            case .invalidRows(let issues):
                "\(issues.prefix(3).joined(separator: " · "))\(issues.count > 3 ? " · …" : "")"
            }
        }
    }
}
