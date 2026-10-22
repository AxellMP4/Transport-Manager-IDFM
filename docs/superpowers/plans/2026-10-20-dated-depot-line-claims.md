# Dated Depot Line Claims Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make each Bords de Marne roster claim show its own site, source date and operational validity, leaving periods unknown when the source does not establish them.

**Architecture:** Add a source-specific claim model to the descriptive depot roster and make its date filter honor optional validity bounds. Preserve the line's aggregate status for scanning and keep `DepotAssignmentRegistry` as the sole source of playable assignments. Render each conflicting claim separately in the existing line catalog sheet.

**Tech Stack:** Swift 6, SwiftUI, Foundation.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`; current evidence boundaries in `docs/IMPLEMENTATION_STATUS.md` and `DepotLineRoster.swift`.

## Global Constraints

- Do not infer a line-to-depot assignment from a route name, fleet sighting, historic source or missing data.
- Do not promote roster claims into `DepotAssignmentRegistry` or make them playable automatically.
- Keep a source's publication/observation date separate from operational validity; omit either when unknown.
- Keep known date boundaries only where a cited source supports them; an unknown period stays visible on every selected audit date with an explicit label.
- Preserve the IDFM 29-lines/7-Noctilien versus eight-names discrepancy and existing conflict statuses.
- Do not add or run tests unless the user requests them; compile the macOS target for verification.

## Review Focus

- Unknown validity must remain visible without being described as current or effective.
- A known start date with unknown end must not be represented as a closed contract-period interval.
- Claims from two sources or sites must remain separately labeled on conflict/shared/partial rows.
- Publication/observation dates must not be reused as validity dates.
- Descriptive roster evidence must not change dispatch eligibility.

---

### Task 1: Model source-specific roster claims

**Files:**
- Modify: `TransportManagerIDFM/Domain/DepotLineRoster.swift`

- [x] Add `DepotLineRosterClaim` with optional site ID, relation label, source title and URL, optional exact source date and label, optional start/end service date keys, and a note.
- [x] Change roster date bounds to optional values. `isVisible(on:)` filters against known bounds and keeps claims with unknown periods visible.
- [x] Stop applying the DSP-wide period from the generic row constructor. Pass a known start only to claims supported by the contract start date; keep unsupported end dates and historical/candidate/secondary observations unknown.
- [x] Allow selected shared, partial and conflict rows to provide separate claims for each source.

### Task 2: Render dates and conflicting claims

**Files:**
- Modify: `TransportManagerIDFM/Features/DepotLineCatalogView.swift`

- [x] Display claim relationship, physical site/center label, source link, source-date label, and validity summary in separate compact sections.
- [x] Show an explicit unknown-date or unknown-validity label when those fields are absent; identify edition/reference labels as undated when no exact source date is established.
- [x] Preserve the line-level aggregate evidence label and note; do not rely on color alone to convey conflicts.

### Task 3: Document and compile

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Describe source-specific dates and unknown periods without claiming complete line/COB coverage.
- [x] Run `git diff --check` and the macOS Debug `xcodebuild ... build` command; record the result in the plan ledger. No automated tests are run.
