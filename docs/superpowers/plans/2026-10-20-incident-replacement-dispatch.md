# Incident replacement bus dispatch

## Objective

Allow a spare bus and available machinist to continue the remaining GTFS stop sequence after a breakdown, while preserving the incident pause and recording the estimated delay. A reserve bus at the incident stop can depart immediately; one at the active depot uses a saved MapKit deadhead route.

## Implementation

1. [x] Persist incident service date, stop sequence, and optional replacement assignment/delay data.
2. [x] Add an engine entry point that validates the incident, reserve bus, machinist, suffix schedule, and optional deadhead route; reuse normal trip event generation while recording a distinct replacement departure event so the same scheduled departure is not counted twice.
3. [x] Add immediate MapKit deadhead calculation and a reserve-dispatch section in the incident response screen. Show the service suffix, machinist, arrival estimate, and delay before dispatch; keep the simulation paused until the player chooses a repair response.
4. [x] Update incident history and implementation status documentation.

## Verification

- macOS Debug app build succeeded with `xcodebuild`.
- No tests were added or run.

## Constraints

- Use only the interrupted trip's remaining GTFS stop visits.
- Preserve the scheduled inter-stop travel intervals by shifting the suffix by the replacement arrival delay.
- Only buses already at the incident stop or at the active depot are eligible.
- Do not add tests or run a test suite unless the user requests it.
