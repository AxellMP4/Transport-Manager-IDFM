import Foundation

struct DepotFacilityObservation: Hashable, Sendable, Identifiable {
    let id: String
    let periodLabel: String
    let siteAreaSquareMeters: Int
    let siteAreaQualifier: String
    let siteAreaIsApproximate: Bool
    let approximateLineCount: Int?
    let line113StandardBusCount: Int?
    let line113StandardBusLengthMeters: Int?
    let standardBusParkingCapacity: Int?
    let articulatedBusParkingCapacity: Int?
    let operationalNote: String
    let limitationNote: String
    let sourceTitle: String
    let sourceURL: URL

    init(
        id: String,
        periodLabel: String,
        siteAreaSquareMeters: Int,
        siteAreaQualifier: String = "d’emprise du site",
        siteAreaIsApproximate: Bool = false,
        approximateLineCount: Int? = nil,
        line113StandardBusCount: Int? = nil,
        line113StandardBusLengthMeters: Int? = nil,
        standardBusParkingCapacity: Int? = nil,
        articulatedBusParkingCapacity: Int? = nil,
        operationalNote: String,
        limitationNote: String,
        sourceTitle: String,
        sourceURL: URL
    ) {
        self.id = id
        self.periodLabel = periodLabel
        self.siteAreaSquareMeters = siteAreaSquareMeters
        self.siteAreaQualifier = siteAreaQualifier
        self.siteAreaIsApproximate = siteAreaIsApproximate
        self.approximateLineCount = approximateLineCount
        self.line113StandardBusCount = line113StandardBusCount
        self.line113StandardBusLengthMeters = line113StandardBusLengthMeters
        self.standardBusParkingCapacity = standardBusParkingCapacity
        self.articulatedBusParkingCapacity = articulatedBusParkingCapacity
        self.operationalNote = operationalNote
        self.limitationNote = limitationNote
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
    }

    var metricLabels: [String] {
        let area = siteAreaSquareMeters.formatted(.number.grouping(.automatic).locale(Locale(identifier: "fr_FR")))
        let areaLabel = "\(siteAreaIsApproximate ? "Environ " : "")\(area) m² \(siteAreaQualifier)"
        var labels = [areaLabel]

        if let approximateLineCount {
            labels.append("Environ \(approximateLineCount) lignes desservies")
        }

        if let line113StandardBusCount, let line113StandardBusLengthMeters {
            labels.append("Ligne 113 : \(line113StandardBusCount) autobus standards de \(line113StandardBusLengthMeters) m")
        }

        if let standardBusParkingCapacity {
            labels.append("Stationnement extérieur : capacité publiée de \(standardBusParkingCapacity) bus standards")
        }

        if let articulatedBusParkingCapacity {
            labels.append("Stationnement extérieur : capacité publiée de \(articulatedBusParkingCapacity) bus articulés")
        }

        return labels
    }
}

enum DepotFacilityEvidenceCatalog {
    static let villiersLeBelCurrent = DepotFacilityObservation(
        id: "villiers-le-bel-capacite-stationnement-2026",
        periodLabel: "Site construit · page RATP modifiée le 26 juin 2026",
        siteAreaSquareMeters: 17_000,
        siteAreaQualifier: "d’emprise du terrain",
        siteAreaIsApproximate: true,
        standardBusParkingCapacity: 76,
        articulatedBusParkingCapacity: 34,
        operationalNote: "La RATP décrit une aire de stationnement à ciel ouvert complétée par un atelier de maintenance dans un bâtiment labellisé HQE.",
        limitationNote: "Les capacités concernent l’aire extérieure de ce seul site et ne renseignent pas le nombre de places d’atelier, les équipements énergétiques ou la répartition des lignes.",
        sourceTitle: "RATP · programme bus2025 · nouveau centre bus de Villiers-le-Bel",
        sourceURL: URL(string: "https://www.ratp.fr/programme-bus2025")!
    )

    static let neuillyPlaisanceHistorical = DepotFacilityObservation(
        id: "neuilly-plaisance-diagnostic-historique",
        periodLabel: "Diagnostic historique · références internes 2020–2022 · avant le transfert DSP45 du 1er novembre 2025",
        siteAreaSquareMeters: 22_000,
        siteAreaQualifier: "d’emprise du site",
        siteAreaIsApproximate: false,
        approximateLineCount: 15,
        line113StandardBusCount: 27,
        line113StandardBusLengthMeters: 12,
        operationalNote: "Le diagnostic indiquait qu’à cette époque le centre ne pouvait pas accueillir de bus articulés; cette contrainte historique ne décrit pas l’infrastructure actuelle.",
        limitationNote: "L’emprise de 22 000 m² n’est pas une capacité de remisage. Les 27 bus concernent la ligne 113 dans le diagnostic et les quelque 15 lignes décrivent son périmètre de service; ces chiffres ne donnent ni le parc total, ni la capacité maximale, ni la capacité actuelle du site après le transfert DSP45.",
        sourceTitle: "IDFM · Schéma de principe Bus Bords de Marne · diagnostic du centre bus",
        sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/e1b086d3-0a35-413f-978c-7919496a980b_BBM_SDP_VFFF.pdf")!
    )

    static let futureBordsDeMarne = DepotFacilityObservation(
        id: "neuilly-sur-marne-cob-projet-emprise-2023",
        periodLabel: "Projet · dossier IDFM de concertation de septembre 2023",
        siteAreaSquareMeters: 32_000,
        siteAreaQualifier: "d’emprise prévue",
        siteAreaIsApproximate: true,
        operationalNote: "Le dossier prévoit le remisage et la maintenance des bus du Bus Bords de Marne et d’autres lignes du secteur.",
        limitationNote: "La surface d’emprise ne donne ni le nombre de places de remisage, ni une capacité opérationnelle, ni les équipements installés. Le document décrit un projet et ne confirme pas la réalisation du site.",
        sourceTitle: "IDFM · dossier de concertation du futur COB · septembre 2023",
        sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/26367fc3-7fd7-4c5e-9c1c-6e2393bd9c3f_2023.10.12%2B-%2BDossier%2Bde%2Bconcertation%2BMECDU%2BBBM.pdf")!
    )
}
