import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

@main
struct DepotLineRosterEvidenceSmoke {
    static func main() {
        guard let site = DepotLineRoster.sites.first(where: { $0.id == "freres-lumiere" }) else {
            fatalError("Le site Frères-Lumière doit rester dans le registre.")
        }

        require(site.availability == .operational, "Frères-Lumière doit être distingué du COB IDFM en projet.")
        require(site.status.localizedCaseInsensitiveContains("correspondance corroborée") && site.status.localizedCaseInsensitiveContains("lignes") && site.status.localizedCaseInsensitiveContains("ventiler"), "Le statut doit signaler le rapprochement d’adresse tout en laissant les lignes à ventiler.")
        require(site.documentedAddress?.localizedCaseInsensitiveContains("47 rue des frères-lumière") == true, "L’adresse SIRENE exacte doit être affichée.")
        require(site.documentedAddress?.contains("41–47") == true, "L’emprise IDFM historique doit rester distincte de l’adresse SIRENE.")
        require(site.evidenceNote.contains("937 651 818 00059"), "La note doit citer le SIRET RATP Cap.")
        require(site.evidenceNote.contains("1er novembre 2025"), "La note doit dater l’ouverture de l’établissement.")
        require(site.evidenceNote.localizedCaseInsensitiveContains("meilleure correspondance documentée"), "La note doit qualifier le rapprochement inter-sources.")
        require(site.evidenceNote.localizedCaseInsensitiveContains("ne constitue pas à lui seul une preuve") && site.evidenceNote.localizedCaseInsensitiveContains("rattachements actuels"), "La note doit préciser que l’adresse ne prouve pas les lignes affectées.")
        require(site.evidenceNote.localizedCaseInsensitiveContains("futur COB") && site.evidenceNote.localizedCaseInsensitiveContains("distinct"), "Le futur COB IDFM doit rester distinct.")

        let evidenceURLs = Set(site.evidenceLinks.map(\.url.absoluteString))
        require(evidenceURLs.contains("https://recherche-entreprises.api.gouv.fr/search?q=93765181800059"), "La fiche doit relier la recherche officielle du SIRET.")
        require(evidenceURLs.contains("https://api-avis-situation-sirene.insee.fr/identification/pdf/93765181800059"), "La fiche doit relier l’avis INSEE reproductible.")
        require(evidenceURLs.contains("https://www.iledefrance-mobilites.fr/medias/portail-idfm-projets/72537622-01f3-44cc-ae73-4f1771f19470_BBM_SDP_VFF.pdf"), "La fiche doit relier le document IDFM du COB rue des Frères-Lumière.")
        require(evidenceURLs.contains("https://www.ratpcap.com/wp-content/uploads/2026/03/Carte_Reseaux_RATPCap_mars2026_compressed.pdf"), "La fiche doit garder la carte RATP Cap actuelle.")

        guard let line113 = DepotLineRoster.rows.first(where: { $0.line == "113" }) else {
            fatalError("La ligne 113 doit rester dans le registre.")
        }
        var parisCalendar = Calendar(identifier: .gregorian)
        parisCalendar.timeZone = GTFSServiceDate.parisTimeZone
        let beforeTransfer = parisCalendar.date(from: DateComponents(year: 2025, month: 10, day: 31))!
        let afterTransfer = parisCalendar.date(from: DateComponents(year: 2025, month: 11, day: 1))!
        require(line113.siteEvidenceClaims(for: "freres-lumiere", on: beforeTransfer).contains(where: { $0.kind == .partialStorage }), "Le remisage partiel historique de la 113 doit rester daté jusqu’au transfert.")
        let currentClaims = line113.siteEvidenceClaims(for: "freres-lumiere", on: afterTransfer)
        require(!currentClaims.contains(where: { $0.kind == .partialStorage || $0.kind == .contractCenter }), "L’adresse actuelle ne doit pas créer une affectation de ligne après le transfert.")
        require(currentClaims.contains(where: { $0.kind == .fleetObservation }), "L’observation de flotte doit rester séparée d’une affectation de service.")

        guard let futureSite = DepotLineRoster.sites.first(where: { $0.id == "neuilly-sur-marne-projet" }) else {
            fatalError("Le projet IDFM doit rester une fiche distincte.")
        }
        require(futureSite.availability == .planned, "Le futur COB ne doit pas devenir un site opérationnel par confusion d’adresse.")

        print("Validation des preuves et limites de rattachement de Frères-Lumière réussie.")
    }
}
