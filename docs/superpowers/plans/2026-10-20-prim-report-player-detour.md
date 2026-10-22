# PRIM Report to Player-Authored Detour Plan

> **For agentic workers:** Implement in the existing TransitCity workspace. Do not add or run automated tests; verify the macOS target with the project build.

**Goal:** Let the player use a dated PRIM traffic observation as context for a manually authored, saved in-game route detour and passenger information notice.

**Architecture:** PRIM data remains a read-only observation until the player chooses “Préparer une déviation”, selects an exact future GTFS segment, reviews the MapKit path and time window, edits the in-game passenger notice, and saves. The saved detour records the PRIM observation as provenance; it does not call PRIM again or infer a segment, route geometry, or simulation effect from message text.

**Tech Stack:** Swift, SwiftUI, Codable, the existing PRIM line-reports client, GTFS timetable archive, MapKit detour editor, and simulation session.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, especially sections 3.3, 7, 9, 10, 12 and 14 Phase I.

## Constraints

- Keep API observations distinct from simulated events. Only the player's explicit save action creates a simulated detour.
- Preserve the source report ID, title, message, line ID, update time, fetch time, source URL and Licence Mobilité in the saved detour.
- Match the selected GTFS route and exact directed adjacent stop pair; never parse a PRIM message to infer stops or a road path.
- Preserve saves made before the optional PRIM and passenger-notice fields existed.
- Passenger information is an in-game notice only; do not send anything to IDFM or real passengers.
- If the PRIM time window is missing or no longer valid for the simulation clock, require the player to review the date fields and choose a future window.
- Keep the native macOS sheet, system form controls, clear labels, Cancel and Save actions, and accessible text-entry labels.

## Tasks

### Task 1: Persist observation provenance with detours

- [x] Add a Codable `PRIMTrafficObservation` snapshot containing the report, line ID, fetch time, source URL and license.
- [x] Add optional PRIM observation and in-game passenger-notice fields to `SimulatedRouteDetour`; keep earlier career saves decodable.
- [x] Pass both fields through `scheduleRouteDetour` without changing the detour matching or timing rules.

### Task 2: Launch the detour editor from a traffic report

- [x] Add an explicit action on each PRIM report for routes operated by the active career.
- [x] Allow the editor to load all future adjacent segments on the selected route when launched without a selected stop.
- [x] Prefill usable report dates and an editable in-game passenger notice; show the source text and explain that the observation does not modify service until saved.
- [x] Save only after the player selects a segment, calculates/reviews a MapKit route and confirms the form.

### Task 3: Show provenance and project status

- [x] Display the saved source observation and in-game passenger notice on the active detour card.
- [x] Update `README.md` and `docs/IMPLEMENTATION_STATUS.md` with delivered scope and remaining full-network/real-passenger messaging limitations.
- [x] Build the Debug macOS app with the existing Xcode project and inspect the result: exit code 0; universal `arm64` and `x86_64` app binary; no Swift diagnostics in the final pass.

## Review Focus

- A missing/ambiguous line reference or a line outside the active career cannot create a detour.
- No external observation automatically schedules an event or overwrites a saved detour.
- The selected segment is a future exact adjacent pair from the pinned GTFS version.
- Older saves without source or notice fields still decode.
- The source report and player notice remain explicitly labeled as real observation and simulated game content, respectively.

## Self-Review

- The PRIM report action is disabled unless the selected GTFS route is operated by the active career. The report view is keyed by route ID so a prior line's result cannot be offered for a newly selected route.
- The detour editor loads future, adjacent stop pairs from the active session's pinned GTFS version. It does not infer a segment or geometry from the PRIM message.
- Provenance and message fields are optional in `SimulatedRouteDetour`; backward decoding was inspected in the model, but no save fixture was run.
- Saving creates the existing simulated detour only after explicit player confirmation. The in-game notice is displayed with it and has no automatic demand effect or external delivery.
- Automated tests were not added or run. The final Debug macOS build passed with exit code 0 for `arm64` and `x86_64`.
