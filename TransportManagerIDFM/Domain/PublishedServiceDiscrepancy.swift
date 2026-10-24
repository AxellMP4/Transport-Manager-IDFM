import Foundation

struct PublishedServiceDiscrepancy: Hashable, Sendable {
    let title: String
    let detail: String
    let sourceTitle: String
    let sourceURL: URL
    let timetableTitle: String
    let timetableURL: URL
    let routePlanTitle: String
    let routePlanURL: URL
    let gtfsSourceTitle: String
    let gtfsSourceURL: URL

    private static let bordsDeMarneAnnouncementURL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-restructure-et-reorganise-loffre-de-bus-sur-les-territoires-des-bords-de-marne-et-de-boucle-nord-de-seine/?lang=fr")!
    private static let line314TimetableTitle = "Horaires officiels de la ligne 314 · 1er novembre 2026–11 juillet 2027"
    private static let line314TimetableURL = URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20261021T153740Z-878f05ec-b765-486b-bb83-7d8a6d99c48b.pdf")!
    private static let routePlanTitle = "Plan schématique officiel 214/314 · août 2026"
    private static let routePlanURL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-operateurs/ORL14VYfG2K1HYNw_THERMO_BOUCLES-DE-MARNE-214-314_08.26.pdf")!
    private static let gtfsSourceURL = URL(string: "https://transport.data.gouv.fr/resources/80921")!

    static func forRoute(
        shortName: String,
        routeID: String,
        serviceDateKey: Int,
        scheduledTripCount: Int
    ) -> PublishedServiceDiscrepancy? {
        guard shortName == "214",
              routeID == "IDFM:C01228",
              serviceDateKey >= 20261101,
              !isSunday(serviceDateKey),
              scheduledTripCount == 0 else {
            return nil
        }

        return PublishedServiceDiscrepancy(
            title: "Service annoncé, départs GTFS manquants",
            detail: "IDFM annonce le maintien et le renfort de fréquence de la 214 dès le 1er novembre, avec transfert des arrêts des Chanoux à la nouvelle 314. La fiche annonce la 314 du lundi au vendredi, toutes les 15 minutes en heures de pointe et toutes les heures en heures creuses. Cette version GTFS ne prévoit aucun départ pour la date choisie. La fiche horaire 214 référencée montre encore des courses passant par les Chanoux sans dater la réorganisation ; elle ne permet donc pas de déduire la grille 214 après le 1er novembre. La fiche officielle de la 314, valable du 1er novembre au 11 juillet, est disponible ci-dessous. Le plan schématique officiel 214/314 d’août 2026 aide à examiner les arrêts et le parcours; il ne fournit pas les horaires détaillés ni une géométrie GPS.",
            sourceTitle: "Communiqué IDFM du 21 octobre 2026",
            sourceURL: bordsDeMarneAnnouncementURL,
            timetableTitle: line314TimetableTitle,
            timetableURL: line314TimetableURL,
            routePlanTitle: routePlanTitle,
            routePlanURL: routePlanURL,
            gtfsSourceTitle: "Ressource GTFS publique IDFM",
            gtfsSourceURL: gtfsSourceURL
        )
    }

    static func forMissingAnnouncedLine314(gtfsRouteShortNames: [String]) -> PublishedServiceDiscrepancy? {
        let contains314 = gtfsRouteShortNames.contains {
            $0.trimmingCharacters(in: .whitespacesAndNewlines) == "314"
        }
        guard !contains314 else { return nil }

        return PublishedServiceDiscrepancy(
            title: "Ligne 314 annoncée, route absente du GTFS",
            detail: "À partir du 1er novembre 2026, IDFM annonce la ligne 314 entre Neuilly-Plaisance RER et la zone industrielle des Chanoux. La date d’effet est le dimanche 1er novembre; le service est prévu du lundi au vendredi, avec premières courses le lundi 2 novembre 2026. Le communiqué prévoit un service du lundi au vendredi, toutes les 15 minutes en heures de pointe et toutes les heures en heures creuses. Le GTFS chargé ne contient aucune route 314 : cette vue ne peut donc pas afficher ses courses détaillées ni sa séquence d’arrêts. Consultez la fiche horaire et le plan officiel ci-dessous; les fréquences publiées ne permettent pas de reconstruire un horaire complet.",
            sourceTitle: "Communiqué IDFM du 21 octobre 2026",
            sourceURL: bordsDeMarneAnnouncementURL,
            timetableTitle: line314TimetableTitle,
            timetableURL: line314TimetableURL,
            routePlanTitle: routePlanTitle,
            routePlanURL: routePlanURL,
            gtfsSourceTitle: "Ressource GTFS publique IDFM",
            gtfsSourceURL: gtfsSourceURL
        )
    }

    private static func isSunday(_ serviceDateKey: Int) -> Bool {
        let year = serviceDateKey / 10_000
        let month = (serviceDateKey / 100) % 100
        let day = serviceDateKey % 100
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components),
              calendar.component(.year, from: date) == year,
              calendar.component(.month, from: date) == month,
              calendar.component(.day, from: date) == day else {
            return false
        }
        return calendar.component(.weekday, from: date) == 1
    }
}
