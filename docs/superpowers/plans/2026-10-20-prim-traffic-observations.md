# PRIM Traffic Observations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show current IDFM traffic messages for the selected bus line as dated observations that never modify the simulated service.

**Architecture:** Query the official Navitia line-reports API on demand for one uniquely matched IDFM line. Keep the API token in the macOS Keychain, parse the response into a small display model, and render the result beside the selected line's archived documents with fetch time and Licence Mobilité attribution.

**Tech Stack:** Swift 6, Foundation URLSession, Security Keychain, SwiftUI, the existing exact `LineReferenceMatcher`.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 10, 12, 14 Phase I and 15.

## Global Constraints

- External traffic observations are separate from simulated events and do not alter a career.
- Query only after the player requests a refresh; use the selected route's unique exact `ID_Line` match.
- Use the official PRIM API and its documented `Authorization: apikey <token>` authentication.
- Keep the token in Keychain, never in the catalogue, career save, logs, or visible text field contents after saving.
- Label the fetch time, source and Licence Mobilité; do not imply full-network coverage.
- Preserve offline play when no token, network or API response is available.

## Review Focus

- No unique IDFM line reference: explain the prerequisite and make no API request.
- Missing token or Keychain failure: show a safe user-facing error without exposing token data.
- Unauthorized, rate-limited, timeout or malformed API response: keep the rest of the game usable and retain the last successful observation.
- Empty reports: show the successful fetch time and a clear empty state.
- Unknown report fields or missing periods: preserve usable text and avoid crashing or inventing a time range.

---

### Task 1: PRIM client and credential storage

**Files:**
- Create: `TransportManagerIDFM/Domain/TrafficInformation.swift`
- Modify: `TransportManagerIDFM.xcodeproj/project.pbxproj`

**Interfaces:**
- `PRIMTrafficReport`: identifiable message fields, line and affected-object labels, cause, severity, optional application period and update time.
- `PRIMTrafficFetchResult`: reports, fetched-at timestamp and source URL.
- `PRIMTrafficInformationClient.fetchReports(idfmLineID:token:) async throws -> PRIMTrafficFetchResult` requests the selected line endpoint in documented pages of at most 100 reports and records the request count.
- `PRIMTrafficTokenStore.load()`, `save(_:)`, and `delete()` read or mutate one generic-password item in Keychain.

- [x] Build the line URI from the canonical IDFM identifier and call only the per-line `line_reports` endpoint, paging by `start_page` with `count=100`.
- [x] Decode known message fields defensively and format Navitia date strings using the Paris time zone.
- [x] Map HTTP status and transport failures to token-safe localized errors.
- [x] Add Keychain save, load and delete without adding the token to any Codable model.

### Task 2: Selected-line interface

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- `PRIMTrafficInformationForRouteView(route:reference:)` keeps token-edit, loading, error and last-successful-result state local to the view.

- [x] Show a Keychain-backed token editor and an explicit clear action.
- [x] Add an on-demand refresh button only when the selected GTFS route has a unique IDFM line reference.
- [x] Render source messages, severity, application period, affected objects and fetch time separately from game incidents.
- [x] Show the number of API requests used to retrieve the line's paged messages.
- [x] Keep the previous successful result visible after failed refreshes and show a distinct successful empty state.

### Task 3: Project documentation and verification

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Document the credential requirement, on-demand scope, source, license and offline behavior.
- [x] Build the macOS target and inspect its exit status.
