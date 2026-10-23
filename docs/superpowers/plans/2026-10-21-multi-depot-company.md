# Multi-Depot Company Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-depot career assumption with a company career that can manage multiple depots and show each depot’s real IDFM network and fleet.

**Design:** `docs/superpowers/specs/2026-10-21-multi-depot-company-design.md`

**Architecture:** Keep the existing `SimulationSession.depotID` as the legacy/home depot for old saves, add optional managed-depot, active-depot, and route-to-depot state, and migrate old sessions to a one-depot company. New careers can add any non-planned depot in the regional registry. Keep public evidence claims separate from player decisions. Update dispatch, fleet, staffing, workshop, and map behavior to use each bus’s assigned depot and an explicit active-depot UI context.

**Tech stack:** Swift 6, SwiftUI, Codable session saves, existing IDFM GTFS, geometry, line-document, depot roster, and assignment registries.

## Tasks

### 1. Depot and route scope

- [x] Reuse the date-aware depot line roster query that distinguishes contract candidates from exact COB evidence.
- [x] Keep the searchable directory available during a career and add an action to manage another depot in the same contract.
- [x] Show GTFS, geometry, plan-PDF, and timetable-PDF coverage per depot and link each line to its documents and schedule grid.

### 2. Backward-compatible company state

- [x] Add optional company depot IDs and an active depot ID to `SimulationSession`.
- [x] Initialize careers with the selected depot; let the player add any other registered operating depot from the regional directory. Old saves default to their original single depot.
- [x] Store operated route IDs by depot; add a depot with an empty operational scope and load its departures when the player assigns a line.
- [x] Keep contract-wide candidate lines separate from player-confirmed operational assignments.

Implementation note: before a career, only dated `.confirmed` route IDs are included automatically. The player explicitly selects other line variants in the depot sidebar; adding another depot creates an empty operational scope until the player assigns lines from its catalogue. The saved per-depot route map then records those choices independently of the source roster claims.

### 3. Depot-specific operations

- [x] Scope the visible bus inventory and purchases to the active depot while keeping company funds shared.
- [x] Add depot assignment to machinists and filter available staff by the bus’s home depot.
- [x] Route deadheads, tow plans, repairs, energy infrastructure, maintenance, workshop capacity, and parts to the individual vehicle’s home depot; keep legacy records scoped to the original depot.
- [x] Preserve company-wide funds while attributing supported vehicle, workshop, parts, energy, and recovery costs to their originating depot.
- [x] Attribute supported daily service statistics to the originating depot, retain consolidated company totals, and state which records remain unattributed.

### 4. Game navigation and map

- [x] Add a persistent active-depot switcher in the operations shell and a clear action to open the complete regional directory.
- [x] Send the first-time depot chooser to the searchable regional directory so depot selection, real-line coverage, and the start-career action share one workspace.
- [x] Let a player assign a line’s GTFS variants to the active managed depot from that line’s details, and show when it is already in operation there.
- [x] Allow a career without a contour when the selected active DSP has matching contract lines and GTFS routes; keep the missing boundary explicit.
- [x] Filter the network, dispatch, fleet, and staff context by the selected depot; map bus markers follow the active depot.
- [x] Draw date-active GTFS trip shapes as a teal dashed fallback when a depot line has no commercial geometry; keep official and indicative coverage counts separate.
- [x] Show a clicked bus’s model, game coquille, current line/course, driver, shift distance, lifetime odometer, incident, simulated position, and estimated course speed.
- [x] Keep line plans, timetables, and stop details contextual to the selected route or stop.

### 5. Audit and verification

- [ ] Audit all rostered depots against the bundled line reference, GTFS services, route geometries, plans, and timetable PDFs.
- [x] Show date-scoped scheduled-departure counts for exact ID_Line matches when inspecting a depot; keep missing, ambiguous, out-of-validity, and no-service states distinct.
- [ ] Check legacy save decoding and multi-depot context changes interactively in the app; optional depot fields retain the old save fallback, but still need an app-level restoration check.
- [x] Compile the macOS target from a frozen source/data snapshot without running tests; verify that the GTFS, route geometries, line reference, documents, and contract contours are present in the app bundle.
- [x] Publish the remaining source gaps by depot instead of claiming full coverage.

Audit note: the 2026-10-20 contract-contour snapshot has 66 contract features. DSP 46 and 47 are absent from it, but their active line-reference rows map to 23 and 28 GTFS route IDs respectively. Career start now allows that published line scope without drawing a contract boundary; the full depot-by-depot document and geometry audit remains open.

Map fallback note: in the bundled GTFS on 2026-10-21, 1,449 route IDs have active service. Comparing canonical IDs with the commercial geometry snapshot leaves 83 active route IDs without a direct commercial line geometry; 81 have GTFS trip shapes and can now appear as indicative dashed paths.

Verification record — 2026-10-23: a macOS Debug build succeeded after separating contract-wide candidate lines from the player's operational assignments. Code commit: 7295e4235e4e9cc122bda782b6a10da44c8b387b. Interactive legacy-save restoration and the complete depot-by-depot source audit remain open.

Service audit note — 2026-10-23: the regional directory now queries scheduled departures for the selected depot and Paris service date by exact active \`ID_Line\`, bounded by the GTFS validity window. This makes the service check available per site; the full manual source audit across all rostered depots remains open. Code commits: \`1957302307a0d0ecf4bbe2eed0b1b6a145c02b1b\`, \`1e36ea60f216651e02377005c90b95a49b50b671\`, \`175d2e599491ca60bce315ec04e42de743590f4d\`, \`814f8ed4c95c5511fbe5756b7b2a9d40a98bb6ad\`.
