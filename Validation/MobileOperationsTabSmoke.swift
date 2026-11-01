import Foundation

#if MOBILE_DASHBOARD_TAB_SMOKE
@main
struct MobileOperationsTabSmoke {
    static func main() {
        let expectedMappings: [(MobileDashboardTab, [String], String)] = [
            (.map, ["network"], "network"),
            (.courses, ["assignments"], "assignments"),
            (.fleet, ["fleet", "staff", "depots"], "fleet"),
            (.reports, ["reports", "incidents"], "reports"),
            (.network, ["lines", "coursesMotifs", "sources"], "lines")
        ]

        precondition(
            MobileDashboardTab.allCases.map(\.title) == ["Carte", "Courses", "Parc", "Rapports", "Réseau"],
            "The iPhone dashboard should expose five native top-level tabs."
        )

        precondition(
            MobileDashboardTab.allCases.map(\.systemImage) == [
                "map.fill", "tram.fill", "bus.fill", "chart.bar.fill",
                "point.topleft.down.to.point.bottomright.curvepath"
            ],
            "Each iPhone tab should keep its labeled SF Symbol."
        )

        precondition(MobileDashboardTab.allCases.count == expectedMappings.count)
        for (tab, expectedWorkspaces, expectedDefault) in expectedMappings {
            precondition(
                tab.workspaceKeys == expectedWorkspaces,
                "The \(tab.title) tab should map to its specified workspaces."
            )
            precondition(
                tab.workspaceKeys.contains(tab.defaultWorkspaceKey)
                    && tab.defaultWorkspaceKey == expectedDefault,
                "The \(tab.title) tab must default to one of its own workspaces."
            )
        }

        let expectedWorkspaces = expectedMappings.flatMap(\.1).sorted()
        let coveredWorkspaces = MobileDashboardTab.allCases.flatMap(\.workspaceKeys).sorted()
        precondition(
            coveredWorkspaces == expectedWorkspaces,
            "The five iPhone tabs must expose each shared workspace exactly once."
        )
        for (tab, workspaces, _) in expectedMappings {
            for workspace in workspaces {
                precondition(
                    MobileDashboardTab.containing(workspaceKey: workspace) == tab,
                    "Workspace \(workspace) must map back to its top-level iPhone tab."
                )
            }
        }

        var selection = MobileDashboardWorkspaceSelection()
        selection.selectWorkspace(workspaceKey: "lines")
        precondition(selection.selectedTab == .network)
        precondition(selection.selectedWorkspaceKey(for: .network) == "lines")
        selection.selectTab(.courses)
        precondition(selection.selectedWorkspaceKey(for: .courses) == "assignments")
        selection.selectTab(.network)
        precondition(
            selection.selectedWorkspaceKey(for: .network) == "lines",
            "Returning to Réseau must restore its non-default Lignes workspace."
        )

        selection.selectWorkspace(workspaceKey: "staff")
        precondition(selection.selectedTab == .fleet)
        precondition(selection.selectedWorkspaceKey(for: .fleet) == "staff")
        selection.selectTab(.reports)
        selection.selectTab(.fleet)
        precondition(
            selection.selectedWorkspaceKey(for: .fleet) == "staff",
            "Returning to Parc must restore its selected Personnel workspace."
        )
        let perTabWorkspaces = MobileDashboardTab.allCases.map(selection.selectedWorkspaceKey(for:))
        precondition(
            Set(perTabWorkspaces).count == MobileDashboardTab.allCases.count,
            "Each native tab must render its own remembered workspace."
        )

        print("The five iPhone dashboard tabs cover all ten workspaces and restore per-tab selections.")
    }
}
#endif
