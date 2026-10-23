import Foundation

struct DepotReference: Identifiable, Hashable {
    let id: String
    let name: String
    let locality: String
    let address: String
    let evidenceLabel: String
    let addressSourceTitle: String
    let addressSourceURL: URL
}

enum DepotEnergyEvidenceStatus: String, Codable, Hashable, Sendable {
    case operationallyConfirmed
    case intentDocumented
    case unknown
    case gameplayAssumption
}

struct DepotEnergyEvidenceLink: Identifiable, Hashable, Sendable {
    let title: String
    let url: URL

    var id: String { url.absoluteString }
}

struct DepotEnergyEvidence: Hashable, Sendable {
    let status: DepotEnergyEvidenceStatus
    let note: String
    let dateLabel: String?
    let sources: [DepotEnergyEvidenceLink]

    var statusTitle: String {
        switch status {
        case .operationallyConfirmed: "Énergie attestée en exploitation"
        case .intentDocumented: "Orientation documentée · mise en service à vérifier"
        case .unknown: "Équipement non documenté"
        case .gameplayAssumption: "Hypothèse de départ du jeu"
        }
    }
}

enum DepotEnergyEvidenceCatalog {
    static func evidence(depotID: String, infrastructure: DepotEnergyInfrastructureKind) -> DepotEnergyEvidence {
        switch (depotID, infrastructure) {
        case (_, .dieselFueling):
            DepotEnergyEvidence(
                status: .gameplayAssumption,
                note: "Le jeu fournit un ravitaillement diesel initial pour permettre le démarrage ; cette installation n’est pas attestée dans la fiche du site.",
                dateLabel: nil,
                sources: []
            )
        case ("saint-maur", .biomethaneFueling):
            DepotEnergyEvidence(
                status: .operationallyConfirmed,
                note: "Île-de-France Mobilités cite Saint-Maur parmi les centres déjà convertis au biométhane au 5 février 2025. Le nombre de postes, le débit et la capacité de bus ne sont pas publiés.",
                dateLabel: "5 février 2025",
                sources: [
                    DepotEnergyEvidenceLink(
                        title: "IDFM · Saint-Maur dans les centres convertis au biométhane",
                        url: URL(string: "https://presse.iledefrance-mobilites.fr/le-centre-operationnel-bus-point-du-jour-passe-a-lelectrique/?lang=fr")!
                    ),
                    DepotEnergyEvidenceLink(
                        title: "IDFM · adresse du centre bus de Saint-Maur",
                        url: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/56c73684-a7ed-4797-8d62-900da8787c53_RAA%2B147-1_D%C3%A9lib%C3%A9rations.pdf")!
                    )
                ]
            )
        case ("neuilly-plaisance", .electricCharging):
            DepotEnergyEvidence(
                status: .intentDocumented,
                note: "La RATP classe Neuilly Bords de Marne dans son groupe de centres orientés vers l’électrique. IDFM relie le centre Bords de Marne à l’ancien centre de la Maltournée à Neuilly-Plaisance. La page RATP signale encore des conversions en cours début 2026 sans préciser le statut de ce site : sa mise sous tension, ses bornes et sa capacité restent à vérifier.",
                dateLabel: "orientation publiée en 2026 · exploitation non confirmée",
                sources: [
                    DepotEnergyEvidenceLink(
                        title: "RATP · programme bus2025 et centres orientés par énergie",
                        url: URL(string: "https://www.ratp.fr/programme-bus2025")!
                    ),
                    DepotEnergyEvidenceLink(
                        title: "IDFM · centre Bords de Marne / ancienne Maltournée à Neuilly-Plaisance",
                        url: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/72537622-01f3-44cc-ae73-4f1771f19470_BBM_SDP_VFF.pdf")!
                    ),
                    DepotEnergyEvidenceLink(
                        title: "IDFM · projet de conversion et limites du COB existant",
                        url: URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/questions/quelles-seront-les-caracteristiques-du-materiel-roulant")!
                    )
                ]
            )
        default:
            DepotEnergyEvidence(
                status: .unknown,
                note: "Aucune source publique recensée ici ne confirme cet équipement pour le dépôt sélectionné. L’absence de preuve n’établit pas une incompatibilité.",
                dateLabel: nil,
                sources: []
            )
        }
    }
}

struct PlannedDepotReference: Identifiable, Hashable {
    let id: String
    let name: String
    let locality: String
    let locationDescription: String
    let statusDescription: String
    let sourceTitle: String
    let sourceURL: URL
}

enum DepotRegistryEntryKind: String, Hashable, Identifiable {
    case confirmedAlias
    case datedAddressReference
    case siteNameCandidate
    case unclassifiedLabel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .confirmedAlias: "Correspondance documentée"
        case .datedAddressReference: "Adresse publiée par IDFM · statut actuel à vérifier"
        case .siteNameCandidate: "Nom de site à vérifier"
        case .unclassifiedLabel: "Libellé à qualifier"
        }
    }

    var explanation: String {
        switch self {
        case .confirmedAlias:
            "Le libellé de la liste d’amorçage correspond à un centre bus identifié dans une source IDFM."
        case .datedAddressReference:
            "Une annexe IDFM publiée le 7 décembre 2022 associe ce nom à une adresse. Elle ne confirme pas son statut actuel ni ses relations réseau, contrat ou exploitant."
        case .siteNameCandidate:
            "Le cahier des charges le donne comme nom de site possible ; son existence actuelle, son adresse et son usage restent à établir."
        case .unclassifiedLabel:
            "Le cahier des charges demande de déterminer s’il s’agit d’un site, d’un exploitant, d’un réseau, d’un contrat ou d’un nom historique."
        }
    }
}

struct DepotRegistryEntry: Identifiable, Hashable {
    let id: String
    let originalLabel: String
    let kind: DepotRegistryEntryKind
    let linkedDepotID: String?
    let documentedAddress: String?
    let evidenceTitle: String?
    let evidenceURL: URL?
}

enum RegionalDepotRegistry {
    private static let addressSourceTitle = "IDFM · Annexe des centres bus et adresses"
    private static let addressSourceURL = URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/56c73684-a7ed-4797-8d62-900da8787c53_RAA%2B147-1_D%C3%A9lib%C3%A9rations.pdf")!

    static let seedEntries: [DepotRegistryEntry] = [
        datedSite("asnieres", "Asnières", address: "19 avenue Gabriel Péri, Asnières-sur-Seine"),
        datedSite("aubervilliers", "Aubervilliers", address: "14–26 rue de la Haie-Coq, Aubervilliers"),
        datedSite("belliard", "Belliard", address: "7–33 rue Belliard, Paris 18e"),
        confirmedAlias("bords-de-marne", "Bords de Marne", depotID: "neuilly-plaisance"),
        site("championnet", "Championnet"),
        datedSite("charlebourg", "Charlebourg", address: "31–41 boulevard National, La Garenne-Colombes"),
        datedSite("corentin", "Corentin", address: "71–73 rue du Père Corentin, Paris 14e", sourceName: "Montrouge Corentin"),
        datedSite("creteil", "Créteil", address: "6 avenue du Maréchal Foch / 1 route de la Pompadour / rue de la Haute Quinte, Créteil"),
        datedSite("croix-nivert", "Croix-Nivert", address: "6–18 rue Charles Lecocq, Paris 15e"),
        datedSite("flandre", "Flandre", address: "168 avenue Jean Jaurès, Pantin", sourceName: "Flandres"),
        datedSite("fontenay", "Fontenay", address: "1–23 avenue de la Division Leclerc, Fontenay-aux-Roses"),
        datedSite("ivry", "Ivry", address: "36–40 rue Pierre et Marie Curie, Ivry-sur-Seine", sourceName: "Quais de Seine d’Ivry"),
        datedSite("lagny", "Lagny", address: "18–20 rue des Pyrénées et 67 rue de Lagny, Paris 20e"),
        datedSite("lebrun", "Lebrun", address: "21–29 rue Le Brun, Paris 13e", sourceName: "Quais de Seine Lebrun"),
        datedSite("les-lilas", "Les Lilas", address: "1–29 rue Floréal, Les Lilas"),
        datedSite("les-pavillons", "Les Pavillons", address: "132 avenue de Rome, Les Pavillons-sous-Bois"),
        datedSite("malakoff", "Malakoff", address: "92–120 avenue du 12 février 1934, Malakoff"),
        datedSite("massy", "Massy", address: "ZAC du Pérou, 400–404 avenue du Maréchal Leclerc, Massy"),
        site("michelet", "Michelet"),
        datedSite("nanterre", "Nanterre", address: "9–31 rue Kléber, Nanterre"),
        datedSite("pleyel", "Pleyel", address: "219–225 boulevard Anatole France, Saint-Denis"),
        datedSite("point-du-jour", "Point du Jour", address: "6–8 place de la Porte de Saint-Cloud, Paris 16e"),
        datedSite("saint-denis", "Saint-Denis", address: "1–5 avenue de Stalingrad et 39/41 avenue Lénine, Saint-Denis"),
        confirmedAlias("saint-maur", "Saint-Maur", depotID: "saint-maur"),
        datedSite("thiais", "Thiais", address: "12 rue du Bas Marin, Thiais"),
        datedSite("vitry", "Vitry", address: "141/155 boulevard de Stalingrad, Vitry-sur-Seine", sourceName: "Vitry-sur-Seine"),
        datedSite("villiers-le-bel", "Villiers le Bel", address: "ZAC des Tissonvilliers III, Villiers-le-Bel"),
        unclassified("voo", "VOO"),
        unclassified("gmr", "GMR"),
        unclassified("bus-stl", "BUS-STL"),
        unclassified("ratp-com", "RATP-COM"),
        unclassified("ratp-dev", "RATP-DEV"),
        unclassified("nanterre-transdev", "Nanterre Transdev")
    ]

    // One additional center appears in the dated IDFM annex but not in the user's seed labels.
    static let additionalHistoricalEntries: [DepotRegistryEntry] = [
        datedSite("bussy-annex-2022", "Bussy", address: "1 allée des Boules, Bussy-Saint-Martin")
    ]

    /// Entries that can be opened as physical-site records. Operator, network and
    /// unclassified labels remain visible in the audit but are not presented as depots.
    static var browseableEntries: [DepotRegistryEntry] {
        (seedEntries.filter { $0.kind != .unclassifiedLabel } + additionalHistoricalEntries)
            .sorted { $0.originalLabel.localizedStandardCompare($1.originalLabel) == .orderedAscending }
    }

    private static func confirmedAlias(_ id: String, _ label: String, depotID: String) -> DepotRegistryEntry {
        DepotRegistryEntry(
            id: id,
            originalLabel: label,
            kind: .confirmedAlias,
            linkedDepotID: depotID,
            documentedAddress: nil,
            evidenceTitle: addressSourceTitle,
            evidenceURL: addressSourceURL
        )
    }

    private static func datedSite(_ id: String, _ label: String, address: String, sourceName: String? = nil) -> DepotRegistryEntry {
        DepotRegistryEntry(
            id: id,
            originalLabel: label,
            kind: .datedAddressReference,
            linkedDepotID: nil,
            documentedAddress: address,
            evidenceTitle: sourceName.map { "Annexe IDFM · \($0) · RAA 147-1 (7 décembre 2022)" }
                ?? "Annexe IDFM · RAA 147-1 (7 décembre 2022)",
            evidenceURL: addressSourceURL
        )
    }

    private static func site(_ id: String, _ label: String) -> DepotRegistryEntry {
        DepotRegistryEntry(
            id: id,
            originalLabel: label,
            kind: .siteNameCandidate,
            linkedDepotID: nil,
            documentedAddress: nil,
            evidenceTitle: nil,
            evidenceURL: nil
        )
    }

    private static func unclassified(_ id: String, _ label: String) -> DepotRegistryEntry {
        DepotRegistryEntry(
            id: id,
            originalLabel: label,
            kind: .unclassifiedLabel,
            linkedDepotID: nil,
            documentedAddress: nil,
            evidenceTitle: nil,
            evidenceURL: nil
        )
    }
}

struct ScenarioNetworkChange: Identifiable, Hashable {
    let id: String
    let effectiveDate: String
    let title: String
    let details: [String]
    let sourceTitle: String
    let sourceURL: URL
}

struct ScenarioLineCoverageEntry: Identifiable, Hashable {
    let lineName: String
    let activeRouteIDs: [String]

    var id: String { "\(lineName):\(activeRouteIDs.joined(separator: ","))" }
    var isPresent: Bool { !activeRouteIDs.isEmpty }
}

struct ScenarioLineCoverage: Hashable {
    let entries: [ScenarioLineCoverageEntry]
    let unlistedActiveEntries: [ScenarioLineCoverageEntry]

    var matchedCount: Int { entries.filter(\.isPresent).count }
    var missingLineNames: [String] { entries.filter { !$0.isPresent }.map(\.lineName) }
    var unlistedActiveRouteCount: Int {
        unlistedActiveEntries.reduce(0) { $0 + $1.activeRouteIDs.count }
    }

    static func compare(
        expectedLineNames: [String],
        against routes: [GTFSRouteSummary]
    ) -> ScenarioLineCoverage {
        let expectedCanonicalNames = Set(expectedLineNames.map(canonicalLineName))
        let routesByName = Dictionary(grouping: routes.filter { !$0.shortName.isEmpty }) {
            canonicalLineName($0.shortName)
        }
        let entries = expectedLineNames.map { lineName in
            let matchingRoutes = routesByName[canonicalLineName(lineName)] ?? []
            return ScenarioLineCoverageEntry(
                lineName: lineName,
                activeRouteIDs: Array(Set(matchingRoutes.map(\.routeID))).sorted()
            )
        }
        let unlistedRoutes = routes.filter { route in
            let canonicalName = canonicalLineName(route.shortName)
            return canonicalName.isEmpty || !expectedCanonicalNames.contains(canonicalName)
        }
        let unlistedGroups = Dictionary(grouping: unlistedRoutes) { route in
            let canonicalName = canonicalLineName(route.shortName)
            return canonicalName.isEmpty ? "route:\(route.routeID)" : "line:\(canonicalName)"
        }
        var unlistedActiveEntries: [ScenarioLineCoverageEntry] = []
        for group in unlistedGroups.values {
            let sortedRoutes = group.sorted { $0.routeID < $1.routeID }
            guard let firstRoute = sortedRoutes.first else { continue }
            let lineName = canonicalLineName(firstRoute.shortName).isEmpty
                ? "Sans nom court · \(firstRoute.displayName)"
                : firstRoute.shortName
            unlistedActiveEntries.append(ScenarioLineCoverageEntry(
                lineName: lineName,
                activeRouteIDs: Array(Set(sortedRoutes.map(\.routeID))).sorted()
            ))
        }
        unlistedActiveEntries.sort {
            $0.lineName.localizedStandardCompare($1.lineName) == .orderedAscending
        }

        return ScenarioLineCoverage(entries: entries, unlistedActiveEntries: unlistedActiveEntries)
    }

    static func canonicalLineName(_ name: String) -> String {
        name.uppercased().filter { $0.isLetter || $0.isNumber }
    }
}

struct ScenarioLineChecklist: Hashable {
    let title: String
    let lineNames: [String]
    let sourceTitle: String?
    let sourceURL: URL?
}

struct ScenarioDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let networkName: String
    let summary: String
    let contractID: String
    let idfmBusContractID: String
    let operatorName: String
    let contractStartDate: String
    let contractEndDate: String
    let contractDurationYears: Int
    let contractExtensionYears: Int
    let contractReportedLineCount: Int
    let contractCOBCount: Int
    let contractPlannedCOBCount: Int
    let contractFleetCount: Int
    let contractCommercialKilometers: Int
    let contractSourceTitle: String
    let contractSourceURL: URL
    let operatorReportDurationYears: Int
    let operatorReportLineCount: Int
    let operatorReportCOBCount: Int
    let operatorReportFleetCount: Int
    let operatorReportCommercialKilometers: Int
    let operatorReportSourceTitle: String
    let operatorReportSourceURL: URL
    let budgetEngagementEuro: Int
    let budgetSourceTitle: String
    let budgetSourceURL: URL
    let financialReference: ScenarioFinancialReference
    let referenceActiveLineCount: Int
    let referenceNoctilienCount: Int
    let baselineDateLabel: String
    let baselineLineNames: [String]
    let postReorganizationLineNames: [String]
    let referenceDepots: [DepotReference]
    let plannedDepots: [PlannedDepotReference]
    let networkChanges: [ScenarioNetworkChange]

    static let bordsDeMarne = ScenarioDefinition(
        id: "bords-de-marne",
        name: "Bords de Marne",
        networkName: "Réseau de bus Bords de Marne",
        summary: "Périmètre de la DSP 45, avec une offre versionnée par date et des rattachements aux centres bus documentés séparément.",
        contractID: "DSP 45",
        idfmBusContractID: "45",
        operatorName: "RATP Cap Île-de-France",
        contractStartDate: "1er novembre 2025",
        contractEndDate: "31 octobre 2031",
        contractDurationYears: 6,
        contractExtensionYears: 2,
        contractReportedLineCount: 29,
        contractCOBCount: 2,
        contractPlannedCOBCount: 1,
        contractFleetCount: 315,
        contractCommercialKilometers: 13_900_000,
        contractSourceTitle: "IDFM · attribution de la DSP 45",
        contractSourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/mise-en-concurrence-des-transports-franciliens/?lang=fr")!,
        operatorReportDurationYears: 8,
        operatorReportLineCount: 31,
        operatorReportCOBCount: 3,
        operatorReportFleetCount: 320,
        operatorReportCommercialKilometers: 18_600_000,
        operatorReportSourceTitle: "Groupe RATP · rapport annuel 2025, p. 21",
        operatorReportSourceURL: URL(string: "https://ratpgroup.com/api/media/rapport-financier-et-de-durabilite-annuel-2025---groupe-ratp.pdf")!,
        budgetEngagementEuro: 28_473_705,
        budgetSourceTitle: "IDFM · budget primitif 2026, annexe B10, p. 193",
        budgetSourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/aUVvfHNYClf9og_0_MaquetteBP26.pdf")!,
        financialReference: ScenarioFinancialReference(
            facts: [
                ScenarioFinancialFact(
                    label: "Valeur de l’offre attribuée · lot 45",
                    value: "1 008 587 465 € · euros 2023 · jusqu’à 96 mois",
                    context: "Valeur publiée pour le lot 45 : 72 mois fermes et 24 mois optionnels, avec des hausses maximales de 10 % des KCC permanents et 5 % des KCC temporaires prises en compte. La notice ne précise pas le traitement de la TVA ; ce montant n’est ni une rémunération annuelle ni un encaissement constaté.",
                    sourceTitle: "TED · avis d’attribution 85449-2025",
                    sourceURL: URL(string: "https://ted.europa.eu/fr/notice/-/detail/85449-2025")!
                ),
                ScenarioFinancialFact(
                    label: "Estimation avant attribution",
                    value: "870 000 000 € HT",
                    context: "Estimation HT publiée séparément de la valeur attribuée. La valeur d’attribution tient compte des hausses maximales de KCC indiquées dans l’avis TED.",
                    sourceTitle: "TED · avis d’attribution 85449-2025",
                    sourceURL: URL(string: "https://ted.europa.eu/fr/notice/-/detail/85449-2025")!
                ),
                ScenarioFinancialFact(
                    label: "Production de référence publiée",
                    value: "13,9 millions de KCC, dont 1,6 million pour Noctilien · année 2021",
                    context: "Volume de kilomètres commerciaux de référence, sans montant de rémunération par kilomètre.",
                    sourceTitle: "TED · avis d’attribution 85449-2025",
                    sourceURL: URL(string: "https://ted.europa.eu/fr/notice/-/detail/85449-2025")!
                ),
                ScenarioFinancialFact(
                    label: "Pondération des critères d’attribution",
                    value: "Valeur économique et financière : 40 % · exploitation et qualité de l’offre : 30 % · social, sociétal et organisation : 15 % · qualité de gestion du matrimoine : 5 % · qualité de service et expérience voyageurs : 5 % · transition et continuité du service : 5 %",
                    context: "Critères de notation des offres pour l’attribution de la DSP 45. Ils décrivent la sélection du titulaire, pas les obligations financières d’exécution ni un barème de bonus ou de malus ; ils ne modifient aucune écriture de la simulation.",
                    sourceTitle: "TED · avis d’attribution 85449-2025",
                    sourceURL: URL(string: "https://ted.europa.eu/fr/notice/-/detail/85449-2025")!
                ),
                ScenarioFinancialFact(
                    label: "Part variable liée à la qualité",
                    value: "10 % du chiffre d’affaires, contre 1 % auparavant",
                    context: "Cadre général annoncé par IDFM. La communication ne donne pas le barème détaillé, les seuils ni les montants en euros de la DSP 45.",
                    sourceTitle: "IDFM · qualité de service des bus, 27 mai 2026",
                    sourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/qualite-de-service-des-bus-en-ile-de-france-une-progression-continue-au-benefice-des-voyageurs/?lang=fr")!
                ),
                ScenarioFinancialFact(
                    label: "Rémunération liée à la validation",
                    value: "30 % à partir de 2026 pour tous les bus franciliens",
                    context: "Règle générale annoncée par IDFM ; le taux unitaire et son calcul financier pour la DSP 45 ne sont pas publiés dans cette source.",
                    sourceTitle: "IDFM · plan de lutte contre la fraude, 13 février 2025",
                    sourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/lancement-du-plan-contre-la-fraude-dans-les-transports-en-commun-franciliens/?lang=fr")!
                ),
                ScenarioFinancialFact(
                    label: "Production DSP 45 rapportée",
                    value: "Supérieure à 94 % · premiers résultats publiés en mai 2026",
                    context: "Résultat observé après le démarrage de l’exploitation ; ce n’est pas un seuil contractuel ni le déclencheur d’un bonus ou d’un malus publié.",
                    sourceTitle: "IDFM · qualité de service des bus, 27 mai 2026",
                    sourceURL: URL(string: "https://presse.iledefrance-mobilites.fr/qualite-de-service-des-bus-en-ile-de-france-une-progression-continue-au-benefice-des-voyageurs/?lang=fr")!
                )
            ],
            separationNote: "Les pièces publiques consultées ne donnent pas la rémunération annuelle de la DSP 45, son échéancier de paiement ni un barème DSP 45 de bonus/malus en euros. Ces repères documentaires n’alimentent pas la trésorerie : les contributions, charges et ajustements du jeu restent des règles simulées distinctes."
        ),
        referenceActiveLineCount: 29,
        referenceNoctilienCount: 7,
        baselineDateLabel: "Liste de contrôle avant le 1er novembre 2026",
        baselineLineNames: [
            "101", "106", "107", "108", "110", "111", "112", "113", "114", "116", "118", "120", "124", "127",
            "201", "203", "210", "214", "221", "303", "306", "520", "N11", "N16", "N32", "N33", "N34", "N35", "N71"
        ],
        postReorganizationLineNames: [
            "101", "106", "107", "108", "110", "111", "112", "113", "114", "116", "118", "120", "124", "127",
            "201", "203", "210", "214", "221", "303", "306", "314", "520", "N11", "N16", "N32", "N33", "N34", "N35", "N71"
        ],
        referenceDepots: [
            DepotReference(
                id: "saint-maur",
                name: "Saint-Maur-des-Fossés",
                locality: "Val-de-Marne",
                address: "4 boulevard Maurice Berteaux, Saint-Maur-des-Fossés (94)",
                evidenceLabel: "Centre bus du lot Bords de Marne",
                addressSourceTitle: "IDFM · Annexe des centres bus et adresses",
                addressSourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/56c73684-a7ed-4797-8d62-900da8787c53_RAA%2B147-1_D%C3%A9lib%C3%A9rations.pdf")!
            ),
            DepotReference(
                id: "neuilly-plaisance",
                name: "Neuilly-Plaisance",
                locality: "Seine-Saint-Denis",
                address: "26–32 boulevard Gallieni, Neuilly-Plaisance (93)",
                evidenceLabel: "Centre bus du lot Bords de Marne",
                addressSourceTitle: "IDFM · Annexe des centres bus et adresses",
                addressSourceURL: URL(string: "https://www.iledefrance-mobilites.fr/medias/portail-idfm/56c73684-a7ed-4797-8d62-900da8787c53_RAA%2B147-1_D%C3%A9lib%C3%A9rations.pdf")!
            )
        ],
        plannedDepots: [
            PlannedDepotReference(
                id: "neuilly-sur-marne-projet",
                name: "Neuilly-sur-Marne · projet de troisième COB",
                locality: "Seine-Saint-Denis",
                locationDescription: "Site retenu dans le secteur des délaissés de l’A103, au nord de l’ex-RN34 ; l’adresse opérationnelle et les équipements restent à confirmer.",
                statusDescription: "Projet IDFM. Les travaux sont envisagés à partir de 2027 ; ce centre n’est pas traité comme un dépôt jouable.",
                sourceTitle: "IDFM · avancement du projet Bus Bords de Marne",
                sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/bus-bordsdemarne/mise-en-oeuvre-bbdm")!
            )
        ],
        networkChanges: [
            ScenarioNetworkChange(
                id: "bords-de-marne-2026-11-01",
                effectiveDate: "1er novembre 2026",
                title: "Réorganisation de plus de vingt lignes",
                details: [
                    "Création de la 314 entre Neuilly-Plaisance RER et la zone industrielle des Chanoux : du lundi au vendredi, toutes les 15 min en pointe et toutes les heures en heures creuses.",
                    "Fréquences renforcées sur les 112, 116, 118, 124, 127, 203, 214 et 303 ; amplitudes étendues sur les 116, 203 et 214.",
                    "La 116 et la 303 bénéficient aussi d’une fréquence renforcée le week-end.",
                    "La 107 circule toutes les 15 min en pointe du lundi au vendredi, toutes les 20 à 30 min le samedi et toutes les 30 min le dimanche ; la 111 passe à toutes les 8 min en pointe du lundi au vendredi.",
                    "Ajustements ponctuels d’horaires sur les 101, 106, 108, 110, 113, 114, 120 et 201.",
                    "La 210 modifie son itinéraire à Fontenay-sous-Bois et Vincennes ; les arrêts des Chanoux passent de la 214 à la 314.",
                    "Aucun changement de fonctionnement annoncé pour les 221, 306, 520, N11, N16, N32, N33, N34, N35 et N71.",
                    "La liste de contrôle de 29 noms est le périmètre de contractualisation 2025, pas le décompte des lignes actives après cette évolution. Le GTFS valide à la date de partie doit faire foi."
                ],
                sourceTitle: "IDFM · évolutions au 1er novembre 2026",
                sourceURL: URL(string: "https://www.iledefrance-mobilites.fr/actualites/locales/detail/a-compter-du-1er-novembre-2026-ile-de-france-mobil")!
            )
        ]
    )

    /// Resolves the contract label from the scenario identity that is persisted in a career.
    /// Bords de Marne keeps its richer scenario while regional careers use `idfm-contract-<ID>`.
    static func contractDisplayName(forScenarioID scenarioID: String) -> String? {
        if scenarioID == bordsDeMarne.id { return bordsDeMarne.contractID }
        let prefix = "idfm-contract-"
        guard scenarioID.hasPrefix(prefix) else { return nil }
        let identifier = String(scenarioID.dropFirst(prefix.count))
        guard !identifier.isEmpty,
              identifier.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) else { return nil }
        return "DSP \(identifier)"
    }

    /// Returns a career attached to a public, non-planned depot and its IDFM contract.
    /// Regional lots reuse the live IDFM contract roster, while Bords de Marne keeps
    /// its richer, separately documented scenario.
    static func forDepot(_ depotID: String) -> ScenarioDefinition {
        if bordsDeMarne.referenceDepots.contains(where: { $0.id == depotID }) {
            return bordsDeMarne
        }
        guard let site = DepotLineRoster.selectableSites.first(where: { $0.id == depotID }),
              site.hasPlayableContractScope,
              let contractID = site.idfmBusContractID,
              let depot = DepotCareerScope.depotReference(for: depotID) else {
            return bordsDeMarne
        }

        let sourceURL = site.sourceURL ?? URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/cob")!
        let sourceTitle = site.evidenceTitle ?? "IDFM · centre opérationnel bus"
        let operatorName = site.status
            .split(separator: "·", maxSplits: 1)
            .last
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? "Exploitant à vérifier"

        return ScenarioDefinition(
            id: DepotCareerScope.scenarioID(forContractID: contractID),
            name: "DSP \(contractID)",
            networkName: "Réseau IDFM · DSP \(contractID)",
            summary: "Carrière d’exploitation sur les lignes réelles que le référentiel IDFM rattache à la DSP \(contractID). Le contrat peut regrouper plusieurs dépôts ; la répartition exacte de chaque ligne par COB reste indiquée selon son niveau de preuve.",
            contractID: "DSP \(contractID)",
            idfmBusContractID: contractID,
            operatorName: operatorName,
            contractStartDate: "voir source IDFM",
            contractEndDate: "voir source IDFM",
            contractDurationYears: 0,
            contractExtensionYears: 0,
            contractReportedLineCount: 0,
            contractCOBCount: 0,
            contractPlannedCOBCount: 0,
            contractFleetCount: 0,
            contractCommercialKilometers: 0,
            contractSourceTitle: sourceTitle,
            contractSourceURL: sourceURL,
            operatorReportDurationYears: 0,
            operatorReportLineCount: 0,
            operatorReportCOBCount: 0,
            operatorReportFleetCount: 0,
            operatorReportCommercialKilometers: 0,
            operatorReportSourceTitle: sourceTitle,
            operatorReportSourceURL: sourceURL,
            budgetEngagementEuro: 0,
            budgetSourceTitle: sourceTitle,
            budgetSourceURL: sourceURL,
            financialReference: ScenarioFinancialReference(
                facts: [],
                separationNote: "Les barèmes de rémunération et de performance propres à cette DSP ne sont pas chargés. Les recettes et charges affichées dans cette carrière sont des règles de simulation du jeu."
            ),
            referenceActiveLineCount: 0,
            referenceNoctilienCount: 0,
            baselineDateLabel: "Le GTFS actif fait foi",
            baselineLineNames: [],
            postReorganizationLineNames: [],
            referenceDepots: DepotCareerScope.depotReferences(forContractID: contractID, including: depot),
            plannedDepots: [],
            networkChanges: []
        )
    }

    func publishedLineChecklist(at serviceDate: Date) -> ScenarioLineChecklist? {
        guard id == Self.bordsDeMarne.id else { return nil }
        let calendar = GTFSServiceDate.calendar(timeZone: GTFSServiceDate.parisTimeZone)
        let selectedDate = calendar.startOfDay(for: serviceDate)
        guard let contractStart = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1)),
              let reorganization = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)),
              let contractEndExclusive = calendar.date(from: DateComponents(year: 2031, month: 11, day: 1)),
              contractStart <= selectedDate,
              selectedDate < contractEndExclusive else { return nil }

        if selectedDate < reorganization {
            return ScenarioLineChecklist(
                title: baselineDateLabel,
                lineNames: baselineLineNames,
                sourceTitle: nil,
                sourceURL: nil
            )
        }
        return ScenarioLineChecklist(
            title: "Lignes citées dans l’avis IDFM du 13 octobre 2026 · à vérifier dans le GTFS",
            lineNames: postReorganizationLineNames,
            sourceTitle: "IDFM · évolutions au 1er novembre 2026",
            sourceURL: networkChanges.first(where: { $0.id == "bords-de-marne-2026-11-01" })?.sourceURL
        )
    }

    func isContractActive(onServiceDateKey dateKey: Int) -> Bool {
        return id == Self.bordsDeMarne.id && dateKey >= 20251101 && dateKey <= 20311031
    }
}

enum DepotCareerScope {
    static let regionalCompanyScenarioID = "idfm-regional-company"

    static func scenarioID(forContractID contractID: String) -> String {
        "idfm-contract-\(LineReferenceMatcher.canonicalIdentifier(contractID))"
    }

    static func scenarioID(forDepotID depotID: String) -> String? {
        if ScenarioDefinition.bordsDeMarne.referenceDepots.contains(where: { $0.id == depotID }) {
            return ScenarioDefinition.bordsDeMarne.id
        }
        guard let site = DepotLineRoster.selectableSites.first(where: { $0.id == depotID }),
              site.hasPlayableContractScope,
              let contractID = site.idfmBusContractID else { return nil }
        return scenarioID(forContractID: contractID)
    }

    static func depotReference(for depotID: String) -> DepotReference? {
        if let depot = ScenarioDefinition.bordsDeMarne.referenceDepots.first(where: { $0.id == depotID }) {
            return depot
        }
        guard let site = DepotLineRoster.selectableSites.first(where: { $0.id == depotID }),
              site.hasPlayableContractScope else { return nil }
        let sourceURL = site.sourceURL ?? URL(string: "https://www.iledefrance-mobilites.fr/le-reseau/projets/cob")!
        let address = site.documentedAddress ?? "\(site.name), \(site.locality), Île-de-France, France"
        return DepotReference(
            id: site.id,
            name: site.name,
            locality: site.locality,
            address: address,
            evidenceLabel: site.status,
            addressSourceTitle: site.evidenceTitle ?? "IDFM · centre opérationnel bus",
            addressSourceURL: sourceURL
        )
    }

    static func depotReferences(forContractID contractID: String, including selectedDepot: DepotReference? = nil) -> [DepotReference] {
        let normalizedContractID = LineReferenceMatcher.canonicalIdentifier(contractID)
        let contractDepots = DepotLineRoster.selectableSites
            .filter {
                $0.availability != .planned
                    && LineReferenceMatcher.canonicalIdentifier($0.idfmBusContractID ?? "") == normalizedContractID
            }
            .compactMap { depotReference(for: $0.id) }
        var byID = Dictionary(uniqueKeysWithValues: contractDepots.map { ($0.id, $0) })
        if let selectedDepot { byID[selectedDepot.id] = selectedDepot }
        return byID.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func supports(scenarioID expectedScenarioID: String, depotID: String) -> Bool {
        if expectedScenarioID == regionalCompanyScenarioID {
            return depotReference(for: depotID) != nil
        }
        return scenarioID(forDepotID: depotID) == expectedScenarioID && depotReference(for: depotID) != nil
    }
}

struct ScenarioFinancialFact: Identifiable, Hashable {
    let label: String
    let value: String
    let context: String
    let sourceTitle: String
    let sourceURL: URL

    var id: String { label }
}

struct ScenarioFinancialReference: Hashable {
    let facts: [ScenarioFinancialFact]
    let separationNote: String
}
