# Monthly Machinist Payroll Summary

**Goal:** Give the player a monthly view of each machinist’s estimated paid hours and costs, using the existing service, training and absence settlement events.

**Architecture:** Persist one optional, Codable payroll record for each settled machinist event. Keep the existing ledger and cash timing unchanged. Group records by Paris civil month and machinist in a new view reachable from the operations dashboard’s reports menu.

**Compatibility:** The new session field is optional for old career saves. Existing ledger entries remain unchanged and are not reconstructed into records; the UI explains that old costs remain in monthly finances without a machinist-level breakdown.

**Scope:** This is a monthly accounting view, not a month-end payroll transfer or legal payslip. No hourly rates, absence factors or cash posting dates change.

## Tasks

- [x] Add typed payroll records for service blocks, training, and each absence type.
- [x] Persist payroll records with the career session and keep zero-cost unpaid absences visible.
- [x] Add monthly per-machinist summary with hours, amounts, and event details.
- [x] Document the reporting scope and remaining HR work.
- [x] Build the macOS target; no tests were added or run.
