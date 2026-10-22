# Network Coverage Ledger Implementation Plan

> **For agentic workers:** Use the existing inline implementation method for this task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Bords de Marne route and evidence coverage auditable by date, route ID, exact IDFM line reference, documents, and recorded depot assignments.

**Architecture:** Add a pure domain projection that joins GTFS routes to the exact canonical `ID_Line`, distinguishes absent and ambiguous reference matches, counts linked documents only through a unique reference, and retains every recorded assignment with its source versions and status. Present it in a separate SwiftUI audit sheet that loads scheduled departures for the selected Paris service date and labels missing or stale data explicitly.

**Tech Stack:** Swift, SwiftUI, existing GTFS and versioned network models.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, especially the network/COB evidence requirements and screens in sections 4, 7, 12, and 15; status gaps in `docs/IMPLEMENTATION_STATUS.md`.

## Global Constraints

- Keep route IDs, `ID_Line`, and assignment versions as exact identifiers; never join by commercial name.
- GTFS service presence, line-name checklists, contract contours, and missing records do not prove contract membership or a COB allocation.
- Preserve `needsReview` and `historical` assignment records as sourced declarations; only label a record operationally usable when its existing validation rules and pinned versions allow it.
- Keep the app native to macOS and use the existing local versioned data; do not add external dependencies.
- Do not claim that real PRIM exports have been imported when none are present.

## Review Focus

- No active GTFS version or date outside its validity window: show activity as unknown, not inactive.
- Multiple canonical `ID_Line` rows for one route: show ambiguous, and do not join documents.
- No unique reference: do not match documents through route names.
- No assignment for a depot: say “à documenter”; do not infer exclusion from the contract or depot.
- Assignment pinned to other network versions or marked needs-review/historical: retain and label it without treating it as usable.

---

### Task 1: Build the route coverage projection

**Files:**
- Create: `TransportManagerIDFM/Domain/NetworkCoverageAudit.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

**Interfaces:**
- Consumes: `GTFSRouteSummary`, `NetworkLineReference`, `NetworkLineDocument`, `DepotLineAssignment`, `NetworkContractFeature`, `DepotReference`, and active version IDs. Contract names are optional display hints; saved `contractID` remains the recorded identifier.
- Produces: `NetworkCoverageAudit.build(routes:activeRouteIDs:references:documents:assignments:scenarioID:depots:activeGTFSVersionID:activeContractVersionID:) -> [NetworkCoverageAuditEntry]`.
- The builder retains all GTFS routes, represents unknown activity/reference/document availability explicitly, distinguishes zero/one/multiple exact canonical reference matches, links documents only for one unique match, and retains matching-scenario assignments with depot name, evidence status, and whether both pinned versions match the active versions.

- [x] Implement the projection and its display-ready status labels in `NetworkCoverageAudit.swift`.
- [x] Document the completed route/date/reference/document/assignment coverage view in the implementation status.

### Task 2: Add the date-scoped audit sheet

**Files:**
- Create: `TransportManagerIDFM/Features/NetworkCoverageAuditView.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- Consumes: a `NetworkLibrary`, the scenario’s depot references, the initial career date, and the Task 1 projection.
- Produces: a read-only sheet with an independent Paris service-date picker, date-scoped GTFS departures, one row per GTFS route, exact reference/document evidence, per-depot recorded assignments, and explicit unknown/missing states.

- [x] Load all bus-route departures for the selected service day, keyed by active GTFS version and date; discard stale asynchronous responses.
- [x] Add a preparation-screen entry point to the sheet and render route IDs, reference match counts, linked plans/hours, assignment evidence/status/version scope, and missing-record caveats.

### Task 3: Compile and close the implementation record

**Files:**
- Modify: `docs/superpowers/plans/2026-10-20-network-coverage-ledger.md`
- Create: `.superpowers/sdd/2026-10-20-network-coverage-ledger/progress.md`

- [x] Build the macOS target with the established `xcodebuild` command.
- [x] Record build output and the lack of real external exports in the progress ledger; leave the overall game goal open.

