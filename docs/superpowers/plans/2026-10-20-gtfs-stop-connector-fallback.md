# GTFS Stop Connector Fallback Implementation Plan

> **For agentic workers:** Inline implementation in this session. Steps use checkbox syntax for tracking.

**Goal:** Keep a scheduled bus moving between geolocated stops when its GTFS trip shape is absent or cannot be matched, without presenting the fallback as an official route.

**Architecture:** Prefer each trip's connected `shapes.txt` geometry. For each remaining valid stop pair, create a two-point stop-to-stop connector and tag its source as an estimate. Carry that provenance through movement legs, distance records, ledger descriptions, the map, and daily reports. Missing stop coordinates remain a visible scheduling error because no defensible map location can be inferred.

**Tech Stack:** Swift, SwiftUI, MapKit, GTFS importer, Codable simulation events.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 3.3, 4.1 and 8.1.

## Global Constraints

- Keep GTFS identifiers and stop order as the source of the service schedule.
- Use connected GTFS shape segments whenever they can be matched in sequence.
- Label stop-to-stop connectors as estimated, never as an IDFM or GTFS shape.
- Keep new persisted provenance optional so existing career files decode.
- Do not infer coordinates for stops whose GTFS coordinates are absent.

## Review Focus

- A shape missing for one trip produces estimated connectors for geolocated consecutive stops.
- A shape that matches only some stop segments keeps official segments and fills only unmatched segments.
- Out-of-order/invalid times still produce no movement leg.
- Old saved movement legs and daily reports decode with absent provenance fields.
- Closed-stop bypasses preserve the movement source on the replacement leg.
- Energy, odometer, wear, breakdown risk and game contribution use the same distance geometry.

---

### Task 1: Build tagged movement geometry

**Files:**
- Modify: `TransportManagerIDFM/Domain/GTFSFeedImporter.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Add `ServiceMovementGeometrySource` with `gtfsShape` and `stopCoordinateEstimate` cases.
- Add optional `movementGeometrySource` to `ScheduledTripStopVisit` and optional `geometrySource` to persisted `ScheduledBusMovementLeg`.
- Preserve the current MapKit/GTFS route preference; use a two-coordinate connector only when a valid adjacent stop segment lacks a usable shape segment.

- [x] Create a connector for each valid uncovered consecutive stop pair and attach its source.
- [x] Propagate the source to movement events and preserve it when a closed-stop bypass replaces a leg.
- [x] Record the source on each service `TripDistanceRecord` and aggregate estimated connector distance in `DailyOperationsReport` using optional fields.
- [x] Mark energy and service-contribution ledger descriptions when their segment uses stop-coordinate distance estimates.

### Task 2: Show the fallback honestly

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Draw estimated movement segments with a distinct dashed map style.
- [x] Explain the estimate in the course-dispatch view whenever any leg uses it.
- [x] Show total distance and the estimated-connector portion separately in the daily report.
- [x] Record that missing shapes now have a labeled stop-connector fallback while stop records without coordinates still cannot be operated.

**Verification:** `xcodebuild -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -derivedDataPath /private/tmp/transport-manager-idfm-derived build` and `git diff --check`. No tests are added or run in this implementation pass.
