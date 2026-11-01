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

- [ ] Add failing smoke coverage for map selection, line-panel access, and preservation of all map-layer controls.
- [ ] On iPhone, present the map at full width and expose the line list as a dismissible sheet; retain the current split map/sidebar on macOS and wide iPad.
- [ ] Adapt map legends, closure/detour notices, empty-fleet actions, and bus/stop details to avoid covering the compact map.
- [ ] Verify selection, camera fitting, layers, and details with the navigation smoke and a compact-width UI run.

### Task 3: Adapt all existing workspaces and simulation controls

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `TransportManagerIDFM/Features/MobileSimulationPlaybackAccessory.swift`
- Modify: `Scripts/validate-mobile-operations-tabs.sh`
- Modify: `Validation/MobileOperationsTabSmoke.swift`

**Interfaces:**
- Existing `workspaceBody` views remain the content for fleet, staff, depots, reports, incidents, line data, course motifs, and sources.
- iOS-specific frames use available width; macOS-specific minimum dimensions remain unchanged.

- [ ] Add failing coverage for workspace reachability and playback actions in the new mobile navigation.
- [ ] Add the iOS 26 Liquid Glass tab accessory for pause/resume, speed, simulated time, and next event; provide the same controls on iOS 17–25.
- [ ] Fit existing sheets and detail presentations to iPhone width without reducing their available game actions.
- [ ] Run targeted smoke scripts and build for iOS and macOS.

### Task 4: Remove the divergent mobile implementation and document delivery

**Files:**
- Modify: `TransportManagerIDFM/TransportManagerIDFMApp.swift`
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [ ] Remove the now-unused simplified mobile screens only after shared dashboard parity is verified.
- [x] Document the five-tab mapping, full mobile workflows, CloudKit entitlement and team requirements for cross-device sync.
- [x] Run the focused existing UI/data validation scripts, `git diff --check`, and iOS/macOS builds.
- [ ] Install and launch on a connected iPhone when Apple Development signing and CoreDevice are available.

## Execution Note

Implement natively in this session, task-by-task, because the existing dashboard owns the complete game state and all tasks must preserve that shared source of truth.
