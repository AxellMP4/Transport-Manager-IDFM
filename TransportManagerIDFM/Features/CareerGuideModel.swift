import Foundation

enum CareerGuideDestination: String, CaseIterable, Identifiable, Sendable {
    case network
    case dispatch
    case operations
    case incidents
    case reports

    var id: Self { self }

    var title: String {
        switch self {
        case .network: "Ouvrir le réseau"
        case .dispatch: "Affecter un départ"
        case .operations: "Suivre l’exploitation"
        case .incidents: "Voir les incidents"
        case .reports: "Consulter les bilans"
        }
    }

    var systemImage: String {
        switch self {
        case .network: "point.topleft.down.to.point.bottomright.curvepath"
        case .dispatch: "tram.fill"
        case .operations: "speedometer"
        case .incidents: "wrench.and.screwdriver"
        case .reports: "chart.bar"
        }
    }
}

struct CareerGuideChapter: Equatable, Hashable, Identifiable, Sendable {
    let id: Int
    let title: String
    let summary: String
    let destinations: [CareerGuideDestination]

    static let all: [CareerGuideChapter] = [
        CareerGuideChapter(
            id: 1,
            title: "Préparer le réseau",
            summary: "Choisis un dépôt, une date couverte par le GTFS et les lignes comprises dans le périmètre de la carrière avant de démarrer.",
            destinations: [.network]
        ),
        CareerGuideChapter(
            id: 2,
            title: "Affecter un départ",
            summary: "Choisis une course à venir, un bus et un machiniste disponibles; vérifie la validation de l’affectation avant de lancer le service.",
            destinations: [.dispatch]
        ),
        CareerGuideChapter(
            id: 3,
            title: "Suivre l’exploitation",
            summary: "Fais avancer l’horloge, observe les courses et les retards, puis mets la simulation en pause pour sauvegarder quand tu veux.",
            destinations: [.operations]
        ),
        CareerGuideChapter(
            id: 4,
            title: "Réagir et faire le bilan",
            summary: "Consulte les incidents et les rapports. Les valeurs d’exploitation et les calculs financiers sont des règles de jeu, pas des relevés contractuels réels.",
            destinations: [.incidents, .reports]
        )
    ]
}
