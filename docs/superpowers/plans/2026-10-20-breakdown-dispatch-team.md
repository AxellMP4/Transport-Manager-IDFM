# Breakdown Dispatch Team Implementation Plan

> **For agentic workers:** Inline implementation in this session. Steps use checkbox syntax for tracking.

**Goal:** Model breakdown recovery as a dispatched team arriving at the bus, followed by a separate bus tow to the active depot.

**Architecture:** Keep the current single recovery resource as an explicit game assumption, anchored to the active depot. Calculate and persist both MapKit routes, reserve the team until the bus reaches the depot, and schedule separate arrival events so machinist wait ends at scene arrival while workshop timing starts at depot arrival. Keep new persisted fields optional for existing career files.

**Tech Stack:** Swift, SwiftUI, CoreLocation, MapKit, Codable session/event persistence.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 3.3 and 8.1–8.3.

## Global Constraints

- Target the native macOS SwiftUI application.
- Use explicit MapKit automobile routes for the dispatched team; do not animate the response ETA as a straight line.
- Keep game estimates labeled and separate from verified IDFM fleet data.
- Preserve existing saved careers by adding optional fields and retaining legacy arrival data.

## Review Focus

- A second incident cannot reserve the same recovery unit before it returns to its base.
- The machinist wait ends when the team reaches the incident, not when the bus reaches the depot.
- Workshop slots begin only after the bus reaches the depot.
- Legacy tow plans and sessions decode with their old single-route semantics.
- Dispatch and tow route endpoints, costs, and ETA labels use the correct leg.

---

### Task 1: Two-leg route plan and resource availability

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`
- Modify: `TransportManagerIDFM/Domain/VehicleTowRouter.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- `VehicleTowPlan` retains its current bus-to-depot route and adds optional recovery-team identity, dispatch departure time, dispatch ETA, dispatch distance, and dispatch coordinates.
- `VehicleTowRouter.nearestDepot(from:depots:teamAvailableAt:)` returns both explicit routes.
- `SimulationSession.nextRecoveryTeamAvailableAt(depotID:)` returns the earliest dispatch time for the one simulated unit associated with that depot.

- [x] Calculate the depot-to-incident response route and incident-to-depot bus tow route separately; report combined service distance for the existing per-kilometer game charge.
- [x] Derive dispatch availability from active and planned tow incidents, and validate both route legs before scheduling.

### Task 2: Persisted dispatch and tow events

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Add `.vehicleTowTeamArrived(incidentID:)`; keep `.vehicleTowArrived(incidentID:)` for bus arrival at the depot.
- Add optional `recoveryTeamArrivedAt` and `depotArrivedAt` incident timestamps; retain `towArrivedAt` for legacy saved data.

- [x] Schedule team-arrival, depot-arrival, workshop-start, and repair-completion events from the two legs and preserve old saved sessions.
- [x] Stop machinist waiting at team arrival; start workshop occupancy at depot arrival.

### Task 3: Player-facing status and documentation

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `README.md`

- [x] Show unit availability, response route and ETA, tow route and ETA, and the game-rule cost basis in the incident UI.
- [x] Update the map/incident status to distinguish “team en route,” “team arrived,” and “bus at depot.”
- [x] Record the single-unit assumption and remaining fleet-management limits.

**Verification:** successful `xcodebuild` Debug macOS build and `git diff --check`. No test target is used in this implementation pass.
