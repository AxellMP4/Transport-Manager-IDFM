# Workshop Capacity Expansion Implementation Plan

> **For agentic workers:** Implement this plan inline in the current workspace. Steps use checkbox syntax for tracking.

**Goal:** Let the player purchase and complete a second depot repair bay, increasing the saved workshop queue capacity.

**Architecture:** Add an optional saved capacity and construction completion date, charge the investment at order time, and complete the upgrade through a persisted simulation event. Workshop scheduling and tow estimates use one bay until construction finishes and two bays afterward. Older saves default to one bay.

**Tech Stack:** Swift 6, SwiftUI, Codable simulation events.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 8.3, 11.3, 12 and 14 (phases G and H).

## Global Constraints

- Preserve old career JSON by defaulting absent workshop fields to the existing one-bay capacity.
- Keep the investment and construction duration explicitly labeled as game rules; use €150,000 and seven simulated days.
- Charge the investment once when ordered and retain the pending completion event through save/export/import.
- Do not increase effective capacity before the completion event.
- Do not add or run tests; verify the macOS target with `xcodebuild`.

## Review Focus

- An old save with no workshop fields must continue with one bay.
- A purchase with insufficient cash or an existing/past upgrade must not mutate cash, ledger or events.
- Tow and preventive-maintenance reservations must both use the same effective capacity.
- Queued jobs that start after the expansion date must be able to use the second bay.
- Save/restore while construction is pending must finish the upgrade exactly once.

---

### Task 1: Persist the workshop expansion investment

**Files:**
- Modify: `TransportManagerIDFM/Domain/VehicleMarket.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

- [x] Define base/max bay counts, price and build duration as workshop game rules.
- [x] Add optional session capacity/construction fields with legacy defaults, a plan method, ledger debit and a persisted completion event.
- [x] Apply the completion event to increase capacity exactly once.

### Task 2: Schedule work against dynamic capacity

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

- [x] Pass current capacity and pending expansion completion into preventive-maintenance, tow-repair and estimate scheduling.
- [x] Let the queue advance to either a job completion or construction completion before retrying a slot.

### Task 3: Expose the investment and document it

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Show current capacity and construction ETA in the workshop panel; allow the one-time purchase and show its price and duration.
- [x] Show dynamic capacity in the incident repair estimate.
- [x] Document the game rules and build the macOS target successfully.
