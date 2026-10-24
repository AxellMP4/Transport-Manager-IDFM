import Foundation

struct PublishedServiceDiscrepancy: Hashable, Sendable {
    let title: String
    let detail: String
    let sourceTitle: String
    let sourceURL: URL
    let timetableTitle: String
    let timetableURL: URL
    let gtfsSourceTitle: String
    let gtfsSourceURL: URL

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
            detail: "IDFM annonce le maintien et le renfort de fréquence de la 214 dès le 1er novembre, avec transfert des arrêts des Chanoux à la nouvelle 314. Cette version GTFS ne prévoit aucun départ pour la date choisie. La fiche horaire 214 référencée montre encore des courses passant par les Chanoux sans dater la réorganisation ; elle ne permet donc pas de déduire la grille 214 après le 1er novembre. La fiche officielle de la 314, valable du 1er novembre au 11 juillet, est disponible ci-dessous.",
            sourceTitle: "Communiqué IDFM du 21 octobre 2026",
            sourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-restructure-et-reorganise-loffre-de-bus-sur-les-territoires-des-bords-de-marne-et-de-boucle-nord-de-seine/?lang=fr")!,
            timetableTitle: "Horaires officiels de la ligne 314 · 1er novembre 2026–11 juillet 2027",
            timetableURL: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20261021T153740Z-878f05ec-b765-486b-bb83-7d8a6d99c48b.pdf")!,
            gtfsSourceTitle: "Ressource GTFS publique IDFM",
            gtfsSourceURL: URL(string: "https://transport.data.gouv.fr/resources/80921")!
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
