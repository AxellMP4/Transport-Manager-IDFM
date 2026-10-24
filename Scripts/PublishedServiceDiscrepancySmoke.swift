import Foundation

@main
struct PublishedServiceDiscrepancySmoke {
    static func main() {
        let notice = PublishedServiceDiscrepancy.forRoute(
            shortName: "214",
            routeID: "IDFM:C01228",
            serviceDateKey: 20261102,
            scheduledTripCount: 0
        )

        guard let notice else {
            fatalError("The missing post-reorganization 214 service should show its published-service notice.")
        }

        precondition(notice.detail.contains("Chanoux"), "The notice should explain the stop transfer to line 314.")
        precondition(notice.detail.contains("314"), "The notice should identify the replacement route.")
        precondition(notice.detail.contains("1er novembre"), "The notice should name the effective date.")
        precondition(
            notice.timetableTitle == "Horaires officiels de la ligne 314 · 1er novembre 2026–11 juillet 2027",
            "The notice should link the verified official timetable for the replacement line."
        )
        precondition(
            notice.timetableURL.absoluteString == "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20261021T153740Z-878f05ec-b765-486b-bb83-7d8a6d99c48b.pdf",
            "The replacement timetable URL should resolve to the current official IDFM PDF."
        )
        precondition(
            notice.gtfsSourceTitle == "Ressource GTFS publique IDFM",
            "The notice should label its public timetable data source clearly."
        )
        precondition(
            notice.gtfsSourceURL.absoluteString == "https://transport.data.gouv.fr/resources/80921",
            "The notice should link to the public IDFM GTFS resource page."
        )
        precondition(
            notice.sourceURL.absoluteString == "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-restructure-et-reorganise-loffre-de-bus-sur-les-territoires-des-bords-de-marne-et-de-boucle-nord-de-seine/?lang=fr",
            "The notice should link to the primary IDFM announcement."
        )

        precondition(
            PublishedServiceDiscrepancy.forRoute(
                shortName: "214",
                routeID: "IDFM:C01228",
                serviceDateKey: 20261101,
                scheduledTripCount: 0
            ) == nil,
            "The notice must not show on Sunday, when the published 214 timetable has no service."
        )
        precondition(
            PublishedServiceDiscrepancy.forRoute(
                shortName: "214",
                routeID: "IDFM:C01228",
                serviceDateKey: 20261031,
                scheduledTripCount: 0
            ) == nil,
            "The notice must not appear before the reorganization."
        )
        precondition(
            PublishedServiceDiscrepancy.forRoute(
                shortName: "214",
                routeID: "IDFM:C01228",
                serviceDateKey: 20261102,
                scheduledTripCount: 12
            ) == nil,
            "A populated GTFS service must take precedence over the missing-service notice."
        )
        precondition(
            PublishedServiceDiscrepancy.forRoute(
                shortName: "214",
                routeID: "IDFM:OTHER",
                serviceDateKey: 20261102,
                scheduledTripCount: 0
            ) == nil,
            "An unrelated line numbered 214 must not inherit this announcement."
        )

        print("Published-service discrepancy checks passed.")
    }
}
