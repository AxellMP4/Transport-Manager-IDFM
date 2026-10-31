# Passenger Load and Validation System

**Status: draft for approval**

## Intent

Make passenger activity an autonomous, visible, and measurable part of every simulated bus course. The game already schedules passenger demand at stops, exchanges passengers, carries queues between courses, records occupancy, and reacts to some stop and route disruptions. This design completes the player-facing load view and adds ticket validation outcomes and analytics without replacing that engine.

## Goals

- Show the current bus position and its current passenger load together. Map bus markers show an occupancy percentage; the fleet row and bus detail show a labelled progress gauge and passenger count against capacity. Use actual vehicle capacity where known and clearly mark estimated game capacity otherwise.
- For each passenger exchange, derive aggregate outcomes for boarded passengers: validated or not validated; successful validations are classified as **Navigo / abonnement**, **ticket unitaire**, **tarif réduit**, or **gratuité**. A valid free title counts as a validation. No individual passenger objects are created.
- Define validation rate as validated boarders divided by total boarders. Show counts and rates by bus, course, line, stop, and selected time period, alongside the title mix and current / peak occupancy.
- Add a **Voyageurs** report section with date range and line / bus filters. Add daily validation totals and title mix to the existing daily report. Derive historical totals from persisted passenger records so reports can be reopened after saving and loading a career. Report disruption effects separately: redirected at closures, left at stops, and displaced or stranded by an interrupted course. Do not count these again as new boardings or validations.
- Keep generated demand and validation outcomes deterministic for the saved career seed, and process them locally without a network or generative AI dependency.
- Preserve existing queue, closure, detour, and breakdown behavior. A disruption changes passenger flow through existing or extended deterministic rules and its outcome is visible in the same reports.

## Product and simulation rules

Counts remain aggregate game estimates. Each stop exchange records the boarded count, validated count by title, and unvalidated count. The selected type and validation outcome are produced from stable per-career/per-course/per-stop randomness, not from actual validation data. Put rates and title-mix weights in a named rules type, label them as game assumptions in the interface, and keep them separate from real IDFM fare facts. Validation counts must not create operator ticket revenue or change cash flow; contractual service revenue remains governed by the existing game model.

## Interface

- On the map, keep each moving bus marker and add a compact load percentage with a color treatment for normal, high, and full loads. The marker remains selectable.
- In the fleet and selected-bus detail, show a full progress indicator with `passengers / capacity`, percentage, capacity provenance, and current course validation rate / title counts.
- In **Rapports → Voyageurs**, show boardings, validations, validation rate, unvalidated boardings, title distribution, maximum load, and breakdowns by line, bus, course, and stop for the selected date range. Empty and older saves should show a clear no-data state.

## Persistence and compatibility

Attach the validation breakdown to saved passenger exchange records, which already carry the bus, route, course, stop, and time keys needed for aggregation. Keep disruption-impact counts with their saved incident/closure or passenger event records and join them into analytics by bus, route, course, stop, and time; add persisted impact data only where the current records do not preserve those keys. New fields must decode safely from existing career saves that contain no validation data. Do not change the existing GTFS/network archive format.

## Non-goals

- Individual animated passengers, learned or generative AI, real-time vehicle GPS, or live passenger-count feeds.
- Claims that simulated title shares, non-validation rates, capacities, or disruption responses represent observed service data.
- Changing company finances to treat validations as fare revenue.

## Builder decisions

Choose transparent default title-mix and validation-rate assumptions that sum consistently, keep the model deterministic and lightweight, and expose the assumptions in explanatory text. Choose accessible colors and labels that work in the current SwiftUI platforms. Preserve existing local changes in the working tree while implementing.

## Acceptance criteria

1. A moving bus can be followed on the map with a readable current occupancy indicator, and selecting it exposes an accessible occupancy gauge.
2. Each exchange produces validated/unvalidated aggregate counts whose sums agree with boarded passengers; category counts sum to validated passengers, including gratuitous validations.
3. Validation rate and title mix can be inspected by bus, trip, route, stop, and date range. Redirected, left-behind, and stranded/displaced passenger counts are separately attributable to their disruption and do not inflate boarding or validation totals.
4. Daily reports and exports/imported career saves preserve the statistics; an older save loads with empty validation history and continues simulation.
5. Replaying the same career seed and stop events produces the same passenger and validation outcomes; disruptions affect and report the appropriate flows.
6. UI and reports label the figures as estimates and keep validation totals out of operator cash flow.
