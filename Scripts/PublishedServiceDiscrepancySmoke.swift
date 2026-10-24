import Foundation

@main
struct PublishedServiceDiscrepancySmoke {
    static func main() {
        let notice = PublishedServiceDiscrepancy.forRoute(
            shortName: "214",
            routeID: "IDFM:C01228",
            serviceDateKey: 20261101,
            scheduledTripCount: 0
        )

        guard let notice else {
            fatalError("The missing post-reorganization 214 service should show its published-service notice.")
        }

        precondition(notice.detail.contains("Chanoux"), "The notice should explain the stop transfer to line 314.")
        precondition(notice.detail.contains("314"), "The notice should identify the replacement route.")
        precondition(notice.detail.contains("1er novembre"), "The notice should name the effective date.")
        precondition(
            notice.sourceURL.absoluteString == "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-restructure-et-reorganise-loffre-de-bus-sur-les-territoires-des-bords-de-marne-et-de-boucle-nord-de-seine/?lang=fr",
            "The notice should link to the primary IDFM announcement."
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
