# Passenger Load and Validation System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make autonomous passenger load and ticket validations visible and reportable for every simulated course.

**Architecture:** Add a pure, deterministic passenger-validation rules model and a pure analytics aggregator. Store one compact aggregate validation breakdown on each saved stop-exchange record, derive historical and daily summaries from those records plus saved disruption events, and present them in reusable SwiftUI gauges and a passenger report.

**Tech Stack:** Swift 6, SwiftUI, MapKit, Foundation, the existing SimulationEngine event queue and JSON career saves.

**Spec:** `docs/superpowers/specs/2026-10-31-passenger-validation-system-design.md`

## Global Constraints

- Passenger counts and title shares are aggregate game estimates, not observed service data.
- Use exactly these validation categories: Navigo / abonnement, ticket unitaire, tarif réduit, gratuité; no-validation is a separate outcome.
- Use deterministic local rules seeded from the career and stable trip/stop identity; do not add a network or generative-AI dependency.
- Keep validations separate from operator ticket revenue and existing cash-flow rules.
- Preserve older career saves by making newly persisted fields optional or explicitly backward-decodable.
- Keep the existing SwiftUI platform set and manual Xcode project registration in sync for every new source file.
- Preserve current uncommitted working-tree changes and the existing passenger-demand event behavior.

## Review Focus

- Old save files without validation fields must decode and resume with empty validation history. Pin this in Task 1’s legacy decode assertion.
- Zero boardings and closed/terminal stops must create no validations and a nil or zero-safe rate. Pin this in Task 1’s boundary assertions and Task 2’s event assertion.
- For every exchange, validated + unvalidated must equal boarded; the four title counts must equal validated. Pin this in Task 1’s partition assertions and Task 2’s integration assertion.
- Replayed trip/stop keys under the same career seed must produce identical category counts; timing shifts must not reshuffle the same riders. Pin this in Task 1’s determinism assertions.
- Redirected, left-behind, and breakdown-displaced counts must be attributable to a disruption without inflating boardings or validations or being counted twice. Pin this in Task 3’s aggregation assertions.

---

### Task 1: Validation Rules and Compatibility-Safe Data Types

**Files:**
- Create: `TransportManagerIDFM/Domain/PassengerValidation.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`
- Create: `Validation/PassengerValidationSmoke.swift`
- Create: `Scripts/validate-passenger-validations.sh`

**Interfaces:**
- Produce `PassengerValidationType` with cases `navigoSubscription`, `singleTicket`, `reducedFare`, and `freeTravel`.
- Produce `PassengerValidationBreakdown` with `boardedCount`, `unvalidatedCount`, and one integer count per validation type; derive `validatedCount` and `validationRate` safely when `boardedCount == 0`.
- Produce `PassengerValidationRules.resolve(boardedCount:tripID:routeID:stopID:stopSequence:randomSeed:) -> PassengerValidationBreakdown`.
- Produce `PassengerLoadStatus` / `PassengerLoadPresentation` for occupancy percentage and normal/high/full thresholds consumed by SwiftUI.

- [x] **Step 1: Write failing smoke assertions** for the four title categories, zero boardings, partition invariants, a repeated stop visit distinguished by stop sequence, and stable results for the same seed and trip/stop identity.
- [x] **Step 2: Run `sh Scripts/validate-passenger-validations.sh`** and confirm it fails because the validation types and rules do not yet exist. Compile only `PassengerValidation.swift` in this unit smoke.
- [x] **Step 3: Implement the domain types and deterministic resolver.** Use explicit game-rule constants: 90% validation chance among boarders and, among successful validations, 70% Navigo/abonnement, 22% ticket unitaire, 6% tarif réduit, and 2% gratuité. Keep the mix summing to 100%; label all values as estimated game rules.
- [x] **Step 4: Register `PassengerValidation.swift` in the project file and rerun the smoke script.** Require all title counts to sum to `validatedCount`, `validatedCount + unvalidatedCount == boardedCount`, and repeated inputs to return equal values.
- [x] **Step 5: Verify the pure model’s boundaries.** Assert that empty boardings return `validationRate == nil`, and that a bus at or above capacity is full while its normalized progress never exceeds 1.

### Task 2: Attach Validations to Every Passenger Exchange

**Files:**
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`
- Create: `Validation/PassengerSystemSmoke.swift`
- Create: `Scripts/validate-passenger-system.sh`

**Interfaces:**
- Add optional `stopSequence` and `validationBreakdown` fields to saved `PassengerStopExchange`; add optional `stopSequence` to pending `PassengerStopDemand` so old saves remain decodable.
- `resolvePassengerDemand` uses the actual `boardedCount` after alighting, capacity, closures, and queue resolution, then calls Task 1’s resolver with stable seed/trip/route/stop/sequence inputs.
- Exchange event history retains the resulting breakdown for save export/import and replay.

- [x] **Step 1: Create an integration smoke scenario** that resolves scheduled passenger-demand events through the engine's production resolver and asserts the emitted `.passengersExchanged` event stores a breakdown for the actual number boarded. Its script copies Domain sources into a temporary snapshot before compiling.
- [x] **Step 2: Run `sh Scripts/validate-passenger-system.sh`** and confirm the new integration assertion fails before engine wiring.
- [x] **Step 3: Add the optional fields and wire `resolvePassengerDemand`.** Full buses and terminals may board zero and resolve to zero validations safely.
- [x] **Step 4: Include a short validation summary in the passenger exchange event text** without presenting the estimated validation amount as ticket revenue.
- [x] **Step 5: Assert legacy decoding.** Decode a pre-feature `PassengerStopExchange` JSON fixture without a validation field and verify that it remains usable with a nil breakdown. JSON-encode/decode a career fixture and assert that validation breakdowns survive unchanged.
- [x] **Step 6: Rerun `sh Scripts/validate-passenger-system.sh` and confirm exchange totals, deterministic outcomes, legacy decoding, and career round-trip preservation pass; rerun the pure rules smoke as well.**
- [x] **Step 7: Exercise scheduled dispatch through a moving bus, automatic stop demand, and passenger validations.** The smoke imports an isolated session into `SimulationEngine`, dispatches a real scheduled trip with a bus and machinist, asserts demand generation for all three visits, advances to a mid-segment position and the next stop, verifies occupancy and per-bus validation analytics, then round-trips the engine export. `CFFIXED_USER_HOME` confines the save to the script’s temporary directory.

### Task 3: Passenger Analytics and Disruption Attribution

**Files:**
- Create: `TransportManagerIDFM/Domain/PassengerAnalytics.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`
- Create: `Validation/PassengerAnalyticsSmoke.swift`
- Create: `Scripts/validate-passenger-analytics.sh`

**Interfaces:**
- Produce `PassengerAnalyticsFilter` for inclusive start/end time plus optional route and vehicle filters.
- Produce `PassengerAnalyticsSnapshot` with boardings, validations, unvalidated boardings, validation rate, per-title totals, maximum occupancy, and separate redirected / left-behind / stranded counts.
- Produce grouped rows keyed by route, vehicle, trip, or stop. Each row retains its boarding denominator so its validation rate is computed from summed counts rather than averaging percentages.
- The aggregator consumes persisted passenger exchanges and the relevant saved closure / incident events; disruption effects are attributed once and excluded from boarding and validation totals.

- [x] **Step 1: Add failing aggregation assertions** for totals, each title category, date boundaries, route and vehicle filters, group rates, disruption attribution, and no double-counting of terminus closures.
- [x] **Step 2: Run `sh Scripts/validate-passenger-analytics.sh`** and confirm the analytics assertions fail because the aggregator is absent.
- [x] **Step 3: Implement the pure analytics reducer** in `PassengerAnalytics.swift`; normalize empty/reversed filters safely, and use sum-of-counts rates.
- [x] **Step 4: Extend the smoke script for closures and incidents.** Assert redirected, left-behind, and displaced counts appear in their separate totals and do not affect validation denominators.
- [x] **Step 5: Rerun `sh Scripts/validate-passenger-analytics.sh` and confirm every aggregation assertion passes.**

### Task 4: Map, Fleet, Bus Detail, and Passenger Reports

**Files:**
- Create: `TransportManagerIDFM/Features/PassengerLoadGaugeView.swift`
- Create: `TransportManagerIDFM/Features/PassengerOperationsReportView.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`

**Interfaces:**
- `PassengerLoadGaugeView` accepts current passenger count, capacity, and whether capacity is estimated; it presents count, percentage, a SwiftUI `ProgressView`, and accessible status text.
- `PassengerOperationsReportView` accepts the active `SimulationSession` and filters the saved exchange/incident data through Task 3’s aggregator.
- Add `ReportWorkspaceSection.passengers` as **Voyageurs** and retain existing report navigation.

- [x] **Step 1: Review the load-presentation assertions** for zero/full/over-capacity percentages and estimated capacity; the existing smoke covers these boundaries.
- [x] **Step 2: Implement the reusable load gauge.** Place it in fleet rows and the selected-bus popover; show a compact percentage in the selectable moving-bus map marker and keep existing route movement unchanged.
- [x] **Step 3: Add current-course validation totals and title mix** to the selected-bus detail and a daily validation/title-mix summary to saved daily report cards.
- [x] **Step 4: Add the Voyageurs report** with date, line, and bus filters; show aggregate KPIs, title distribution, occupancy peak, disruption effects, and grouping controls for line, bus, course, and stop.
- [x] **Step 5a: Build the macOS and iOS Simulator app targets.** Debug builds pass for macOS x86_64 and iOS Simulator x86_64; the products and Info.plist files were checked.
- [ ] **Step 5b: Inspect the map, fleet row, bus detail, and report on a running build at narrow and wide window sizes.** On 1 Nov the diagnostic macOS app was accessible at 1,420 × 900 points, then inspected at its 1,180-point minimum width. Carte/Lignes and the line 116 timetable grid rendered, including the map legend, the uncertain-COB cue and horizontal stop scrolling. The zero-vehicle fleet, exploitation report, no-passenger empty state and monthly financial report were also visible; the career remained paused and unchanged. At minimum width, the old empty-map footer crushed its help text into near-vertical fragments. `EmptyMapFleetActionCard` now adapts its copy and action layout; the layout smoke and Debug macOS build pass. The crash report traced the earlier diagnostic launch failure to eager `CKContainer` initialization in an unsigned build; that initializer is now lazy and Debug inspection can skip CloudKit explicitly. The rebuilt bundle still could not be launched here (`Launchd job spawn failed`, code 162), so its visual result remains unconfirmed and this checklist stays open. The current save has no bus, so movement, load gauge and selected-bus detail could not be inspected; interactive legacy-save restoration also remains pending. The headless live-engine smoke proves movement coordinates, stop exchange, updated load, analytics, and export persistence, but does not replace this UI check. The scratch save is isolated under `/private/tmp/TransitCityRuntimeInspection`; temporary source/project edits were restored byte-for-byte.

### Task 5: Documentation and End-to-End Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Verify: all files introduced or modified above

- [x] **Step 1: Update README feature and limitation notes.** The four title categories, deterministic estimates, rate definition, reports and filters, save compatibility, disruption metrics, and separation from cash receipts are documented.
- [x] **Step 2: Update implementation status** with implemented behavior and exact verification evidence, preserving prior historical entries.
- [x] **Step 3: Run the validation-rules, passenger-system, and passenger-analytics smoke scripts.** All three report `PASS` for rules, persistence, integration, aggregation, and disruption attribution.
- [x] **Step 4: Run `git diff --check`, parse all Swift sources, and build the Debug macOS and iOS Simulator targets.** All checks pass; both builds terminate with code 0.
- [ ] **Step 5: Launch the current Debug macOS app and inspect the map movement, load indicators, reports, and empty/legacy-save states.** A 1 Nov visual review confirms the map, timetable, zero-fleet market, and empty passenger/exploitation and monthly-finance reports are visible. The UI was inspected at its 1,180-point minimum width and a compact empty-map footer was implemented. A CloudKit launch crash in the unsigned diagnostic build was isolated and guarded for Debug inspection, but macOS still refuses to spawn the rebuilt temporary bundle with code 162, so its rendered result is unverified. The scratch career has no owned bus, so movement/load and bus-detail states remain unverified; interactive legacy-save restoration also remains pending. The ordinary Debug macOS universal build succeeds, and scratch user data remains isolated under `/private/tmp/TransitCityRuntimeInspection`.
