import Foundation

struct PublishedServiceDiscrepancy: Hashable, Sendable {
    let title: String
    let detail: String
    let sourceTitle: String
    let sourceURL: URL

    static func forRoute(
        shortName: String,
        routeID: String,
        serviceDateKey: Int,
        scheduledTripCount: Int
    ) -> PublishedServiceDiscrepancy? {
        guard shortName == "214",
              routeID == "IDFM:C01228",
              serviceDateKey >= 20261101,
              scheduledTripCount == 0 else {
            return nil
        }

        return PublishedServiceDiscrepancy(
            title: "Service annoncé, départs GTFS manquants",
            detail: "IDFM annonce le maintien et le renfort de fréquence de la 214 dès le 1er novembre, avec transfert des arrêts des Chanoux à la nouvelle 314. Cette version GTFS ne prévoit aucun départ pour la date choisie. La fiche 214 référencée, valable jusqu’au 31 décembre, montre encore des courses passant par les Chanoux sans distinguer l’entrée en vigueur de la réorganisation ; elle ne permet donc pas de déduire la grille après le 1er novembre.",
            sourceTitle: "Communiqué IDFM du 21 octobre 2026",
            sourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-restructure-et-reorganise-loffre-de-bus-sur-les-territoires-des-bords-de-marne-et-de-boucle-nord-de-seine/?lang=fr")!
        )
    }
}
