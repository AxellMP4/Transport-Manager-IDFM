# Active GTFS Route Coverage Audit Implementation Plan

> **For agentic workers:** This bounded task is being implemented inline in the current TransitCity workspace.

**Goal:** Show every bus route with scheduled departures on the selected day and flag routes outside the published Bords de Marne name reference for qualification.

**Architecture:** Keep GTFS coverage comparison in `ScenarioCatalog.swift`; load departures for all bus routes from the pinned GTFS version, then render expected matches and additional active routes in the career setup view. The audit reports GTFS facts only and never assigns a route to DSP 45 or a COB.

**Tech Stack:** Swift, SwiftUI, Xcode, local versioned GTFS data.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, especially §5 and §4.1.

## Global Constraints

- Keep the deliverable a native macOS SwiftUI game in Swift.
- Keep service coverage date-based and tied to the selected GTFS version.
- Do not infer DSP membership or COB allocation from route names, departures, or geometry.
- Present undocumented facts as unknown and use French UI labels.
- Do not add or run tests for this task; verify the macOS build.

## Review Focus

- A listed route has active departures: keep its route IDs visible.
- An active route name is absent from the reference: show it as “à qualifier.”
- A route has no short name: surface its route ID so it is not silently omitted.
- A listed route has no departure that day: keep it in the “sans départ” report.
- Multiple GTFS route IDs share a short name: group the name while retaining every route ID.

---

### Task 1: Audit all active bus routes against the published reference

**Files:**
- Modify: `TransportManagerIDFM/Domain/ScenarioCatalog.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Create: `docs/superpowers/plans/2026-10-20-active-gtfs-route-audit.md`

**Interfaces:**
- Consumes: `GTFSRouteSummary`, `NetworkLibrary.loadScheduledDepartures(gtfsVersionID:routeIDs:from:through:)`, and `ScenarioLineCoverage.compare(expectedLineNames:against:)`.
- Produces: coverage entries for expected names and additional active route names, each retaining the active GTFS route IDs.

- [x] Inspect the selected-day coverage query and keep its existing expected-name matches.
- [x] Query all routes in the active GTFS bus catalogue and retain only those with departures on the selected day.
- [x] Group additional route IDs by short name; give unnamed routes a visible “Sans nom court” label with identifying detail.
- [x] Show additional active routes in a disclosure section labeled “à qualifier,” and state that the audit proves neither DSP membership nor COB allocation.
- [x] Update the implementation status and use a legible semantic text style for regional evidence labels.
- [x] Verify with `xcodebuild -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -sdk macosx -destination 'platform=macOS' -derivedDataPath /private/tmp/transitcity-derived SWIFT_OPTIMIZATION_LEVEL=-Onone CODE_SIGNING_ALLOWED=NO build`.

**Review:** An independent review prompted the disclosure counter to report active route IDs, not grouped names; the plan and implementation status now agree on completion.
