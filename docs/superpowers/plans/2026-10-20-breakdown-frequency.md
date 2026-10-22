# Breakdown Frequency Setting Implementation Plan

> **For agentic workers:** Implement this plan inline in the current workspace. Steps use checkbox syntax for tracking.

**Goal:** Let a player choose a lower, standard, or higher deterministic breakdown frequency when preparing a career, and preserve that rule in saves.

**Architecture:** Add a Codable domain setting with explicit gameplay multipliers. Carry it from the career preparation view into `SimulationSession`, use it when computing the existing seeded hazard, and show the selected setting in the saved career summary. Treat a missing value in older saves as standard.

**Tech Stack:** Swift 6, SwiftUI, Codable simulation state.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 7, 8.2, 12 and 14 (phases F and G).

## Global Constraints

- Preserve old career JSON by making the new session field optional and defaulting absent values to standard.
- Keep breakdown outcomes reproducible from the saved seed and the selected frequency.
- Frequency multipliers are visible gameplay rules, not real-world failure statistics.
- Keep the existing hazard factors and its 50% probability ceiling.
- Do not add or run tests; verify the macOS target with `xcodebuild`.

## Review Focus

- Old saves without the field must behave as standard frequency.
- The chosen setting must survive JSON export/import through the existing session Codable flow.
- All three settings must affect the hazard before the same deterministic roll is compared.
- The hazard must remain bounded by the existing 50% ceiling.
- The preparation UI must prevent changing a setting after the career starts and display the persisted value thereafter.

---

### Task 1: Save and apply the breakdown frequency setting

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

**Interfaces:**
- Add `VehicleIncidentFrequency: String, Codable, CaseIterable, Hashable, Identifiable, Sendable` with `reduced`, `standard`, and `increased` values, labels, explanatory text, and hazard multipliers `0.5`, `1.0`, and `2.0`.
- Add optional `SimulationSession.breakdownFrequency` and a computed standard fallback for older saves.
- Add a `breakdownFrequency` argument to `SimulationEngine.startNew` and pass it into the new session.
- Pass the saved setting into `plannedVehicleIncident`; multiply the existing hazard coefficient before calculating `min(0.5, 1 - exp(-hazard))`.

- [x] Add the Codable setting and persist it on career creation.
- [x] Apply the selected multiplier to the existing seeded breakdown probability without changing the deterministic roll.
- [x] Add a three-option picker to career preparation, show the saved value in the active-career summary, and document the gameplay multipliers.
- [x] Build the macOS target successfully.
