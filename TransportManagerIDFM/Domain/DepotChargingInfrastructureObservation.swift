import Foundation

struct DepotChargingInfrastructureObservation: Hashable, Sendable, Identifiable {
    let id: String
    let periodLabel: String
    let statusLabel: String
    let plannedChargingPointCount: Int
    let declaredChargingPointCount: Int
    let nominalPowerKilowatts: Int
    let operationalNote: String
    let limitationNote: String
    let sourceTitle: String
    let sourceURL: URL
    let orderTitle: String
    let orderURL: URL

    var metricLabels: [String] {
        [
            "\(plannedChargingPointCount) points prévus dans le dossier",
            "\(declaredChargingPointCount) points déclarés à l’inspection",
            "\(nominalPowerKilowatts) kW par point de charge"
        ]
    }
}

enum DepotChargingInfrastructureEvidenceCatalog {
    static let neuillyPlaisance = DepotChargingInfrastructureObservation(
        id: "neuilly-plaisance-dimensionnement-icpe-2023",
        periodLabel: "Dossier ICPE · rapport d’inspection du 16 octobre 2023 · arrêté préfectoral du 29 avril 2024",
        statusLabel: "Dimensionnement réglementaire · mise en service à confirmer",
        plannedChargingPointCount: 202,
        declaredChargingPointCount: 205,
        nominalPowerKilowatts: 100,
        operationalNote: "Le rapport d’inspection du Centre bus Bords de Marne, au 32 boulevard Galliéni à Neuilly-Plaisance, décrit un projet de 202 points de charge et 205 points déclarés, d’une puissance unitaire de 100 kW. L’arrêté préfectoral précise que ses prescriptions s’appliquent à la mise en service des installations.",
        limitationNote: "Ces nombres décrivent le dossier réglementaire, pas un inventaire des bornes installées ou actives. La date de mise en service, le raccordement disponible et la capacité opérationnelle actuelle du dépôt ne sont pas établis. Aucun total de puissance du site n’est déduit.",
        sourceTitle: "Géorisques · rapport d’inspection ICPE · Centre bus Bords de Marne",
        sourceURL: URL(string: "https://www.georisques.gouv.fr/webappReport/ws/installations/inspection/Gd7NBjMbn9bTbdo61OSzKXseEmfvRe5L")!,
        orderTitle: "Préfecture de Seine-Saint-Denis · arrêté n° 2024-1312 du 29 avril 2024",
        orderURL: URL(string: "https://www.seine-saint-denis.gouv.fr/Actions-de-l-Etat/Environnement-risques-et-nuisances/1-Installations-classees-pour-la-protection-de-l-environnement/Installations-a-declaration/Arretes-prefectoraux/AP-n-2024-1312-du-29-avril-2024-RATP-sise-32-boulevard-Gallieni-NEUILLY-PLAISANCE")!
    )
}
