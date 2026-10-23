# GTFS Service Hour Filter Implementation Plan

> **For agentic workers:** Execute inline in this workspace; verify with the macOS build and project-file lint.

**Goal:** Make GTFS bus directions queryable by date and hour using the active version's calendars, service exceptions and stop times, then expose that query in the stop detail until the simulation clock is available.

**Architecture:** Index each stop direction by its GTFS service IDs and scheduled service-hour offsets, and keep active dates in a compact versioned sidecar index. A date/time query uses the Europe/Paris calendar and shifts service dates backward for trips after midnight or beyond 24:00. Missing stop times and dates outside the feed validity window stay unknown. Existing GTFS archives remain the source of truth; older stop indexes decode with empty schedule metadata.

**Tech Stack:** Swift, SwiftUI, Foundation, local JSON indexes.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, requirements 4.1, 4.4 and Phase C.

## Global Constraints

- Preserve GTFS IDs, source dates, provenance, and the archived feed for each version.
- Do not infer line-to-contract or line-to-depot assignments from geometry.
- Decode existing stop indexes that do not yet contain schedule-hour fields.
- Do not add or run tests unless explicitly requested; verify with a macOS build and project-file lint.

## Review Focus

- `calendar_dates.txt` additions and removals override weekly calendars for the same service date.
- Trips after midnight (GTFS times at or above 24:00) use the prior service date.
- Multiple service IDs and multiple directions at one stop remain distinct.
- Previously imported stop indexes without schedule data remain readable and report schedule status as unknown.
- A missing or malformed departure time must not be presented as proof that a direction is not served.

---

### Task 1: Add schedule index models

**Files:**
- Modify: `TransportManagerIDFM/Domain/NetworkCatalog.swift`
- Modify: `TransportManagerIDFM/Domain/GTFSFeedImporter.swift`

**Interfaces:**
- Produce `GTFSServiceCalendar(serviceID: String, activeDates: [Int])`.
- Produce `GTFSServiceHour(serviceID: String, hourOffset: Int)` and add defaulted `serviceHours` and conservative `hasIncompleteSchedule` fields to `GTFSStopRouteDirection`.

- [x] Add Codable, Hashable, Sendable value models and make old direction indexes decode when `serviceHours` is absent.

### Task 2: Parse and persist GTFS calendars and hours

**Files:**
- Modify: `TransportManagerIDFM/Domain/GTFSFeedImporter.swift`

**Interfaces:**
- Add `[GTFSServiceCalendar]` to `GTFSFeedInspection`.
- Add `NetworkVersionStore.loadServiceCalendars(for:)`.

- [x] Read `service_id`, `departure_time` (falling back to `arrival_time`), weekday calendars, and exception types 1 and 2.
- [x] Aggregate unique service-hour buckets per stop/direction, accounting for GTFS times beyond 24:00.
- [x] Archive the sorted service calendar index alongside each version's stop and route indexes.

### Task 3: Filter the stop detail by the selected game time

**Files:**
- Modify: `TransportManagerIDFM/Domain/NetworkLibrary.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- Add `NetworkLibrary.isDirectionScheduled(_:at:) -> Bool?`; `nil` means the imported index has no schedule evidence.

- [x] Load calendars for the active GTFS version and query the selected Europe/Paris date and hour, including after-midnight service dates.
- [x] Add date/time selection and an active-directions filter to the stop detail; visibly distinguish unknown schedule data from no service.
- [x] Connect the selected date/time to the persistent simulation clock when a career is active; the stop detail reads `SimulationSession.simulatedAt` and the exploratory picker remains available before a career.

### Task 4: Update project status and verify

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Record the exploratory date/hour filter and its live simulation-clock integration; keep authenticated live-export validation pending.
- [x] Run `xcodebuild -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -destination 'generic/platform=macOS' -derivedDataPath /private/tmp/transport-manager-idfm-derived CODE_SIGNING_ALLOWED=NO -quiet build`.
- [x] Run `plutil -lint TransportManagerIDFM.xcodeproj/project.pbxproj`.
