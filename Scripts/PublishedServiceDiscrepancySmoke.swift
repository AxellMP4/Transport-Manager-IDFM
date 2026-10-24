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
            notice.detail.contains("15 minutes en heures de pointe")
                && notice.detail.contains("toutes les heures en heures creuses"),
            "The notice should summarize the officially announced weekday headways for line 314."
        )
        precondition(
            notice.detail.contains("plan schématique officiel 214/314"),
            "The notice should make the official route plan available for stop and path review."
        )
        precondition(
            notice.timetableTitle == "Horaires officiels de la ligne 314 · 1er novembre 2026–11 juillet 2027",
            "The notice should link the verified official timetable for the replacement line."
        )
        precondition(
            notice.timetableURL.absoluteString == "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20261021T153740Z-878f05ec-b765-486b-bb83-7d8a6d99c48b.pdf",
            "The replacement timetable URL should resolve to the current official IDFM PDF."
        )
        precondition(
            notice.routePlanTitle == "Plan schématique officiel 214/314 · août 2026",
            "The notice should label the combined route plan as a schematic reference."
        )
        precondition(
            notice.routePlanURL.absoluteString == "https://www.iledefrance-mobilites.fr/medias/portail-idfm-operateurs/ORL14VYfG2K1HYNw_THERMO_BOUCLES-DE-MARNE-214-314_08.26.pdf",
            "The plan link should point to the official 214/314 diagram included by IDFM."
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

        let missing314Notice = PublishedServiceDiscrepancy.forMissingAnnouncedLine314(
            gtfsRouteShortNames: ["214", "N11"]
        )
        guard let missing314Notice else {
            fatalError("The scenario should explain when the announced 314 is absent from loaded GTFS.")
        }
        precondition(missing314Notice.title.contains("314"), "The notice should identify line 314.")
        precondition(
            missing314Notice.detail.contains("Neuilly-Plaisance RER")
                && missing314Notice.detail.contains("Chanoux"),
            "The notice should preserve the officially published termini."
        )
        precondition(
            missing314Notice.detail.contains("15 minutes en heures de pointe")
                && missing314Notice.detail.contains("heures creuses"),
            "The notice should include published service frequencies without inventing trips."
        )
        precondition(
            missing314Notice.detail.contains("premières courses le lundi 2 novembre 2026"),
            "The 314 notice should distinguish the 1 November effective date from its first weekday service."
        )
        precondition(
            missing314Notice.timetableURL.absoluteString == notice.timetableURL.absoluteString
                && missing314Notice.routePlanURL.absoluteString == notice.routePlanURL.absoluteString
                && missing314Notice.gtfsSourceURL.absoluteString == notice.gtfsSourceURL.absoluteString,
            "The 314 notice should link to the official timetable, combined plan, and public GTFS source."
        )
        precondition(
            PublishedServiceDiscrepancy.forMissingAnnouncedLine314(gtfsRouteShortNames: ["214", "314"]) == nil,
            "Do not show a missing-route notice when GTFS contains the 314."
        )
        precondition(
            PublishedServiceDiscrepancy.forMissingAnnouncedLine314(gtfsRouteShortNames: [" 314 "]) == nil,
            "Whitespace around a GTFS route short name must not trigger a false missing-route notice."
        )

        print("Published-service discrepancy checks passed.")
    }
}
