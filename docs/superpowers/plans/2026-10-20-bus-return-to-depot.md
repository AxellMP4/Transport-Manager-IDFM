# Bus Return to Depot Implementation Plan

**Goal:** Let a bus at a terminus return to its career's selected depot over a saved MapKit road route, with the road distance included in fleet usage and energy accounting.

**Architecture:** Reuse the existing MapKit route workflow and `recordTripDistance` accounting path. A validated return plan is stored in the start event; the bus carries a saved movement leg until a dated arrival event places it at the selected depot. The fleet panel calculates and shows the route estimate before dispatch.

**Tech Stack:** Swift 6, SwiftUI, MapKit, Core Location, Codable simulation events.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 5, 7, 13 and 14 (phase F).

## Global Constraints

- Keep the game native to macOS with SwiftUI and Apple MapKit.
- Keep events, route coordinates, and movement state in the career save.
- Route only to the depot selected for the current career; do not infer site coordinates.
- Preserve existing career saves with additive Codable fields or event cases.
- Mark road routing and energy as calculated/estimated; do not present them as real-time traffic history or official operating costs.

## Review Focus

- A stale plan or a bus that moved while MapKit was routing must not be dispatched.
- Invalid or non-finite route coordinates, distance, or ETA must be rejected.
- A route must target the active career depot and originate at the bus's saved location.
- Saving during the trip must preserve the route and complete at the same depot after restore.
- The return leg must add odometer, wear, energy, and ledger entries without contract revenue.

## Files

- Modify `TransportManagerIDFM/Domain/SimulationEngine.swift` for the Codable plan/event, validation, scheduling, movement, and accounting event.
- Modify `TransportManagerIDFM/Domain/VehicleMarket.swift` for the returning-to-depot status.
- Modify `TransportManagerIDFM/Domain/VehicleDeadheadRouter.swift` for address resolution and MapKit directions from a terminus to the active depot.
- Modify `TransportManagerIDFM/Features/OperationsDashboardView.swift` for an estimate/confirmation action, map visibility, and fleet status.
- Update `README.md` and `docs/IMPLEMENTATION_STATUS.md` with scope and remaining driver-relief limitations.

## Implementation Steps

- [x] Add the return-route model and event cases; route to the selected depot from the current bus coordinate and validate the result.
- [x] Schedule the return trip only while the bus is idle at a stop; animate its saved movement leg and place it at the depot on arrival.
- [x] Record the return distance through existing non-service odometer, wear, and energy accounting, with no service contribution.
- [x] Add fleet UI to calculate a current route, review distance/ETA/estimated energy, confirm dispatch, and show the moving bus on the map.
- [x] Update the checklist and README; typecheck all Swift sources and compile/link the macOS arm64 executable.

## Follow-up — machinist assignment and pay

The initial return route accounted for the bus but not the person driving it. The follow-up uses the machinist from the bus's most recent course, checks qualification, conflicts, the 2-hour gap and 10-hour block limit, and allows the same duty block to reopen. When a previously settled block is extended, only the incremental payroll is posted to preserve the existing journal entry.

- [x] Assign the latest course machinist to the return and persist it as a normal service assignment.
- [x] Reopen a recent duty block when the return fits its existing game rules; otherwise require a new block after minimum rest.
- [x] Settle the return or block extension at arrival, with an idempotent payroll record and correct cash delta.
- [x] Show the assigned machinist and estimated payroll alongside the route and energy estimate.
- [x] Document that machinist location is not modeled; typecheck all sources and compile/link the arm64 executable.
- [x] Bind the saved return movement and arrival to a destination snapshot for the active depot address; verify the arrival against the route endpoint and saved destination while allowing older saves to validate against their final route coordinate.
