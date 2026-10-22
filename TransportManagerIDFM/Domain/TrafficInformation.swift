import Foundation
import Security

struct PRIMTrafficReport: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let message: String
    let cause: String?
    let severity: String?
    let applicationStart: Date?
    let applicationEnd: Date?
    let updatedAt: Date?
    let affectedObjects: [String]
}

struct PRIMTrafficObservation: Codable, Hashable, Sendable {
    let report: PRIMTrafficReport
    let idfmLineID: String
    let fetchedAt: Date
    let sourceURL: URL
    let license: String

    init(report: PRIMTrafficReport, idfmLineID: String, fetch: PRIMTrafficFetchResult) {
        self.report = report
        self.idfmLineID = idfmLineID
        fetchedAt = fetch.fetchedAt
        sourceURL = fetch.sourceURL
        license = fetch.license
    }
}

struct PRIMTrafficFetchResult: Sendable {
    let reports: [PRIMTrafficReport]
    let fetchedAt: Date
    let sourceURL: URL
    let license: String
    let requestCount: Int
}

enum PRIMTrafficAlertDisposition: String, Codable, Hashable, Sendable {
    case needsReview
    case detourPlanned
    case dismissed

    var title: String {
        switch self {
        case .needsReview: "À traiter"
        case .detourPlanned: "Déviation planifiée"
        case .dismissed: "Ignorée"
        }
    }
}

struct PRIMTrafficAlert: Codable, Hashable, Identifiable, Sendable {
    let routeID: String
    var observation: PRIMTrafficObservation
    let firstSeenAt: Date
    var lastSeenAt: Date
    var disposition: PRIMTrafficAlertDisposition
    var plannedDetourID: String?

    var id: String {
        Self.identifier(idfmLineID: observation.idfmLineID, reportID: observation.report.id)
    }

    init(
        routeID: String,
        observation: PRIMTrafficObservation,
        firstSeenAt: Date,
        lastSeenAt: Date,
        disposition: PRIMTrafficAlertDisposition = .needsReview,
        plannedDetourID: String? = nil
    ) {
        self.routeID = routeID
        self.observation = observation
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.disposition = disposition
        self.plannedDetourID = plannedDetourID
    }

    static func identifier(idfmLineID: String, reportID: String) -> String {
        let lineID = LineReferenceMatcher.canonicalIdentifier(idfmLineID)
        let reportID = reportID.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(lineID.utf8.count):\(lineID)\(reportID.utf8.count):\(reportID)"
    }

    func isExpired(at simulatedAt: Date) -> Bool {
        observation.report.applicationEnd.map { $0 < simulatedAt } ?? false
    }
}

enum PRIMTrafficInformationError: LocalizedError {
    case invalidLineIdentifier
    case invalidResponse
    case unauthorized
    case forbidden
    case rateLimited
    case serviceUnavailable
    case httpStatus(Int)
    case keychainFailure

    var errorDescription: String? {
        switch self {
        case .invalidLineIdentifier:
            "L’identifiant IDFM de cette ligne ne peut pas être utilisé pour interroger PRIM."
        case .invalidResponse:
            "PRIM a renvoyé une réponse trafic illisible. Réessayez plus tard."
        case .unauthorized:
            "Le jeton PRIM est absent ou refusé. Vérifiez-le dans les réglages trafic."
        case .forbidden:
            "L’accès PRIM à ces messages est refusé pour ce compte. Vérifiez votre abonnement et vos droits."
        case .rateLimited:
            "Le quota PRIM est atteint. Attendez avant de relancer la demande."
        case .serviceUnavailable:
            "Le service trafic IDFM est temporairement indisponible. La simulation reste utilisable."
        case let .httpStatus(status):
            "La demande trafic IDFM a échoué (HTTP \(status)). La simulation reste utilisable."
        case .keychainFailure:
            "Le trousseau macOS n’a pas pu lire ou enregistrer le jeton PRIM."
        }
    }
}

enum PRIMTrafficTokenStore {
    private static let account = "prim-traffic-api-token"
    private static var service: String {
        Bundle.main.bundleIdentifier ?? "TransportManagerIDFM"
    }

    static func hasToken() throws -> Bool {
        try load() != nil
    }

    static func load() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            throw PRIMTrafficInformationError.keychainFailure
        }
        return token
    }

    static func save(_ token: String) throws {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let data = cleaned.data(using: .utf8) else {
            throw PRIMTrafficInformationError.unauthorized
        }

        let status = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else {
                throw PRIMTrafficInformationError.keychainFailure
            }
        } else if status != errSecSuccess {
            throw PRIMTrafficInformationError.keychainFailure
        }
    }

    static func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PRIMTrafficInformationError.keychainFailure
        }
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum PRIMTrafficInformationClient {
    private static let apiRoot = "https://prim.iledefrance-mobilites.fr/marketplace/v2/navitia/line_reports"
    private static let documentationURL = URL(string: "https://prim.iledefrance-mobilites.fr/fr/apis/idfm-navitia-line_reports-v2")!

    static func fetchReports(idfmLineID: String, token: String) async throws -> PRIMTrafficFetchResult {
        let uri = try lineURI(for: idfmLineID)
        var reports: [PRIMTrafficReport] = []
        var knownReportIDs: Set<String> = []
        var expectedResultCount: Int?
        var fetchedItemCount = 0
        var page = 0
        var requestCount = 0
        repeat {
            let pageResult = try await fetchPage(uri: uri, token: token, page: page)
            requestCount += 1
            expectedResultCount = pageResult.totalResult ?? expectedResultCount
            fetchedItemCount += pageResult.itemsOnPage
            for report in pageResult.reports where knownReportIDs.insert(report.id).inserted {
                reports.append(report)
            }
            guard let expectedResultCount,
                  fetchedItemCount < expectedResultCount,
                  pageResult.itemsOnPage >= pageResult.itemsPerPage,
                  pageResult.itemsPerPage > 0 else { break }
            page += 1
        } while true

        return PRIMTrafficFetchResult(
            reports: reports,
            fetchedAt: Date(),
            sourceURL: documentationURL,
            license: "Licence Mobilité IDFM",
            requestCount: requestCount
        )
    }

    private static func fetchPage(uri: String, token: String, page: Int) async throws -> TrafficAPIPage {
        let encodedURI = uri.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        guard !encodedURI.isEmpty,
              var components = URLComponents(string: "\(apiRoot)/lines/\(encodedURI)/line_reports") else {
            throw PRIMTrafficInformationError.invalidLineIdentifier
        }
        components.queryItems = [
            URLQueryItem(name: "count", value: "100"),
            URLQueryItem(name: "start_page", value: String(page))
        ]
        guard let url = components.url else { throw PRIMTrafficInformationError.invalidLineIdentifier }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("apikey \(token.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PRIMTrafficInformationError.serviceUnavailable
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PRIMTrafficInformationError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200..<300:
            break
        case 401:
            throw PRIMTrafficInformationError.unauthorized
        case 403:
            throw PRIMTrafficInformationError.forbidden
        case 429:
            throw PRIMTrafficInformationError.rateLimited
        case 500..<600:
            throw PRIMTrafficInformationError.serviceUnavailable
        default:
            throw PRIMTrafficInformationError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try decodePage(from: data)
        } catch {
            throw PRIMTrafficInformationError.invalidResponse
        }
    }

    private static func lineURI(for idfmLineID: String) throws -> String {
        let lineID = LineReferenceMatcher.canonicalIdentifier(idfmLineID)
        guard !lineID.isEmpty, lineID.unicodeScalars.allSatisfy(CharacterSet.alphanumerics.contains) else {
            throw PRIMTrafficInformationError.invalidLineIdentifier
        }
        return "line:IDFM:\(lineID)"
    }

    private static func decodePage(from data: Data) throws -> TrafficAPIPage {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PRIMTrafficInformationError.invalidResponse
        }
        let rawReports: [[String: Any]]
        if let lineReports = root["line_reports"] as? [[String: Any]] {
            rawReports = lineReports
        } else if let disruptions = root["disruptions"] as? [[String: Any]] {
            rawReports = disruptions
        } else {
            throw PRIMTrafficInformationError.invalidResponse
        }
        let reports = rawReports.enumerated().compactMap { index, rawReport in
            makeReport(rawReport, fallbackID: "report-\(index)")
        }
        let pagination = root["pagination"] as? [String: Any]
        return TrafficAPIPage(
            reports: reports,
            totalResult: (pagination?["total_result"] as? NSNumber)?.intValue,
            itemsPerPage: (pagination?["items_per_page"] as? NSNumber)?.intValue ?? 100,
            itemsOnPage: (pagination?["items_on_page"] as? NSNumber)?.intValue ?? rawReports.count
        )
    }

    private static func makeReport(_ raw: [String: Any], fallbackID: String) -> PRIMTrafficReport? {
        let messages = messageTexts(raw["messages"])
        let message = messages.joined(separator: "\n\n")
        let explicitTitle = raw["title"] as? String
        let title = nonEmpty(explicitTitle) ?? messages.first.map(firstLine(of:)) ?? "Information trafic IDFM"
        guard !message.isEmpty || explicitTitle != nil else { return nil }

        let severity = raw["severity"] as? [String: Any]
        let line = raw["line"] as? [String: Any]
        let applicationPeriods = raw["application_periods"] as? [[String: Any]] ?? []
        let firstPeriod = applicationPeriods.first
        let lastPeriod = applicationPeriods.last

        return PRIMTrafficReport(
            id: nonEmpty(raw["id"] as? String) ?? fallbackID,
            title: title,
            message: message.isEmpty ? title : message,
            cause: nonEmpty(raw["cause"] as? String),
            severity: nonEmpty(severity?["name"] as? String),
            applicationStart: parseDate(firstPeriod?["begin"] as? String),
            applicationEnd: parseDate(lastPeriod?["end"] as? String),
            updatedAt: parseDate(raw["updated_at"] as? String),
            affectedObjects: affectedObjectNames(raw, line: line)
        )
    }

    private static func messageTexts(_ value: Any?) -> [String] {
        if let text = value as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return [text.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        if let message = value as? [String: Any],
           let text = nonEmpty(message["text"] as? String) {
            return [text]
        }
        guard let messages = value as? [[String: Any]] else { return [] }
        return messages.compactMap { nonEmpty($0["text"] as? String) }
    }

    private static func affectedObjectNames(_ raw: [String: Any], line: [String: Any]?) -> [String] {
        var names: [String] = []
        if let name = nonEmpty(line?["name"] as? String) { names.append("Ligne \(name)") }
        for object in raw["pt_objects"] as? [[String: Any]] ?? [] {
            let embeddedType = (object["embedded_type"] as? String)?.replacingOccurrences(of: "_", with: " ")
            let nested = ["line", "stop_point", "stop_area", "network"].compactMap { object[$0] as? [String: Any] }.first
            let name = nonEmpty(object["name"] as? String) ?? nonEmpty(nested?["name"] as? String)
            if let name {
                names.append(embeddedType.map { "\($0.capitalized) · \(name)" } ?? name)
            }
        }
        for object in raw["impacted_objects"] as? [[String: Any]] ?? [] {
            if let name = nonEmpty(object["name"] as? String) {
                let type = (object["type"] as? String)?.replacingOccurrences(of: "_", with: " ")
                names.append(type.map { "\($0.capitalized) · \(name)" } ?? name)
            }
        }
        return Array(Set(names)).sorted()
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value = nonEmpty(value) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.isLenient = false
        for format in ["yyyyMMdd'T'HHmmss", "yyyy-MM-dd'T'HH:mm:ssXXXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func firstLine(of value: String) -> String {
        String(value.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first ?? "Information trafic IDFM")
    }
}

private struct TrafficAPIPage {
    let reports: [PRIMTrafficReport]
    let totalResult: Int?
    let itemsPerPage: Int
    let itemsOnPage: Int
}
