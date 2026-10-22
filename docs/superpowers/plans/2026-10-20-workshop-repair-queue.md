# Workshop Repair Queue

**Goal:** Make the active depot’s repair capacity affect the simulated return-to-service time after a tow.

**Architecture:** Model one shared bay as an explicit gameplay rule. On repair confirmation, reserve the earliest slot after the tow ETA; on preventive maintenance at the depot, reserve the earliest slot from the current time. Persist workshop start and completion times and schedule arrival, work-start and completion events. Display the queue delay and updated vehicle status.

**Compatibility:** New workshop timestamps are optional on incident records. Existing tow repairs without a recorded start use their saved tow ETA as the inferred workshop start when calculating availability.

**Scope:** Towed repairs and preventive maintenance at the active depot use this queue. On-site interventions and preventive maintenance at a stop keep their existing timing. Depot-specific real-world capacity, upgrades, spare parts and workshop staffing remain open.

## Tasks

- [x] Add a single-bay gameplay rule and deterministic earliest-slot calculation.
- [x] Persist workshop start times and schedule work-start events after tow arrival or while queued for depot maintenance.
- [x] Show queued status and time estimates in the incident and fleet views.
- [x] Document the simulated capacity and remaining operational gaps.
- [x] Build the macOS target; no tests were added or run.
