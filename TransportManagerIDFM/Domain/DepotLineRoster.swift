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
    let operatorName: String?
    let additionalEvidenceTitle: String?
    let additionalEvidenceURL: URL?
    let supportingEvidence: [DepotSiteEvidenceLink]
    let fleetObservation: DepotFleetObservation?
    let facilityObservations: [DepotFacilityObservation]
    let chargingInfrastructureObservation: DepotChargingInfrastructureObservation?

    var evidenceLinks: [DepotSiteEvidenceLink] {
        var links: [DepotSiteEvidenceLink] = []
        if let evidenceTitle, let sourceURL {
            links.append(DepotSiteEvidenceLink(title: evidenceTitle, url: sourceURL))
        }
        if let additionalEvidenceTitle, let additionalEvidenceURL {
            links.append(DepotSiteEvidenceLink(title: additionalEvidenceTitle, url: additionalEvidenceURL))
        }
        links.append(contentsOf: supportingEvidence)
        var seenURLs = Set<String>()
        return links.filter { seenURLs.insert($0.url.absoluteString).inserted }
    }

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
        operatorName: String? = nil,
        additionalEvidenceTitle: String? = nil,
        additionalEvidenceURL: URL? = nil,
        supportingEvidence: [DepotSiteEvidenceLink] = [],
        fleetObservation: DepotFleetObservation? = nil,
        facilityObservations: [DepotFacilityObservation] = [],
        chargingInfrastructureObservation: DepotChargingInfrastructureObservation? = nil
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
        self.operatorName = operatorName
        self.additionalEvidenceTitle = additionalEvidenceTitle
        self.additionalEvidenceURL = additionalEvidenceURL
        self.supportingEvidence = supportingEvidence
        self.fleetObservation = fleetObservation
        self.facilityObservations = facilityObservations
        self.chargingInfrastructureObservation = chargingInfrastructureObservation
    }
}

enum DepotDirectoryAvailabilityFilter: String, CaseIterable, Hashable, Identifiable, Sendable {
    case all
    case operational
    case currentStatusUnverified
    case planned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Tous les statuts"
        case .operational: "En activité"
        case .currentStatusUnverified: "À vérifier"
        case .planned: "Projets"
        }
    }

    func includes(_ site: DepotLineRosterSite) -> Bool {
        switch self {
        case .all: true
        case .operational: site.availability == .operational
        case .currentStatusUnverified: site.availability == .currentStatusUnverified
        case .planned: site.availability == .planned
        }
    }
}

enum DepotDirectoryQualityFilter: String, CaseIterable, Hashable, Identifiable, Sendable {
    case all
    case documentedAddress
    case identifiedContract
    case observedFleet
    case evidenceLinks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "Toutes les données"
        case .documentedAddress: "Adresse publiée"
        case .identifiedContract: "Contrat identifié"
        case .observedFleet: "Parc observé"
        case .evidenceLinks: "Avec source publiée"
        }
    }

    func includes(_ site: DepotLineRosterSite) -> Bool {
        switch self {
        case .all: true
        case .documentedAddress:
            site.documentedAddress?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .identifiedContract:
            site.idfmBusContractID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .observedFleet:
            site.fleetObservation != nil
        case .evidenceLinks:
            !site.evidenceLinks.isEmpty
        }
    }
}

struct DepotDirectorySiteFilter: Hashable, Sendable {
    var availability: DepotDirectoryAvailabilityFilter
    var operatorName: String?
    var contractID: String?
    var quality: DepotDirectoryQualityFilter

    init(
        availability: DepotDirectoryAvailabilityFilter = .all,
        operatorName: String? = nil,
        contractID: String? = nil,
        quality: DepotDirectoryQualityFilter = .all
    ) {
        self.availability = availability
        self.operatorName = operatorName
        self.contractID = contractID
        self.quality = quality
    }

    func applying(to sites: [DepotLineRosterSite]) -> [DepotLineRosterSite] {
        sites.filter { site in
            availability.includes(site)
                && (operatorName == nil || normalized(site.operatorName) == normalized(operatorName))
                && (contractID == nil || LineReferenceMatcher.canonicalIdentifier(site.idfmBusContractID ?? "")
                    == LineReferenceMatcher.canonicalIdentifier(contractID ?? ""))
                && quality.includes(site)
        }
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

struct DepotSiteEvidenceLink: Hashable, Identifiable, Sendable {
    let title: String
    let url: URL

    var id: String { url.absoluteString }
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
    static let reorganizationURL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-restructure-et-reorganise-loffre-de-bus-sur-les-territoires-des-bords-de-marne-et-de-boucle-nord-de-seine/?lang=fr")!
    static let historicalBordsDeMarneCenterURL = URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/questions/quelles-seront-les-caracteristiques-du-materiel-roulant")!
    private static let ratpSeineSaintDenisBrochure2026URL = URL(string: "https://ratpgroup.com/api/media/brochure-ratp-en-seine-saint-denis-2026.pdf")!
    static let gtfsDatasetURL = URL(string: "https://prim.iledefrance-mobilites.fr/fr/jeux-de-donnees/offre-horaires-tc-gtfs-idfm")!
    static let documentsDatasetURL = URL(string: "https://data.iledefrance-mobilites.fr/explore/dataset/fiches-horaires-et-plans/")!
    static let lineReferenceURL = URL(string: "https://data.iledefrance-mobilites.fr/explore/dataset/referentiel-des-lignes/")!
    private static let ratpBus2025URL = URL(string: "https://www.ratp.fr/programme-bus2025")!
    private static let ratpDSP45DepotSplitURL = URL(string: "https://askip.ratpgroup.com/question/ile-de-france-mobilites-vient-de-publier-4-appels-doffres-quels-sont-les-centres-bus-concernes/")!
    private static let ratpBouclesDeMarne2025AnnualReportURL = URL(string: "https://ratpgroup.com/api/media/rapport-financier-et-de-durabilite-annuel-2025---groupe-ratp.pdf")!
    private static let idfmBordsDeMarneCOBPreselectionURL = URL(string: "https://presse.iledefrance-mobilites.fr/trois-premiers-candidats-pressentis-pour-exploiter-les-lignes-de-bus-des-territoires-de-marne-et-brie-des-boucles-nord-de-seine-et-des-bords-de-marne/?lang=fr")!
    private static let idfmBordsDeMarneCOBAwardURL = URL(string: "https://presse.iledefrance-mobilites.fr/mise-en-concurrence-des-transports-franciliens/?lang=fr")!
    private static let ratpCapDSP45AwardURL = URL(string: "https://www.ratpcap.com/blog/ratp-cap-ile-de-france-remporte-lexploitation-des-lots-bus-petite-couronne-pour-les-territoires-boucles-nord-de-seine-et-bords-de-marne/")!
    private static let idfmDSP41To47URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-designe-les-operateurs-bus-de-quatre-lots-en-petite-couronne-et-dun-lot-en-grande-couronne/?lang=fr")!
    private static let idfmDSP36To40URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-designe-les-operateurs-bus-de-trois-lots-en-petite-couronne-et-reattribue-un-lot-en-grande-couronne/?lang=fr")!
    private static let idfmDSP1And18And24URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-confirme-lattribution-de-deux-lots-de-bus-et-le-marche-pam/?lang=fr")!
    private static let idfmDSP48And49URL = URL(string: "https://presse.iledefrance-mobilites.fr/ile-de-france-mobilites-designe-ratp-cap-ile-de-france-comme-operateur-des-deux-derniers-lots-de-bus-de-paris-et-petite-couronne/?lang=fr")!
    private static let idfmDepotSchedule2024URL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/Zk4bEiol0Zci9XOy_CalendriersiteIDFMv22052024.pdf")!
    private static let ratpCapNeuillyPlaisanceElectricTransitionURL = URL(string: "https://carrieres.ratpcap.com/job/Neuilly-Plaisance-M%C3%A9canicien-Bus-FH-93-93360/1169481455/")!

    static let sites: [DepotLineRosterSite] = [
        DepotLineRosterSite(
            id: "saint-maur",
            name: "COB Saint-Maur",
            locality: "Saint-Maur-des-Fossés",
            status: "COB DSP45 · affectations par ligne à établir",
            availability: .operational,
            evidenceNote: "Le site figure parmi les deux COB de la DSP45. Le tableau ligne–centre de l’ancien contrat IDFM–RATP documente Saint-Maur avant le transfert du 1er novembre 2025 ; les lignes du nouvel exploitant ne sont pas ventilées par COB dans les sources consultées. RATP Group chiffre rétrospectivement neuf lignes pour Saint-Maur en 2022, sans publier leurs numéros dans cet article. Légifrance recense le site et sa surface de 9 566 m² en 2011. Un dossier préfectoral de sécurité de 2023 décrit une station de compression GNV et six autobus remisés dessous. En février 2025, IDFM cite Saint-Maur parmi dix centres convertis au biométhane. Une offre RATP Cap consultée le 24 octobre 2026 évoque une transition vers une flotte 100 % électrique, mais sa date de publication et l’avancement sur place ne sont pas indiqués; ces étapes successives ne prouvent pas le mix d’énergie ni la capacité de ravitaillement actuelle.",
            sourceURL: contractEvidenceURL,
            evidenceTitle: "IDFM–RATP · tableau ligne–centre 2025–2026",
            idfmBusContractID: "45",
            additionalEvidenceTitle: "RATP Group · répartition des lignes du lot 45 par centre-bus · 29 mars 2022",
            additionalEvidenceURL: ratpDSP45DepotSplitURL,
            supportingEvidence: [
                DepotSiteEvidenceLink(
                    title: "Légifrance · surface patrimoniale du centre bus Saint-Maur Créteil · 2011",
                    url: URL(string: "https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000024998705")!
                ),
                DepotSiteEvidenceLink(
                    title: "Préfecture du Val-de-Marne · arrêté ICPE n° 2023/01781 · 12 mai 2023",
                    url: URL(string: "https://www.val-de-marne.gouv.fr/contenu/telechargement/23283/180658/file/RAA%20sp%C3%A9cial%20N%C2%B067%20du%2015%20mai%20et%2016%20mai%202023.pdf")!
                ),
                DepotSiteEvidenceLink(
                    title: "Préfecture · étude de sécurité incendie du centre de Saint-Maur · 2023",
                    url: URL(string: "https://www.seine-saint-denis.gouv.fr/index.php/contenu/telechargement/23562/190970/file/4_PJ_C_Memoire_de_r%C3%A9ponse_vdef2_18-10-2023_complet.pdf")!
                ),
                DepotSiteEvidenceLink(
                    title: "IDFM · centres bus convertis au biométhane · février 2025",
                    url: URL(string: "https://presse.iledefrance-mobilites.fr/le-centre-operationnel-bus-point-du-jour-passe-a-lelectrique/?lang=fr")!
                ),
                DepotSiteEvidenceLink(
                    title: "RATP Cap · offre maintenance · transition électrique annoncée à Saint-Maur",
                    url: URL(string: "https://carrieres.ratpcap.com/job/SAINT-MAUR-Agent-d%26apos%3Binterface-maintenance-exploitation-bus-FH-93-94100/1355315155/")!
                )
            ],
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
            ),
            facilityObservations: [DepotFacilityEvidenceCatalog.saintMaurHistoric]
        ),
        DepotLineRosterSite(
            id: "neuilly-plaisance",
            name: "COB Neuilly-Plaisance",
            locality: "Neuilly-Plaisance",
            status: "COB recensé · lignes DSP45 à ventiler",
            availability: .operational,
            evidenceNote: "La brochure RATP d’avril 2026 identifie le COB Neuilly-Plaisance parmi ses sites opérationnels et indique séparément que la DSP 45 Boucles de Marne est exploitée par RATP Cap IDF depuis le 1er novembre 2025. Le rapport des comptes administratifs IDFM 2024 mentionne une convention de financement de 12,1 M€ pour adapter Neuilly-Plaisance aux bus à batteries électriques. La page RATP Bus2025 modifiée le 26 juin 2026 liste Neuilly Bords de Marne parmi les centres adaptés pour accueillir 100 % de bus électriques; elle précise toutefois que, début 2026, dix centres étaient convertis à l’électrique et quatre sites restaient en travaux, sans les identifier. Ces sources établissent une convention de financement et un périmètre d’adaptation, pas l’achèvement des travaux à Neuilly-Plaisance, le nombre ou la puissance des bornes, ni la capacité électrique ou de remisage actuelle. Une offre RATP Cap consultée le 24 octobre 2026 décrit aussi une transition vers une flotte 100 % électrique, sans date de publication visible. Aucune de ces sources ne répartit les lignes du contrat entre les COB. En 2022, RATP Group comptait treize lignes du centre-bus de Bords-de-Marne pour le lot 45, sans donner leurs numéros dans cet article ni établir les affectations après le transfert. Le tableau ligne–centre de l’ancien contrat IDFM–RATP reste borné au 31 octobre 2025.",
            sourceURL: ratpSeineSaintDenisBrochure2026URL,
            evidenceTitle: "RATP · présence en Seine-Saint-Denis · avril 2026",
            idfmBusContractID: "45",
            additionalEvidenceTitle: "RATP Group · répartition des lignes du lot 45 par centre-bus · 29 mars 2022",
            additionalEvidenceURL: ratpDSP45DepotSplitURL,
            supportingEvidence: [
                DepotSiteEvidenceLink(
                    title: "IDFM · convention de financement pour l’adaptation électrique · 2024",
                    url: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/aADLYOvxEdbNPLZd_RapportCA2024.pdf")!
                ),
                DepotSiteEvidenceLink(
                    title: "RATP · centres adaptés aux bus 100 % électriques · Bus2025",
                    url: URL(string: "https://www.ratp.fr/programme-bus2025")!
                ),
                DepotSiteEvidenceLink(
                    title: "RATP Cap · offre mécanicien · transition électrique annoncée à Neuilly-Plaisance",
                    url: ratpCapNeuillyPlaisanceElectricTransitionURL
                )
            ],
            fleetObservation: DepotFleetObservation(
                totalVehicleCount: 201,
                energyCounts: [
                    DepotFleetEnergyCount(energyTitle: "Diesel", vehicleCount: 149),
                    DepotFleetEnergyCount(energyTitle: "Hybride", vehicleCount: 52)
                ],
                averageFleetAgeYears: 12.7,
                airConditionedVehicleSharePercent: 0,
                reviewedOnLabel: "Résultat indexé consulté le 23 octobre 2026 · actualisation source non datée",
                sourceFreshnessNote: "Le résultat de recherche du 23 octobre donne 201 véhicules, 149 diesel et 52 hybrides. L’ouverture textuelle de la même fiche renvoie encore un instantané antérieur à 200 véhicules, 148 diesel et 52 hybrides; TC Infos ne date pas l’inventaire.",
                limitationNote: "Comptage de véhicules observés; il ne donne ni la capacité maximale du site, ni ses postes d’atelier ou de ravitaillement, ni les lignes auxquelles chaque véhicule est affecté.",
                sourceTitle: "TC Infos · parc actuel du COB Neuilly-Plaisance",
                sourceURL: neuillyDepotURL,
                comparisonNote: "Le résultat indexé récent de la fiche détaillée et le récapitulatif de l’exploitant concordent à 201 véhicules; la fiche détaillée y donne 149 diesel, 52 hybrides, 12,7 ans d’âge moyen et 0 % de véhicules climatisés. L’ouverture textuelle de la fiche affiche encore une capture antérieure à 200 véhicules (148 diesel, 52 hybrides, 12,6 ans). La source n’horodate pas son inventaire; le compte le plus récent reste une observation, pas une capacité certifiée.",
                comparisonSourceTitle: "TC Infos · récapitulatif de l’exploitant (201 véhicules)",
                comparisonSourceURL: URL(string: "https://tc-infos.fr/exploitant/2975")!
            ),
            facilityObservations: [DepotFacilityEvidenceCatalog.neuillyPlaisanceHistorical],
            chargingInfrastructureObservation: DepotChargingInfrastructureEvidenceCatalog.neuillyPlaisance
        ),
        DepotLineRosterSite(
            id: "freres-lumiere",
            name: "Site Frères-Lumière",
            locality: "Neuilly-sur-Marne · ZI des Chanoux",
            status: "COB RATP Cap · correspondance corroborée · lignes à ventiler",
            availability: .operational,
            evidenceNote: "Le schéma de principe IDFM situe un COB loué rue des Frères-Lumière à partir du 1er juillet 2023 pour remiser une partie des articulés de la 113. Le répertoire SIRENE officiel indique qu’un établissement secondaire RATP Cap Boucles de Marne, SIRET 937 651 818 00059, actif depuis le 1er novembre 2025, exerce une activité de transport de voyageurs au 47 rue des Frères-Lumière. L’avis de situation INSEE consulté confirme cette adresse, avec une situation au 13 décembre 2025. La carte RATP Cap de mars 2026 marque un COB dans la commune sans en préciser l’adresse. Une offre de recrutement consultée le 24 octobre 2026 cite Neuilly-sur-Marne comme l’un des trois centres possibles, sans date de publication visible; elle n’identifie pas le site par son adresse ni ne répartit les lignes. Le croisement des sources IDFM, SIRENE et RATP Cap fait du 47 rue des Frères-Lumière la meilleure correspondance documentée; c’est un rapprochement fortement étayé, mais la carte ne nomme pas l’adresse et l’établissement SIRENE ne constitue pas à lui seul une preuve de dépôt d’autobus. Les rattachements actuels des lignes restent à vérifier. Le remisage partiel de la 113 est documenté uniquement jusqu’au transfert du 31 octobre 2025; les véhicules TC Infos observés sur ce site ne révèlent pas quels services en partent et ne donnent pas sa capacité maximale. Le futur COB du projet IDFM vers 2030 est un site distinct.",
            sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/1c3d876c-ef6f-4f9f-ae60-8756ae273ba7_RAA_153-2.pdf"),
            documentedAddress: "47 rue des Frères-Lumière, Neuilly-sur-Marne · emprise IDFM 41–47",
            evidenceTitle: "IDFM · décision de bail et remisage partiel de la 113 à Frères-Lumière · 2023",
            additionalEvidenceTitle: "RATP Cap · carte des réseaux et COB · mars 2026 · symbole en commune sans adresse",
            additionalEvidenceURL: URL(string: "https://www.ratpcap.com/wp-content/uploads/2026/03/Carte_Reseaux_RATPCap_mars2026_compressed.pdf"),
            supportingEvidence: [
                DepotSiteEvidenceLink(
                    title: "IDFM · schéma de principe · COB loué rue des Frères-Lumière et remisage partiel de la 113 · 2023",
                    url: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/72537622-01f3-44cc-ae73-4f1771f19470_BBM_SDP_VFF.pdf")!
                ),
                DepotSiteEvidenceLink(
                    title: "INSEE · avis de situation SIRENE · RATP Cap Boucles de Marne, SIRET 937 651 818 00059 · situation au 13 décembre 2025",
                    url: URL(string: "https://api-avis-situation-sirene.insee.fr/identification/pdf/93765181800059")!
                ),
                DepotSiteEvidenceLink(
                    title: "Répertoire national des entreprises · établissement RATP Cap, SIRET 937 651 818 00059 · consulté le 24 octobre 2026",
                    url: URL(string: "https://recherche-entreprises.api.gouv.fr/search?q=93765181800059")!
                ),
                DepotSiteEvidenceLink(
                    title: "IDFM · présélection du lot 45 · trois COB dont un nouveau site à Neuilly-sur-Marne · 24 octobre 2024",
                    url: idfmBordsDeMarneCOBPreselectionURL
                ),
                DepotSiteEvidenceLink(
                    title: "IDFM · lot 45 · deux COB existants et un troisième à aménager à Neuilly-sur-Marne · 6 novembre 2024",
                    url: idfmBordsDeMarneCOBAwardURL
                ),
                DepotSiteEvidenceLink(
                    title: "RATP Cap · annonce d’attribution du lot 45 · deux centres à Saint-Maur et Neuilly-Plaisance · 12 novembre 2024",
                    url: ratpCapDSP45AwardURL
                ),
                DepotSiteEvidenceLink(
                    title: "RATP Group · rapport annuel 2025 · trois COB et 320 véhicules à Boucles de Marne",
                    url: ratpBouclesDeMarne2025AnnualReportURL
                ),
                DepotSiteEvidenceLink(
                    title: "RATP Cap · offre de conducteur · trois COB possibles et 31 lignes annoncées · consultée le 24 octobre 2026, page non datée",
                    url: URL(string: "https://carrieres.ratpcap.com/job/Neuilly-Plaisance-Conducteur-de-bus-FH-93-93360/1344932755/")!
                )
            ],
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
        contractSite("le-mesnil-amelot", "Le Mesnil-Amelot", "Le Mesnil-Amelot", dsp: "DSP 39", operatorName: nil, serviceFrom: "1er mars 2026", sourceTitle: "IDFM · calendrier des centres DSP du 22 mai 2024", sourceURL: idfmDepotSchedule2024URL),
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
        directorySite(
            "villiers-le-bel",
            "Villiers-le-Bel",
            "Villiers-le-Bel",
            address: "23 avenue des Entrepreneurs",
            dspID: "43",
            facilityObservations: [DepotFacilityEvidenceCatalog.villiersLeBelCurrent]
        ),
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
        dspID: String?,
        facilityObservations: [DepotFacilityObservation] = []
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
            idfmBusContractID: dspID,
            facilityObservations: facilityObservations
        )
    }

    private static func contractSite(
        _ id: String,
        _ name: String,
        _ locality: String,
        dsp: String,
        operatorName: String?,
        serviceFrom: String?,
        sourceTitle: String,
        sourceURL: URL,
        isPlanned: Bool = false
    ) -> DepotLineRosterSite {
        let operatorLabel = operatorName ?? "exploitant à vérifier"
        let status = isPlanned
            ? "Site annoncé pour \(dsp) · \(operatorLabel)"
            : "COB nommé pour \(dsp) · \(operatorLabel)"
        let timing = serviceFrom.map { " · mise en service du lot annoncée le \($0)" } ?? ""
        let note = isPlanned
            ? "IDFM cite ce site dans le cadre de \(dsp). Il reste annoncé comme futur/projet et n’est pas traité comme un dépôt opérationnel. Aucune ligne ne lui est affectée dans le jeu."
            : "IDFM nomme ce COB dans le périmètre de \(dsp) pour \(operatorLabel)\(timing). Cette source confirme le centre dans le lot, mais ne répartit pas les lignes du contrat entre les différents COB."
        return DepotLineRosterSite(
            id: id,
            name: name,
            locality: locality,
            status: status,
            availability: isPlanned ? .planned : .operational,
            evidenceNote: note,
            sourceURL: sourceURL,
            evidenceTitle: sourceTitle,
            idfmBusContractID: String(dsp.dropFirst(4)),
            operatorName: operatorName
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
        let primarySourceURL = preferred.sourceURL ?? supplemental.sourceURL
        var supportingEvidence: [DepotSiteEvidenceLink] = []
        var seenEvidenceURLs = Set([primarySourceURL?.absoluteString, additionalEvidenceURL?.absoluteString].compactMap { $0 })
        for source in preferred.evidenceLinks + supplemental.evidenceLinks where seenEvidenceURLs.insert(source.url.absoluteString).inserted {
            supportingEvidence.append(source)
        }

        return DepotLineRosterSite(
            id: preferred.id,
            name: preferred.name,
            locality: preferred.locality,
            status: currentSite.status,
            availability: currentSite.availability,
            evidenceNote: evidenceNote,
            sourceURL: primarySourceURL,
            documentedAddress: preferred.documentedAddress ?? supplemental.documentedAddress,
            evidenceTitle: preferred.evidenceTitle ?? supplemental.evidenceTitle,
            idfmBusContractID: preferred.idfmBusContractID ?? supplemental.idfmBusContractID,
            operatorName: preferred.operatorName == supplemental.operatorName
                ? preferred.operatorName
                : (preferred.operatorName == nil ? supplemental.operatorName : supplemental.operatorName == nil ? preferred.operatorName : nil),
            additionalEvidenceTitle: additionalEvidenceTitle,
            additionalEvidenceURL: additionalEvidenceURL,
            supportingEvidence: supportingEvidence,
            fleetObservation: preferred.fleetObservation ?? supplemental.fleetObservation,
            facilityObservations: facilityObservations,
            chargingInfrastructureObservation: preferred.chargingInfrastructureObservation ?? supplemental.chargingInfrastructureObservation
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

    // Shared by depot-site records above; line-roster evidence lives in the validated CSV manifest.
    private static let futureBBDMPrinciplesURL = URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/principes-amenagement-fonctionnement-bbdm")!
    private static let futureBBDMConsultationURL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/26367fc3-7fd7-4c5e-9c1c-6e2393bd9c3f_2023.10.12%2B-%2BDossier%2Bde%2Bconcertation%2BMECDU%2BBBM.pdf")!
    private static let neuillyDepotURL = URL(string: "https://tc-infos.fr/exploitant/2975/depot/4663")!

    static let rows: [DepotLineRosterRow] = DepotLineRosterManifestCatalog.state.rosterRows

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
