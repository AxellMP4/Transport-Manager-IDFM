# Depot-First Operations Map Implementation Plan

> **For agentic workers:** Follow the existing native implementation workflow and keep each step reviewable.

**Goal:** Start the game with the selected depot’s dated lines and route map ready, then let the player inspect moving buses and stop departures without crowding the main screen.

**Architecture:** Bootstrap the bundled public GTFS snapshot on first launch, keep the curated depot roster as the depot-to-line source, and join lines to route shapes only through exact canonical IDFM identifiers. Rework the dashboard around a depot picker, line list, and map; move advanced catalog and management screens behind menus and use selection popovers for bus and stop details.

**Tech Stack:** SwiftUI, MapKit, existing Codable GTFS importer and local network store.

**Spec:** User request in this conversation, including the attached route-map example.

## Global Constraints

- Keep uncertain depot assignments explicitly marked as observed, shared, candidate, or conflicting.
- Never fabricate a public fleet number, driver, radar reading, timetable, or line match.
- Preserve access to existing management and import tools.
- No automated tests are added or run; the project instructions require build verification only when requested.

## Review Focus

- First launch with no imported GTFS: bundled snapshot should bootstrap and report progress.
- Depot with uncertain or unmatched lines: show evidence and keep unmatched lines in the list without drawing a false shape.
- Bus without a current assignment or route geometry: show known values and label missing/estimated values clearly.
- Stop with several serving routes: only display departures associated with that stop and selected depot.
- Existing saved careers: continue loading and keep their saved depot locked during play.

## Files

- Modify `TransportManagerIDFM/Features/OperationsDashboardView.swift` for the map-first screen, depot lines, map layers, bus/stop popovers, and compact controls.
- Modify `TransportManagerIDFM/Domain/NetworkLibrary.swift` and `TransportManagerIDFM.xcodeproj/project.pbxproj` for first-run bundled GTFS bootstrap.
- Modify `TransportManagerIDFM/Domain/VehicleMarket.swift` and `TransportManagerIDFM/Domain/SimulationEngine.swift` only if the fleet label requires persisted game-issued bus identifiers.

## Tasks

### Task 1: First-run network availability

- [x] Bundle the dated GTFS ZIP and commercial-route GeoJSON archive, and import them on first launch when no active snapshots exist.
- [x] Keep the existing manual import and surface concise bootstrap, loading, and error states.
- [x] Build the app to verify resource wiring and Swift compilation.

### Task 2: Depot-first map

- [x] Replace the permanent scenario and inspector columns with a compact line sidebar plus the map.
- [x] Keep the depot picker directly visible and make all date-visible roster rows selectable.
- [x] Draw every uniquely matched route geometry for the chosen depot, with evidence status reflected in line labels.
- [x] Show bus markers without directions or next-passage text.
- [x] Build the app to verify Swift compilation.

### Task 3: Clickable operation details

- [x] Make bus markers selectable and show model, a clearly game-issued fleet shell number, current-service km, lifetime odometer, assigned machinist when present, and simulated position/radar status.
- [x] Keep stop detail behind a stop click and show its relevant timetable there.
- [x] Build the app to verify Swift compilation.

### Task 4: Clear access to advanced tools

- [x] Keep schedules, plans, source audit, imports, market, personnel, dispatch, reports, and incidents available from grouped controls.
- [x] Build and open the app preview to verify the app launches.
