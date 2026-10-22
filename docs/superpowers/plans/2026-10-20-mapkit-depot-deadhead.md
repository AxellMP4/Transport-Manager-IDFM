# MapKit Depot Deadhead Implementation Plan

> **For agentic workers:** Use the existing project execution workflow and complete this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Route a bus from its career depot to the first GTFS stop before the scheduled service time, and account for that deadhead as work and vehicle movement.

**Architecture:** Resolve the selected depot address and request a MapKit automobile route to the first stop coordinate. Persist the route and the derived leave/arrival times as simulation events; reject depot dispatch when the bus cannot reach the stop by its GTFS departure. Preserve assignment from a bus already waiting at the first stop.

**Tech Stack:** Swift 6, SwiftUI, MapKit, Core Location, Codable simulation events.

**Spec:** `docs/IMPLEMENTATION_STATUS.md` — Phase in progress, item “Modéliser la sortie du dépôt et l’acheminement au premier arrêt”.

## Global Constraints

- Preserve existing saved careers by adding only optional model properties or new Codable enum cases with compatible decoding.
- Use the session's selected depot and versioned GTFS first-stop coordinates; do not infer a depot from route or contract geometry.
- The scheduled first-stop departure remains the service start; deadhead arrival must be no later than that time.
- MapKit routing and the depot geocode are calculated data, not proof of the actual entrance, current traffic, or a surveyed route.
- Deadhead distance contributes to odometer, energy and wear, but not to provisional passenger-service revenue.
- Do not add or run tests unless the user asks; verify compilation with the macOS build.

## Review Focus

- A route that would arrive after the first stop's scheduled departure must not be dispatched from the depot.
- A route calculated for a different depot, first stop, origin, or stale request must be rejected.
- A bus already at the first stop remains dispatchable without a MapKit route.
- A save during deadhead must continue the same path and arrive at the same scheduled stop.
- Deadhead distance changes odometer, energy and condition exactly once and earns no service revenue.

---

### Task 1: Plan and validate depot-to-stop routes

**Files:**
- Create or modify `TransportManagerIDFM/Domain/VehicleDeadheadRouter.swift`.
- Modify `TransportManagerIDFM/Domain/SimulationEngine.swift` for the Codable `VehicleDeadheadPlan`.

**Interfaces:**
- Produce `VehicleDeadheadRouter.route(from depot: DepotReference, to stop: ScheduledTripStopVisit, serviceStartAt: Date, earliestDepartureAt: Date) async throws -> VehicleDeadheadPlan`.
- Persist depot ID/name, exact requested source address and geocoded address, stop ID/name/coordinates, route distance, ETA, route coordinates, calculation time, and source title.
- Choose the shortest valid route whose ETA permits departure no earlier than the current simulated time.
- Compute planned leave time as scheduled first-stop departure minus route ETA; reject invalid geometry, stale plans, mismatched depot/stop/origin/destination, or a leave time before the current simulated time.

- [x] Implement MapKit geocoding and automobile routing, returning a validated saved plan.
- [x] Pass a plan only for a bus selected at the career's active depot; leave buses at the first stop route-free.

### Task 2: Schedule and simulate deadhead movement

**Files:**
- Modify `TransportManagerIDFM/Domain/SimulationEngine.swift`.
- Modify `TransportManagerIDFM/Domain/VehicleMarket.swift` for the in-motion status.

**Interfaces:**
- Extend `dispatchScheduledDeparture(eventSequence:vehicleID:machinistID:stopVisits:deadheadPlan:)` with an optional `VehicleDeadheadPlan`.
- Add Codable events for deadhead departure and arrival. Their processing starts the saved movement leg, positions the bus at the first stop on arrival, and leaves the existing `busDeparted` event at its GTFS time.
- Start the machinist duty block at the deadhead leave time when a route exists.

- [x] Schedule leave and arrival events with stable sequence order and retain the same plan in save data.
- [x] Account deadhead distance once in the odometer, wear, energy use and ledger; record zero service revenue.

### Task 3: Expose the route in dispatch and on the map

**Files:**
- Modify `TransportManagerIDFM/Features/OperationsDashboardView.swift`.
- Modify `README.md` and `docs/IMPLEMENTATION_STATUS.md`.

- [x] Calculate and display route distance, MapKit ETA, planned leave time and arrival time when a depot bus is selected.
- [x] Disable depot dispatch while routing, when routing fails, when simulated time passes the planned leave time, or when arrival would miss the scheduled first stop; keep first-stop buses usable.
- [x] Draw the deadhead polyline and show the bus moving to the first stop.
- [x] Document that depot exits are now routed while full network-data validation and missing-shape coverage remain outstanding.
- [x] Run the macOS Debug build and resolve compilation errors.

**Review findings resolved:** Keep the dispatch button disabled and show an explanation if simulated time passes the calculated leave time; persist and validate the exact depot address sent for geocoding; gate every asynchronous route response with a fresh request UUID so A→B→A selection cannot revive an old plan; filter route alternatives by the available time before selecting the shortest feasible route.

**Ruling:** Use MapKit's ETA at calculation time as the full lead time and schedule departure so the bus arrives exactly at the GTFS time. When alternatives exist, choose the shortest route that fits before the scheduled first-stop time and after the current simulated time. GTFS supplies no depot-to-stop drive time or layover margin; the cost if MapKit's ETA is optimistic is that real future traffic could make the bus late.

**Verification:** `xcodebuild -quiet -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath /tmp/transport-manager-idfm-deadhead-verified CODE_SIGNING_ALLOWED=NO build` completed successfully (exit code 0). Xcode logged unavailable CoreSimulator services while building the macOS target. No tests were run, per this plan. MapKit geocoding/directions and the animation still require runtime verification with Apple Maps availability; the local build alone does not establish either.
