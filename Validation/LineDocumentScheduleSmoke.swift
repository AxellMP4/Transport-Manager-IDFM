import Foundation

@main
struct LineDocumentScheduleSmoke {
    static func main() {
        let timetable214 = LineDocumentStore.supplementalBordsDeMarneSchedules(for: "IDFM:C01228")
        let timetable314 = LineDocumentStore.supplementalBordsDeMarneSchedules(for: "C02890")

        precondition(timetable214.count == 1, "La fiche horaire 214 doit être associée à son ID_Line public.")
        precondition(
            timetable214[0].documentURL == "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20261029T101054Z-d933042c-cf70-42d5-aebb-768007465237.pdf"
                && timetable214[0].documentName.contains("214")
                && timetable214[0].attributes["date_validite"] == "2026-11-01/2027-07-11",
            "La fiche 214 doit conserver son lien et sa période de validité publiés."
        )
        precondition(timetable314.count == 1, "La fiche horaire 314 doit être associée à son ID_Line public.")
        precondition(
            timetable314[0].documentURL == "https://ilico.iledefrance-mobilites.fr/uploads/fiches/20261021T153740Z-878f05ec-b765-486b-bb83-7d8a6d99c48b.pdf"
                && timetable314[0].documentName.contains("314")
                && timetable314[0].attributes["date_validite"] == "2026-11-01/2027-07-11",
            "La fiche 314 doit conserver son lien et sa période de validité publiés."
        )

        let importedDuplicate = NetworkLineDocument(
            id: "catalog-copy-of-314-timetable",
            idLine: "C02890",
            documentName: "Copie issue du CSV actualisé",
            documentURL: timetable314[0].documentURL,
            documentType: "HORAIRE",
            lineName: "314",
            attributes: [:]
        )
        let plan = NetworkLineDocument(
            id: "catalog-plan-of-314",
            idLine: "C02890",
            documentName: "Plan de ligne 314",
            documentURL: "https://example.invalid/plan-314.pdf",
            documentType: "PLAN",
            lineName: "314",
            attributes: [:]
        )
        let unrelated = NetworkLineDocument(
            id: "catalog-timetable-of-214",
            idLine: "C01228",
            documentName: "Horaires 214",
            documentURL: "https://example.invalid/horaires-214.pdf",
            documentType: "HORAIRE",
            lineName: "214",
            attributes: [:]
        )
        let merged314 = LineDocumentStore.documents(
            fromCatalog: [importedDuplicate, plan, unrelated],
            for: "IDFM:C02890"
        )
        precondition(merged314.count == 2, "Le lien IDFM récent doit compléter le catalogue sans doublon ni autre ligne.")
        precondition(Set(merged314.map(\.documentURL)) == Set([timetable314[0].documentURL, plan.documentURL]))
        precondition(
            LineDocumentStore.documents(fromCatalog: [], for: "").isEmpty,
            "Un identifiant de ligne vide ne doit pas révéler de documents."
        )

        print("PASS: current official 214/314 timetable links are line-matched and deduplicated")
    }
}
