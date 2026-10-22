# MapKit Breakdown Tow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the player dispatch a broken bus to the active depot selected for the Bords de Marne career using a road route calculated by MapKit, then repair it at that depot.

**Architecture:** Resolve the active depot's published address at dispatch time, request an automobile route from MapKit, and store its coordinates, distance, ETA, destination and source in the incident. The simulation moves the bus along the stored route, emits a tow-arrival event, holds it in maintenance for the existing severity repair duration, then returns it to the active depot. Two existing on-site responses remain available when routing is unavailable.

**Tech Stack:** Swift 6, SwiftUI, MapKit, Core Location, Codable simulation state.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 8.1, 8.3, 12 and 15.

## Global Constraints

- Keep this a native macOS Swift and SwiftUI application using Apple MapKit.
- Store simulation events and incident state in the career save.
- Keep source evidence distinct from estimates and gameplay rules.
- Do not invent depot coordinates; resolve the dated source addresses at the time of dispatch and show the source and route provider.
- Preserve existing career saves by making new incident data optional when decoded.
- Routing is a live external service; failed routing must leave on-site recovery available.

## Review Focus

- Geocoding can fail or return no coordinate; do not offer a tow without a valid road route.
- A route or ETA with non-finite, negative or zero values must be rejected.
- The player may lack enough cash; do not schedule or move the bus before payment validation succeeds.
- A save made during a tow must preserve its route and continue along the same geometry after restore.
- The destination depot address is a dated source reference; label geocoding and MapKit routing as calculated data, not verified site survey or simulated traffic history.

---

### Task 1: Route-aware breakdown towing

**Files:**
- Create: `TransportManagerIDFM/Domain/VehicleTowRouter.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `README.md`

**Interfaces:**
- `VehicleTowRouter.nearestDepot(from:depots:) async throws -> VehicleTowPlan` geocodes the active depot address, requests driving directions, and returns a validated plan. The caller passes only the depot selected for the career; other documented COBs are not staffed in that career.
- `VehicleTowPlan` stores depot identity, route distance, expected travel seconds, destination coordinate, route coordinates, resolved address, calculation time and routing source label.
- `SimulationEngine.scheduleVehicleRepair(incidentID:response:towPlan:)` accepts a plan only for `.towToDepot`, validates route geometry and funds, and persists the plan with the incident.
- `VehicleIncident.towPlan` is optional so older saved incident records continue to decode.

- [x] Implement the MapKit and Core Location router; reject missing or invalid route results.
- [x] Add tow dispatch, tow-arrival and depot repair completion to the saved event flow; show the bus moving on its route and transfer its location to the destination depot.
- [x] Show the selected depot, route distance, MapKit ETA, source links and game-rule cost in the incident response sheet; retain both on-site options on router failure.
- [x] Document that travel routing uses MapKit at dispatch time and that truck availability, repair capacity, traffic history and driver relief remain unmodeled.
- [x] Run the macOS Debug build and resolve compile errors.

**Ruling:** Route towing only to the career's selected depot, even though the scenario documents two COBs. The simulation operates one selected COB and has no depot-transfer or multi-depot staffing model; sending a bus to the other site would leave it incorrectly available to the selected depot's trips. The cost if this is wrong is that a bus cannot use another Bords de Marne COB as a workshop until multi-depot careers are implemented.

**Verification:** `xcodebuild -quiet -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath /tmp/transport-manager-idfm-tow CODE_SIGNING_ALLOWED=NO build` completed successfully. The runtime geocoding/directions result depends on Apple Maps availability and was not exercised by the local build.
