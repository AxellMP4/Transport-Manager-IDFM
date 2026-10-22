# Depot Energy Evidence and Market Gating Plan

**Goal:** Make depot energy readiness visible and consequential for bus purchasing and dispatch while preserving the evidence gaps in the Bords de Marne site records.

**Evidence boundary:** Saint-Maur biomethane operation is confirmed by IDFM on 2025-02-05. Neuilly Bords de Marne has an electrical conversion intent, but the commissioning date, installed quantity and operational capacity are not confirmed. The planned COB at Neuilly-sur-Marne remains a separate site. Diesel support in a new game is a clearly labeled gameplay assumption.

**Architecture:** Add a depot energy evidence catalog distinct from the player's saved energy infrastructure projects. Store only player-built infrastructure and pending completion events in the optional, Codable-compatible session fields. Unknown evidence does not become an assumed physical asset. The market and dispatch path consult current depot readiness and direct the player to an explicitly priced, timed gameplay installation when needed.

**Constraints:** Preserve old career decoding and existing model/energy IDs. Never infer a line assignment, site crosswalk, installation quantity or site capacity from an energy label. Keep all non-source costs and delays marked as gameplay rules. Do not add or run tests; compile the macOS target.

## Tasks

- [x] Add dated depot-energy evidence states and the energy-to-equipment mapping.
- [x] Persist optional player infrastructure projects, schedule completion through simulation events, and retain old-save decoding behavior.
- [x] Gate new purchases and dispatch by readiness; preserve legacy-bus operation where older saves lack the new state.
- [x] Show source-backed depot status, unknown capacity, project cost/delay, and purchase eligibility in the market UI.
- [x] Update the implementation status and README, then compile the macOS Debug target.

## Verification

Run the existing macOS Debug `xcodebuild ... build` command. No automated test suite is requested or run.
