# Machinist Absence Types and Remuneration Plan

**Goal:** Give planned machinist absences a saved type and an explicit simulated pay estimate, then record that cost when the absence ends.

**Rules:** Paid leave uses 100% of the machinist's estimated loaded hourly rate; simulated medical leave uses 50%; unpaid leave uses 0%. The player enters the work hours affected because the project has no shift calendar for unassigned work. These are game rules and not payroll or labor-law calculations.

**Compatibility:** New absence fields remain optional when decoding older career saves. Old absences keep their historical no-pay behavior. Canceling a future absence removes its completion event.

## Tasks

- [x] Add a Codable absence type, paid-hours estimate and settlement fields to the saved absence record.
- [x] Schedule an absence-completion event; settle the estimated amount once into the existing machinist-payroll ledger category.
- [x] Add type and paid-hours controls, a visible estimate, and recent absence history to Personnel.
- [x] Update README and implementation status; compile the macOS target without running tests.

## Review focus

- Old saves without new absence fields decode with no retroactive charge.
- Paid leave, simulated medical leave and unpaid leave produce the stated game-rule amounts.
- An absence cancellation removes its future completion event.
- Completion updates one saved record and creates at most one financial ledger entry.
