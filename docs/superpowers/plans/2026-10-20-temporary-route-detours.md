# Temporary Route Detours Implementation Plan

> **For agentic workers:** This plan is executed in the current TransitCity workspace. Use the existing project design as approved authority. Do not add or run automated tests; compile the macOS app for verification.

**Goal:** Let the player plan a temporary MapKit road detour on a route segment, see it on the operations map, and apply its saved path and added time to future GTFS trips that traverse that segment while the incident is active.

**Architecture:** Keep the detour as optional, Codable session state so earlier saves still decode. The simulation transforms stop visits before scheduling a matching future trip: it substitutes the movement geometry and shifts downstream stop, passenger-demand, completion, machinist-duty, and vehicle-reservation times by the chosen delay. A MapKit router returns candidate road paths; the native operations map hosts the route-scoped editor and renders the saved temporary geometry.

**Tech Stack:** Swift, SwiftUI, MapKit, Codable; existing GTFS timetable and event engine.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, especially sections 3.3, 7, 9, 10 and 13. This is one implementation slice of section 9; it does not close the full detour, passenger-redirection, accessibility, or network-coverage requirements.

## Global Constraints

- The project targets native macOS in Swift with SwiftUI and MapKit; do not add external dependencies.
- Simulation timing and event processing must not depend on view redraw frequency.
- Preserve compatibility with saved sessions that predate route detours by making the new session collection optional and reading missing values as an empty list.
- Store selected detour coordinates and delay in the session; resuming a save must not require MapKit to recalculate an already planned path.
- Use exact route, stop ID, and directed stop sequence matching; do not match a service segment by public line name alone.
- Keep the route geometry and added time labeled as MapKit/game estimates, not IDFM operational data.
- Follow the existing operations-map and simulation-event patterns and preserve the source GTFS schedule.

## Review Focus

- An old save without detour data still decodes and behaves as before.
- A detour whose route, ordered stop pair, or active window does not match a dispatched trip has no effect on that trip.
- Coordinates must be finite, within latitude/longitude bounds, and joined to the exact segment endpoints.
- Added time shifts every downstream event and both bus/machinist reservations without changing the departure before the affected segment.
- Extending an incident moves its scheduled end event once; a stale prior end must not terminate the extended incident.

---

### Task 1: Persist detour incidents and apply them to scheduled trips

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Add `SimulatedRouteDetour: Codable, Hashable, Identifiable, Sendable` with an ID, route ID, from/to stop IDs, names and sequences, `startsAt`, `scheduledEndAt`, optional `endedAt`, saved `[BusMovementCoordinate]`, and `additionalTravelSeconds`.
- Add optional `SimulationSession.routeDetours: [SimulatedRouteDetour]? = nil` and `activeRouteDetours`/lookup helpers.
- Add `scheduleRouteDetour(routeID:orderedRouteVisits:fromVisit:toVisit:startsAt:endsAt:replacementCoordinates:additionalTravelSeconds:) throws -> SimulatedRouteDetour` and `extendRouteDetour(id:to:) throws -> SimulatedRouteDetour`. Pass the ordered stops from the selected GTFS trip so the engine can verify the endpoint pair is adjacent.
- Add distinct route-detour scheduled, started, and ended event kinds and event summaries. On end, update `endedAt` only when the stored `scheduledEndAt` equals the event time.
- Add a detour-specific movement geometry source.

- [x] Validate that the route is operated, the selected visits form a forward adjacent segment with valid endpoint coordinates, the incident window is positive, the added time is finite and nonnegative, and the saved replacement path begins/ends at those stop coordinates.
- [x] Reject overlapping incidents for the same route and directed segment; allow extension only to a later end time and replace the old pending end event.
- [x] In `dispatchScheduledDeparture`, match detours by route, ordered endpoint IDs/sequences, and segment departure time within the active window. Replace only that segment's coordinates and shift all stop visits from its destination onward by the added seconds before creating demand, movement, and completion events.
- [x] Use the transformed end time for bus reservation and machinist duty. Persist the selected coordinates so an already saved detour survives GTFS and network-version changes.
- [x] Manually inspect Codable compatibility and event ordering against the review-focus cases; do not add tests.
- [x] Verify the target with `xcodebuild -quiet -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build`.

### Task 2: Produce saved MapKit route alternatives

**Files:**
- Create: `TransportManagerIDFM/Domain/RouteDetourRouter.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`

**Interfaces:**
- Add `RouteDetourCandidate: Identifiable, Hashable, Sendable` containing route distance, expected travel time, and `[BusMovementCoordinate]`.
- Add `RouteDetourRouter.alternatives(from:to:departureAt:) async throws -> [RouteDetourCandidate]` using `MKDirections` with alternate automobile routes.

- [x] Convert each valid `MKRoute` polyline to stored coordinates, explicitly pin the first and last coordinate to the selected GTFS stop coordinates, and discard malformed or zero-length candidates.
- [x] Sort candidates by expected travel time then distance and return a user-readable error when MapKit provides no valid alternative.
- [x] Add the new source file to the Xcode project’s Domain group and Sources build phase.
- [x] Verify the macOS build using the command in Task 1.

### Task 3: Author, inspect, and display detours on the operations map

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- Add a route-detour editor launched from the selected stop detail for one of its operated route IDs.
- The editor loads the active version’s timetable, offers only valid directed adjacent stop segments with future service, requests MapKit alternatives, and calls `SimulationEngine.scheduleRouteDetour` with the selected path and delay.

- [x] Provide route, segment, start/end window, candidate path, distance, expected travel time, and added-time controls with clear MapKit/game-estimate labels.
- [x] Explain that v1 applies to matching trips dispatched after the detour is recorded; already dispatched buses are not retroactively rerouted.
- [x] Add a distinct dashed `MapPolyline` for active detours to the operations map and show their route, segment, remaining time, and extension action.
- [x] Keep the existing stop-closure UI and behavior available independently.
- [x] Verify the macOS build using the command in Task 1.

### Task 4: Record the delivered scope and remaining section 9 gaps

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Record the route/time matching and downstream delay behavior as implemented only after Tasks 1–3 are complete.
- [x] Keep passenger redirection to replacement stops, pedestrian distance/accessibility, detours for already running buses, route-wide replacement-stop effects, and official real-world road incidents explicitly open.
- [x] Build the app and confirm the bundled application contains the new compiled behavior.

## Self-Review

- **Spec coverage:** Tasks 1–3 cover the first persistent, player-authored route-segment detour with saved geometry, simulation delay, route map display, and automatic time-window expiry/extension. Section 9’s alternate stops, pedestrian routing, accessibility, real incident imports, traveller messaging, and already-running bus retiming remain open by design and are listed in Task 4.
- **Step scan:** Each task has a bounded owner, exact files, and checkable implementation/build outcomes. The UI consumes Task 1 and Task 2 interfaces without changing their shapes.
- **Type consistency:** The router returns `[BusMovementCoordinate]`, which the engine persists on `SimulatedRouteDetour`; the editor passes exact `ScheduledTripStopVisit` endpoints to the engine API.
- **Review focus:** Compatibility, match misses, coordinate validation, downstream timing, and incident extension all map to explicit Task 1 implementation checks; build verification covers integration.
- **Proportion:** The plan describes one v1 feature from the approved larger game spec, with explicit remaining requirements so it cannot be mistaken for completion of the full goal.
