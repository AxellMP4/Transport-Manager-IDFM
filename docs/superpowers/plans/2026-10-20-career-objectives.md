# Career Objectives Implementation Plan

> **For agentic workers:** Implement natively in this session; do not add or run tests unless the user requests them.

**Goal:** Add a small, persistent-by-derivation onboarding path that teaches a player to acquire a bus, hire staff, complete a trip, and reach the first daily report.

**Architecture:** Derive four objective states from `SimulationSession` fleet data and saved event/report history. Render them in the active career scenario panel; do not add duplicate save state or financial rewards.

**Tech Stack:** Swift 6, SwiftUI, native macOS 14 app.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md` sections 3, 12, and 13.

## Global Constraints

- The deliverable remains a native macOS game written in Swift and created in Xcode.
- Persist events in simulated-time order and retain the network version in each save.
- Explain uncertain game rules and do not present them as verified operating or contract facts.
- Do not add or run tests unless requested.

## Review Focus

- A new career starts with an empty fleet and no machinists; the panel must show these steps as incomplete.
- A bus still in delivery must not complete the vehicle objective.
- Replacement departure events must not count as a completed trip.
- A trip completed at a closed terminus still counts as a completed course.
- Existing and legacy saves must derive progress from available fields without requiring migration.

---

### Task 1: Derive and show career objectives

**Files:**
- Create: `TransportManagerIDFM/Domain/CareerObjectives.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

**Interfaces:**
- Produce `CareerObjective` with stable ID, title, short instruction, current count, target count, and completion state.
- Produce `CareerObjectiveCatalog.objectives(for session: SimulationSession) -> [CareerObjective]`.
- Derive progress from delivered fleet vehicles, current machinists, completed service events, and saved daily reports.

- [x] Add the computed objective model and four starter objectives.
- [x] Add an active-career card with each objective's progress and the next incomplete instruction.
- [x] Record the feature in implementation status and compile the macOS Debug app.

## Verification

- `xcodebuild -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -sdk macosx -derivedDataPath /private/tmp/transport-manager-idfm-derived CODE_SIGNING_ALLOWED=NO build` — succeeded.
- No tests were added or run.
