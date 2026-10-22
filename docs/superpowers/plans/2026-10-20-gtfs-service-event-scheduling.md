# GTFS Service Event Scheduling Implementation Plan

> **For agentic workers:** Execute inline in this workspace; verify with the macOS build and project-file lint.

**Goal:** Populate a new simulation with real bus-trip departure events from its pinned GTFS version for the selected service date.

**Architecture:** Extend the versioned GTFS import with a compact index of each bus trip's first usable departure, keyed by service ID. A date-aware planner applies the stored GTFS calendars and Paris service-day clock rules, then passes ordered events into the simulation session. The existing clock owns event ordering and persistence.

**Tech Stack:** Swift 6, Foundation, SwiftUI, existing CSV and ZIP readers, local JSON indexes.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 4.4, 5 and 7.

## Global Constraints

- Keep route and trip identifiers stable; do not infer a relationship from a route name.
- Evaluate service dates using the imported calendar and exceptions.
- Preserve GTFS times after midnight, including values greater than `24:00:00`, in `Europe/Paris`.
- Do not add or run tests unless explicitly requested; verify with a macOS build and project-file lint.

## Review Focus

- A trip with no usable first-stop time must not receive a fabricated departure.
- A date exception must override the weekly service pattern.
- A start after midnight must include prior-service-day departures whose GTFS time is over 24 hours.
- Equal-time departures must retain deterministic sequence ordering.
- Keep the saved pending-event queue bounded to a two-day initial timetable horizon, then extend it in one-day windows as the clock advances.

Ruling: Start with a 48-hour timetable horizon and append 24-hour windows once 24 hours remain — this includes overnight service and gives local GTFS loading a full day of lead time without expanding the entire rolling feed; cost if wrong: one extra day of scheduled events is saved at a time.

---

### Task 1: Persist first-stop departure records with each GTFS version

**Files:**
- Modify: `TransportManagerIDFM/Domain/NetworkCatalog.swift`
- Modify: `TransportManagerIDFM/Domain/GTFSFeedImporter.swift`

**Interfaces:**
- Add Codable `GTFSServiceTripDeparture` with `tripID`, `routeID`, `serviceID` and `departureSeconds`.
- Add `GTFSFeedInspection.busTripDepartures` and persist it as `trip-departures.json` beside each version's route, stop and calendar indexes.
- Add `NetworkVersionStore.loadTripDepartures(for:)`.

- [x] Parse `stop_sequence` and retain a departure only when the earliest stop itself has a valid departure time.
- [x] Parse full GTFS clock values to seconds without truncating hours above 24.
- [x] Persist the compact versioned index and load it through the store.

### Task 2: Build and connect date-specific departure events

**Files:**
- Modify: `TransportManagerIDFM/Domain/GTFSFeedImporter.swift`
- Modify: `TransportManagerIDFM/Domain/NetworkLibrary.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- Add `NetworkVersionStore.loadServiceDepartures(for:from:through:)` returning sorted `ScheduledServiceDeparture` values.
- Add `SimulationEngine.startNew(..., scheduledDepartures:)` and seed the queue with stable trip-ID tie-breaking.
- Add a session schedule horizon so the interface can append the next GTFS date as the simulated date advances.

- [x] Apply calendar exceptions and convert GTFS service-day seconds into Paris-local dates, including prior-day overnight service.
- [x] Load initial departures before starting the career and show a loading state while the timetable is prepared.
- [x] Append the following 24-hour window once the current horizon is within 24 hours, without duplicating timestamps already queued.
- [x] Show pending departure count and latest processed service event in the simulation controls.

### Task 3: Update progress and verify

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Record scheduled departures as implemented while keeping stop-by-stop vehicle movement and event effects pending.
- [x] Run the macOS build and project-file lint.

Ruling: Omit test creation and execution because a higher-priority session instruction forbids tests unless the user asks; use the macOS build and project lint as the available verification — cost if wrong: GTFS edge-case regressions may remain unnoticed until a real feed is imported.
