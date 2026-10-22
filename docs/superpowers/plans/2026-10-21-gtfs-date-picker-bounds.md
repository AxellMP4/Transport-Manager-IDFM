# GTFS Date Picker Bounds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the service date selectors inside the known validity window of the GTFS version they inspect.

**Architecture:** Convert the version’s validity endpoints to Paris service-day boundaries. Apply the resulting range to the audit and timetable date pickers, clamp initial or newly out-of-range selections, and retain the existing unevaluated state when valid bounds are unavailable.

**Tech Stack:** Swift, SwiftUI, Xcode macOS target.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`; open date-selection limitation in `docs/IMPLEMENTATION_STATUS.md`.

## Global Constraints

- Use the active version’s known `validFrom` and `validThrough` dates.
- Normalize picker bounds to start of day in `Europe/Paris`.
- Do not fabricate bounds when either endpoint is missing or invalid.
- Preserve the existing warning and non-evaluated behavior for invalid metadata.
- Build the Debug macOS target; do not add or run automated tests in this change.

## Review Focus

- A selected date before or after the window is clamped to the nearest valid day.
- Both endpoints remain selectable as full service dates.
- Missing or inverted bounds leave date evaluation unavailable and do not create an invalid closed range.
- Changing the active GTFS version re-bounds the audit selection.

---

### Task 1: Bound the audit and timetable date pickers

**Files:**
- Modify: `TransportManagerIDFM/Features/NetworkCoverageAuditView.swift`
- Modify: `TransportManagerIDFM/Features/GTFSRouteTimetableGridView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

**Interfaces:**
- Consumes: `NetworkVersion.validFrom`, `validThrough`, and `GTFSServiceDate.parisTimeZone`.
- Produces: a valid, date-only selection range for each picker when both GTFS bounds are usable.

- [x] Apply range limits and clamp the initial selection in both views.
- [x] Update implementation status and external limitations.
- [x] Parse changed Swift sources and build the Debug macOS target.
