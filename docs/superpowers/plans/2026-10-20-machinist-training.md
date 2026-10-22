# Machinist Qualification Training Implementation Plan

> **For agentic workers:** Continue inline in this workspace. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a standard-qualified machinist complete a scheduled articulated-bus training course, become qualified at its end, and charge the training time to the career.

**Architecture:** Store training records in the Codable career session and process qualification upgrades through a dated simulation event. Training reserves an eight-hour simulated duty interval, uses the existing hourly labor estimate, and obeys the same 11-hour rest rule as other duty blocks. The Personnel screen schedules, tracks, and cancels courses that have not started.

**Tech Stack:** Swift 6, SwiftUI, Foundation, existing event simulation and JSON save model.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 7, 11.3, 12 and Phase H; `docs/IMPLEMENTATION_STATUS.md`, workforce gaps.

## Global Constraints

- Training may not overlap a service, another training, or a planned absence.
- Require the existing 11-hour game rest between training and service duty blocks.
- Only upgrade a machinist from standard to articulated qualification.
- Use an eight-hour simulated training block and the existing estimated loaded hourly wage; label both as game rules.
- Keep training records optional in older saved sessions and do not change existing JSON keys.
- Do not add or run tests unless requested; verify with the macOS Debug build.

## Review Focus

- Old career saves without training records still decode.
- Scheduled training prevents an overlapping or insufficiently rested dispatch.
- Qualification changes exactly once, only when its completion event is processed.
- Cancellation is limited to unstarted training, removes its pending event, and does not charge wages.
- Completed training is charged once at completion and appears in the financial ledger.

### Task 1: Persist training and apply qualification upgrades

**Files:**
- Modify `TransportManagerIDFM/Domain/VehicleMarket.swift`.
- Modify `TransportManagerIDFM/Domain/SimulationEngine.swift`.

- [x] Add a backward-compatible optional training collection to `SimulationSession` and a Codable training record with source qualification, target qualification, interval, estimated labor cost, and completion/cancellation dates.
- [x] Add an eight-hour course rule, a completion event, and event application that upgrades standard to articulated and records the wage expense once.
- [x] Add engine scheduling and cancellation operations; reject invalid qualification, stale dates, duplicate active training, and cancellation after the course starts.

### Task 2: Enforce workforce availability and rest

**Files:**
- Modify `TransportManagerIDFM/Domain/SimulationEngine.swift`.

- [x] Include scheduled and completed training intervals in machinist availability checks; a course blocks overlapping work and requires the established 11-hour rest on either side.
- [x] Reject training that overlaps an absence or service duty block; reject absences that overlap scheduled training.
- [x] Ensure cancelled training is ignored by availability checks and its completion event is removed.

### Task 3: Add training controls to Personnel

**Files:**
- Modify `TransportManagerIDFM/Features/OperationsDashboardView.swift`.

- [x] Add a training editor for an eligible standard-qualified machinist, showing its start, eight-hour duration, estimated wage cost, qualification result, and rest rule.
- [x] List upcoming, active, completed, and cancelled courses; expose cancellation only before the start.
- [x] Show the articulated qualification after the completion event and remove the upgrade action.

### Task 4: Update project status and build

**Files:**
- Modify `README.md` and `docs/IMPLEMENTATION_STATUS.md`.
- Update this plan and `.superpowers/sdd/2026-10-20-machinist-training/progress.md`.

- [x] Document training progression, its game-rule duration/pay basis, and remaining HR gaps.
- [x] Run the macOS Debug build and resolve compilation errors; do not run tests.

**Ruling:** Training duration is eight simulated hours and uses the current qualification's estimated hourly labor cost. These are visible simulation rules, not a claim about real driver-training requirements; cost if wrong: qualification progression may be faster or cheaper than the career's desired balance.
