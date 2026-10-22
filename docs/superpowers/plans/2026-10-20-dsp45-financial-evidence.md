# DSP 45 Published Financial Evidence Implementation Plan

> **For agentic workers:** Implement in the existing TransitCity workspace. Do not add or run automated tests; verify the macOS target with the project build.

**Goal:** Show the player the public financial and production facts available for DSP 45, while keeping those references separate from the game's simulated cash flow.

**Architecture:** Add a small immutable reference model to `ScenarioDefinition`, with every displayed fact linked to its source and an explanatory limit. Render the facts in the existing Bords de Marne scenario panel as a native disclosure group; do not feed the published contract figures into simulation accounting.

**Tech Stack:** Swift, SwiftUI, Foundation.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, especially sections 2, 5 and 11.2.

## Global Constraints

- The app remains a native macOS SwiftUI application.
- Real public observations, estimates and general IDFM policy stay distinct from DSP 45 clauses and simulated game rules.
- Do not infer annual remuneration, payment dates, contractual quality thresholds or euro bonus/malus values from the published figures.
- Do not add or run automated tests; the final verification is a Debug macOS Xcode build.

## Review Focus

- The TED award value is a maximum multi-year concession value, not annual cash receipts; VAT treatment is not specified in the notice.
- The TED estimated value excluding VAT remains distinct from the value awarded.
- The 13.9 million KCC reference (including 1.6 million Noctilien KCC, year 2021) describes production volume, not revenue.
- IDFM's 10% quality share and 30% validation-linked share are broad published policy context, not a disclosed DSP 45 euro schedule.
- DSP 45's reported production above 94% is a published result, not a contractual threshold or bonus trigger.

---

### Task 1: Model cited contract facts

**Files:**
- Modify: `TransportManagerIDFM/Domain/ScenarioCatalog.swift`

- [x] Add immutable `ScenarioFinancialFact` and `ScenarioFinancialReference` value types. Each fact carries a label, displayed value, context, source title and source URL; the reference also carries a simulation-separation note.
- [x] Add a `financialReference` property to `ScenarioDefinition` and populate the Bords de Marne scenario with the TED award/estimated values, the year-2021 KCC reference, IDFM's general quality and validation policy, and IDFM's first reported DSP 45 production result.
- [x] Keep missing DSP 45 remuneration, payment schedule and euro bonus/malus terms explicit in the reference note; do not expose any fact as a simulation input.

### Task 2: Present the evidence in the scenario panel

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

- [x] Add a native `DisclosureGroup` titled “Repères financiers publiés” to the existing contract reference card.
- [x] Show each fact's label, value, short context and source link; preserve readable wrapping and system secondary text hierarchy.
- [x] State that none of these published amounts are credited to the player's balance or used as the game's contribution/bonus/malus rules.

### Task 3: Record project status and build

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Create: `.superpowers/sdd/2026-10-20-dsp45-financial-evidence/progress.md`

- [x] Document the added evidence and its limits; mark the broader DSP 45 finance research item as partially documented, not complete.
- [x] Build the Debug macOS app with the existing Xcode project and record the command and result in the progress ledger.

## Self-Review

- Renamed the TED label to identify the single awarded Lot 45 and added the maximum KCC variation assumptions (+10% permanent, +5% temporary) to the awarded value context.
- Kept the 10% quality share and 30% validation-linked share labeled as general IDFM policy, not a DSP 45 euro schedule.
- Kept production above 94% labeled as a reported result, not a contractual threshold or bonus trigger.
- No automated tests were added or run. Final Debug macOS build passed for `arm64` and `x86_64`.

