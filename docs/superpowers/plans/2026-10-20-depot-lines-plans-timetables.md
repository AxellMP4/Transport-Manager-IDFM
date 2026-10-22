# Depot Lines, Plans and Timetables Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the complete dated line roster, official plan/timetable links, and GTFS timetable grid accessible for every Bords de Marne depot.

**Architecture:** Add an evidence-aware roster manifest for DSP 45 and reconcile its commercial line numbers against the official IDFM line reference, then map those references to GTFS route IDs only through unique exact IDs. Add a depot view for confirmed, candidate, and unresolved lines with official links, plus a date- and direction-filtered timetable matrix built from archived GTFS departures and stop visits.

**Tech Stack:** Swift 6, SwiftUI, Foundation, existing `NetworkLibrary`, `NetworkVersionStore`, `LineReferenceStore`, `LineDocumentStore`, and `DepotAssignmentStore`.

**Spec:** `docs/superpowers/specs/2026-10-20-depot-lines-plans-timetables-design.md`

## Global Constraints

- Keep GTFS `routeID`, IDFM `ID_Line`, and commercial line name as separate values.
- A route/depot assignment is usable only with dated, valid evidence; do not infer it from a route's geometry, stops, name, or proximity.
- Preserve network, reference, and document versions; show route variants rather than merging distinct IDs.
- Keep IDFM plan and timetable PDFs as external links and retain source metadata; do not bundle PDFs.
- Keep Saint-Maur and Neuilly-Plaisance as current playable depots; Neuilly-sur-Marne remains a future site.
- Treat 1 November 2026 as a dated network change and use the GTFS snapshot that covers the selected service date.
- Do not add or run automated tests for this task; verify with source review and a macOS build.

## Review Focus

- Duplicate IDFM line references must stay unmatched rather than resolve to an arbitrary route.
- Multiple route IDs with the same short name must appear as distinct variants.
- Calendar exceptions and trips past midnight must follow the selected GTFS service date.
- A line with no PDF link or no GTFS trip must stay visible with a clear missing-data state.
- Historical, shared, and candidate depot assignments must not enter the operational roster as confirmed.

---

### Task 1: Evidence-aware Bords de Marne roster

**Files:**
- Create: `docs/data/bords-de-marne-depot-roster.csv`
- Create: `TransportManagerIDFM/Domain/DepotLineRoster.swift`
- Modify: `TransportManagerIDFM/Domain/ScenarioCatalog.swift`

**Interfaces:**
- `DepotLineRosterEntry` stores contract ID, service period, commercial line name, optional candidate depot ID, service class, evidence status, evidence title/URL, and notes.
- `DepotLineRosterCatalog.entries(for:serviceDate:) -> [DepotLineRosterEntry]` returns the date-valid contract roster without claiming an unresolved COB assignment.
- Runtime implementation: `DepotLineRosterManifestCatalog.entries(for:)` reads the bundled CSV after schema/evidence validation. The richer claim graph is still hand-authored in `DepotLineRoster.swift` and is not yet generated from these manifest entries.

- [x] Record the 22 regular lines and 7 Noctilien names in the pre-reorganization contract roster and the 314 change effective 1 November 2026.
- [x] Add the historical candidate split of nine Saint-Maur regular lines and thirteen Bords-de-Marne regular lines only with `needsReview` or `historical` status where current individual COB evidence is absent.
- [x] Keep shared/Noctilien lines and 314 unassigned until a dated source proves a COB relationship.
- [x] Preserve evidence limitations in the data rows; aggregate DSP 45 membership must never become a depot assignment.
- [x] Add a manifest loader that validates required fields, date ranges, known scenario depot IDs, and web evidence URLs before exposing rows to the app.

### Task 2: Reconcile depot roster with imported network data

**Files:**
- Modify: `TransportManagerIDFM/Domain/NetworkLibrary.swift`
- Modify: `TransportManagerIDFM/Domain/LineReferenceImporter.swift`
- Modify: `TransportManagerIDFM/Domain/NetworkCatalog.swift` only if an additional coverage model is required.

**Interfaces:**
- `DepotLineCoverage` reports contract entries, unique IDFM matches, GTFS route variants, documents, and unresolved reasons for one depot/date.
- `NetworkLibrary.depotLineCoverage(depotID:serviceDate:operatedRouteIDs:) -> DepotLineCoverage` uses the active version identifiers and never matches GTFS routes by short name alone.

- [x] Load current route references and plan/timetable documents through the existing import/download APIs.
- [x] Map roster names to unique IDFM reference records, then map each `ID_Line` to all exact GTFS route IDs.
- [ ] Report missing/duplicate line-reference matches, unlisted active GTFS routes, missing depot evidence, and routes with no matching PDF rows separately.
- [x] Retain per-route documents and all route variants without selecting one representative route.
- [x] Reuse the depot assignment evidence registry for operational eligibility; candidate roster records remain visible but do not unlock a career.

### Task 3: Depot line catalogue UI

**Files:**
- Create: `TransportManagerIDFM/Features/DepotLineCatalogView.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- The view receives `ScenarioDefinition`, selected depot ID, `NetworkLibrary`, and service date.
- A line row receives one roster entry, zero or more exact GTFS route IDs, document links, and evidence status.

- [x] Add an entry point from the selected depot's operations panel to its line catalogue.
- [ ] Group lines by confirmed assignment, historical/probable candidate, shared/unassigned, and active route IDs needing qualification.
- [x] Show route variants and their GTFS identifiers next to the commercial line name.
- [x] Show every official plan and timetable link returned for each matched route; include source type and any known validity dates.
- [ ] Show distinct states for missing GTFS, missing reference, missing documents, and unconfirmed depot evidence.
- [x] Provide an action to download/import the official line-reference and documents CSVs using the existing NetworkLibrary methods.

### Task 4: Date-aware timetable grid

**Files:**
- Create: `TransportManagerIDFM/Features/GTFSRouteTimetableGridView.swift`
- Modify: `TransportManagerIDFM/Domain/NetworkLibrary.swift`
- Modify: `TransportManagerIDFM/Features/DepotLineCatalogView.swift`

**Interfaces:**
- `GTFSRouteTimetableGridView` receives the exact GTFS route, active GTFS version ID, and selected service date.
- It loads departures via `loadScheduledDepartures(gtfsVersionID:routeIDs:from:through:)` and stop visits via `loadScheduledTripStopVisits(gtfsVersionID:tripID:serviceDateKey:)`.

- [x] Load all trips for the selected route and service date, honoring GTFS calendars, exceptions, and after-midnight service times.
- [x] Group trips by direction/headsign and sort by first departure time, preserving the distinct GTFS route IDs.
- [x] Render a horizontally scrollable matrix with one trip per row and ordered stops as columns; show a concise first/last departure summary above it.
- [ ] Offer a service-date picker constrained to the GTFS validity period and explain when the feed does not cover the selected date.
- [x] Keep the official timetable PDF link alongside the GTFS-derived grid and label the GTFS schedule as theoretical.
- [x] Show empty states for a route with no active service, incomplete stop times, or unavailable shape/stop data without fabricating times.

### Task 5: Documentation and verification

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Document the roster's effective dates, official source imports, the difference between DSP membership and COB assignment, and the limits of public assignment evidence.
- [x] Update the implementation register with data coverage, remaining unknown depot assignments, and the GTFS date used for the latest verified schedule.
- [x] Review the changed source files and build the macOS Debug target; record the exact result and any data access limitation.

### Remaining work

- The CSV is bundled and has a runtime loader that validates its schema, line categories, date ranges, unique dated rows, depot IDs, and HTTP(S) evidence/document URLs. It now preserves secondary evidence, historical center labels and periods, service announcements, document validity text, multiple plan/timetable URLs, and titled project documents. The line detail exposes these records while explicitly keeping site IDs and center labels from acting as COB assignment evidence. The richer per-depot claim graph and operational catalog rows still come from Swift; migrate those only after preserving claim kind, site, and validity dates.
- The coverage report now deduplicates lines by `ID_Line`, distinguishes route variants and reports reference/GTFS/document/official-trace coverage per depot. It still needs an explicit count/list of active GTFS routes outside the depot roster, plus a per-route document-missing diagnostic.
- The service-date picker reports dates outside the selected GTFS feed's validity, but still permits choosing them; constrain the picker or provide a bounded date selection.
- Latest source review and build: macOS Debug `x86_64`, **BUILD SUCCEEDED**, 21 October 2026, 02:42 Europe/Paris. No automated tests were run. Xcode emitted CoreSimulator/App Intents environment warnings; the macOS target completed successfully. The app was not launched, so the runtime validation label was compiled but not observed in a running window.

