@main
struct MachinistServiceRuleSummarySmoke {
    static func main() {
        let rows = MachinistServiceRuleSummary.rows(
            maximumGap: 2 * 60 * 60,
            maximumServiceBlock: 10 * 60 * 60,
            minimumRest: 11 * 60 * 60
        )

        let expected: [MachinistServiceRuleRow] = [
            MachinistServiceRuleRow(
                id: .betweenCourses,
                title: "Battement entre courses",
                limit: "2 h max",
                explanation: "Espacement maximal entre deux courses du même bloc.",
                symbol: "arrow.left.and.right"
            ),
            MachinistServiceRuleRow(
                id: .serviceBlock,
                title: "Présence dans un bloc",
                limit: "10 h max",
                explanation: "Durée entre la première course et la dernière du bloc.",
                symbol: "clock"
            ),
            MachinistServiceRuleRow(
                id: .recoveryRest,
                title: "Repos avant reprise",
                limit: "11 h min",
                explanation: "Attendre après un service ou une formation avant une nouvelle affectation.",
                symbol: "moon.zzz"
            )
        ]
        guard rows == expected else {
            fatalError("Les trois résumés doivent reprendre les seuils existants sans ajouter de règle.")
        }
        print("PASS : résumé des battements, blocs et repos dérivé des seuils de jeu reçus.")
    }
}
