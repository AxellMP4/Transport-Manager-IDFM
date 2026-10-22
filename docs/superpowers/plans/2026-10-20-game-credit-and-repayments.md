# Game Credit and Repayments Implementation Plan

> Build a saved, event-driven borrowing loop so vehicle purchases can combine treasury capital and financing. All loan terms are explicitly gameplay rules, not real bank offers or DSP 45 terms.

## Scope

- Add durable loan records and amortization installments to the career save.
- Let the player draw a fixed-rate game loan from the finance screen; credit proceeds to cash immediately.
- Schedule principal and interest payments as simulation events and account for both in the ledger.
- Separate financing cash flows from operating income/expenses in monthly reports.
- Keep older save files readable by making the new session and ledger fields optional.
- Do not add or run automated tests; build the macOS target.

## Tasks

### 1. Model game loans

- [x] Add loan rules, amortization installment and loan value types.
- [x] Store optional loan records on `SimulationSession` for backward compatibility.
- [x] Add optional ledger-entry nature to distinguish operating and financing flows.

### 2. Integrate loans with the simulation clock

- [x] Add an engine action that validates amount/term and issues a loan.
- [x] Credit the cash balance and record the financing draw.
- [x] Schedule all monthly installments as dated simulation events.
- [x] At each installment, update remaining principal, split principal/interest ledger entries, and debit cash exactly once.
- [x] Keep events and loan progress in the exported, imported and autosaved career JSON.

### 3. Present financing in the game

- [x] Add a native finance panel to choose amount and term and show the fixed gameplay APR and installment estimate before issue.
- [x] Show active loan balances, next payment, paid installments and total interest.
- [x] Distinguish operating receipts/expenses from financing cash flow; retain the complete ledger detail.
- [x] Update README and implementation status with gameplay-rule limits.

### 4. Review and verify

- [x] Review repayment math, date handling, backward compatibility and double-payment prevention.
- [x] Build Debug macOS for arm64 and x86_64; do not run tests.
- [x] Record results in the SDD progress ledger.
