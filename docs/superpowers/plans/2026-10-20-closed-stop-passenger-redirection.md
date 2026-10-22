# Closed Stop Passenger Redirection Implementation Plan

> **For agentic workers:** Execute this plan in the current TransitCity workspace. Do not add or run automated tests; compile the macOS app and manually inspect compatibility and queue cases.

**Goal:** Let an operator close one served stop for one operated route, guide passengers to a selected replacement stop on that route with a saved MapKit walking path, and resume pickup there.

**Architecture:** Extend persisted stop-closure records with optional per-route replacement guidance so old saves continue decoding. Move the queue already waiting at a closed stop when the closure starts, then redirect later estimated arrivals during passenger exchanges. Move passengers ending a trip at a closed terminal to the replacement queue. A dedicated MapKit pedestrian router and SwiftUI sheet let the player inspect the walking path and distance before recording the closure.

**Tech Stack:** Swift 6, SwiftUI, MapKit, existing GTFS stop index and event engine.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 9 and 11.1.

## Global Constraints

- Keep closures route-scoped when a replacement stop is selected; a replacement must be served by every route it replaces.
- Preserve existing all-route stop-closure actions when no replacement guidance is supplied.
- Store exact GTFS stop IDs, MapKit walking coordinates, distance, and estimated duration in the career save.
- Treat pedestrian accessibility as unknown unless a dated source provides evidence; MapKit walking directions are not proof of wheelchair access.
- Keep route-segment detours and their non-retroactive dispatch behavior independent from stop closures.
- Do not describe MapKit routes, walking times, passenger counts, or accessibility as official IDFM data.

## Review Focus

- Old saves whose stop closures lack replacement fields still decode and retain current behavior.
- A replacement equal to the closed stop, outside the GTFS version, or not served by the affected route is rejected.
- A closed stop with guidance transfers its existing waiting queue immediately and later estimated arrivals exactly once into the replacement queue; the closure event records the initial transfer count.
- A closed terminal sends onboard passengers to the replacement queue; a closure without guidance retains current stranded behavior.
- Closures affecting only a subset of routes redirect only those route queues.
- Accessibility remains visibly unknown and is not inferred from MapKit geometry.

---

### Task 1: Persist replacement guidance and redirect simulated passengers

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Add `StopClosureAccessibilityEvidence` with `.unknown` and `StopClosureReplacementGuide: Codable, Hashable, Sendable` containing route ID, exact replacement stop ID/name/coordinate, saved walking coordinates, route distance, expected walking seconds, and accessibility evidence.
- Add optional `replacementGuidesByRouteID: [String: StopClosureReplacementGuide]?` to `SimulatedStopClosure`.
- Extend `PassengerStopExchange` with optional redirected count, replacement stop ID, and replacement waiting count.
- Extend `closeStop(...)` with a default-empty `replacementGuidesByRouteID` argument.

- [x] Validate guide keys against the affected operated routes; require distinct stops, valid endpoints, a finite nonzero path/distance, finite positive walking time, and unknown accessibility unless supported evidence is supplied.
- [x] At closure start, move the existing closed-stop queue to the selected replacement queue and record its count in the closure event; during later passenger-demand events, move new estimated arrivals and record those redirects in the exchange history. Without a guide, retain the current waiting behavior.
- [x] When a trip terminates at a closed stop, move stranded onboard passengers to that route’s replacement queue when one is configured; otherwise preserve the existing queue behavior.
- [x] Manually inspect queue writes for double counting, route scoping, Codable compatibility, and behavior when no replacement exists.

### Task 2: Calculate and review a pedestrian replacement route

**Files:**
- Create: `TransportManagerIDFM/Domain/StopReplacementRouter.swift`
- Create: `TransportManagerIDFM/Features/StopClosureEditorView.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`

**Interfaces:**
- Add `StopReplacementWalkingRoute` with distance, expected walking seconds, and saved `[BusMovementCoordinate]`.
- Add `StopReplacementRouter.walkingRoute(from:to:) async throws` for `GTFSStopSummary` endpoints.
- Add a route-scoped request from the stop detail and a native sheet that selects another stop served by the exact operated route, chooses a closure duration, previews the walking route, and calls `SimulationEngine.closeStop` with the saved guide.

- [x] Reject invalid/equal stops, malformed coordinates, failed MapKit routes, and malformed/zero-length walking geometry; pin path endpoints to exact GTFS stop coordinates.
- [x] Display walking distance and estimated time, and state in the editor that accessibility is not verified by GTFS or MapKit.
- [x] Close the existing stop popover before presenting the editor; preserve the existing one-hour/four-hour all-route closure actions.
- [x] Verify the macOS build with `xcodebuild -quiet -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build`.

### Task 3: Show active guidance and record scope

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Render the active pedestrian guidance as a distinct dashed map line and identify its replacement stop.
- [x] Show the replacement stop, walking estimate, and unknown accessibility status in the affected stop detail and closure event summary.
- [x] Keep closure and route-detour overlays visually distinct and preserve the existing closure expiration event.
- [x] Document passenger redirection as implemented while leaving official incident imports, evidence-backed accessibility, passenger messaging, and replacement stops requiring a route geometry change open.
- [x] Build the macOS app and confirm the compiled universal executable contains the replacement-routing UI and engine behavior.

## Self-Review

- Scope is limited to stop closures with a replacement already served by the affected route. It does not modify the bus path or replace the separate route-segment MapKit detour system.
- Old closures retain empty replacement guidance through optional Codable fields; old closures therefore behave as before.
- The initial waiting queue transfer is applied atomically when the closure is recorded and its count is saved in that closure’s event; later arrivals are applied atomically through exchange events.
- Passengers from a closed terminal with a configured replacement use a distinct history event so redirected riders do not inflate stranded/left-behind totals.
- Accessibility remains explicitly unknown because the indexed GTFS stop model does not carry evidence that would support an accessibility claim.
