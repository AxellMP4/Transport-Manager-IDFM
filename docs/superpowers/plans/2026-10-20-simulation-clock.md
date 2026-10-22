# Simulation Clock and Save Foundation Plan

> **For agentic workers:** Execute inline in this workspace; verify with the macOS build and project-file lint.

**Goal:** Add a persistent, event-aware game clock with the speed controls specified in the IDFM management-game plan and bind the stop schedule filter to that clock.

**Architecture:** A Codable career snapshot pins the scenario, selected depot and all active network versions, plus simulated time, speed, random seed and ordered events. A main-actor engine advances from monotonic real elapsed time, processes every crossed event in timestamp/sequence order, and autosaves locally. Restored careers start paused and resume only after a visible user action.

**Tech Stack:** Swift 6, SwiftUI, Foundation, Combine, local JSON saves.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 3, 7, 13 and Phase F.

## Global Constraints

- At ×1, simulated time advances by the measured real elapsed time; supported speeds are pause, ×1, ×2, ×5, ×10, ×30, ×60 and ×300.
- Never skip events when a tick crosses more than one scheduled timestamp; equal-time events retain insertion order.
- A career save pins network version IDs and stores simulated date, speed and random seed.
- Do not start a career unless `NetworkCatalog.isPlayable` is true.
- Do not add or run tests unless explicitly requested; verify with a macOS build and project-file lint.

## Review Focus

- Speed changes apply the old speed through the change instant before using the new speed.
- Long real-time gaps and ×300 advancement process every crossed event in stable order.
- Restoring a save does not advance time until the player resumes.
- Network version pins remain attached to a career even if the active catalog later changes.
- Save failures are surfaced to the player and do not silently discard the in-memory career.

---

### Task 1: Add the simulation session and clock engine

**Files:**
- Create: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Produce `SimulationSpeed`, `SimulationEvent`, `SimulationSession`, `SimulationDataVersions`, `SimulationSaveStore`, and `SimulationEngine`.
- `SimulationEngine.startNew(scenarioID:depotID:networkVersions:startDate:) throws` creates and persists a new session.
- `SimulationEngine.isDirectionScheduled` integration stays in `NetworkLibrary`; clock state is exposed as `session` and `isRunning`.

- [x] Add the supported speeds and Codable event/session models, with deterministic timestamp then sequence ordering.
- [x] Advance from monotonic elapsed time, process all crossed events, provide pause/resume/next-event controls, and autosave to Application Support.
- [x] Load the newest saved session paused; retain its saved speed and data-version pins.

### Task 2: Connect the engine to the game interface

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

- [x] Add the preparation date/time and start a session only after the catalog gate passes.
- [x] Show persistent simulation time, speed selection, pause/resume, next-event action and save status while a session exists.
- [x] Make the stop detail use the session clock; retain its exploratory date/time picker before a career starts.
- [x] Disable source imports during an active saved career so its pinned data cannot silently change underneath it.

### Task 3: Update progress and verify

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`

- [x] Record clock, save and event-order foundations while keeping actual trip movement and event effects pending.
- [x] Run `xcodebuild -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -destination 'generic/platform=macOS' -derivedDataPath /private/tmp/transport-manager-idfm-derived CODE_SIGNING_ALLOWED=NO -quiet build`.
- [x] Run `plutil -lint TransportManagerIDFM.xcodeproj/project.pbxproj`.
