# Jeu complet sur iPhone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give iPhone players the same career, live map, fleet, staff, reports, incident and network-data workflows as the full macOS game, with an iOS-native compact layout.

**Architecture:** Reuse `OperationsDashboardView` and its single `SimulationEngine`/`NetworkLibrary` state as the iOS game. Add a five-tab iPhone navigation model that maps to all ten existing workspaces, remembers one subsection per tab, then adapt the shared dashboard’s map, headers, sheets and playback controls for compact widths. Debug and Release use the iOS CloudKit entitlement when the selected Apple team supports the capability; unsigned inspection builds can explicitly pass `--disable-cloud-sync-for-inspection`.

**Tech Stack:** Swift 6, SwiftUI, MapKit, existing validation shell/Swift smoke scripts, Xcode iOS 26.2 SDK.

**Spec:** `docs/superpowers/specs/2026-11-01-iphone-full-game-design.md`

## Global Constraints

- Keep the iOS deployment target at iOS 17.0; guard iOS 26 Liquid Glass APIs with availability checks.
- Keep all ten current `OperationsWorkspaceTab` cases reachable from five native iPhone tabs.
- Use the shared career engine, network library, pinned data versions, save/import/export, and existing game rules.
- Keep iCloud entitlements enabled for Debug and Release so a capable Apple team can test same-account Mac/iPhone sync. A team that cannot provision iCloud can use the explicit local inspection launch argument; never claim that configuration proves cloud sync.
- Do not add third-party dependencies.
- Preserve macOS layout and behavior.

## Review Focus

- A workspace opened by an existing action (buy bus, assign departure, incident response) selects the matching iPhone tab and subsection.
- Every workspace remains reachable after map selection, career creation, and career restore.
- Long map overlays and details do not cover all map interactions on compact screens.
- Save, launch-menu, and active-incident sheets fit iPhone width and dismissal remains clear.
- iOS 17 fallback and iOS 26 bottom-accessory paths expose identical simulation controls.

---

### Task 1: Map the complete dashboard into iPhone tabs

**Files:**
- Modify: `TransportManagerIDFM/TransportManagerIDFMApp.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `Scripts/validate-mobile-operations-tabs.sh`
- Modify: `Validation/MobileOperationsTabSmoke.swift`

**Interfaces:**
- The mobile tab type exposes five cases and a stable mapping to the existing workspace raw values.
- Workspace selection remains stored in `OperationsDashboardView`; each top-level tab remembers its own subsection, while direct navigation selects the matching tab and subsection.

- [x] Add a smoke assertion proving the five tabs cover all ten current workspaces and each default belongs to its tab; run it and confirm it fails before implementation.
- [x] Implement the category mapping and test the bidirectional mapping for every workspace.
- [x] Make `OperationsDashboardView` the iOS root so launch, save, data, and game actions share one source of truth.
- [x] Add the iPhone `TabView` and compact subsection selectors; retain all workspaces and the existing macOS navigation.
- [x] Run the navigation smoke and compile the shared app sources.

### Task 2: Make the operations map usable on iPhone

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `Scripts/validate-mobile-operations-tabs.sh`
- Modify: `Validation/MobileOperationsTabSmoke.swift`

**Interfaces:**
- `selectedWorkspaceTab == .network` remains the sole selection state for the map.
- A compact line-list sheet reuses `depotLineSidebar`; selecting a line closes the sheet and updates the same map layers.

- [x] Add failing smoke coverage for map selection, line-panel access, dismissal, camera fitting, and preservation of all map-layer controls; confirm RED before the detail correction and GREEN afterward.
- [x] On iPhone, present the map at full width and expose the line list as a dismissible sheet; retain the current split map/sidebar on macOS and wide iPad.
- [x] Keep legends and disruption notices in dismissible sheets; make compact empty-fleet controls 44 points and bus/stop details scrollable with an explicit close action.
- [x] Verify workspace selection, line selection, camera fitting, and layer controls with the navigation smoke.
- [ ] Run a compact-width visual UI pass on a simulator or iPhone; CoreSimulator is unavailable in this session.

### Task 3: Adapt all existing workspaces and simulation controls

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `TransportManagerIDFM/Features/MobileSimulationPlaybackAccessory.swift`
- Modify: `Scripts/validate-mobile-operations-tabs.sh`
- Modify: `Validation/MobileOperationsTabSmoke.swift`

**Interfaces:**
- Existing `workspaceBody` views remain the content for fleet, staff, depots, reports, incidents, line data, course motifs, and sources.
- iOS-specific frames use available width; macOS-specific minimum dimensions remain unchanged.

- [x] Add failing smoke coverage for all workspace mappings, playback controls, and compact hit targets; confirm RED before the 44-point and depot-navigation corrections.
- [x] Verify the iOS 26 Liquid Glass tab accessory for pause/resume, speed, simulated time, and next event; keep equivalent 44-point controls on iOS 17–25.
- [x] Keep speed, next event, and pause/resume in the iOS 26 inline placement by sharing the same 44-point control group with the expanded accessory.
- [x] Adapt vehicle, staff, depot, line/timetable, and GTFS audit detail sheets to iPhone width while retaining their macOS minimum sizes and actions.
- [x] Make pending GTFS departures navigate to a full-width assignment detail on compact iPhone; keep the fixed two-column departure/detail layout on macOS and wide iPad.
- [x] Keep a persistent 44-point assignment action in the compact detail and return to the departure list after a successful assignment.
- [x] Run the targeted mobile, vehicle, timetable, depot-directory, roster, career-restore, and guide smokes; add a regression check for iOS-only navigation APIs in the shared dispatch view.
- [x] Build the current macOS Debug target universally (`x86_64 arm64`) from a temporary copy with the required data resources; verify the executable architectures and Info.plist.
- [x] Build the current Debug iPhoneOS target for arm64 after the compact dispatch source correction; verify its Info.plist and iOS 17.0 minimum.

### Task 4: Remove the divergent mobile implementation and document delivery

**Files:**
- Modify: `TransportManagerIDFM/TransportManagerIDFMApp.swift`
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Verify that the shared dashboard covers the active career/menu, GTFS dispatch, fleet/staff/workshop, reports/finances, guide, JSON transfer, and cloud restore paths; remove the now-unused 1,538-line simplified iPhone implementation and its duplicate screens.
- [x] Require explicit confirmation before a JSON import replaces the active career view, preserving the paused local career in the save list.
- [x] Move the first iCloud-restore gate into `CareerRestorePresentation`, consumed by the shared launch menu, and retarget the restore smoke to that active flow.
- [x] Document the five-tab mapping, full mobile workflows, CloudKit entitlement and team requirements for cross-device sync.
- [x] Run the focused mobile-tab, career-restore, and career-guide smokes plus Swift and shell syntax checks for the changed files.
- [ ] Run `git diff --check` across all pre-existing tracked changes; the path-filtered check for the four files changed in this continuation passes. The worktree scheme still hits the Xcode operation-group hang, though both platform builds pass from a temporary copy.
- [ ] Run the compact iPhone UI visually in Simulator or on a connected iPhone; CoreSimulator remains unavailable.
- [ ] Install and launch on a connected iPhone when Apple Development signing and CoreDevice are available.

## Execution Note

Implement natively in this session, task-by-task, because the existing dashboard owns the complete game state and all tasks must preserve that shared source of truth.
