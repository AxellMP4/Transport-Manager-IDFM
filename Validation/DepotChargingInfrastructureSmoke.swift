import Foundation

let observation = DepotChargingInfrastructureEvidenceCatalog.neuillyPlaisance
let saintMaurObservation = DepotFacilityEvidenceCatalog.saintMaurHistoric

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

@main
struct DepotChargingInfrastructureSmoke {
    static func main() {
        require(observation.plannedChargingPointCount == 202, "Le projet ICPE doit afficher 202 points prévus.")
        require(observation.declaredChargingPointCount == 205, "La déclaration ICPE doit afficher 205 points.")
        require(observation.nominalPowerKilowatts == 100, "La puissance unitaire déclarée doit rester à 100 kW.")
        require(observation.statusLabel.localizedCaseInsensitiveContains("mise en service"), "Le statut doit distinguer le projet de sa mise en service.")
        require(observation.limitationNote.localizedCaseInsensitiveContains("capacité opérationnelle"), "La limite doit préciser que la capacité opérationnelle est inconnue.")
        require(observation.sourceURL.host == "www.georisques.gouv.fr", "La source principale doit être le rapport public Géorisques.")
        require(observation.orderURL.host == "www.seine-saint-denis.gouv.fr", "La source de mise en service doit être l'arrêté préfectoral officiel.")
        require(observation.metricLabels.contains(where: { $0.contains("202") }), "La carte doit exposer les 202 points prévus.")
        require(observation.metricLabels.contains(where: { $0.contains("205") }), "La carte doit exposer les 205 points déclarés.")
        require(observation.metricLabels.contains(where: { $0.contains("100 kW") }), "La carte doit exposer la puissance unitaire.")
        require(saintMaurObservation.siteAreaSquareMeters == 9_566, "La fiche Saint-Maur doit conserver la surface patrimoniale publiée.")
        require(saintMaurObservation.periodLabel.contains("2011") && saintMaurObservation.periodLabel.contains("2025"), "La fiche Saint-Maur doit dater séparément son contexte documentaire.")
        require(saintMaurObservation.operationalNote.contains("six bus") && saintMaurObservation.operationalNote.localizedCaseInsensitiveContains("biométhane"), "La fiche Saint-Maur doit afficher les faits documentés sur le GNV et le biométhane.")
        require(saintMaurObservation.limitationNote.localizedCaseInsensitiveContains("capacité actuelle du site"), "La fiche Saint-Maur doit distinguer la preuve historique de sa capacité actuelle.")
        require(saintMaurObservation.sourceURL.host == "www.legifrance.gouv.fr", "La surface doit être liée à la source patrimoniale officielle.")

        print("Validation des observations documentaires des dépôts réussie.")
    }
}
