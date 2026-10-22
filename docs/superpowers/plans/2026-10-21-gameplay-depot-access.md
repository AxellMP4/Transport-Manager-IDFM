# Gameplay Depot Access Implementation Plan

**Goal:** Make the game flow center on operating real IDFM lines from a chosen depot, while letting players inspect every depot in the regional directory.

**Architecture:** Keep each career pinned to its chosen depot and the IDFM contract that provides its real lines. Let the depot directory browse other sites independently during a career, and treat public contract-linked sites with an unverified current status as playable only when the date, line roster, GTFS services, and contract contour support a career. Preserve planned sites and sites without an identified contract as consultation-only.

**Tech Stack:** Swift, SwiftUI, existing IDFM depot registry and GTFS/line-document catalogs.

## Global Constraints

- Keep the career's depot and pinned network versions stable after the career starts.
- Keep uncertain COB-to-line assignments marked as candidates.
- Do not make a planned depot playable.
- Do not invent lines or timetables when public references are missing.
- Do not add or run tests for this change; perform a compile check only.

## Review Focus

- A directory selection during an active career must not change that career's depot.
- A contract-linked site with unverified operating status may start only when its required network data is available.
- A planned site or a site without a public contract remains consultation-only.
- Browsed line details must not navigate the active career map to a line outside its pinned depot scope.
- Starting a career still pins the actual chosen depot and route list into its save.

---

### Task 1: Separate depot browsing from the active career

**Files:**
- Modify: `TransportManagerIDFM/Features/DepotInspectorView.swift`
- Modify: `TransportManagerIDFM/Features/DepotLineCatalogView.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

- [x] Let the depot directory inspect and open every site while a career is active.
- [x] Keep browse selection separate from the career depot and make line details read-only for sites outside the active career.
- [x] Explain in the directory that browsing another site does not change the active career.

### Task 2: Enable contract-linked depots with unverified status

**Files:**
- Modify: `TransportManagerIDFM/Domain/DepotLineRoster.swift`
- Modify: `TransportManagerIDFM/Domain/ScenarioCatalog.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `TransportManagerIDFM/Features/DepotInspectorView.swift`

- [x] Define career eligibility from a non-planned site with a public IDFM bus contract.
- [x] Apply the same eligibility rule when building a career scenario and when validating depot references.
- [x] Update start guidance and depot labels so unverified status remains visible.
- [x] Add the publicly named DSP48/49 lines where the October 2026 IDFM snapshot has no contract IDs, while showing the remaining DSP49 count gap.

### Task 3: Check the app build

- [x] Parse the changed Swift files.
- [x] Build the macOS Xcode target without running tests.
- [x] Update the implementation status with the depot browsing and career eligibility behavior.
