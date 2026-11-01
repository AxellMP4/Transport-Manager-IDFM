import Foundation

#if CAREER_GUIDE_FLOW_SMOKE
@main
struct CareerGuideFlowSmoke {
    static func main() {
        let chapters = CareerGuideChapter.all
        precondition(chapters.map(\.title) == [
            "Préparer le réseau",
            "Affecter un départ",
            "Suivre l’exploitation",
            "Réagir et faire le bilan"
        ])
        precondition(chapters.map { $0.destinations.map(\.rawValue) } == [
            ["network"],
            ["dispatch"],
            ["operations"],
            ["incidents", "reports"]
        ])
        precondition(CareerGuideDestination.allCases.count == 5)
        print("The optional career guide has four chapters and working screen destinations.")
    }
}
#endif
