# Incident Diagnosis Implementation Plan

**Goal:** Add a saved, timed diagnosis decision before repair choices for newly generated breakdowns.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 8.1–8.2.

**Rules:** The diagnosis is a fictional, deterministic gameplay result. It takes 15 simulated minutes and costs €180. It does not claim to identify a real mechanical fault. Existing saves without the new optional fields keep their direct repair flow.

**Files:**
- Modify `TransportManagerIDFM/Domain/SimulationEngine.swift`.
- Modify `TransportManagerIDFM/Features/OperationsDashboardView.swift`.
- Modify `docs/IMPLEMENTATION_STATUS.md`.

## Steps

- [x] Add optional diagnosis state to incidents and a persisted completion event.
- [x] Schedule and charge for the diagnosis, process intervening events, and pause at its result.
- [x] Gate repair and reserve-bus dispatch on completed diagnosis for new incidents.
- [x] Show the fictional finding, recommendation, duration, and cost in the incident UI and history.
- [x] Include diagnosis spending in daily incident expenses and document its limits.
- [x] Build the macOS target.

## Verification

- Build the macOS target with `xcodebuild`.
- Do not add or run tests for this task.
