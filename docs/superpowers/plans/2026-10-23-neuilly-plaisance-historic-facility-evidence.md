# Neuilly-Plaisance Historical Facility Evidence Plan

> **For agentic workers:** Implement this plan task by task. Each step is independently checkable.

**Goal:** Add IDFM’s dated site-area, line-service, and vehicle-restriction evidence for the historic Bords de Marne bus center to the depot inspector without presenting it as current capacity.

**Architecture:** Store a typed, source-linked observation separately from fleet counts and from current operational status. Merge observations by stable ID when site records are combined, and render the facts with their historical limits in the existing depot detail view.

**Tech Stack:** Swift, SwiftUI, Xcode macOS target.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 4.2 and 5; `docs/IMPLEMENTATION_STATUS.md`, regional depot capacity item.

## Global Constraints

- The IDFM diagnostic reports an approximately 22,000 m² site, roughly 15 served lines, and 27 standard 12 m buses on line 113.
- Those values predate the DSP45 transfer on 1 November 2025 and do not describe current maximum capacity, total fleet, or line-to-COB assignment.
- Keep the stated historic articulated-bus restriction tied to the diagnostic period.
- Build the Debug macOS target and update the implementation tracker.

## Review Focus

- Do not label site area or line count as vehicle-storage capacity.
- Keep line 113’s 27-bus observation separate from total site fleet and capacity.
- Ensure merged site metadata keeps the observation exactly once.
- Keep the evidence source visible and the time limit readable in the depot inspector.

---

### Task 1: Add and show the historical facility observation

**Files:**
- Create: `TransportManagerIDFM/Domain/DepotFacilityObservation.swift`
- Modify: `TransportManagerIDFM/Domain/DepotLineRoster.swift`
- Modify: `TransportManagerIDFM/Features/DepotInspectorView.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`
- Modify: `docs/data/bords-de-marne-depot-roster-notes.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Verify: targeted Swift runner, `git diff --check`, and Debug macOS build.

- [x] Add the typed observation, source link, dates, figures, and explicit limits.
- [x] Merge observations by stable ID and render them in the existing depot detail view.
- [x] Record the source limits and validation result in the data notes and implementation status.
