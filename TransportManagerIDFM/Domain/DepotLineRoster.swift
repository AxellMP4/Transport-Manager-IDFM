import Foundation

enum DepotLineEvidenceStatus: String, Hashable, Sendable {
    case confirmed = "Rattachement documenté"
    case shared = "Partagée"
    case partial = "Remisage partiel"
    case observedPool = "Parc de ligne observé"
    case candidate = "Affectation candidate"
    case unresolved = "Non attribuée"
    case conflict = "Sources contradictoires"
    case planned = "Projet"

    var systemImage: String {
        switch self {
        case .confirmed: "checkmark.seal.fill"
        case .shared: "arrow.triangle.branch"
        case .partial: "bus.fill"
        case .observedPool: "eye"
        case .candidate: "questionmark.circle"
        case .unresolved: "minus.circle"
        case .conflict: "exclamationmark.triangle.fill"
        case .planned: "hammer"
        }
    }
}

enum DepotSiteAvailability: Hashable, Sendable {
    case operational
    case planned
    case currentStatusUnverified

    var label: String {
        switch self {
        case .operational: "En activité · preuve publique"
        case .planned: "Projet · non opérationnel"
        case .currentStatusUnverified: "Site référencé · statut actuel à vérifier"
        }
    }

    var shortLabel: String {
        switch self {
        case .operational: "En activité"
        case .planned: "Projet"
        case .currentStatusUnverified: "À vérifier"
        }
    }

    var systemImage: String {
        switch self {
        case .operational: "building.2.fill"
        case .planned: "hammer"
        case .currentStatusUnverified: "questionmark.circle"
        }
    }

    var isOperational: Bool { self == .operational }
}

struct DepotLineRosterSite: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let locality: String
    let status: String
    let availability: DepotSiteAvailability
    let evidenceNote: String
    let sourceURL: URL?
    let documentedAddress: String?
    let evidenceTitle: String?
    let idfmBusContractID: String?
    let additionalEvidenceTitle: String?
    let additionalEvidenceURL: URL?
    let fleetObservation: DepotFleetObservation?
    let facilityObservations: [DepotFacilityObservation]

    var isOperational: Bool { availability.isOperational }

    /// The public contract defines a real line roster for this site. An unverified
    /// operating status stays visible but does not prevent a career on that contract.
    var hasPlayableContractScope: Bool {
        availability != .planned && idfmBusContractID != nil
    }

    init(
        id: String,
        name: String,
        locality: String,
        status: String,
        availability: DepotSiteAvailability,
        evidenceNote: String,
        sourceURL: URL?,
        documentedAddress: String? = nil,
        evidenceTitle: String? = nil,
        idfmBusContractID: String? = nil,
        additionalEvidenceTitle: String? = nil,
        additionalEvidenceURL: URL? = nil,
        fleetObservation: DepotFleetObservation? = nil,
        facilityObservations: [DepotFacilityObservation] = []
    ) {
        self.id = id
        self.name = name
        self.locality = locality
        self.status = status
        self.availability = availability
        self.evidenceNote = evidenceNote
        self.sourceURL = sourceURL
        self.documentedAddress = documentedAddress
        self.evidenceTitle = evidenceTitle
        self.idfmBusContractID = idfmBusContractID
        self.additionalEvidenceTitle = additionalEvidenceTitle
        self.additionalEvidenceURL = additionalEvidenceURL
        self.fleetObservation = fleetObservation
        self.facilityObservations = facilityObservations
    }
}

struct DepotFleetEnergyCount: Hashable, Identifiable, Sendable {
    let energyTitle: String
    let vehicleCount: Int

    var id: String { energyTitle }
}

struct DepotFleetObservation: Hashable, Sendable {
    let totalVehicleCount: Int
    let energyCounts: [DepotFleetEnergyCount]
    let averageFleetAgeYears: Double?
    let airConditionedVehicleSharePercent: Int?
    let reviewedOnLabel: String
    let sourceFreshnessNote: String
    let limitationNote: String
    let sourceTitle: String
    let sourceURL: URL
    let comparisonNote: String?
    let comparisonSourceTitle: String?
    let comparisonSourceURL: URL?

    init(
        totalVehicleCount: Int,
        energyCounts: [DepotFleetEnergyCount],
        averageFleetAgeYears: Double?,
        airConditionedVehicleSharePercent: Int?,
        reviewedOnLabel: String,
        sourceFreshnessNote: String,
        limitationNote: String,
        sourceTitle: String,
        sourceURL: URL,
        comparisonNote: String? = nil,
        comparisonSourceTitle: String? = nil,
        comparisonSourceURL: URL? = nil
    ) {
        self.totalVehicleCount = totalVehicleCount
        self.energyCounts = energyCounts
        self.averageFleetAgeYears = averageFleetAgeYears
        self.airConditionedVehicleSharePercent = airConditionedVehicleSharePercent
        self.reviewedOnLabel = reviewedOnLabel
        self.sourceFreshnessNote = sourceFreshnessNote
        self.limitationNote = limitationNote
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
        self.comparisonNote = comparisonNote
        self.comparisonSourceTitle = comparisonSourceTitle
        self.comparisonSourceURL = comparisonSourceURL
    }
}

struct DepotLineDocumentLink: Identifiable, Hashable, Sendable {
    let title: String
    let type: String
    let url: URL
    let validity: String
    let note: String?

    var id: String { "\(type)|\(url.absoluteString)" }
}

enum DepotLineRosterClaimKind: String, Hashable, Sendable {
    case contractCenter = "Centre indiqué au contrat"
    case sharedContractCenters = "Centres listés au contrat"
    case partialStorage = "Remisage partiel"
    case fleetObservation = "Observation de parc"
    case candidateAssignment = "Affectation candidate"
    case networkScopeOnly = "Périmètre sans COB établi"
    case conflictingClaim = "Affirmation en conflit"
    case announcedService = "Service annoncé"
    case supportingSource = "Source complémentaire"

    var systemImage: String {
        switch self {
        case .contractCenter, .sharedContractCenters: "building.2"
        case .partialStorage: "bus.fill"
        case .fleetObservation: "eye"
        case .candidateAssignment: "questionmark.circle"
        case .networkScopeOnly: "point.3.connected.trianglepath.dotted"
        case .conflictingClaim: "exclamationmark.triangle"
        case .announcedService: "calendar.badge.clock"
        case .supportingSource: "link"
        }
    }
}

struct DepotLineRosterClaim: Identifiable, Hashable, Sendable {
    let kind: DepotLineRosterClaimKind
    let siteID: String?
    let centerLabel: String?
    let sourceTitle: String
    let sourceURL: URL?
    let sourceDate: Date?
    let sourceDateLabel: String?
    let validFromKey: Int?
    let validThroughKey: Int?
    let note: String?

    init(
        kind: DepotLineRosterClaimKind,
        siteID: String?,
        centerLabel: String?,
        sourceTitle: String,
        sourceURL: URL?,
        sourceDate: Date? = nil,
        sourceDateLabel: String?,
        validFromKey: Int?,
        validThroughKey: Int?,
        note: String?
    ) {
        self.kind = kind
        self.siteID = siteID
        self.centerLabel = centerLabel
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
        self.sourceDate = sourceDate
        self.sourceDateLabel = sourceDateLabel
        self.validFromKey = validFromKey
        self.validThroughKey = validThroughKey
        self.note = note
    }

    var id: String {
        "\(siteID ?? "unknown-site")|\(kind.rawValue)|\(sourceTitle)|\(sourceURL?.absoluteString ?? "")"
    }

    var sourceDateSummary: String {
        if let sourceDateLabel {
            return sourceDate == nil
                ? "Référence ou édition de source : \(sourceDateLabel) · date exacte inconnue"
                : "Source datée : \(sourceDateLabel)"
        }
        if let sourceDate {
            return "Source datée : \(sourceDate.formatted(date: .numeric, time: .omitted))"
        }
        return "Date de publication ou d’observation inconnue"
    }

    var validitySummary: String {
        switch (validFromKey, validThroughKey) {
        case (nil, nil):
            "Période de validité inconnue"
        case let (start?, end?):
            "Valide du \(Self.dateLabel(start)) au \(Self.dateLabel(end))"
        case let (start?, nil):
            "À partir du \(Self.dateLabel(start)) · fin inconnue"
        case let (nil, end?):
            "Jusqu’au \(Self.dateLabel(end)) · début inconnu"
        }
    }

    /// Unknown validity remains visible in a date-filtered catalog, but is not evidence that the claim is current.
    func isVisible(on date: Date) -> Bool {
        guard let key = GTFSServiceDate.key(for: date, timeZone: GTFSServiceDate.parisTimeZone) else { return false }
        if let validFromKey, key < validFromKey { return false }
        if let validThroughKey, key > validThroughKey { return false }
        return true
    }

    private static func dateLabel(_ key: Int) -> String {
        String(format: "%02d/%02d/%04d", key % 100, key / 100 % 100, key / 10_000)
    }
}

struct DepotLineRosterRow: Identifiable, Hashable, Sendable {
    let line: String
    let category: String
    let siteIDs: [String]
    let evidenceStatus: DepotLineEvidenceStatus
    let note: String
    let publicDocuments: [DepotLineDocumentLink]
    let claims: [DepotLineRosterClaim]
    var canonicalLineID: String? = nil

    var id: String { canonicalLineID.map { "\(line)|\($0)" } ?? line }

    func evidenceStatus(on date: Date) -> DepotLineEvidenceStatus {
        let currentClaims = claims.filter { $0.isVisible(on: date) && $0.kind != .supportingSource }
        guard !currentClaims.isEmpty else { return .unresolved }

        if currentClaims.contains(where: { $0.kind == .conflictingClaim }) { return .conflict }
        if currentClaims.contains(where: { $0.kind == .partialStorage }) { return .partial }
        if currentClaims.contains(where: { $0.kind == .sharedContractCenters }) { return .shared }
        if currentClaims.contains(where: { $0.kind == .contractCenter && $0.siteID != nil }) { return .confirmed }
        if currentClaims.contains(where: { $0.kind == .fleetObservation }) { return .observedPool }
        if currentClaims.contains(where: { $0.kind == .candidateAssignment }) { return .candidate }
        if currentClaims.contains(where: { $0.kind == .announcedService && $0.siteID != nil }) { return .planned }
        return .unresolved
    }

    func isVisible(on date: Date) -> Bool {
        claims.contains { $0.isVisible(on: date) }
    }

    func siteIDsWithEvidence(on date: Date) -> Set<String> {
        var evidenceSiteIDs = Set<String>()
        for claim in claims where claim.isVisible(on: date) {
            if let siteID = claim.siteID, claim.kind != .supportingSource {
                evidenceSiteIDs.insert(siteID)
            } else if claim.siteID == nil, claim.kind == .sharedContractCenters {
                evidenceSiteIDs.formUnion(siteIDs)
            }
        }
        return evidenceSiteIDs
    }

    func siteEvidenceClaims(for siteID: String, on date: Date) -> [DepotLineRosterClaim] {
        claims.filter { claim in
            guard claim.isVisible(on: date), claim.kind != .supportingSource else { return false }
            if claim.siteID == siteID { return true }
            return claim.siteID == nil
                && claim.kind == .sharedContractCenters
                && siteIDs.contains(siteID)
        }
    }

    func isVisible(atSite siteID: String, on date: Date) -> Bool {
        !siteEvidenceClaims(for: siteID, on: date).isEmpty
    }
}

enum DepotLineRoster {
    static let bordsDeMarneManifestSiteIDs: Set<String> = [
        "saint-maur", "neuilly-plaisance", "freres-lumiere", "neuilly-sur-marne-projet"
    ]

    static let contractEvidenceURL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/aTFjzHNYClf9nz_6_ContratBUS2025-2026_vsigne%CC%81eLP.pdf")!
    static let awardEvidenceURL = URL(string: "https://presse.iledefrance-mobilites.fr/mise-en-concurrence-des-transports-franciliens/?lang=fr")!
    static let wikipediaURL = URL(string: "https://fr.wikipedia.org/wiki/R%C3%A9seau_de_bus_Bord_de_Marne")!
    static let databusURL = URL(string: "https://busparisiens.fr/DataBus/tel/DB_liste.php")!
    static let reorganizationURL = URL(string: "https://www.iledefrance-mobilites.fr/actualites/locales/detail/a-compter-du-1er-novembre-2026-ile-de-france-mobil")!
    private static let reorganizationServiceSummaries: [String: String] = [
        "101": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "106": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "107": "Fréquences annoncées : 15 min en pointe en semaine, 20 à 30 min le samedi et 30 min le dimanche.",
        "108": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "110": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "111": "Fréquence annoncée de 8 min en pointe du lundi au vendredi.",
        "112": "Renfort de fréquence annoncé.",
        "113": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "114": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "116": "Fréquence renforcée, amplitude horaire élargie et fréquence renforcée le week-end annoncées.",
        "118": "Renfort de fréquence annoncé.",
        "120": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "124": "Renfort de fréquence annoncé.",
        "127": "Renfort de fréquence annoncé.",
        "201": "Ajustements ponctuels des horaires annoncés ; la nouvelle grille détaillée n’est pas publiée ici.",
        "203": "Fréquence renforcée et amplitude horaire élargie annoncées.",
        "210": "Parcours modifié à Fontenay-sous-Bois et Vincennes pour desservir les Rigollots ; fréquence annoncée de 20 min en journée du lundi au vendredi.",
        "214": "Maintien de la ligne avec fréquences renforcées et amplitude horaire élargie ; les arrêts de la ZI des Chanoux sont transférés à la nouvelle 314.",
        "221": "Aucune modification de fonctionnement annoncée.",
        "303": "Renfort de fréquence annoncé, y compris le week-end.",
        "306": "Aucune modification de fonctionnement annoncée.",
        "314": "Nouvelle liaison Neuilly-Plaisance RER–ZI des Chanoux, du lundi au vendredi : 15 min en pointe et 60 min en heures creuses.",
        "520": "Aucune modification de fonctionnement annoncée.",
        "N11": "Aucune modification de fonctionnement annoncée.",
        "N16": "Aucune modification de fonctionnement annoncée.",
        "N32": "Aucune modification de fonctionnement annoncée.",
        "N33": "Aucune modification de fonctionnement annoncée.",
        "N34": "Aucune modification de fonctionnement annoncée.",
        "N35": "Aucune modification de fonctionnement annoncée.",
        "N71": "Aucune modification de fonctionnement annoncée."
    ]
    static let historicalBordsDeMarneCenterURL = URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/questions/quelles-seront-les-caracteristiques-du-materiel-roulant")!
    private static let ratpSeineSaintDenisBrochure2026URL = URL(string: "https://ratpgroup.com/api/media/brochure-ratp-en-seine-saint-denis-2026.pdf")!
    static let gtfsDatasetURL = URL(string: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm")!
    static let documentsDatasetURL = URL(string: "https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/")!
    static let lineReferenceURL = URL(string: "https://data.iledefrance-mobilites.fr/explore/dataset/referentiel-des-lignes/")!
    private static let ratpBus2025URL = URL(string: "https://www.ratp.fr/programme-bus2025")!
    private static let ratpDSP45DepotSplitURL = URL(string: "https://askip.ratpgroup.com/question/ile-de-france-mobilites-vient-de-publier-4-appels-doffres-quels-sont-les-centres-bus-concernes/")!
    private static let idfmDSP41To47URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-designe-les-operateurs-bus-de-quatre-lots-en-petite-couronne-et-dun-lot-en-grande-couronne/?lang=fr")!
    private static let idfmDSP36To40URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-designe-les-operateurs-bus-de-trois-lots-en-petite-couronne-et-reattribue-un-lot-en-grande-couronne/?lang=fr")!
    private static let idfmDSP1And18And24URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-confirme-lattribution-de-deux-lots-de-bus-et-le-marche-pam/?lang=fr")!
    private static let idfmDSP48And49URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-designe-ratp-cap-ile-de-france-comme-operateur-des-deux-derniers-lots-de-bus-de-paris-et-petite-couronne/?lang=fr")!
    private static let idfmDepotSchedule2024URL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/Zk4bEiol0Zci9XOy_CalendriersiteIDFMv22052024.pdf")!

    static let sites: [DepotLineRosterSite] = [
        DepotLineRosterSite(
            id: "saint-maur",
            name: "COB Saint-Maur",
            locality: "Saint-Maur-des-Fossés",
            status: "COB DSP45 · affectations par ligne à établir",
            availability: .operational,
            evidenceNote: "Le site figure parmi les deux COB de la DSP45. Le tableau ligne–centre de l’ancien contrat IDFM–RATP documente Saint-Maur avant le transfert du 1er novembre 2025 ; les lignes du nouvel exploitant ne sont pas ventilées par COB dans les sources consultées. RATP Group chiffre rétrospectivement neuf lignes pour Saint-Maur dans la préparation du lot 45 en 2022, sans en publier les numéros dans cet article.",
            sourceURL: contractEvidenceURL,
            evidenceTitle: "IDFM–RATP · tableau ligne–centre 2025–2026",
            idfmBusContractID: "45",
            additionalEvidenceTitle: "RATP Group · répartition des lignes du lot 45 par centre-bus · 29 mars 2022",
            additionalEvidenceURL: ratpDSP45DepotSplitURL,
            fleetObservation: DepotFleetObservation(
                totalVehicleCount: 98,
                energyCounts: [
                    DepotFleetEnergyCount(energyTitle: "Gaz", vehicleCount: 92),
                    DepotFleetEnergyCount(energyTitle: "Diesel", vehicleCount: 6)
                ],
                averageFleetAgeYears: 4.5,
                airConditionedVehicleSharePercent: 94,
                reviewedOnLabel: "Page consultée le 23 octobre 2026 · actualisation source non datée",
                sourceFreshnessNote: "TC Infos présente le parc comme actuel, sans indiquer la date de mise à jour de son inventaire.",
                limitationNote: "Comptage de véhicules observés; il ne donne ni la capacité maximale du site, ni ses postes d’atelier ou de ravitaillement, ni les lignes auxquelles chaque véhicule est affecté.",
                sourceTitle: "TC Infos · parc actuel du dépôt Saint-Maur",
                sourceURL: URL(string: "https://tc-infos.fr/exploitant/2975/depot/4665")!
            )
        ),
        DepotLineRosterSite(
            id: "neuilly-plaisance",
            name: "COB Neuilly-Plaisance",
            locality: "Neuilly-Plaisance",
            status: "COB recensé · lignes DSP45 à ventiler",
            availability: .operational,
            evidenceNote: "La brochure RATP d’avril 2026 identifie le COB Neuilly-Plaisance parmi ses sites opérationnels et indique séparément que la DSP 45 Boucles de Marne est exploitée par RATP Cap IDF depuis le 1er novembre 2025. Elle ne répartit pas les lignes du contrat entre les COB. En 2022, RATP Group comptait treize lignes du centre-bus de Bords-de-Marne pour le lot 45, sans donner leurs numéros dans cet article ni établir les affectations après le transfert. Le tableau ligne–centre de l’ancien contrat IDFM–RATP reste borné au 31 octobre 2025.",
            sourceURL: ratpSeineSaintDenisBrochure2026URL,
            evidenceTitle: "RATP · présence en Seine-Saint-Denis · avril 2026",
            idfmBusContractID: "45",
            additionalEvidenceTitle: "RATP Group · répartition des lignes du lot 45 par centre-bus · 29 mars 2022",
            additionalEvidenceURL: ratpDSP45DepotSplitURL,
            fleetObservation: DepotFleetObservation(
                totalVehicleCount: 200,
                energyCounts: [
                    DepotFleetEnergyCount(energyTitle: "Diesel", vehicleCount: 148),
                    DepotFleetEnergyCount(energyTitle: "Hybride", vehicleCount: 52)
                ],
                averageFleetAgeYears: 12.6,
                airConditionedVehicleSharePercent: 0,
                reviewedOnLabel: "Page consultée le 23 octobre 2026 · actualisation source non datée",
                sourceFreshnessNote: "TC Infos présente le parc comme actuel, sans indiquer la date de mise à jour de son inventaire.",
                limitationNote: "Comptage de véhicules observés; il ne donne ni la capacité maximale du site, ni ses postes d’atelier ou de ravitaillement, ni les lignes auxquelles chaque véhicule est affecté.",
                sourceTitle: "TC Infos · parc actuel du COB Neuilly-Plaisance",
                sourceURL: neuillyDepotURL,
                comparisonNote: "La page récapitulative de l’exploitant TC Infos indique 201 véhicules pour ce site, tandis que sa fiche détaillée en compte 200 (148 diesel et 52 hybrides). Les deux pages donnent une période de parc « depuis novembre 2025 » sans date de mise à jour; le total détaillé reste une observation, pas une capacité certifiée.",
                comparisonSourceTitle: "TC Infos · récapitulatif de l’exploitant (201 véhicules)",
                comparisonSourceURL: URL(string: "https://tc-infos.fr/exploitant/2975")!
            ),
            facilityObservations: [DepotFacilityEvidenceCatalog.neuillyPlaisanceHistorical]
        ),
        DepotLineRosterSite(
            id: "freres-lumiere",
            name: "Site Frères-Lumière",
            locality: "Neuilly-sur-Marne · ZI des Chanoux",
            status: "Site d’appui de la ligne 113 · flotte observée",
            availability: .operational,
            evidenceNote: "La décision IDFM de 2023 documente un remisage d’appui pour une partie des articulés de la 113. Le parc actuel TC Infos recense 12 Irisbus Citelis 18 diesel sur ce site au relevé du 23 octobre 2026, sans attribuer d’autres lignes. La date de mise à jour du parc n’est pas publiée et ce nombre ne représente pas la capacité maximale. La carte RATP Cap de mars 2026 identifie aussi un COB à Neuilly-sur-Marne sans préciser son nom ni son adresse : elle corrobore un COB dans la commune, mais ne permet pas de confirmer que son symbole désigne ce site Frères-Lumière. Celui-ci reste distinct du futur COB IDFM.",
            sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/1c3d876c-ef6f-4f9f-ae60-8756ae273ba7_RAA_153-2.pdf"),
            additionalEvidenceTitle: "RATP Cap · carte des réseaux et COB · mars 2026 (adresse à confirmer)",
            additionalEvidenceURL: URL(string: "https://www.ratpcap.com/wp-content/uploads/2026/03/Carte_Reseaux_RATPCap_mars2026_compressed.pdf"),
            fleetObservation: DepotFleetObservation(
                totalVehicleCount: 12,
                energyCounts: [DepotFleetEnergyCount(energyTitle: "Diesel", vehicleCount: 12)],
                averageFleetAgeYears: 13.4,
                airConditionedVehicleSharePercent: 0,
                reviewedOnLabel: "Page consultée le 23 octobre 2026 · actualisation source non datée",
                sourceFreshnessNote: "TC Infos présente le parc comme actuel; les véhicules listés sont des Citelis 18 arrivés sur le site entre novembre 2025 et mars 2026.",
                limitationNote: "Comptage de véhicules observés, pas capacité maximale du site ou répartition des courses.",
                sourceTitle: "TC Infos · parc actuel du dépôt Frères-Lumière",
                sourceURL: URL(string: "https://tc-infos.fr/exploitant/2975/depot/4664")!
            )
        ),
        DepotLineRosterSite(
            id: "neuilly-sur-marne-projet",
            name: "COB Neuilly-sur-Marne · projet",
            locality: "Neuilly-sur-Marne",
            status: "Projet IDFM · mise en service visée vers 2030",
            availability: .planned,
            evidenceNote: "Les études d’avant-projet étaient en cours selon l’actualité IDFM du 1er octobre 2026 ; les sources consultées ne confirment pas le démarrage du chantier. La mise en service du projet est visée vers 2030. La page actuelle des principes IDFM décrit des bus bi-articulés électriques de 24 m, d’environ 145 personnes ; la FAQ IDFM du 22 février 2024 en annonçait environ 150. Ces estimations de projet restent distinctes et la configuration finale n’est pas publiée. Le dossier de concertation IDFM de septembre 2023 prévoyait pour le nouveau COB une emprise d’environ 32 000 m², destinée au remisage et à la maintenance des bus du BBM et d’autres lignes ; cette surface ne donne ni nombre de places, ni capacité opérationnelle. IDFM précise que les COB existants ne peuvent pas recevoir les futurs véhicules faute de place. Les capacités propres à chaque COB existant et les lignes supplémentaires du futur site restent à établir. Ce site est distinct de Frères-Lumière.",
            sourceURL: futureBBDMPrinciplesURL,
            evidenceTitle: "IDFM · principes d’aménagement et capacité prévisionnelle des bus · page consultée le 23 octobre 2026",
            additionalEvidenceTitle: "IDFM · dossier de concertation 2023 · emprise prévue du futur COB",
            additionalEvidenceURL: futureBBDMConsultationURL,
            facilityObservations: [DepotFacilityEvidenceCatalog.futureBordsDeMarne]
        )
    ]

    /// COBs named in IDFM contract notices and dated schedules. Lot membership does
    /// not establish which individual lines are based at each COB.
    private static let currentContractSites: [DepotLineRosterSite] = [
        contractSite("coubron", "Coubron", "Coubron", dsp: "DSP 9", operatorName: "Keolis", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution DSP 9 Marne et Brie", sourceURL: awardEvidenceURL),
        contractSite("chelles", "Chelles", "Chelles", dsp: "DSP 9", operatorName: "Keolis", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution DSP 9 Marne et Brie", sourceURL: awardEvidenceURL),
        contractSite("la-trentaine-1", "La Trentaine 1", "Chelles", dsp: "DSP 9", operatorName: "Keolis", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution DSP 9 Marne et Brie", sourceURL: awardEvidenceURL),
        contractSite("la-trentaine-2", "La Trentaine 2", "Chelles", dsp: "DSP 9", operatorName: "Keolis", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution DSP 9 Marne et Brie", sourceURL: awardEvidenceURL),
        contractSite("bussy", "Bussy-Saint-Martin", "Bussy-Saint-Martin", dsp: "DSP 9", operatorName: "Keolis", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution DSP 9 Marne et Brie", sourceURL: awardEvidenceURL),
        contractSite("pontault-combault", "Pontault-Combault", "Pontault-Combault", dsp: "DSP 9", operatorName: "Keolis", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution DSP 9 Marne et Brie", sourceURL: awardEvidenceURL),
        contractSite("le-mesnil-amelot", "Le Mesnil-Amelot", "Le Mesnil-Amelot", dsp: "DSP 39", operatorName: "Exploitant à vérifier", serviceFrom: "1er mars 2026", sourceTitle: "IDFM · calendrier des centres DSP du 22 mai 2024", sourceURL: idfmDepotSchedule2024URL),
        contractSite("nanterre", "Nanterre", "Nanterre", dsp: "DSP 41", operatorName: "RATP Cap", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("charlebourg", "Charlebourg", "La Garenne-Colombes", dsp: "DSP 41", operatorName: "RATP Cap", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("les-guilleraies", "Les Guilleraies", "Nanterre", dsp: "DSP 41", operatorName: "RATP Cap", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("point-du-jour", "Point du Jour", "Paris 16e", dsp: "DSP 41", operatorName: "RATP Cap", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("asnieres", "Asnières", "Asnières-sur-Seine", dsp: "DSP 42", operatorName: "RATP Cap", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution de la DSP 42", sourceURL: awardEvidenceURL),
        contractSite("pleyel", "Pleyel", "Saint-Denis", dsp: "DSP 42", operatorName: "RATP Cap", serviceFrom: "1er novembre 2025", sourceTitle: "IDFM · attribution de la DSP 42", sourceURL: awardEvidenceURL),
        contractSite("aubervilliers", "Aubervilliers", "Aubervilliers", dsp: "DSP 43", operatorName: "RATP Cap", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("saint-denis", "Saint-Denis", "Saint-Denis", dsp: "DSP 43", operatorName: "RATP Cap", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("villiers-le-bel", "Villiers-le-Bel", "Villiers-le-Bel", dsp: "DSP 43", operatorName: "RATP Cap", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("creteil", "Créteil", "Créteil", dsp: "DSP 46", operatorName: "RATP Cap", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("thiais", "Thiais", "Thiais", dsp: "DSP 46", operatorName: "RATP Cap", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("ivry", "Ivry", "Ivry-sur-Seine", dsp: "DSP 47", operatorName: "Keolis", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("vitry", "Vitry", "Vitry-sur-Seine", dsp: "DSP 47", operatorName: "Keolis", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("villeneuve-le-roi", "Villeneuve-le-Roi", "Villeneuve-le-Roi", dsp: "DSP 47", operatorName: "Keolis", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL),
        contractSite("choisy-le-roi-tzen5", "Choisy-le-Roi · projet TZen 5", "Choisy-le-Roi", dsp: "DSP 47", operatorName: "Keolis", serviceFrom: nil, sourceTitle: "IDFM · attribution des DSP 41–47", sourceURL: idfmDSP41To47URL, isPlanned: true),
        contractSite("bailly-romainvilliers", "Bailly-Romainvilliers", "Bailly-Romainvilliers", dsp: "DSP 10", operatorName: "Transdev", serviceFrom: "1er janvier 2026", sourceTitle: "IDFM · attribution DSP 10 Marne-la-Vallée", sourceURL: idfmDSP41To47URL),
        contractSite("lagny", "Lagny-sur-Marne", "Lagny-sur-Marne", dsp: "DSP 10", operatorName: "Transdev", serviceFrom: "1er janvier 2026", sourceTitle: "IDFM · attribution DSP 10 Marne-la-Vallée", sourceURL: idfmDSP41To47URL),
        contractSite("massy", "Massy", "Massy", dsp: "DSP 36", operatorName: "RATP Cap", serviceFrom: "1er mars 2026", sourceTitle: "IDFM · attribution des DSP 36–40", sourceURL: idfmDSP36To40URL),
        contractSite("morangis", "Morangis", "Morangis", dsp: "DSP 36", operatorName: "RATP Cap", serviceFrom: "1er mars 2026", sourceTitle: "IDFM · attribution des DSP 36–40", sourceURL: idfmDSP36To40URL),
        contractSite("fontenay", "Fontenay", "Fontenay-aux-Roses", dsp: "DSP 40", operatorName: "ATM SPA", serviceFrom: "1er mars 2026", sourceTitle: "IDFM · attribution des DSP 36–40", sourceURL: idfmDSP36To40URL),
        contractSite("bagneux-hydrogene", "Bagneux · COB hydrogène", "Bagneux", dsp: "DSP 40", operatorName: "ATM SPA", serviceFrom: nil, sourceTitle: "IDFM · attribution des DSP 36–40", sourceURL: idfmDSP36To40URL, isPlanned: true),
        contractSite("flandre", "Flandre", "Pantin", dsp: "DSP 44", operatorName: "Transdev", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 36–40", sourceURL: idfmDSP36To40URL),
        contractSite("les-pavillons", "Pavillons", "Les Pavillons-sous-Bois", dsp: "DSP 44", operatorName: "Transdev", serviceFrom: "1er mai 2026", sourceTitle: "IDFM · attribution des DSP 36–40", sourceURL: idfmDSP36To40URL),
        contractSite("genicourt", "Génicourt", "Génicourt", dsp: "DSP 1", operatorName: "Transdev", serviceFrom: "1er août 2025", sourceTitle: "IDFM · attribution des DSP 1, 18 et 24", sourceURL: idfmDSP1And18And24URL),
        contractSite("magny-en-vexin", "Magny-en-Vexin", "Magny-en-Vexin", dsp: "DSP 1", operatorName: "Transdev", serviceFrom: "1er août 2025", sourceTitle: "IDFM · attribution des DSP 1, 18 et 24", sourceURL: idfmDSP1And18And24URL),
        contractSite("etampes", "Étampes", "Étampes", dsp: "DSP 24", operatorName: "Transdev", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 1, 18 et 24", sourceURL: idfmDSP1And18And24URL),
        contractSite("boissy-le-cutte", "Boissy-le-Cutté", "Boissy-le-Cutté", dsp: "DSP 24", operatorName: "Transdev", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 1, 18 et 24", sourceURL: idfmDSP1And18And24URL),
        contractSite("saint-arnoult-en-yvelines", "Saint-Arnoult-en-Yvelines", "Saint-Arnoult-en-Yvelines", dsp: "DSP 24", operatorName: "Transdev", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 1, 18 et 24", sourceURL: idfmDSP1And18And24URL),
        contractSite("saint-fargeau-ponthierry", "Saint-Fargeau-Ponthierry", "Saint-Fargeau-Ponthierry", dsp: "DSP 18", operatorName: "Transdev", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 1, 18 et 24", sourceURL: idfmDSP1And18And24URL),
        contractSite("vaux-le-penil", "Vaux-le-Pénil", "Vaux-le-Pénil", dsp: "DSP 18", operatorName: "Transdev", serviceFrom: "1er août 2026", sourceTitle: "IDFM · attribution des DSP 1, 18 et 24", sourceURL: idfmDSP1And18And24URL),
        contractSite("croix-nivert", "Croix-Nivert", "Paris 15e", dsp: "DSP 48", operatorName: "RATP Cap", serviceFrom: "1er novembre 2026", sourceTitle: "IDFM · attribution des DSP 48–49", sourceURL: idfmDSP48And49URL),
        contractSite("lebrun", "Lebrun", "Paris 13e", dsp: "DSP 48", operatorName: "RATP Cap", serviceFrom: "1er novembre 2026", sourceTitle: "IDFM · attribution des DSP 48–49", sourceURL: idfmDSP48And49URL),
        contractSite("corentin", "Corentin", "Paris 14e", dsp: "DSP 48", operatorName: "RATP Cap", serviceFrom: "1er novembre 2026", sourceTitle: "IDFM · attribution des DSP 48–49", sourceURL: idfmDSP48And49URL),
        contractSite("malakoff", "Malakoff", "Malakoff", dsp: "DSP 48", operatorName: "RATP Cap", serviceFrom: "1er novembre 2026", sourceTitle: "IDFM · attribution des DSP 48–49", sourceURL: idfmDSP48And49URL),
        contractSite("belliard", "Belliard", "Paris 18e", dsp: "DSP 49", operatorName: "RATP Cap", serviceFrom: "1er novembre 2026", sourceTitle: "IDFM · attribution des DSP 48–49", sourceURL: idfmDSP48And49URL),
        contractSite("nation", "Nation", "Paris 12e", dsp: "DSP 49", operatorName: "RATP Cap", serviceFrom: "1er novembre 2026", sourceTitle: "IDFM · attribution des DSP 48–49", sourceURL: idfmDSP48And49URL),
        contractSite("les-lilas", "Les Lilas", "Les Lilas", dsp: "DSP 49", operatorName: "RATP Cap", serviceFrom: "1er novembre 2026", sourceTitle: "IDFM · attribution des DSP 48–49", sourceURL: idfmDSP48And49URL)
    ]

    private static let publicRegionalDepotDirectoryURL = URL(string: "https://fr.wikipedia.org/wiki/Liste_des_centres_op%C3%A9rationnels_bus_en_%C3%8Ele-de-France")!
    private static let publicRegionalDepotDirectoryTitle = "Répertoire public des centres opérationnels bus · dernière mise à jour de la page : 29 septembre 2026"

    /// Completes the selector from the public Île-de-France depot directory.
    /// The directory is secondary evidence for site and network labels. Its
    /// network labels are cross-referenced with IDFM's line reference to identify
    /// a contract; neither source allocates every route to one COB.
    private static let publicRegionalDepotDirectorySites: [DepotLineRosterSite] = [
        directorySite("point-du-jour", "Point du Jour", "Paris 16e", address: "6 bis place de la Porte-de-Saint-Cloud", dspID: "41"),
        directorySite("belliard", "Belliard", "Paris 18e", address: "29 rue Belliard", dspID: "49"),
        directorySite("lagny-paris", "Lagny", "Paris 20e", address: "67 rue de Lagny", dspID: "49"),
        directorySite("corentin", "Corentin", "Paris 14e", address: "73 rue du Père-Corentin", dspID: "48"),
        directorySite("croix-nivert", "Croix-Nivert", "Paris 15e", address: "10 rue Charles-Lecocq", dspID: "48"),
        directorySite("lebrun", "Lebrun", "Paris 13e", address: "29 rue Le Brun", dspID: "48"),

        directorySite("argenteuil", "Argenteuil", "Argenteuil", address: "18 rue Jean Poulmarch", dspID: "33"),
        directorySite("saint-ouen-laumone", "Saint-Ouen-l’Aumône", "Saint-Ouen-l’Aumône", address: "13 rue du Tréate · ZAC du Vert Galant", dspID: "2"),
        directorySite("louvres", "Louvres", "Louvres", address: "4 rue Beaumontoir", dspID: "6"),
        directorySite("villiers-le-bel", "Villiers-le-Bel", "Villiers-le-Bel", address: "23 avenue des Entrepreneurs", dspID: "43"),
        directorySite("saint-gratien", "Saint-Gratien", "Saint-Gratien", address: "1 chemin du Clos Saint-Paul", dspID: "5"),
        directorySite("genicourt", "Génicourt", "Génicourt", address: "35 rue des Fossettes", dspID: "1"),
        directorySite("magny-en-vexin", "Magny-en-Vexin", "Magny-en-Vexin", address: "ZA de la Demi-Lune · 7 rue des Frères Montgolfier", dspID: "1"),
        directorySite("beauchamp", "Beauchamp", "Beauchamp", address: "53–55 chaussée Jules César", dspID: "4"),

        directorySite("boissy-saint-leger", "Boissy-Saint-Léger", "Boissy-Saint-Léger", address: "31 rue des Sablons", dspID: "21"),
        directorySite("limeil-brevannes", "Limeil-Brévannes", "Limeil-Brévannes", address: "2 allée Guy Boniface", dspID: "21"),
        directorySite("saint-maur", "Saint-Maur", "Saint-Maur-des-Fossés", address: "4 boulevard Maurice-Berteaux", dspID: "45"),
        directorySite("creteil", "Créteil", "Créteil", address: "6 avenue du Maréchal-Foch", dspID: "46"),
        directorySite("thiais", "Thiais", "Thiais", address: "12 rue du Bas Marin", dspID: "46"),
        directorySite("ivry", "Ivry", "Ivry-sur-Seine", address: "36 rue Pierre et Marie Curie", dspID: "47"),
        directorySite("vitry", "Vitry", "Vitry-sur-Seine", address: "149 bis boulevard de Stalingrad", dspID: "47"),
        directorySite("villeneuve-le-roi", "Villeneuve-le-Roi", "Villeneuve-le-Roi", address: "Rue des Vœux Saint-Georges", dspID: "47"),

        directorySite("asnieres", "Asnières-sur-Seine", "Asnières-sur-Seine", address: "19 avenue Gabriel-Péri", dspID: "42"),
        directorySite("bagneux-chatillon", "Bagneux–Châtillon", "Châtillon", address: "3 avenue Jean-Jaurès", dspID: "40"),
        directorySite("fontenay", "Fontenay-aux-Roses", "Fontenay-aux-Roses", address: "3 avenue de la Division-Leclerc", dspID: "40"),
        directorySite("charlebourg", "Charlebourg", "La Garenne-Colombes", address: "41 boulevard National", dspID: "41"),
        directorySite("nanterre", "Nanterre–Kléber", "Nanterre", address: "31 rue Kléber", dspID: "41"),
        directorySite("les-guilleraies", "Nanterre–Les Guilleraies", "Nanterre", address: "40–42 avenue des Guilleraies", dspID: "41"),
        directorySite("malakoff", "Malakoff", "Malakoff", address: "120 avenue du 12-Février-1934", dspID: "48"),

        directorySite("neuilly-plaisance", "Neuilly-Plaisance", "Neuilly-Plaisance", address: "32 boulevard Gallieni", dspID: "45"),
        directorySite("freres-lumiere", "Frères Lumière", "Neuilly-sur-Marne", address: "41–47 rue des Frères-Lumière", dspID: "45"),
        directorySite("pleyel", "Saint-Denis–Pleyel", "Saint-Denis", address: "36 rue des Renouillères", dspID: "42"),
        directorySite("coubron", "Coubron", "Coubron", address: "29 avenue Corot", dspID: "9"),
        directorySite("flandre", "Flandre", "Pantin", address: "168 avenue Jean-Jaurès", dspID: "44"),
        directorySite("les-pavillons", "Les Pavillons", "Les Pavillons-sous-Bois", address: "134 avenue de Rome", dspID: "44"),
        directorySite("tremblay-en-france", "Tremblay-en-France", "Tremblay-en-France", address: "29 rue du Sausset", dspID: "7"),
        directorySite("villepinte", "Villepinte", "Villepinte", address: "241 chemin du Loup · 255 boulevard Ballanger", dspID: "7"),
        directorySite("aubervilliers", "Aubervilliers", "Aubervilliers", address: "26 rue de la Haie-Coq", dspID: "43"),
        directorySite("saint-denis-gonesse", "Saint-Denis–Gonesse", "Saint-Denis", address: "39–41 avenue Lénine", dspID: "43"),
        directorySite("les-lilas", "Les Lilas", "Les Lilas", address: "25 rue Floréal", dspID: "49"),

        directorySite("wissous", "Wissous", "Wissous", address: "ZI de Villemilan · 15 avenue Ampère", dspID: "37"),
        directorySite("avrainville", "Avrainville", "Avrainville", address: "1 rue Camille-Flammarion", dspID: "25"),
        directorySite("bretigny-sur-orge", "Brétigny-sur-Orge", "Brétigny-sur-Orge", address: "1 rue des Cochets · ZI des Cochets", dspID: "25"),
        directorySite("montlhery", "Montlhéry", "Montlhéry", address: "123 rue Paul-Fort", dspID: "25"),
        directorySite("sainte-genevieve-des-bois", "Sainte-Geneviève-des-Bois", "Sainte-Geneviève-des-Bois", address: "ZAC de la Croix-Blanche · 1 avenue de la Résistance", dspID: "25"),
        directorySite("bondoufle", "Bondoufle", "Bondoufle", address: "5 rue du Canal-Prolongée", dspID: "23"),
        directorySite("corbeil-essonnes", "Corbeil-Essonnes", "Corbeil-Essonnes", address: "26 rue Émile-Zola", dspID: "23"),
        directorySite("ormoy", "Ormoy", "Ormoy", address: "110 avenue des Roissy-Hauts", dspID: "31"),
        directorySite("etampes", "Étampes", "Étampes", address: "12–14 rue des Épinants · ZAC du Bois Bourdon", dspID: "24"),
        directorySite("massy", "Massy", "Massy", address: "ZAC du Pérou · avenue du Maréchal-Leclerc", dspID: "36"),
        directorySite("morangis", "Morangis", "Morangis", address: "10 rue Gustave-Eiffel", dspID: "36"),
        directorySite("buc", "Buc", "Buc", address: "41 avenue Roland-Garros", dspID: "26"),
        directorySite("marcoussis", "Marcoussis", "Marcoussis", address: "ZI La Fontaine de Jouvence · 5 rue Angiboust", dspID: "26"),
        directorySite("saclay-razel-bec", "Saclay–Razel-Bec", "Saclay", address: "3 rue René-Razel", dspID: "26"),
        directorySite("athis-mons-seine-grand-orly", "Athis-Mons", "Athis-Mons", address: "172 avenue François-Mitterrand", dspID: nil),

        directorySite("montesson-paul-doumer", "Montesson", "Montesson", address: "156 avenue Paul-Doumer", dspID: "33"),
        directorySite("houdan", "Houdan", "Houdan", address: "6 route de Bu · ZAC de la Prévôté", dspID: "30"),
        directorySite("mere", "Méré", "Méré", address: "14 chemin de la Gare", dspID: "30"),
        directorySite("rambouillet-ampere", "Rambouillet–Ampère", "Rambouillet", address: "3 rue Ampère", dspID: "30"),
        directorySite("saint-arnoult-rue-remond", "Saint-Arnoult-en-Yvelines", "Saint-Arnoult-en-Yvelines", address: "63 rue du Docteur-Rémond", dspID: "30"),
        directorySite("saint-arnoult-en-yvelines", "Saint-Arnoult-en-Yvelines", "Saint-Arnoult-en-Yvelines", address: "17 rue des Corroyés · ZI des Corroyés", dspID: "24"),
        directorySite("conflans-sainte-honorine", "Conflans-Sainte-Honorine", "Conflans-Sainte-Honorine", address: "1 rue de l’Hautil · ZA des Boutries", dspID: "2"),
        directorySite("plaisir-les-gatines", "Plaisir–Les Gâtines", "Plaisir", address: "Allée Maurice-Mallet", dspID: "28"),
        directorySite("versailles-mortemets", "Versailles–Mortemets", "Versailles", address: "Allée des Mortemets", dspID: "28"),
        directorySite("bonnieres-sur-seine", "Bonnières-sur-Seine", "Bonnières-sur-Seine", address: "1 chemin du Halage", dspID: "35"),
        directorySite("epone", "Épône", "Épône", address: "2 avenue de la Couronne-des-Prés", dspID: "35"),
        directorySite("mantes-la-jolie", "Mantes-la-Jolie", "Mantes-la-Jolie", address: "2–4 impasse Sainte-Claire-Deville", dspID: "35"),
        directorySite("carrieres-sous-poissy", "Carrières-sous-Poissy", "Carrières-sous-Poissy", address: "18 rue de la Senette · Le Grand Clos", dspID: "34"),
        directorySite("ecquevilly", "Ecquevilly", "Ecquevilly", address: "4 rue de la Chamoiserie", dspID: "34"),
        directorySite("verneuil-sur-seine", "Verneuil-sur-Seine", "Verneuil-sur-Seine", address: "Chemin du Rouillard · ZAE du Rouillard", dspID: "34"),
        directorySite("montesson-gabriel-peri", "Montesson", "Montesson", address: "52 avenue Gabriel-Péri", dspID: "33"),
        directorySite("trappes-les-bruyeres", "Trappes–Les Bruyères", "Trappes", address: "9 avenue Jean-Pierre-Timbaud · ZAI des Bruyères", dspID: "29"),
        directorySite("trappes-la-rigole", "Trappes–La Rigole", "Trappes", address: "Rue Denis-Papin", dspID: "29"),
        directorySite("velizy", "Vélizy", "Vélizy-Villacoublay", address: "Rue du Général-Valérie-André", dspID: "27"),
        directorySite("plaisir-jacques-monod", "Plaisir", "Plaisir", address: "Rue Jacques-Monod", dspID: "38"),
        directorySite("rosny-sur-seine", "Rosny", "Rosny-sur-Seine", address: "Rue Gustave-Eiffel", dspID: "38"),

        directorySite("couilly-pont-aux-dames", "Couilly-Pont-aux-Dames", "Couilly-Pont-aux-Dames", address: "240 chemin de Martigny", dspID: "12"),
        directorySite("coulommiers", "Coulommiers", "Coulommiers", address: "24 boulevard de la Marne · ZI de Coulommiers", dspID: "12"),
        directorySite("la-ferte-gaucher", "La Ferté-Gaucher", "La Ferté-Gaucher", address: "Lieu-dit Le Petit Taillis", dspID: "12"),
        directorySite("la-ferte-sous-jouarre", "La Ferté-sous-Jouarre", "La Ferté-sous-Jouarre", address: "73 rue Pierre-Marx", dspID: "12"),
        directorySite("rebais", "Rebais", "Rebais", address: "4 rue du Pré-Ancel · ZA du Pré-Ancel", dspID: "12"),
        directorySite("le-mesnil-amelot", "Le Mesnil-Amelot", "Le Mesnil-Amelot", address: "34 rue de Guivry", dspID: "39"),
        directorySite("saint-fargeau-fontainebleau", "Saint-Fargeau-Ponthierry", "Saint-Fargeau-Ponthierry", address: "Rue du Luxembourg · ZAC de l’Europe", dspID: "16"),
        directorySite("vulaines-sur-seine", "Vulaines-sur-Seine", "Vulaines-sur-Seine", address: "12 rue du Petit-Rocher", dspID: "16"),
        directorySite("saint-fargeau-ponthierry", "Saint-Fargeau-Ponthierry", "Saint-Fargeau-Ponthierry", address: "Rue du Luxembourg", dspID: "18"),
        directorySite("vaux-le-penil", "Vaux-le-Pénil", "Vaux-le-Pénil", address: "400 rue des Trois-Tilleuls", dspID: "18"),
        directorySite("bussy", "Bussy-Saint-Martin", "Bussy-Saint-Martin", address: "ZAI de Torcy · rue des Épinettes", dspID: "9"),
        directorySite("la-trentaine-1", "Chelles–La Trentaine 1–2", "Chelles", address: "Avenue de la Trentaine", dspID: "9"),
        directorySite("chelles-nast", "Chelles–Nast", "Chelles", address: "75 rue Gustave-Nast", dspID: "9"),
        directorySite("pontault-combault", "Pontault-Combault", "Pontault-Combault", address: "Rue de Bruxelles", dspID: "9"),
        directorySite("bailly-romainvilliers", "Bailly-Romainvilliers", "Bailly-Romainvilliers", address: "1 rue Saint-Jacques", dspID: "10"),
        directorySite("lagny", "Lagny-sur-Marne", "Lagny-sur-Marne", address: "21–25 rue Jacquard", dspID: "10"),
        directorySite("pontault-combault-marne-et-seine", "Pontault-Combault", "Pontault-Combault", address: "34 route de Paris", dspID: "21"),
        directorySite("lizy-sur-ourcq", "Lizy-sur-Ourcq", "Lizy-sur-Ourcq", address: "2 route d’Echampeu", dspID: "11"),
        directorySite("brie-comte-robert", "Brie-Comte-Robert", "Brie-Comte-Robert", address: "CD 50 · 25 Grande Rue de Villemeneux", dspID: "13"),
        directorySite("gretz-armainvilliers", "Gretz-Armainvilliers", "Gretz-Armainvilliers", address: "47 rue Ampère · ZI", dspID: "13"),
        directorySite("guignes", "Guignes", "Guignes", address: "ZA rue du Bois-Boulay", dspID: "13"),
        directorySite("rozay-en-brie", "Rozay-en-Brie", "Rozay-en-Brie", address: "5 boulevard Thiers", dspID: "13"),
        directorySite("donnemarie-dontilly", "Donnemarie-Dontilly", "Donnemarie-Dontilly", address: "Rue du Montpensier", dspID: "14"),
        directorySite("montereau-fault-yonne", "Montereau-Fault-Yonne", "Montereau-Fault-Yonne", address: "6–9 rue du Pharle", dspID: "15"),
        directorySite("nangis", "Nangis", "Nangis", address: "1 rue René-Cassin · ZI", dspID: "14"),
        directorySite("provins", "Provins", "Provins", address: "2 rue Georges-Dromigny", dspID: "14"),
        directorySite("villiers-saint-georges", "Villiers-Saint-Georges", "Villiers-Saint-Georges", address: "Zone industrielle", dspID: "14"),
        directorySite("dammartin-en-goele", "Dammartin-en-Goële", "Dammartin-en-Goële", address: "3 rue Clément-Ader", dspID: "8"),
        directorySite("mitry-mory", "Mitry-Mory", "Mitry-Mory", address: "100 rue des Frères-Lumière", dspID: "8"),
        directorySite("saint-soupplets", "Saint-Soupplets", "Saint-Soupplets", address: "1 rue de la Clochette", dspID: "8"),
        directorySite("cesson", "Cesson", "Cesson", address: "Rue de la Coulée-Verte", dspID: "19"),
        directorySite("combs-la-ville", "Combs-la-Ville", "Combs-la-Ville", address: "14 rue Jean-Rostand · ZA du Bois de l’Ormeau", dspID: "19"),
        directorySite("lieusaint", "Lieusaint", "Lieusaint", address: "Avenue René-Cassin", dspID: "19"),
        directorySite("nemours", "Nemours", "Nemours", address: "12 avenue John-Fitzgerald-Kennedy", dspID: "17")
    ]

    private static func directorySite(
        _ id: String,
        _ name: String,
        _ locality: String,
        address: String,
        dspID: String?
    ) -> DepotLineRosterSite {
        let mappedDSP = dspID.map { "DSP \($0)" }
        let status = mappedDSP.map { "Répertoire public · réseau \($0) · exploitant à vérifier" }
            ?? "Répertoire public · réseau actuel à vérifier"
        let evidenceNote: String
        let availability: DepotSiteAvailability
        if let mappedDSP {
            availability = .operational
            evidenceNote = "Site et réseau recensés dans le répertoire public des COB, dont la page était actualisée le 29 septembre 2026. Le réseau est rapproché à \(mappedDSP) grâce au référentiel officiel IDFM des lignes. Le site est consultable et jouable à partir du contrat correspondant ; ses lignes sont celles du lot, avec l’affectation à ce COB indiquée comme candidate tant qu’une source directe ne répartit pas les lignes entre centres."
        } else {
            availability = .currentStatusUnverified
            evidenceNote = "Site listé dans un répertoire public des COB, dont la page était actualisée le 29 septembre 2026. Le réseau historique indiqué par cette liste n’a pas de correspondance unique avec un contrat IDFM actif ; le site reste consultable sans lignes ou carrière inventées."
        }
        return DepotLineRosterSite(
            id: id,
            name: name,
            locality: locality,
            status: status,
            availability: availability,
            evidenceNote: evidenceNote,
            sourceURL: publicRegionalDepotDirectoryURL,
            documentedAddress: "\(address), \(locality)",
            evidenceTitle: publicRegionalDepotDirectoryTitle,
            idfmBusContractID: dspID
        )
    }

    private static func contractSite(
        _ id: String,
        _ name: String,
        _ locality: String,
        dsp: String,
        operatorName: String,
        serviceFrom: String?,
        sourceTitle: String,
        sourceURL: URL,
        isPlanned: Bool = false
    ) -> DepotLineRosterSite {
        let status = isPlanned
            ? "Site annoncé pour \(dsp) · \(operatorName)"
            : "COB nommé pour \(dsp) · \(operatorName)"
        let timing = serviceFrom.map { " · mise en service du lot annoncée le \($0)" } ?? ""
        let note = isPlanned
            ? "IDFM cite ce site dans le cadre de \(dsp). Il reste annoncé comme futur/projet et n’est pas traité comme un dépôt opérationnel. Aucune ligne ne lui est affectée dans le jeu."
            : "IDFM nomme ce COB dans le périmètre de \(dsp) pour \(operatorName)\(timing). Cette source confirme le centre dans le lot, mais ne répartit pas les lignes du contrat entre les différents COB."
        return DepotLineRosterSite(
            id: id,
            name: name,
            locality: locality,
            status: status,
            availability: isPlanned ? .planned : .operational,
            evidenceNote: note,
            sourceURL: sourceURL,
            evidenceTitle: sourceTitle,
            idfmBusContractID: String(dsp.dropFirst(4))
        )
    }

    private static let currentRATPDepotIDs: Set<String> = [
        "asnieres", "aubervilliers", "belliard", "charlebourg", "corentin", "creteil",
        "croix-nivert", "flandre", "fontenay", "ivry", "lagny", "lebrun", "les-lilas",
        "les-pavillons", "malakoff", "massy", "nanterre", "pleyel", "point-du-jour",
        "saint-denis", "saint-maur", "thiais", "vitry", "neuilly-plaisance"
    ]

    /// Physical sites and site candidates that can be browsed from the map selector.
    /// Unclassified labels (operators, networks or historical names) stay in the audit register.
    static var selectableSites: [DepotLineRosterSite] {
        var result: [DepotLineRosterSite] = []
        var resultIndexByID: [String: Int] = [:]
        for candidate in sites + currentContractSites + publicRegionalDepotDirectorySites {
            if let index = resultIndexByID[candidate.id] {
                result[index] = mergeSiteMetadata(preferred: result[index], supplemental: candidate)
            } else {
                resultIndexByID[candidate.id] = result.count
                result.append(candidate)
            }
        }
        var knownIDs = Set(resultIndexByID.keys)

        for entry in RegionalDepotRegistry.browseableEntries {
            let siteID = entry.linkedDepotID ?? (entry.id == "bussy-annex-2022" ? "bussy" : entry.id)
            guard knownIDs.insert(siteID).inserted else { continue }
            let isCurrentRATPDepot = currentRATPDepotIDs.contains(siteID)

            let locality = entry.documentedAddress?
                .split(separator: ",")
                .last
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                ?? "Localité à vérifier"
            let status = isCurrentRATPDepot
                ? "Centre bus cité dans le programme RATP Bus2025"
                : entry.kind == .datedAddressReference
                    ? "Adresse publiée par IDFM · activité actuelle à vérifier"
                    : "Nom de site cité · existence et activité à vérifier"
            let evidenceNote = isCurrentRATPDepot
                ? "La RATP cite ce centre dans son programme Bus2025 actualisé en juin 2026. Cette preuve documente le site, mais ne répartit pas les lignes de bus entre les centres."
                : entry.kind.explanation

            result.append(DepotLineRosterSite(
                id: siteID,
                name: entry.originalLabel,
                locality: locality,
                status: status,
                availability: isCurrentRATPDepot ? .operational : .currentStatusUnverified,
                evidenceNote: evidenceNote,
                sourceURL: isCurrentRATPDepot ? ratpBus2025URL : entry.evidenceURL,
                documentedAddress: entry.documentedAddress,
                evidenceTitle: isCurrentRATPDepot ? "RATP · programme Bus2025 · centres bus" : entry.evidenceTitle
            ))
        }

        return result.sorted {
            if $0.availability != $1.availability {
                return availabilityOrder($0.availability) < availabilityOrder($1.availability)
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func mergeSiteMetadata(
        preferred: DepotLineRosterSite,
        supplemental: DepotLineRosterSite
    ) -> DepotLineRosterSite {
        let preferredPriority = availabilityPriority(preferred.availability)
        let supplementalPriority = availabilityPriority(supplemental.availability)
        let currentSite = supplementalPriority > preferredPriority ? supplemental : preferred
        let evidenceNote: String
        if preferred.evidenceNote == supplemental.evidenceNote || supplemental.evidenceNote.isEmpty {
            evidenceNote = preferred.evidenceNote
        } else if preferred.evidenceNote.isEmpty {
            evidenceNote = supplemental.evidenceNote
        } else {
            let supplementalTitle = supplemental.evidenceTitle.map { "\($0) · " } ?? ""
            evidenceNote = "\(preferred.evidenceNote)\n\n\(supplementalTitle)\(supplemental.evidenceNote)"
        }
        let additionalEvidenceTitle: String?
        let additionalEvidenceURL: URL?
        if preferred.additionalEvidenceURL != nil {
            additionalEvidenceTitle = preferred.additionalEvidenceTitle
            additionalEvidenceURL = preferred.additionalEvidenceURL
        } else if supplemental.sourceURL != nil, supplemental.sourceURL != preferred.sourceURL {
            additionalEvidenceTitle = supplemental.evidenceTitle
            additionalEvidenceURL = supplemental.sourceURL
        } else {
            additionalEvidenceTitle = supplemental.additionalEvidenceTitle
            additionalEvidenceURL = supplemental.additionalEvidenceURL
        }
        var facilityObservations = preferred.facilityObservations
        for observation in supplemental.facilityObservations where !facilityObservations.contains(where: { $0.id == observation.id }) {
            facilityObservations.append(observation)
        }

        return DepotLineRosterSite(
            id: preferred.id,
            name: preferred.name,
            locality: preferred.locality,
            status: currentSite.status,
            availability: currentSite.availability,
            evidenceNote: evidenceNote,
            sourceURL: preferred.sourceURL ?? supplemental.sourceURL,
            documentedAddress: preferred.documentedAddress ?? supplemental.documentedAddress,
            evidenceTitle: preferred.evidenceTitle ?? supplemental.evidenceTitle,
            idfmBusContractID: preferred.idfmBusContractID ?? supplemental.idfmBusContractID,
            additionalEvidenceTitle: additionalEvidenceTitle,
            additionalEvidenceURL: additionalEvidenceURL,
            fleetObservation: preferred.fleetObservation ?? supplemental.fleetObservation,
            facilityObservations: facilityObservations
        )
    }

    private static func availabilityPriority(_ availability: DepotSiteAvailability) -> Int {
        switch availability {
        case .operational: 2
        case .currentStatusUnverified: 1
        case .planned: 0
        }
    }

    private static func availabilityOrder(_ availability: DepotSiteAvailability) -> Int {
        switch availability {
        case .operational: 0
        case .planned: 2
        case .currentStatusUnverified: 1
        }
    }

    private static let oldRatpLineCenterEvidenceFrom = 20250101
    private static let oldRatpLineCenterEvidenceThrough = 20251031
    private static let dsp45Start = 20251101
    private static let dsp45End = 20311031
    private static let dsp45LineIDs: Set<String> = [
        "101", "106", "107", "108", "110", "111", "112", "113", "114", "116", "118",
        "120", "124", "127", "201", "203", "210", "214", "221", "303", "306", "520",
        "N11", "N16", "N32", "N33", "N34", "N35", "N71"
    ]
    private static let oldRatpBordsDeMarneLineIDs: Set<String> = [
        "113", "114", "116", "118", "120", "124", "127", "203", "210", "214", "221", "303", "520", "N34"
    ]
    private static let futureBordsDeMarneProjectURL = URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne")!
    private static let futureCobUpdateURL = URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/actualites/photo-de-la-couverture-de-la-lettre-dinfo")!
    private static let futureCobFAQURL = URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/questions/materiel-roulant-cob")!
    private static let futureBBDMPrinciplesURL = URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/principes-amenagement-fonctionnement-bbdm")!
    private static let futureBBDMConsultationURL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/26367fc3-7fd7-4c5e-9c1c-6e2393bd9c3f_2023.10.12%2B-%2BDossier%2Bde%2Bconcertation%2BMECDU%2BBBM.pdf")!
    private static let futureCobNoticeURL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/Z3gGG5bqstJ99BnH_B_Notice_explicative.pdf")!
    private static let futureBordsDeMarneSchemeURL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/72537622-01f3-44cc-ae73-4f1771f19470_BBM_SDP_VFF.pdf")!
    private static let neuillyDepotURL = URL(string: "https://tc-infos.fr/exploitant/2975/depot/4663")!
    private static let bordsDeMarneFireReportURL = URL(string: "https://www.leparisien.fr/info-paris-ile-de-france-oise/transports/quatre-bus-prennent-feu-en-moins-de-deux-mois-la-ratp-depose-plainte-contre-x-aucune-piste-nest-ecartee-16-12-2025-YOOGWRR5HZCT5MZDUYW2MCS3UE.php")!
    private static let currentTCInfosLineURLs: [String: URL] = [
        "101": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33111")!,
        "106": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33112")!,
        "113": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33118")!,
        "114": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33119")!,
        "116": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33120")!,
        "118": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33121")!,
        "120": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33122")!,
        "124": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33123")!,
        "127": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33124")!,
        "203": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33126")!,
        "214": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33128")!,
        "221": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33129")!,
        "303": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33130")!,
        "N11": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33133")!,
        "N32": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33135")!,
        "N33": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33136")!,
        "N34": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33137")!,
        "N35": URL(string: "https://tc-infos.fr/reseau/1452/ligne/33138")!
    ]

    private static func sourceDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = GTFSServiceDate.parisTimeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private static func neuillyPlaisanceLine(
        _ line: String,
        note: String,
        documents: [DepotLineDocumentLink] = [],
        additionalClaims: [DepotLineRosterClaim] = []
    ) -> DepotLineRosterRow {
        row(line, category: "Régulière", sites: ["neuilly-plaisance"], center: "NEUILLY-PLAISANCE", status: .observedPool,
            source: "TC Infos · matériel du groupe de lignes au COB Neuilly-Plaisance",
            url: currentTCInfosLineURLs[line] ?? neuillyDepotURL,
            secondarySource: "Wikipédia · variantes et fiches de ligne, source secondaire",
            secondaryURL: wikipediaURL,
            note: note,
            documents: documents,
            claims: [DepotLineRosterClaim(
                kind: .fleetObservation,
                siteID: "neuilly-plaisance",
                centerLabel: "NEUILLY-PLAISANCE",
                sourceTitle: "TC Infos · matériel du groupe de lignes au COB Neuilly-Plaisance",
                sourceURL: currentTCInfosLineURLs[line] ?? neuillyDepotURL,
                sourceDateLabel: "Observations de parc depuis novembre 2025",
                validFromKey: dsp45Start,
                validThroughKey: nil,
                note: "Observation communautaire de véhicules dans un parc partagé entre plusieurs lignes ; elle ne confirme pas une affectation exclusive ni la répartition de toutes les courses."
            )] + (oldRatpBordsDeMarneLineIDs.contains(line) ? historicalBordsDeMarneCenterClaims() : []) + additionalClaims)
    }

    private static func observedPoolNeuillyPlaisanceLine(_ line: String, note: String, documents: [DepotLineDocumentLink] = []) -> DepotLineRosterRow {
        let sourceURL = currentTCInfosLineURLs[line] ?? neuillyDepotURL
        return row(line, category: "Régulière", sites: ["neuilly-plaisance"], center: "NEUILLY-PLAISANCE", status: .observedPool,
            source: "TC Infos · parc partagé observé après transfert DSP45",
            url: sourceURL,
            secondarySource: "Wikipédia · variantes et fiches de ligne, source secondaire",
            secondaryURL: wikipediaURL,
            note: note,
            documents: documents,
            claims: [DepotLineRosterClaim(
                kind: .fleetObservation,
                siteID: "neuilly-plaisance",
                centerLabel: "NEUILLY-PLAISANCE",
                sourceTitle: "TC Infos · matériel du groupe de lignes au COB Neuilly-Plaisance",
                sourceURL: sourceURL,
                sourceDateLabel: "Observations de parc depuis novembre 2025",
                validFromKey: dsp45Start,
                validThroughKey: nil,
                note: "La même flotte de groupe est reproduite sur plusieurs fiches de lignes ; elle n’établit pas une affectation exclusive par ligne."
            )] + (oldRatpBordsDeMarneLineIDs.contains(line) ? historicalBordsDeMarneCenterClaims() : []))
    }

    private static func secondaryNeuillyPlaisanceLine(
        _ line: String,
        note: String,
        documents: [DepotLineDocumentLink] = [],
        additionalClaims: [DepotLineRosterClaim] = []
    ) -> DepotLineRosterRow {
        row(line, category: "Régulière", sites: ["neuilly-plaisance"], center: "NEUILLY-PLAISANCE", status: .candidate,
            source: "Wikipédia · affectation historique à corroborer",
            url: wikipediaURL,
            note: note,
            documents: documents,
            claims: [DepotLineRosterClaim(
                kind: .supportingSource,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "Wikipédia · affectation historique à corroborer",
                sourceURL: wikipediaURL,
                sourceDateLabel: nil,
                validFromKey: nil,
                validThroughKey: nil,
                note: "Source secondaire ; période de validité et présence après transfert non établies."
            )] + additionalClaims + (oldRatpBordsDeMarneLineIDs.contains(line) ? historicalBordsDeMarneCenterClaims() : []))
    }

    private static func historicalBordsDeMarneCenterClaims() -> [DepotLineRosterClaim] {
        [
            DepotLineRosterClaim(
                kind: .contractCenter,
                siteID: "neuilly-plaisance",
                centerLabel: "BORDS DE MARNE",
                sourceTitle: "IDFM · annexe ligne–centre du contrat IDFM–RATP 2025–2026",
                sourceURL: contractEvidenceURL,
                sourceDateLabel: "Tableau ligne–centre du contrat IDFM–RATP 2025–2026",
                validFromKey: oldRatpLineCenterEvidenceFrom,
                validThroughKey: oldRatpLineCenterEvidenceThrough,
                note: "Le tableau ligne–centre nomme le centre pour cette ligne, mais ne donne pas de date de validité individuelle. La borne prudente est la veille du transfert DSP45, le 31 octobre 2025. La FAQ IDFM situe le centre historique des Bords de Marne à Neuilly-Plaisance ; cette source ne confirme pas l’affectation après le transfert."
            ),
            DepotLineRosterClaim(
                kind: .supportingSource,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · centre bus historique des Bords de Marne à Neuilly-Plaisance",
                sourceURL: historicalBordsDeMarneCenterURL,
                sourceDate: sourceDate(year: 2023, month: 6, day: 28),
                sourceDateLabel: "FAQ publiée le 28 juin 2023",
                validFromKey: nil,
                validThroughKey: nil,
                note: "Cette source localise le centre physique historique ; elle ne confirme pas l’affectation de chaque ligne après le changement de DSP."
            )
        ]
    }

    private static func row(
        _ line: String,
        category: String,
        sites: [String] = [],
        center: String? = nil,
        status: DepotLineEvidenceStatus,
        source: String = "Contrat bus IDFM 2025–2026",
        url: URL? = contractEvidenceURL,
        secondarySource: String? = nil,
        secondaryURL: URL? = nil,
        note: String,
        documents: [DepotLineDocumentLink] = [],
        sourceDate: Date? = nil,
        sourceDateLabel: String? = nil,
        validFromKey: Int? = nil,
        validThroughKey: Int? = nil,
        claims: [DepotLineRosterClaim]? = nil
    ) -> DepotLineRosterRow {
        let rowClaims: [DepotLineRosterClaim]
        if let claims {
            var explicitClaims = claims
            if let secondarySource,
               !claims.contains(where: { $0.sourceURL == secondaryURL }) {
                explicitClaims.append(DepotLineRosterClaim(
                    kind: .supportingSource,
                    siteID: nil,
                    centerLabel: nil,
                    sourceTitle: secondarySource,
                    sourceURL: secondaryURL,
                    sourceDateLabel: nil,
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: nil
                ))
            }
            rowClaims = explicitClaims
        } else {
            let kind = claimKind(for: status)
            var generated = [DepotLineRosterClaim(
                kind: kind,
                siteID: sites.count == 1 ? sites[0] : nil,
                centerLabel: center,
                sourceTitle: source,
                sourceURL: url,
                sourceDate: sourceDate,
                sourceDateLabel: sourceDateLabel,
                validFromKey: validFromKey,
                validThroughKey: validThroughKey,
                note: validFromKey != nil && validThroughKey == nil
                    ? "La source utilisée ne précise pas la date de fin de validité de ce rattachement."
                    : nil
            )]
            if let secondarySource {
                generated.append(DepotLineRosterClaim(
                    kind: .supportingSource,
                    siteID: nil,
                    centerLabel: nil,
                    sourceTitle: secondarySource,
                    sourceURL: secondaryURL,
                    sourceDateLabel: nil,
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: nil
                ))
            }
            rowClaims = generated
        }

        var claimsWithNetworkScope = rowClaims
        if let serviceSummary = reorganizationServiceSummaries[line],
           !rowClaims.contains(where: { $0.kind == .announcedService && $0.validFromKey == 20261101 }) {
            claimsWithNetworkScope.append(DepotLineRosterClaim(
                kind: .announcedService,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · évolution de l’offre de la ligne \(line) au 1er novembre 2026",
                sourceURL: reorganizationURL,
                sourceDate: Self.sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: "\(serviceSummary) Cette annonce décrit le service à compter du 1er novembre ; elle ne désigne aucun COB et ne remplace pas une grille horaire post-réorganisation."
            ))
        }
        if dsp45LineIDs.contains(line) {
            claimsWithNetworkScope.append(DepotLineRosterClaim(
                kind: .networkScopeOnly,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · périmètre DSP 45 après transfert à RATP Cap",
                sourceURL: awardEvidenceURL,
                sourceDate: Self.sourceDate(year: 2024, month: 11, day: 6),
                sourceDateLabel: "Annonce IDFM du 6 novembre 2024",
                validFromKey: dsp45Start,
                validThroughKey: dsp45End,
                note: "Cette affirmation maintient la ligne dans le périmètre de la DSP 45 jusqu’au 31 octobre 2031 ; elle ne désigne aucun COB."
            ))
        }

        return DepotLineRosterRow(
            line: line,
            category: category,
            siteIDs: sites,
            evidenceStatus: status,
            note: note,
            publicDocuments: documents,
            claims: claimsWithNetworkScope
        )
    }

    private static func claimKind(for status: DepotLineEvidenceStatus) -> DepotLineRosterClaimKind {
        switch status {
        case .confirmed: .contractCenter
        case .shared: .sharedContractCenters
        case .partial: .partialStorage
        case .observedPool: .fleetObservation
        case .candidate: .candidateAssignment
        case .unresolved: .networkScopeOnly
        case .conflict: .conflictingClaim
        case .planned: .announcedService
        }
    }

    private static let saintMaurRouteNotes: [String: String] = [
        "101": "Joinville-le-Pont RER ↔ Champigny–Camping International. Wikipédia signale un service estival en soirée jusqu’à 00 h 30. IDFM annonce des ajustements horaires ponctuels au 1er novembre 2026.",
        "106": "Joinville-le-Pont RER ↔ Villiers-sur-Marne–Le Plessis-Trévise RER, avec des courses de pointe partielles entre Joinville RER et Fourchette de Bry. IDFM annonce des ajustements horaires ponctuels au 1er novembre 2026.",
        "107": "École vétérinaire de Maisons-Alfort ↔ Saint-Maur–Créteil / Saint-Maur–La Pie. Après environ 19 h 40 et les dimanches/jours fériés, des courses sont limitées à École vétérinaire ↔ Saint-Maur–Créteil. À partir du 1er novembre 2026, IDFM annonce 15 min en pointe en semaine, 20–30 min le samedi et 30 min le dimanche.",
        "108": "Joinville-le-Pont RER ↔ Champigny–Jeanne Vacher. IDFM annonce des ajustements horaires ponctuels au 1er novembre 2026.",
        "110": "Joinville-le-Pont RER ↔ Villiers-sur-Marne RER. Les deux dernières courses quotidiennes au départ de Villiers terminent à Verdun. IDFM annonce des ajustements horaires ponctuels au 1er novembre 2026.",
        "111": "Paris–Terroirs de France ↔ Gare de Champigny–Saint-Maur / Place de l’Écluse, avec des courses partielles vers Saint-Maur–Corneilles, Charenton–Écoles et La Varenne–Chennevières, ainsi qu’un service scolaire. L’itinéraire indiqué par le plan n’est pas desservi le dimanche. À partir du 1er novembre 2026, IDFM annonce 8 min en pointe en semaine.",
        "112": "Château de Vincennes ↔ La Varenne–Chennevières RER. À partir de 22 h, des courses sont limitées à Château de Vincennes ↔ Place Rimini. IDFM annonce un renfort de fréquence au 1er novembre 2026.",
        "201": "Paris–Porte Dorée ↔ Champigny–Diderot–La Plage. IDFM annonce des ajustements horaires ponctuels au 1er novembre 2026.",
        "306": "Saint-Maur–Créteil ↔ Noisy-le-Grand–Mont d’Est. La variante du soir par 8 Mai 1945 et Lycée Georges Clemenceau est signalée par Wikipédia, mais ces arrêts ne figurent pas sur le plan IDFM de septembre 2025 ni dans les séquences des courses GTFS actives du 20 octobre 2026 ; elle reste à confirmer. IDFM indique que la ligne n’est pas modifiée le 1er novembre 2026."
    ]

    private static func confirmedSaintMaur(_ lines: [String]) -> [DepotLineRosterRow] {
        lines.map { line in
            var claims = [DepotLineRosterClaim(
                kind: .contractCenter,
                siteID: "saint-maur",
                centerLabel: "SAINT-MAUR",
                sourceTitle: "Contrat bus IDFM 2025–2026",
                sourceURL: contractEvidenceURL,
                sourceDateLabel: "Tableau ligne–centre du contrat IDFM–RATP 2025–2026",
                validFromKey: oldRatpLineCenterEvidenceFrom,
                validThroughKey: oldRatpLineCenterEvidenceThrough,
                note: "Le tableau établit le rattachement historique avant le transfert DSP45, sans désigner le COB de cette ligne sous le nouvel exploitant."
            )]

            if let sourceURL = currentTCInfosLineURLs[line] {
                claims.append(DepotLineRosterClaim(
                    kind: .fleetObservation,
                    siteID: "saint-maur",
                    centerLabel: "SAINT-MAUR-DES-FOSSÉS",
                    sourceTitle: "TC Infos · parc actuel de la ligne \(line) au dépôt de Saint-Maur",
                    sourceURL: sourceURL,
                    sourceDateLabel: "Les véhicules recensés indiquent une arrivée sur la ligne en novembre 2025; date d’actualisation du parc inconnue",
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: "TC Infos liste le même pool de 92 autobus GNV sur les lignes 101 et 106, dont des Heuliez GX 337 GNV et des Iveco Urbanway 12 GNV, avec RATP Cap Boucles de Marne et le dépôt Saint-Maur-des-Fossés. L’inventaire est une source secondaire sans date de mise à jour publiée; il ne prouve ni une affectation exclusive, ni toutes les courses, ni une validité continue."
                ))
            }

            let postTransferNote = currentTCInfosLineURLs[line] == nil
                ? " Faute de ventilation par COB publiée pour le nouvel exploitant, ce rattachement historique n’est pas établi à partir du 1er novembre 2025."
                : " TC Infos observe le même pool de 92 véhicules sur les lignes 101 et 106 à Saint-Maur; cette source secondaire ne répartit pas les courses et ne donne pas de date d’actualisation précise."

            return row(line, category: "Régulière", sites: ["saint-maur"], center: "SAINT-MAUR", status: .confirmed,
                secondarySource: "Wikipédia · terminus et variantes de la ligne \(line), source secondaire",
                secondaryURL: wikipediaURL,
                note: "\(saintMaurRouteNotes[line] ?? "Ligne du réseau Bords de Marne.") Le tableau ligne–centre de l’ancien contrat RATP indique Saint-Maur avant le transfert DSP45.\(postTransferNote)",
                documents: documentsByLine[line] ?? [],
                claims: claims)
        }
    }

    private static let documentsByLine: [String: [DepotLineDocumentLink]] = [
        "101": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 101", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T085240Z-8def6ccc-8dbc-4ad3-9243-b4d8073824ab.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 101", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260730T113913Z-d471c89b-19df-480c-b6a2-d346d028a8c9.pdf")!, validity: "17 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "106": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 106", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T085603Z-df1fe503-ca4e-4ae1-a22d-f652a47aca45.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 106", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260730T114038Z-37ba7208-7497-41b2-a2ef-8512dda52901.pdf")!, validity: "24 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "107": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 107", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T085636Z-69b39a41-2e5f-47b4-8df1-2dc77a59c5d4.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 107", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T093959Z-5c2c8178-6764-4da6-bee6-5e1b8eb2c745.pdf")!, validity: "24 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "108": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 108", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T085729Z-23559102-37a9-4484-83fa-fb6c83230c30.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 108", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T094059Z-8005910b-fff5-4bf9-b6d9-68c289d43ac0.pdf")!, validity: "17 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "110": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 110", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T085802Z-a783c298-92f9-4760-b386-52641ab83826.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 110", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T094210Z-6672caaf-801e-4bb5-995e-e60716b3ad06.pdf")!, validity: "17 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "111": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 111", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T085849Z-c7d42ed2-b646-4ec2-82bb-4aca1c79e7c1.pdf")!, validity: "Édition imprimée 08/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 111", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T095707Z-d70ed6f9-234a-4af0-8bc3-c7b449c77cfd.pdf")!, validity: "24 août–31 décembre 2026", note: "Le catalogue IDFM référence ce PDF direct ; son accès avait renvoyé une erreur 503 lors de l’audit précédent, à retester.")
        ],
        "112": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 112", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T085933Z-eeb37844-5783-4875-8687-147939be3ddd.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 112", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T095824Z-9687ca3e-60c6-46ce-ab4a-82557bdf095d.pdf")!, validity: "17 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "113": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 113", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090013Z-4510ab7e-f40c-45e9-821c-1ff5c812f592.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 113", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260908T122254Z-2ca59811-b570-4aaa-8511-60d3b513bfa5.pdf")!, validity: "24 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "114": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 114", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090039Z-bb5822e2-fadd-493b-9749-3dba742609cd.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 114", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T114902Z-ffbc0d53-45b8-4593-978e-813b17cdb157.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "116": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 116", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090115Z-76d5edf2-413a-4dae-a57c-d40449dd2abb.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Plan RATP de la ligne 116 · itinéraire actuel", type: "Plan", url: URL(string: "https://www.ratp.fr/informer/picts/plans/pdf/bus_banlieue/100/116.pdf")!, validity: "Plan RATP en vigueur depuis juin 2024", note: "Complément au plan IDFM importé ; le tracé actuel est Montreuil–Boissière–Acacia ↔ Champigny–Saint-Maur RER."),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 116", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T114954Z-20415638-2f31-48a0-b3ac-3de7daa287c1.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "118": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 118", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090151Z-007ee2fb-a92c-41bb-8ae8-e079c7ed2a35.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 118", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T115215Z-ca709488-8f93-433f-a192-bb02a93acb17.pdf")!, validity: "24 août–31 décembre 2026", note: nil)
        ],
        "120": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 120", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090356Z-24ad7400-6570-4e93-b536-30b1e6cdf77e.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 120", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T115633Z-261f8f09-337f-4fe3-9316-08241d937d46.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "124": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 124", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090531Z-bb1bd60b-7b4a-408c-a395-30e209396c2d.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 124", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T115858Z-262e6339-9a7e-49bb-9bef-1cf2d8f9d71a.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "127": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 127", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090600Z-9e02c309-b58c-43af-a28c-ef41cf57dd7b.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 127", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T120247Z-3b0fd457-85d8-4cf1-ba0b-bf24c6b8a2ac.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "201": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 201", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090628Z-191af08d-e751-4492-8900-697562011213.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 201", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260923T164040Z-06f76da0-0d59-4769-abe3-027bcf646021.pdf")!, validity: "17 août–31 décembre 2026", note: "IDFM annonce des évolutions de service au 1er novembre 2026 ; vérifier que cette fiche intègre les horaires après cette date.")
        ],
        "203": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 203", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090728Z-f5faf449-5bd8-4687-bf8a-c5810ff19313.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 203", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T120520Z-5b8308ff-fb5f-4a4c-95f4-8194dacb9171.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "210": [
            DepotLineDocumentLink(title: "Plan IDFM 210 · nouveau tracé", type: "Plan", url: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-operateurs/Z0Wq6apsk5v1smk3_THERMO_BOUCLE_DE_MARNE_210_08.26.pdf")!, validity: "Édition août 2026", note: "Nouveau tracé par Les Rigollots à partir du 1er novembre 2026."),
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 210", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090812Z-b97eeed8-d50b-4dea-ba9e-e71a67249a23.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 210", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T120559Z-68642148-98f3-41ed-bd12-1f12f03743db.pdf")!, validity: "17 août–31 décembre 2026", note: "Le plan IDFM 08/2026 annonce un nouveau tracé au 1er novembre ; vérifier l’application de cette fiche après la mise en service du tracé.")
        ],
        "214": [
            DepotLineDocumentLink(title: "Plan IDFM combiné 214/314", type: "Plan", url: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-operateurs/ORL14VYfG2K1HYNw_THERMO_BOUCLES-DE-MARNE-214-314_08.26.pdf")!, validity: "Édition août 2026", note: "Présente le tracé de la 214 et la création de la 314 au 1er novembre 2026."),
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 214", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090840Z-45a99174-853b-4461-96a3-d3b61ec9cf4f.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 214", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T120700Z-91244797-b36f-4b56-8121-1a392b819b04.pdf")!, validity: "17 août–31 décembre 2026", note: "Des courses vers la ZI des Chanoux sont transférées à la nouvelle 314 à partir du 1er novembre 2026 ; vérifier la grille après ce changement.")
        ],
        "221": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 221", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260818T070453Z-79901d8b-8930-4e8e-b930-b8d6554e763f.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 221", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260827T123018Z-2ca9bf4e-b5e6-476f-a430-5ec2525344cd.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "303": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 303", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260403T152754Z-e384d780-e26e-4bdb-a3e4-a6d68389a6d8.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 303", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20261012T171145Z-97287b3e-c064-4385-aef5-5c294c68a304.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "306": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 306", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T091038Z-23709e89-4d4c-423b-9ddf-aa1083527c5a.pdf")!, validity: "Édition imprimée 09/2025", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 306", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T121351Z-9b530976-eb80-45ca-9f58-a69af1e74cd1.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "520": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne 520", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T091110Z-53a1b0a5-d5fe-4c3e-a4b2-c1c3e759c105.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 520", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T121434Z-ac0c8e81-933c-403c-8dcd-f51df24b6496.pdf")!, validity: "17 août–31 décembre 2026", note: nil)
        ],
        "N11": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N11", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260824T103016Z-1932ea1e-0892-42cf-9c71-09db46e50d74.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N11", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260824T102957Z-23953f6e-d5ef-4c26-b569-0c747ec86377.pdf")!, validity: "1 septembre 2026–31 août 2028", note: nil)
        ],
        "N16": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N16", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260818T075824Z-48c047a2-f287-4538-ab38-affa038c27fe.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N16", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T125150Z-12ac88d6-e5d8-48de-baf3-0789b72cfdaa.pdf")!, validity: "Période exacte à consulter dans le PDF", note: "Le nom du lien dans le catalogue IDFM ne donne pas la période de validité ; lire le PDF avant usage.")
        ],
        "N31": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N31", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260801T172952Z-398259fa-d99d-4086-a204-21f9b8897ba3.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N31", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T122903Z-65386406-5e2d-43ee-b313-59009883e47a.pdf")!, validity: "à compter du 16 août 2026 au 18 juillet 2027", note: nil)
        ],
        "N32": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N32", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20251022T140413Z-c6d7355b-08b2-4722-be6a-3a78cc71cd02.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N32", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T131554Z-ffa8a463-5cad-4116-89b9-cf1929e4d42a.pdf")!, validity: "Période exacte à consulter dans le PDF", note: "Le nom du lien dans le catalogue IDFM ne donne pas la période de validité ; lire le PDF avant usage.")
        ],
        "N33": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N33", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260824T133300Z-067c8290-1ec1-40b1-b38a-ba4995c7e899.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N33", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260824T134559Z-0205836c-b0a2-4312-b68c-979580713f9e.pdf")!, validity: "Période exacte à consulter dans le PDF", note: "Le nom du lien dans le catalogue IDFM ne donne pas la période de validité ; lire le PDF avant usage.")
        ],
        "N34": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N34", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20251022T140713Z-863e0224-81d9-490a-987c-3493fc2089e6.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N34", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260814T141002Z-b803f652-4da5-4b94-a380-84e7dabe2158.pdf")!, validity: "Période exacte à consulter dans le PDF", note: "Le nom du lien dans le catalogue IDFM ne donne pas la période de validité ; lire le PDF avant usage.")
        ],
        "N35": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N35", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20251022T141104Z-3868ddcb-5855-47e0-b435-30e12411e752.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N35", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260527T060244Z-08ce2def-5ff0-447a-beda-85aae77b2737.pdf")!, validity: "Expirée le 12 juillet 2026", note: "Dernière grille officielle trouvée ; sa validité est échue au 12 juillet 2026.")
        ],
        "N71": [
            DepotLineDocumentLink(title: "Plan IDFM de la ligne N71", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260818T074948Z-d50b1db6-8795-47da-84a4-e8d5e747d623.pdf")!, validity: "Date d’édition à vérifier dans le PDF", note: nil),
            DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne N71", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260818T074533Z-aa4a429c-46fd-47fe-b12f-45e8469b54b9.pdf")!, validity: "Période exacte à consulter dans le PDF", note: "Le nom du lien dans le catalogue IDFM ne donne pas la période de validité ; lire le PDF avant usage.")
        ],
        "314": [
            DepotLineDocumentLink(title: "Plan IDFM combiné 214/314", type: "Plan", url: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-operateurs/ORL14VYfG2K1HYNw_THERMO_BOUCLES-DE-MARNE-214-314_08.26.pdf")!, validity: "Édition août 2026 · ligne active à partir du 1er novembre 2026", note: "Le plan montre le tracé, pas le COB d’affectation. Le catalogue IDFM exporté le 20 octobre ne publie pas de fiche horaire PDF directe pour 314.")
        ]
    ]

    static let rows: [DepotLineRosterRow] = confirmedSaintMaur(
        ["101", "106", "107", "108", "110", "111", "112", "201", "306"]
    ) + [
        row("113", category: "Régulière", sites: ["bussy", "neuilly-plaisance", "freres-lumiere"], center: "BORDS DE MARNE", status: .partial,
            source: "IDFM · remisage de bus de la ligne 113 à Frères-Lumière",
            url: sites.first(where: { $0.id == "freres-lumiere" })?.sourceURL,
            secondarySource: "TC Infos · matériel 113 au COB Neuilly-Plaisance",
            secondaryURL: currentTCInfosLineURLs["113"],
            note: "Nogent-sur-Marne RER ↔ Chelles (Mairie ou Terre-Ciel). Le service Terre-Ciel dépend des horaires d’ouverture du centre commercial. Le plan IDFM de septembre 2025 montre Pointe de Gournay sur le tracé, et le GTFS actif du 20 octobre 2026 contient des courses qui desservent cet arrêt, certaines avec Pointe de Gournay comme terminus. Le GTFS confirme des courses datées, pas une fréquence garantie au-delà de sa validité. Le pool de Citelis 12 à Neuilly-Plaisance et d’articulés à Frères-Lumière est partagé ; aucun site n’est traité comme exploitant de toutes les courses. IDFM documente aussi cinq articulés utilisés sur des services partiels de la 113 et rattachés historiquement à Bussy via la ligne 206 avant l’ouverture de Frères-Lumière ; le sort de ces véhicules après cette évolution n’est pas établi.",
            documents: [
                DepotLineDocumentLink(title: "Plan IDFM/RATP de la ligne 113", type: "Plan", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/plans/20260211T090013Z-4510ab7e-f40c-45e9-821c-1ff5c812f592.pdf")!, validity: "Édition 09/2025", note: "Même plan pour les deux sites ; il ne décrit pas les affectations de dépôt."),
                DepotLineDocumentLink(title: "Fiche horaires IDFM de la ligne 113", type: "Fiche horaire", url: URL(string: "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20260908T122254Z-2ca59811-b570-4aaa-8511-60d3b513bfa5.pdf")!, validity: "24 août–31 décembre 2026", note: "IDFM annonce des ajustements ponctuels au 1er novembre 2026 ; cette fiche ne confirme pas les heures après ces ajustements.")
            ],
            claims: [
                DepotLineRosterClaim(
                    kind: .partialStorage,
                    siteID: "bussy",
                    centerLabel: "BUSSY-SAINT-MARTIN",
                    sourceTitle: "IDFM · Schéma de principe Bus Bords de Marne · articulés 113 rattachés via la ligne 206",
                    sourceURL: futureBordsDeMarneSchemeURL,
                    sourceDate: nil,
                    sourceDateLabel: "Situation décrite depuis juin 2022 · date d’édition exacte du schéma non vérifiée",
                    validFromKey: 20220601,
                    validThroughKey: 20230630,
                    note: "IDFM décrit cinq articulés de renfort de la 113 rattachés à Bussy via la ligne 206 depuis juin 2022. Leur répartition après l’ouverture de Frères-Lumière en juillet 2023 n’est pas établie."
                ),
                DepotLineRosterClaim(
                    kind: .partialStorage,
                    siteID: "freres-lumiere",
                    centerLabel: "FRÈRES-LUMIÈRE",
                    sourceTitle: "IDFM · décision de bail et remisage d’appui de la ligne 113",
                    sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/1c3d876c-ef6f-4f9f-ae60-8756ae273ba7_RAA_153-2.pdf"),
                    sourceDate: sourceDate(year: 2023, month: 9, day: 6),
                    sourceDateLabel: "Décision IDFM du 6 septembre 2023 · bail effectif au 1er juillet 2023",
                    validFromKey: 20230701,
                    validThroughKey: 20251031,
                    note: "La décision décrit un remisage d’appui d’autobus articulés affectés au renfort de la 113, puis la mise à disposition du site au délégataire DSP45. Elle ne prouve pas que toutes les courses de la ligne partent de cette adresse."
                ),
                DepotLineRosterClaim(
                    kind: .fleetObservation,
                    siteID: "neuilly-plaisance",
                    centerLabel: "NEUILLY-PLAISANCE",
                    sourceTitle: "TC Infos · Citelis 12 du pool de la ligne 113 à Neuilly-Plaisance",
                    sourceURL: currentTCInfosLineURLs["113"],
                    sourceDateLabel: "Observations de parc depuis novembre 2025",
                    validFromKey: 20251101,
                    validThroughKey: nil,
                    note: "Observation communautaire d’une partie du parc de ligne ; ne répartit pas toutes les courses."
                ),
                DepotLineRosterClaim(
                    kind: .fleetObservation,
                    siteID: "freres-lumiere",
                    centerLabel: "FRÈRES-LUMIÈRE",
                    sourceTitle: "TC Infos · parc courant de la ligne 113, dont des articulés à Frères-Lumière",
                    sourceURL: currentTCInfosLineURLs["113"],
                    sourceDateLabel: "Véhicules recensés entre novembre 2025 et mars 2026",
                    validFromKey: 20251101,
                    validThroughKey: nil,
                    note: "Observation communautaire du parc de ligne ; la fiche dépôt TC Infos compte 12 Citelis 18 mais ne donne pas les services qui partent de ce site."
                ),
                DepotLineRosterClaim(
                    kind: .supportingSource,
                    siteID: nil,
                    centerLabel: nil,
                    sourceTitle: "IDFM · schéma de principe du Bus Bords de Marne · parc historique de la 113",
                    sourceURL: futureBordsDeMarneSchemeURL,
                    sourceDate: nil,
                    sourceDateLabel: "Données de situation antérieures au transfert DSP45 · date exacte du fait non précisée",
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: "Le dossier situe le Centre bus historique des Bords de Marne, anciennement la Maltournée, à Neuilly-Plaisance : environ 22 000 m², entretien, maintenance et remisage d’environ 15 lignes, dont la 113 exploitée à l’époque avec 27 autobus standards de 12 m. Il indique qu’à la date du dossier le site ne pouvait accueillir des articulés de 18 m, et évoque une conversion électrique prévue vers 2024. Le document ne liste pas les 15 lignes, ne confirme pas la capacité après travaux et ne décrit pas les affectations depuis le transfert DSP45."
                )
            ]),
        neuillyPlaisanceLine("114", note: "Château de Vincennes ↔ Villemomble–Les Coquetiers / Le Raincy–Villemomble–Montfermeil RER. Le plan signale des variantes liées aux écoles, aux marchés et au dimanche. TC Infos montre un parc partagé avec plusieurs lignes ; cela ne prouve pas une affectation exclusive.", documents: documentsByLine["114"] ?? []),
        observedPoolNeuillyPlaisanceLine("116", note: "Montreuil–Boissière–Acacia ↔ Champigny–Saint-Maur RER. L’itinéraire Marché dessert un arrêt le mardi de 7 h à 15 h vers Champigny, et le samedi de 9 h à 21 h dans les deux sens. IDFM annonce un renfort de fréquence et des horaires élargis au 1er novembre 2026. TC Infos observe du matériel à Neuilly-Plaisance, mais reproduit un pool partagé de véhicules sur plusieurs lignes.", documents: documentsByLine["116"] ?? []),
        neuillyPlaisanceLine("118", note: "Château de Vincennes ↔ Gare de Val de Fontenay. Le plan IDFM de septembre 2025 et les séquences des courses GTFS actives du 20 octobre 2026 ne montrent pas les anciens terminus partiels à Ledru-Rollin ou OFPRA ; IDFM annonce un renfort de fréquence au 1er novembre 2026. TC Infos montre un parc de groupe partagé.", documents: documentsByLine["118"] ?? []),
        neuillyPlaisanceLine("120", note: "Nogent-sur-Marne RER ↔ Noisy-le-Grand–Mont d’Est ; des courses partielles en pointe relient Nogent RER à Hôpital Sainte-Camille. TC Infos montre un parc de groupe partagé.", documents: documentsByLine["120"] ?? []),
        neuillyPlaisanceLine("124", note: "Château de Vincennes ↔ Montreuil–Boissière. TC Infos montre un parc de groupe partagé ; IDFM annonce un renfort de fréquence au 1er novembre 2026.", documents: documentsByLine["124"] ?? []),
        neuillyPlaisanceLine(
            "127",
            note: "Montreuil–Croix-de-Chavaux avec terminus selon les courses à Place de la Résistance ou Gagny–Charles-de-Gaulle ; services de marché, scolaires et du dimanche figurent sur le plan. Le Parisien rapporte qu’un bus de la 127 en service a brûlé à Montreuil le 4 novembre 2025 et rattache les véhicules concernés au dépôt de Neuilly-Plaisance et au réseau Boucles de Marne ; cette observation ponctuelle ne répartit pas toutes les courses. TC Infos montre aussi un parc de groupe partagé.",
            documents: documentsByLine["127"] ?? [],
            additionalClaims: [DepotLineRosterClaim(
                kind: .fleetObservation,
                siteID: "neuilly-plaisance",
                centerLabel: "NEUILLY-PLAISANCE",
                sourceTitle: "Le Parisien · véhicule de la ligne 127 rattaché au dépôt de Neuilly-Plaisance",
                sourceURL: bordsDeMarneFireReportURL,
                sourceDate: sourceDate(year: 2025, month: 12, day: 16),
                sourceDateLabel: "Article du 16 décembre 2025 · incident du 4 novembre",
                validFromKey: 20251104,
                validThroughKey: 20251104,
                note: "L’article rapporte un bus de la 127 en service le 4 novembre 2025 puis indique que les véhicules Citelis des quatre incendies appartenaient au dépôt de Neuilly-Plaisance et au lot Boucles de Marne. Source de presse secondaire, limitée à l’incident et au véhicule concerné ; elle ne prouve pas une affectation exclusive de la ligne ni la répartition de toutes ses courses."
            )]
        ),
        neuillyPlaisanceLine("203", note: "Gare de Neuilly-Plaisance ↔ Bougainville. L’extension vers Maison-Blanche est annoncée pour début 2027 et n’est pas encore une variante en service. IDFM annonce un renfort de fréquence et des horaires élargis au 1er novembre 2026. TC Infos montre un parc de groupe partagé.", documents: documentsByLine["203"] ?? []),
        secondaryNeuillyPlaisanceLine(
            "210",
            note: "Vincennes ↔ Villiers-sur-Marne, avec un itinéraire du dimanche. L’ancien contrat IDFM–RATP indique le centre « Bords de Marne », situé historiquement à Neuilly-Plaisance, jusqu’au transfert DSP45 du 1er novembre 2025. IDFM annonce un nouveau tracé par Les Rigollots au 1er novembre 2026, mais ne confirme pas le COB après le transfert ; l’affectation actuelle reste non établie.",
            documents: documentsByLine["210"] ?? [],
            additionalClaims: [DepotLineRosterClaim(
                kind: .announcedService,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · changement de parcours de la ligne 210",
                sourceURL: reorganizationURL,
                sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: "L’annonce date un changement de parcours ; elle ne nomme pas le COB de la ligne après la réorganisation."
            )]
        ),
        neuillyPlaisanceLine(
            "214",
            note: "Gare de Neuilly-Plaisance ↔ Gagny–Roger-Salengro ; seules les courses desservant la ZI des Chanoux sont transférées à la 314 au 1er novembre 2026. IDFM annonce que la 214 continue avec une fréquence renforcée et une amplitude élargie. Le GTFS du 20 octobre omet pourtant ses courses après cette date : traiter cet écart comme un conflit de version, pas comme une suppression. L’annonce ne confirme pas le COB de la 214 après la réorganisation.",
            documents: documentsByLine["214"] ?? [],
            additionalClaims: [DepotLineRosterClaim(
                kind: .announcedService,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · maintien de la ligne 214 après la réorganisation",
                sourceURL: reorganizationURL,
                sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: "L’annonce indique que la 214 continue avec fréquences renforcées et amplitude élargie ; seuls les arrêts de la ZI des Chanoux sont transférés à la 314. Cette preuve porte sur le service, pas sur le COB. Le GTFS daté du 20 octobre ne fournit pas les courses 214 annoncées après la date de changement."
            ), DepotLineRosterClaim(
                kind: .fleetObservation,
                siteID: "neuilly-plaisance",
                centerLabel: "NEUILLY-PLAISANCE",
                sourceTitle: "Le Parisien · véhicule de la ligne 214 rattaché au dépôt de Neuilly-Plaisance",
                sourceURL: bordsDeMarneFireReportURL,
                sourceDate: sourceDate(year: 2025, month: 12, day: 16),
                sourceDateLabel: "Article du 16 décembre 2025 · incident du 2 décembre",
                validFromKey: 20251202,
                validThroughKey: 20251202,
                note: "L’article rapporte qu’un bus Citelis a brûlé sur la 214 près de la gare RER de Neuilly-Plaisance le 2 décembre 2025 puis indique que les véhicules concernés appartenaient au dépôt de Neuilly-Plaisance et au lot Boucles de Marne. Source de presse secondaire, limitée à l’incident et au véhicule concerné ; elle ne prouve pas une affectation exclusive de la ligne ni la répartition de toutes ses courses."
            )]
        ),
        neuillyPlaisanceLine("221", note: "Gallieni ↔ Pointe de Gournay ; après 21 h, plusieurs courses sont partielles entre le cimetière de Villemomble et Rosny–Bois-Perrier. TC Infos montre un parc de groupe partagé. IDFM annonce que la ligne est inchangée au 1er novembre 2026.", documents: documentsByLine["221"] ?? []),
        neuillyPlaisanceLine("303", note: "Bondy–Avenue de Rosny ↔ Noisy-le-Grand–Mont d’Est. Le catalogue IDFM du 20 octobre 2026 référence un plan et une fiche horaires 2026 ; IDFM annonce un renfort de fréquence, notamment le week-end, au 1er novembre. TC Infos montre un parc de groupe partagé.", documents: documentsByLine["303"] ?? []),
        secondaryNeuillyPlaisanceLine(
            "520",
            note: "Boullereaux–Champigny ↔ Bry-sur-Marne–Europe, service de semaine en journée. L’ancien contrat IDFM–RATP indique le centre « Bords de Marne », situé historiquement à Neuilly-Plaisance, jusqu’au transfert DSP45 du 1er novembre 2025. IDFM annonce que la ligne reste inchangée au 1er novembre 2026, mais ne confirme pas son COB après le transfert ; l’affectation actuelle reste non établie.",
            documents: documentsByLine["520"] ?? [],
            additionalClaims: [DepotLineRosterClaim(
                kind: .announcedService,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · ligne 520 inchangée au 1er novembre 2026",
                sourceURL: reorganizationURL,
                sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: "L’annonce confirme le maintien du service de la 520, pas son affectation à un COB après la réorganisation."
            )]
        ),
        row("N11", category: "Noctilien", sites: ["saint-maur", "neuilly-plaisance"], center: "SAINT-MAUR · BORDS DE MARNE · CHARLEBOURG", status: .shared,
            secondarySource: "TC Infos · parc de ligne à Neuilly-Plaisance",
            secondaryURL: currentTCInfosLineURLs["N11"],
            note: "Pont de Neuilly ↔ Château de Vincennes. L’ancien contrat RATP cite trois centres pour N11 (Charlebourg, Bords de Marne et Saint-Maur), sans répartir les courses, jusqu’au transfert DSP45 du 1er novembre 2025. TC Infos observe aussi des véhicules à Neuilly-Plaisance après transfert ; cette observation ne prouve pas la répartition de toutes les courses.",
            documents: documentsByLine["N11"] ?? [],
            claims: [
                DepotLineRosterClaim(
                    kind: .sharedContractCenters,
                    siteID: nil,
                    centerLabel: "SAINT-MAUR · BORDS DE MARNE · CHARLEBOURG",
                    sourceTitle: "IDFM · annexe des centres cités pour N11",
                    sourceURL: contractEvidenceURL,
                    sourceDateLabel: "Contrat bus 2025–2026",
                    validFromKey: oldRatpLineCenterEvidenceFrom,
                    validThroughKey: oldRatpLineCenterEvidenceThrough,
                    note: "L’annexe de l’ancien contrat nomme trois centres sans répartir les courses ni les véhicules. Cette relation s’arrête au plus tard au transfert DSP45 du 1er novembre 2025."
                ),
                DepotLineRosterClaim(
                    kind: .fleetObservation,
                    siteID: "neuilly-plaisance",
                    centerLabel: "NEUILLY-PLAISANCE",
                    sourceTitle: "TC Infos · parc de ligne à Neuilly-Plaisance",
                    sourceURL: currentTCInfosLineURLs["N11"],
                    sourceDateLabel: nil,
                    validFromKey: dsp45Start,
                    validThroughKey: nil,
                    note: "Observation de parc postérieure au transfert DSP45 ; la page ne publie pas de période plus précise."
                )
            ]),
        row("N33", category: "Noctilien", center: "SAINT-MAUR · centre historique", status: .unresolved,
            note: "L’ancien tableau IDFM–RATP indique Saint-Maur jusqu’au transfert DSP45 du 1er novembre 2025 ; il n’établit pas le COB de N33 après cette date. IDFM annonce que le service reste inchangé au 1er novembre 2026, sans préciser son COB. L’export officiel IDFM du 20 octobre 2026 référence un plan et une fiche horaires directs ; la période exacte de cette fiche reste à lire dans le PDF.",
            documents: documentsByLine["N33"] ?? [],
            sourceDateLabel: "Contrat bus 2025–2026",
            validFromKey: oldRatpLineCenterEvidenceFrom,
            validThroughKey: oldRatpLineCenterEvidenceThrough,
            claims: [
                DepotLineRosterClaim(
                    kind: .contractCenter,
                    siteID: "saint-maur",
                    centerLabel: "SAINT-MAUR",
                    sourceTitle: "IDFM · annexe des centres cités pour N33",
                    sourceURL: contractEvidenceURL,
                    sourceDateLabel: "Contrat bus 2025–2026",
                    validFromKey: oldRatpLineCenterEvidenceFrom,
                    validThroughKey: oldRatpLineCenterEvidenceThrough,
                    note: "Le rattachement historique s’arrête au transfert DSP45 du 1er novembre 2025."
                ),
                DepotLineRosterClaim(
                    kind: .announcedService,
                    siteID: nil,
                    centerLabel: nil,
                    sourceTitle: "IDFM · ligne N33 inchangée au 1er novembre 2026",
                    sourceURL: reorganizationURL,
                    sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                    sourceDateLabel: "Annonce du 13 octobre 2026",
                    validFromKey: 20261101,
                    validThroughKey: nil,
                    note: "IDFM annonce la continuité du service N33 ; cette preuve ne désigne aucun COB après le transfert DSP45."
                )
            ]),
        row("N34", category: "Noctilien", sites: ["neuilly-plaisance"], center: "NEUILLY-PLAISANCE", status: .observedPool,
            source: "TC Infos · parc de ligne après transfert DSP45",
            url: currentTCInfosLineURLs["N34"],
            note: "Paris–Gare de Lyon Diderot ↔ Torcy RER. TC Infos observe du matériel N34 à Neuilly-Plaisance dans le parc post-transfert ; cette preuve communautaire décrit le matériel de ligne, pas la répartition de tous les services. Le catalogue IDFM du 20 octobre 2026 fournit une fiche horaires directe, dont la période est à consulter dans le PDF.",
            documents: documentsByLine["N34"] ?? [],
            claims: [DepotLineRosterClaim(
                kind: .fleetObservation,
                siteID: "neuilly-plaisance",
                centerLabel: "NEUILLY-PLAISANCE",
                sourceTitle: "TC Infos · matériel de ligne N34 à Neuilly-Plaisance",
                sourceURL: currentTCInfosLineURLs["N34"],
                sourceDateLabel: "Véhicules recensés après novembre 2025",
                validFromKey: dsp45Start,
                validThroughKey: nil,
                note: "Observation communautaire de parc ; la page répète un pool partagé de véhicules, sans confirmer une affectation exclusive ni sa durée."
            )] + historicalBordsDeMarneCenterClaims()),
        row("N16", category: "Noctilien", status: .unresolved, source: "IDFM · périmètre DSP 45", url: awardEvidenceURL,
            note: "Ligne listée dans le périmètre du réseau ; aucune affectation à l’un de ces deux COB établie publiquement.",
            documents: documentsByLine["N16"] ?? [],
            sourceDate: sourceDate(year: 2024, month: 11, day: 6),
            sourceDateLabel: "Annonce IDFM du 6 novembre 2024"),
        row("N32", category: "Noctilien", sites: ["saint-maur"], center: "CRÉTEIL (contrat historique) · SAINT-MAUR (observation TC Infos)", status: .observedPool,
            source: "TC Infos · parc de ligne après transfert DSP45",
            url: currentTCInfosLineURLs["N32"],
            secondarySource: "Contrat bus IDFM 2025–2026",
            secondaryURL: contractEvidenceURL,
            note: "L’ancien contrat IDFM–RATP indique Créteil jusqu’au transfert DSP45 ; après le transfert, TC Infos observe des véhicules N32 à Saint-Maur. Ces sources portent sur des périodes successives : le parc observé ne confirme pas une affectation exclusive ni toutes les courses.",
            documents: documentsByLine["N32"] ?? [],
            claims: [
                DepotLineRosterClaim(
                    kind: .fleetObservation,
                    siteID: "saint-maur",
                    centerLabel: "SAINT-MAUR",
                    sourceTitle: "TC Infos · parc de N32 après transfert DSP45",
                    sourceURL: currentTCInfosLineURLs["N32"],
                    sourceDateLabel: "Données de parc après novembre 2025",
                    validFromKey: dsp45Start,
                    validThroughKey: nil,
                    note: "Observation de véhicules ; ne confirme ni la répartition de toutes les courses ni sa durée."
                ),
                DepotLineRosterClaim(
                    kind: .contractCenter,
                    siteID: nil,
                    centerLabel: "CRÉTEIL",
                    sourceTitle: "IDFM · centre indiqué au contrat bus 2025–2026",
                    sourceURL: contractEvidenceURL,
                    sourceDateLabel: "Contrat bus 2025–2026",
                    validFromKey: oldRatpLineCenterEvidenceFrom,
                    validThroughKey: oldRatpLineCenterEvidenceThrough,
                    note: "Le centre indiqué est extérieur aux COB physiques de ce scénario. Ce rattachement appartient à l’ancien périmètre RATP et ne s’applique pas après le transfert DSP45."
                )
            ]),
        row("N35", category: "Noctilien", sites: ["saint-maur"], center: "CRÉTEIL (contrat historique) · SAINT-MAUR (observation TC Infos)", status: .observedPool,
            source: "TC Infos · parc de ligne après transfert DSP45",
            url: currentTCInfosLineURLs["N35"],
            secondarySource: "Contrat bus IDFM 2025–2026",
            secondaryURL: contractEvidenceURL,
            note: "L’ancien contrat IDFM–RATP indique Créteil jusqu’au transfert DSP45 ; après le transfert, TC Infos observe des véhicules N35 à Saint-Maur. Ces sources portent sur des périodes successives : le parc observé ne confirme pas une affectation exclusive ni toutes les courses.",
            documents: documentsByLine["N35"] ?? [],
            claims: [
                DepotLineRosterClaim(
                    kind: .fleetObservation,
                    siteID: "saint-maur",
                    centerLabel: "SAINT-MAUR",
                    sourceTitle: "TC Infos · parc de N35 après transfert DSP45",
                    sourceURL: currentTCInfosLineURLs["N35"],
                    sourceDateLabel: "Données de parc après novembre 2025",
                    validFromKey: dsp45Start,
                    validThroughKey: nil,
                    note: "Observation de véhicules ; ne confirme ni la répartition de toutes les courses ni sa durée."
                ),
                DepotLineRosterClaim(
                    kind: .contractCenter,
                    siteID: nil,
                    centerLabel: "CRÉTEIL",
                    sourceTitle: "IDFM · centre indiqué au contrat bus 2025–2026",
                    sourceURL: contractEvidenceURL,
                    sourceDateLabel: "Contrat bus 2025–2026",
                    validFromKey: oldRatpLineCenterEvidenceFrom,
                    validThroughKey: oldRatpLineCenterEvidenceThrough,
                    note: "Le centre indiqué est extérieur aux COB physiques de ce scénario. Ce rattachement appartient à l’ancien périmètre RATP et ne s’applique pas après le transfert DSP45."
                )
            ]),
        row("N71", category: "Noctilien", center: "THIAIS", status: .unresolved,
            note: "L’ancien contrat IDFM–RATP indique le centre de Thiais avant le transfert DSP45. Ce centre est extérieur aux COB du scénario, et aucune affectation actuelle de N71 à Saint-Maur ou Neuilly-Plaisance n’est établie.",
            documents: documentsByLine["N71"] ?? [],
            sourceDateLabel: "Contrat bus 2025–2026",
            validFromKey: oldRatpLineCenterEvidenceFrom,
            validThroughKey: oldRatpLineCenterEvidenceThrough),
        row("N31", category: "Conflit historique hors roster actif", center: "VITRY", status: .conflict,
            source: "IDFM · annonce DSP 45 et contrat bus 2025–2026",
            url: awardEvidenceURL,
            secondarySource: "Contrat bus IDFM 2025–2026",
            secondaryURL: contractEvidenceURL,
            note: "L’annonce IDFM de 2024 l’incluait dans le périmètre annoncé, mais la liste actuelle comporte 29 lignes dont 7 Noctilien et l’annexe 2025–2026 indique Vitry. N31 est conservée comme conflit historique, hors des 29 lignes actives et sans affectation à un COB Bords de Marne.",
            documents: documentsByLine["N31"] ?? [],
            claims: [
                DepotLineRosterClaim(
                    kind: .networkScopeOnly,
                    siteID: nil,
                    centerLabel: nil,
                    sourceTitle: "IDFM · annonce du périmètre DSP 45",
                    sourceURL: awardEvidenceURL,
                    sourceDate: sourceDate(year: 2024, month: 11, day: 6),
                    sourceDateLabel: "Annonce IDFM du 6 novembre 2024",
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: "Le périmètre contractuel ne précise pas un COB Bords de Marne pour cette ligne."
                ),
                DepotLineRosterClaim(
                    kind: .contractCenter,
                    siteID: nil,
                    centerLabel: "VITRY",
                    sourceTitle: "IDFM · centre indiqué au contrat bus 2025–2026",
                    sourceURL: contractEvidenceURL,
                    sourceDateLabel: "Contrat bus 2025–2026",
                    validFromKey: oldRatpLineCenterEvidenceFrom,
                    validThroughKey: oldRatpLineCenterEvidenceThrough,
                    note: "Vitry est extérieur aux COB physiques de ce scénario. L’annonce d’attribution de 2024 et la table de l’ancien contrat divergent sur le périmètre de N31 ; elle reste conservée comme conflit historique, hors roster actif retenu."
                )
            ]),
        row("314", category: "Ligne DSP 45 annoncée · COB à confirmer", sites: ["saint-maur", "neuilly-plaisance"], status: .candidate,
            source: "IDFM · réorganisation au 1er novembre 2026",
            url: reorganizationURL,
            note: "Liaison Neuilly-Plaisance RER ↔ ZI des Chanoux, annoncée du lundi au vendredi (15 min en pointe, 60 min en creuse) à partir du 1er novembre 2026. Le plan IDFM 214/314 d’août 2026 est disponible, mais aucun PDF de grille horaire ni document d’affectation au COB n’a été retrouvé.",
            documents: documentsByLine["314"] ?? [],
            sourceDate: sourceDate(year: 2026, month: 10, day: 13),
            sourceDateLabel: "Annonce du 13 octobre 2026",
            validFromKey: 20261101,
            claims: [DepotLineRosterClaim(
                kind: .announcedService,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · nouvelle ligne 314 annoncée sans COB publié",
                sourceURL: reorganizationURL,
                sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: "L’annonce date le début du service, mais ne confirme pas son affectation à un COB."
            ), DepotLineRosterClaim(
                kind: .networkScopeOnly,
                siteID: nil,
                centerLabel: nil,
                sourceTitle: "IDFM · ligne 314 créée lors de la réorganisation DSP45",
                sourceURL: reorganizationURL,
                sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: dsp45End,
                note: "Le service de la 314 est annoncé dans la réorganisation ; aucune affectation à Saint-Maur ou Neuilly-Plaisance n’est publiée."
            ), DepotLineRosterClaim(
                kind: .candidateAssignment,
                siteID: "saint-maur",
                centerLabel: "COB Saint-Maur",
                sourceTitle: "IDFM · ligne 314 candidate pour le périmètre DSP45",
                sourceURL: reorganizationURL,
                sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: "La ligne est annoncée dans le réseau DSP45, mais aucune source publique ne la répartit entre Saint-Maur et Neuilly-Plaisance. Affectation affichée comme candidate."
            ), DepotLineRosterClaim(
                kind: .candidateAssignment,
                siteID: "neuilly-plaisance",
                centerLabel: "COB Neuilly-Plaisance",
                sourceTitle: "IDFM · ligne 314 candidate pour le périmètre DSP45",
                sourceURL: reorganizationURL,
                sourceDate: sourceDate(year: 2026, month: 10, day: 13),
                sourceDateLabel: "Annonce du 13 octobre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: "La ligne est annoncée dans le réseau DSP45, mais aucune source publique ne la répartit entre Saint-Maur et Neuilly-Plaisance. Affectation affichée comme candidate."
            )])
    ] + [
        row("BBM · projet", category: "Ligne de projet", sites: ["neuilly-sur-marne-projet"], center: "COB NEUILLY-SUR-MARNE · FUTUR", status: .planned,
            source: "IDFM · projet Bus Bords de Marne et desserte prévue du futur COB",
            url: futureBordsDeMarneProjectURL,
            note: "Future liaison Val-de-Fontenay ↔ Chelles–Gournay, environ 8,5 km et 17 stations. Mise en service visée vers 2030 ; fréquence annoncée à titre prévisionnel (environ 4 min en pointe et 6 min en creuse). Aucun numéro commercial n’est publié. Ce sont des prévisions de projet, pas une grille horaire opérateur. Aucune ligne actuelle n’est publiquement affectée au futur COB ; les lignes mutualisées éventuelles restent à définir.",
            documents: [
                DepotLineDocumentLink(title: "Notice explicative du projet de COB", type: "Dossier de projet", url: futureCobNoticeURL, validity: "Document de projet · édition à consulter dans le PDF", note: "Document de localisation et d’aménagement du site ; ce n’est ni un plan opérateur de ligne ni une grille horaire."),
                DepotLineDocumentLink(title: "Dossier de concertation 2023 · futur COB d’environ 32 000 m²", type: "Dossier de projet", url: futureBBDMConsultationURL, validity: "Septembre 2023 · emprise de projet", note: "Surface prévisionnelle destinée au remisage et à la maintenance ; elle ne publie pas le nombre de places ni une capacité opérationnelle."),
                DepotLineDocumentLink(title: "Schéma de principe du Bus Bords de Marne", type: "Document de projet", url: futureBordsDeMarneSchemeURL, validity: "Schéma de principe IDFM", note: "Présente le projet de transport et le futur site ; ne fournit pas de grille horaire opérateur."),
                DepotLineDocumentLink(title: "Lignes susceptibles de partager le futur COB", type: "FAQ IDFM", url: futureCobFAQURL, validity: "Page projet IDFM", note: "IDFM indique que les autres lignes susceptibles d’être accueillies restent à définir.")
            ],
            sourceDate: sourceDate(year: 2026, month: 10, day: 1),
            sourceDateLabel: "Projet IDFM · actualité du 1er octobre 2026",
            claims: [
                DepotLineRosterClaim(
                    kind: .announcedService,
                    siteID: "neuilly-sur-marne-projet",
                    centerLabel: "COB NEUILLY-SUR-MARNE · FUTUR",
                    sourceTitle: "IDFM · Bus Bords de Marne prévu pour le futur COB",
                    sourceURL: futureBordsDeMarneProjectURL,
                    sourceDate: sourceDate(year: 2026, month: 10, day: 1),
                    sourceDateLabel: "Actualité IDFM du 1er octobre 2026",
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: "La ligne est présentée sous le nom générique Bus Bords de Marne ; aucun numéro commercial n’est publié. La cible 2030 et les fréquences sont des prévisions, pas un horaire d’exploitation."
                ),
                DepotLineRosterClaim(
                    kind: .supportingSource,
                    siteID: "neuilly-sur-marne-projet",
                    centerLabel: "COB NEUILLY-SUR-MARNE · FUTUR",
                    sourceTitle: "IDFM · études d’avant-projet du COB",
                    sourceURL: futureCobUpdateURL,
                    sourceDate: sourceDate(year: 2026, month: 10, day: 1),
                    sourceDateLabel: "Actualité IDFM du 1er octobre 2026",
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: "Les études sont en cours ; la publication ne confirme pas un démarrage de chantier."
                ),
                DepotLineRosterClaim(
                    kind: .supportingSource,
                    siteID: "neuilly-sur-marne-projet",
                    centerLabel: nil,
                    sourceTitle: "IDFM · lignes partageant éventuellement le COB",
                    sourceURL: futureCobFAQURL,
                    sourceDateLabel: nil,
                    validFromKey: nil,
                    validThroughKey: nil,
                    note: "Les autres lignes à accueillir ne sont pas définies dans la source."
                )
            ])
    ]

    static func tcInfosDepotURL(for siteID: String) -> URL {
        let depotID = switch siteID {
        case "saint-maur": "4665"
        case "neuilly-plaisance": "4663"
        case "freres-lumiere": "4664"
        default: "4663"
        }
        return URL(string: "https://tc-infos.fr/exploitant/2975/depot/\(depotID)")!
    }
}

enum DepotContractLineScope {
    static func candidateRows(
        for site: DepotLineRosterSite?,
        references: [NetworkLineReference],
        serviceDate: Date,
        excluding visibleDepotRows: [DepotLineRosterRow]
    ) -> [DepotLineRosterRow] {
        guard let site,
              site.availability != .planned,
              let contractID = site.idfmBusContractID else { return [] }
        let canonicalContractID = LineReferenceMatcher.canonicalIdentifier(contractID)
        guard !canonicalContractID.isEmpty else { return [] }

        let contractReferences = references.filter {
            guard let referenceContractID = $0.busContractID,
                  LineReferenceMatcher.canonicalIdentifier(referenceContractID) == canonicalContractID else { return false }
            return $0.isActive(on: serviceDate) == true
        }
        let referencesByID = Dictionary(grouping: contractReferences) {
            LineReferenceMatcher.canonicalIdentifier($0.idLine)
        }

        let alreadyRepresentedIDs = Set(visibleDepotRows.flatMap { row -> [String] in
            if let canonicalLineID = row.canonicalLineID { return [canonicalLineID] }
            let normalizedName = row.line.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let matchingIDs = Set(contractReferences.filter {
                $0.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == normalizedName
            }.map { LineReferenceMatcher.canonicalIdentifier($0.idLine) })
            return matchingIDs.count == 1 ? Array(matchingIDs) : []
        })

        let referenceCandidates: [DepotLineRosterRow] = referencesByID.keys.sorted().compactMap { canonicalLineID in
            guard !canonicalLineID.isEmpty,
                  !alreadyRepresentedIDs.contains(canonicalLineID),
                  let rows = referencesByID[canonicalLineID],
                  let firstReference = rows.first else { return nil }

            let displayNames = Set(rows.map { reference in
                let shortName = reference.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines)
                return shortName.isEmpty ? reference.nameLine.trimmingCharacters(in: .whitespacesAndNewlines) : shortName
            }.filter { !$0.isEmpty })
            guard !displayNames.isEmpty else { return nil }
            let lineName = displayNames.sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }.joined(separator: " / ")

            let startKeys = rows.compactMap { idfmDateKey($0.validFrom) }
            let endKeys = rows.compactMap { idfmDateKey($0.validTo) }
            let hasOpenEndedReference = rows.contains {
                $0.validTo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            let validFromKey = startKeys.min()
            let validThroughKey = hasOpenEndedReference ? nil : endKeys.max()
            let validityText = "Validité IDFM : \(firstReference.validFrom.isEmpty ? "début inconnu" : firstReference.validFrom) – \(firstReference.validTo.isEmpty ? "sans date de fin renseignée" : firstReference.validTo)."
            let note = "Le référentiel IDFM associe la ligne commerciale \(lineName) (ID_Line \(canonicalLineID)) au contrat \(contractID). Il ne précise pas quel COB de ce contrat exploite cette ligne. Tracé et documents sont montrés pour qualification, avec rattachement au dépôt à confirmer. \(validityText)"
            let claim = DepotLineRosterClaim(
                kind: .candidateAssignment,
                siteID: site.id,
                centerLabel: site.name,
                sourceTitle: "IDFM · référentiel des lignes · contrat \(contractID) · ID_Line \(canonicalLineID)",
                sourceURL: DepotLineRoster.lineReferenceURL,
                sourceDateLabel: nil,
                validFromKey: validFromKey,
                validThroughKey: validThroughKey,
                note: note
            )
            return DepotLineRosterRow(
                line: lineName,
                category: "Ligne du lot · COB à confirmer",
                siteIDs: [site.id],
                evidenceStatus: .candidate,
                note: note,
                publicDocuments: [],
                claims: [claim],
                canonicalLineID: canonicalLineID
            )
        }

        let representedIDs = alreadyRepresentedIDs.union(referenceCandidates.compactMap(\.canonicalLineID))
        let upcomingCandidates = upcomingPublicCandidates(
            for: site,
            references: references,
            serviceDate: serviceDate,
            excludingLineIDs: representedIDs
        )
        return referenceCandidates + upcomingCandidates
    }

    static func publicRosterNote(for site: DepotLineRosterSite?, serviceDate: Date) -> String? {
        guard let site,
              let contractID = site.idfmBusContractID,
              let dateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone) else { return nil }
        switch LineReferenceMatcher.canonicalIdentifier(contractID) {
        case "48":
            if dateKey < 20261101 {
                return "La DSP 48 démarre le 1er novembre 2026. Choisis une date à partir de ce jour pour afficher les lignes et horaires du nouveau lot."
            }
            return "La liste AUT de septembre 2026 nomme 25 lignes pour la DSP 48, comme le total annoncé par IDFM. Leur répartition entre les COB reste à confirmer."
        case "49":
            if dateKey < 20261101 {
                return "La DSP 49 démarre le 1er novembre 2026. Choisis une date à partir de ce jour pour afficher les lignes et horaires du nouveau lot."
            }
            return "La liste AUT de septembre 2026 nomme 39 lignes ; IDFM en annonce 41 pour la DSP 49. Deux lignes du total restent à identifier et ne sont pas inventées ici."
        default:
            return nil
        }
    }

    private static let upcomingPublicLineNames: [String: [String]] = [
        "48": ["21", "24", "28", "30", "58", "59", "63", "64", "67", "68", "70", "82", "84", "88", "92", "94", "PC", "123", "126", "128", "169", "171", "188", "260", "388"],
        "49": ["20", "26", "29", "38", "39", "40", "46", "48", "56", "57", "60", "69", "76", "77", "80", "86", "87", "96", "102", "109", "115", "121", "122", "129", "215", "318", "322", "341", "N01", "N02", "N13", "N41", "N42", "N43", "N44", "N45", "N51", "N52", "N53"]
    ]

    private static let officialRATPLinePages: [String: URL] = [
        "N45": URL(string: "https://www.ratp.fr/plans-lignes/noctilien/n45")!,
        "N52": URL(string: "https://www.ratp.fr/plans-lignes/noctilien/n52")!,
        "N53": URL(string: "https://www.ratp.fr/plans-lignes/noctilien/n53")!
    ]

    private static let upcomingPublicRosterURL = URL(string: "https://www.aut-idf.org/tdl-perimetre/")!

    private static func upcomingPublicCandidates(
        for site: DepotLineRosterSite,
        references: [NetworkLineReference],
        serviceDate: Date,
        excludingLineIDs: Set<String>
    ) -> [DepotLineRosterRow] {
        guard let contractID = site.idfmBusContractID,
              let dateKey = GTFSServiceDate.key(for: serviceDate, timeZone: GTFSServiceDate.parisTimeZone),
              dateKey >= 20261101 else { return [] }
        let canonicalContractID = LineReferenceMatcher.canonicalIdentifier(contractID)
        guard let lineNames = upcomingPublicLineNames[canonicalContractID] else { return [] }

        return lineNames.compactMap { lineName in
            let matchingReferences = references.filter { reference in
                reference.shortNameLine.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == lineName
                    && reference.transportMode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "BUS"
                    && reference.isActive(on: serviceDate) == true
                    && (reference.busContractID == nil
                        || LineReferenceMatcher.canonicalIdentifier(reference.busContractID ?? "") == canonicalContractID)
            }
            let referencesByID = Dictionary(grouping: matchingReferences) {
                LineReferenceMatcher.canonicalIdentifier($0.idLine)
            }
            guard referencesByID.count == 1,
                  let (canonicalLineID, lineReferences) = referencesByID.first,
                  !canonicalLineID.isEmpty,
                  !excludingLineIDs.contains(canonicalLineID),
                  let reference = lineReferences.first else { return nil }

            let note = "La liste publique AUT de septembre 2026 place la ligne \(lineName) dans la DSP \(contractID), avec transfert à RATP Cap Île-de-France le 1er novembre 2026. IDFM confirme le contrat et le nombre total de lignes ; les sources ne précisent pas quel COB exploite cette ligne. Les données GTFS, plans et horaires sont rapprochés par son ID_Line \(canonicalLineID). Rattachement au COB à confirmer."
            let claim = DepotLineRosterClaim(
                kind: .candidateAssignment,
                siteID: site.id,
                centerLabel: site.name,
                sourceTitle: "AUT · périmètre des lignes DSP \(contractID) · septembre 2026",
                sourceURL: upcomingPublicRosterURL,
                sourceDateLabel: "septembre 2026 · transfert du lot le 1er novembre 2026",
                validFromKey: 20261101,
                validThroughKey: nil,
                note: note
            )
            return DepotLineRosterRow(
                line: reference.shortNameLine,
                category: "Ligne réelle DSP \(contractID) · COB à confirmer",
                siteIDs: [site.id],
                evidenceStatus: .candidate,
                note: note,
                publicDocuments: officialRATPLinePages[reference.shortNameLine.uppercased()].map { url in
                    [DepotLineDocumentLink(
                        title: "Horaires de la ligne \(reference.shortNameLine) · RATP",
                        type: "HORAIRE_WEB",
                        url: url,
                        validity: "Page RATP consultée le 21 octobre 2026 · période à vérifier sur la page",
                        note: "La page officielle permet d’ouvrir les horaires en ligne. Aucun PDF statique actuel n’est relié à cette ligne dans l’export IDFM chargé; la grille du jeu utilise les courses GTFS."
                    )]
                } ?? [],
                claims: [claim],
                canonicalLineID: canonicalLineID
            )
        }
    }

    private static func idfmDateKey(_ value: String) -> Int? {
        let components = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-", omittingEmptySubsequences: false)
        guard components.count == 3,
              components[0].count == 4,
              components[1].count == 2,
              components[2].count == 2,
              components.allSatisfy({ $0.allSatisfy(\.isNumber) }),
              let date = GTFSServiceDate.date(from: components.joined()) else { return nil }
        return GTFSServiceDate.key(for: date, timeZone: GTFSServiceDate.parisTimeZone)
    }
}
