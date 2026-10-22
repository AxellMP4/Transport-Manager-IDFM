# PRIM Traffic Alerts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist each newly consulted PRIM line report as a reviewable career alert and connect it to the existing detour workflow.

**Architecture:** Add a backward-compatible optional alert collection to `SimulationSession`, ingest and deduplicate reports in `SimulationEngine`, and expose the saved alert queue in the Incidents workspace. Reuse the existing PRIM fetch and `RouteDetourEditorView`; only a player-confirmed detour changes simulated service.

**Tech Stack:** Swift, SwiftUI, Codable, Xcode macOS target.

**Spec:** `docs/superpowers/specs/2026-10-21-prim-traffic-alerts-design.md`.

## Global Constraints

- PRIM requests remain manual and require the saved API token.
- Persist only reports for routes operated by the active career; use canonical IDFM line ID plus report ID for deduplication.
- Keep the official observation separate from simulated incidents and do not change service before the player saves a detour.
- Existing saves without alert data remain readable.
- Expired reports stay in history but cannot start a new detour; unknown periods remain explicitly unevaluated.
- Build the Debug macOS target; do not add or run automated tests in this change.

## Review Focus

- Re-fetching an unchanged report updates `lastSeenAt` without creating a duplicate.
- Reports fetched before a career or for an unoperated route are not attached to the career.
- A dismissed report remains visible in history and a newer source update can be reviewed again.
- Scheduling a detour from an alert marks that alert handled and links the detour ID.
- No fetched report changes service, passenger demand, finance, or events until the player saves a detour.

---

### Task 1: Add persistent alert lifecycle to the simulation

**Files:**
- Modify: `TransportManagerIDFM/Domain/TrafficInformation.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Consumes: `PRIMTrafficFetchResult`, `PRIMTrafficObservation`, `SimulationSession.effectiveOperatedRouteIDs(for:)`.
- Produces: `SimulationEngine.recordPRIMTrafficReports(...)`, `dismissPRIMTrafficAlert(id:)`, and `PRIMTrafficAlert` with stable identity, source dates, disposition, and optional linked detour ID.

- [x] Add the alert model and optional save field with backward-compatible defaults.
- [x] Ingest reports for operated routes, deduplicate by canonical IDFM ID and report ID, update last-seen data, and reopen dismissed alerts when the source update changes.
- [x] Mark a source alert as detour-planned when `scheduleRouteDetour` saves its sourced detour; add a dismiss operation.

### Task 2: Connect PRIM fetches and show alerts in the Incidents workspace

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- Consumes: alert model and engine operations from Task 1.
- Produces: successful route fetches automatically enter the active career’s review queue; the Incidents workspace offers “Préparer une déviation” and “Ignorer”.

- [x] Pass the simulation into the PRIM route view and ingest fetched reports only for an active career route.
- [x] Display the persisted alert history, current status, source, application period, and actions in Incidents.
- [x] Route the prepare action through the existing `RouteDetourEditorView` and refresh the UI with the saved alert status.

### Task 3: Record scope and validate the macOS target

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Record the implemented alert lifecycle and separately note that actual PRIM content remains unverified without the authenticated token.
- [x] Run `swiftc -frontend -parse` on modified Swift files and build the Debug macOS target.
