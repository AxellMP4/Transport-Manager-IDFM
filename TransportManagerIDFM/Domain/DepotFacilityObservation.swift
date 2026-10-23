import Foundation

struct DepotFacilityObservation: Hashable, Sendable, Identifiable {
    let id: String
    let periodLabel: String
    let siteAreaSquareMeters: Int
    let approximateLineCount: Int
    let line113StandardBusCount: Int
    let line113StandardBusLengthMeters: Int
    let articulatedBusLimitation: String
    let limitationNote: String
    let sourceTitle: String
    let sourceURL: URL

    var metricLabels: [String] {
        [
            "\(siteAreaSquareMeters.formatted(.number.grouping(.automatic).locale(Locale(identifier: "fr_FR")))) m² d’emprise du site",
            "Environ \(approximateLineCount) lignes desservies",
            "Ligne 113 : \(line113StandardBusCount) autobus standards de \(line113StandardBusLengthMeters) m"
        ]
    }
}

enum DepotFacilityEvidenceCatalog {
    static let neuillyPlaisanceHistorical = DepotFacilityObservation(
        id: "neuilly-plaisance-diagnostic-historique",
        periodLabel: "Diagnostic historique · références internes 2020–2022 · avant le transfert DSP45 du 1er novembre 2025",
        siteAreaSquareMeters: 22_000,
        approximateLineCount: 15,
        line113StandardBusCount: 27,
        line113StandardBusLengthMeters: 12,
        articulatedBusLimitation: "Le diagnostic indiquait qu’à cette époque le centre ne pouvait pas accueillir de bus articulés; cette contrainte historique ne décrit pas l’infrastructure actuelle.",
        limitationNote: "L’emprise de 22 000 m² n’est pas une capacité de remisage. Les 27 bus concernent la ligne 113 dans le diagnostic et les quelque 15 lignes décrivent son périmètre de service; ces chiffres ne donnent ni le parc total, ni la capacité maximale, ni la capacité actuelle du site après le transfert DSP45.",
        sourceTitle: "IDFM · Schéma de principe Bus Bords de Marne · diagnostic du centre bus",
        sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/e1b086d3-0a35-413f-978c-7919496a980b_BBM_SDP_VFFF.pdf")!
    )
}
