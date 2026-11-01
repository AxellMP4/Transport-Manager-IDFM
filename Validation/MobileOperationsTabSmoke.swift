import Foundation

#if MOBILE_FINANCIAL_TAB_SMOKE
@main
struct MobileOperationsTabSmoke {
    static func main() {
        let expectedTabs = ["Carrière", "Courses", "Réseau", "Parc", "Finances"]
        precondition(
            MobileOperationsTab.allCases.map(\.title) == expectedTabs,
            "The mobile navigation should expose the same-career financial report as a top-level tab."
        )
        precondition(
            MobileOperationsTab.allCases.map(\.systemImage) == [
                "chart.line.uptrend.xyaxis",
                "tram.fill",
                "point.topleft.down.to.point.bottomright.curvepath",
                "bus",
                "chart.bar.fill"
            ],
            "Each mobile section should keep its labeled SF Symbol."
        )
        print("Mobile operations tabs include the financial report.")
    }
}
#endif
