# Active GTFS Routes Without IDFM References Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show bus routes with GTFS departures on the selected date when no valid active or upcoming bus reference in the IDFM snapshot matches their canonical route identifier.

**Architecture:** Extend the existing IDFM-to-GTFS coverage result with an optional reverse-coverage list. Compute it only when the IDFM references, GTFS routes, and selected-date activity are all available; display it in the existing network audit as a separate qualification list.

**Tech Stack:** Swift, SwiftUI, Xcode macOS target.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`; current gap recorded in `docs/IMPLEMENTATION_STATUS.md`.

## Global Constraints

- Match only by canonical `ID_Line` and route identifier; never infer contract or depot from a departure, name, or missing record.
- Include only route IDs with indexed GTFS departures on the selected date.
- A reference is eligible only if its transport mode is bus, its status is `active` or `prochainement active`, and its validity includes the selected date.
- Keep the result unavailable when any required source or date activity cannot be evaluated.
- Build the Debug macOS target; do not add or run automated tests in this change.

## Review Focus

- A route with an eligible exact IDFM reference must not appear in the reverse-coverage list.
- A route without an eligible exact reference appears only when it has departures on the selected date.
- Missing references, invalid GTFS dates, and unavailable activity must not be reported as zero unmatched routes.
- Routes shown for qualification must not acquire a contract or depot assignment.
- Empty but successfully loaded inputs must produce an evaluated empty list.

---

### Task 1: Add reverse coverage to the existing audit

**Files:**
- Modify: `TransportManagerIDFM/Domain/NetworkCoverageAudit.swift`
- Modify: `TransportManagerIDFM/Features/NetworkCoverageAuditView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

**Interfaces:**
- Consumes: `NetworkCoverageAudit.buildIDFMToGTFS(...)`, selected-date `activeRouteIDs`, and existing IDFM status/date eligibility.
- Produces: an optional `[GTFSRouteSummary]` on `NetworkCoverageIDFMAudit`, containing active GTFS routes with no eligible canonical IDFM bus reference.

- [x] Return `nil` unless references, routes, and selected-date activity are all evaluable; return a sorted list, including an empty list, when evaluable.
- [x] Show the list and its unavailable state in the reverse direction of the existing IDFM-to-GTFS section, sharing its filter and pagination.
- [x] Update the implementation ledger with scope, matching rules, limitations, and build result.
- [x] Run `swiftc -frontend -parse` on modified Swift files and build `TransportManagerIDFM` with Xcode using the Debug macOS configuration.
