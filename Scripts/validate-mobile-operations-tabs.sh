#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-mobile-tabs.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"
swiftc \
    -swift-version 6 \
    -D MOBILE_CLOUD_RESTORE_SMOKE \
    -D MOBILE_DASHBOARD_TAB_SMOKE \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift" \
    "$project_root/Validation/MobileOperationsTabSmoke.swift" \
    -o "$temporary_directory/MobileOperationsTabSmoke"
"$temporary_directory/MobileOperationsTabSmoke"

app_source="$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift"
dashboard_source="$project_root/TransportManagerIDFM/Features/OperationsDashboardView.swift"
playback_accessory_source="$project_root/TransportManagerIDFM/Features/MobileSimulationPlaybackAccessory.swift"
depot_inspector_source="$project_root/TransportManagerIDFM/Features/DepotInspectorView.swift"
network_coverage_source="$project_root/TransportManagerIDFM/Features/NetworkCoverageAuditView.swift"
dispatch_source="$dashboard_source"

if ! rg -Uq '#if os\(iOS\)[\r\n]+[[:space:]]*OperationsDashboardView\(\)' "$app_source"; then
    echo "The iOS app root must use OperationsDashboardView." >&2
    exit 1
fi

if ! rg -Fq 'TabView(selection: mobileDashboardTabSelection)' "$dashboard_source"; then
    echo "The shared dashboard must bind the native TabView to workspace selection." >&2
    exit 1
fi

if ! rg -Fq 'ForEach(MobileDashboardTab.allCases)' "$dashboard_source" \
    || ! rg -Fq '.tag(tab)' "$dashboard_source"; then
    echo "The shared dashboard must render all five MobileDashboardTab cases." >&2
    exit 1
fi

if ! rg -Fq 'get: { mobileWorkspaceSelection.selectedTab }' "$dashboard_source"; then
    echo "Workspace changes must select their containing iPhone tab." >&2
    exit 1
fi

if ! rg -Fq 'mobileWorkspaceSelection.selectTab(tab)' "$dashboard_source" \
    || ! rg -Fq 'mobileWorkspaceSelection.selectWorkspace(workspaceKey: workspace.rawValue)' "$dashboard_source"; then
    echo "Top-level tabs and external workspace navigation must update remembered selection." >&2
    exit 1
fi

if ! rg -Fq 'Picker(selection: mobileWorkspaceBinding(for: tab))' "$dashboard_source" \
    || ! rg -Fq 'tab.workspaceKeys.compactMap' "$dashboard_source" \
    || ! rg -Fq 'ForEach(workspaces)' "$dashboard_source"; then
    echo "The iPhone tab must expose its workspace subsections through the shared selection state." >&2
    exit 1
fi

if ! rg -Fq 'mobileWorkspaceSelection.selectedWorkspaceKey(for: tab)' "$dashboard_source" \
    || ! rg -Fq 'workspaceContent(for: workspace)' "$dashboard_source"; then
    echo "Every native tab must render the workspace remembered for that tab." >&2
    exit 1
fi

if sed -n '/private var mobileWorkspaceTabItems:/,/private var dashboardFileHandling:/p' "$dashboard_source" \
    | rg -Fq 'Color.clear'; then
    echo "Inactive native tabs must keep their workspace subtrees mounted." >&2
    exit 1
fi

if ! rg -Fq 'accessibilityLabel("Options de carrière et sauvegarde")' "$dashboard_source" \
    || ! rg -Fq 'Label("Menu principal", systemImage: "house")' "$dashboard_source" \
    || ! rg -Fq 'Label("Sauvegarder maintenant", systemImage: "externaldrive")' "$dashboard_source"; then
    echo "Career menu and save actions must remain clearly accessible on iPhone." >&2
    exit 1
fi

if ! rg -Fq 'CareerGuideView(' "$project_root/TransportManagerIDFM/Features/GameLaunchMenuView.swift" \
    || ! rg -Fq 'onOpenGuideDestination: { destination in' "$dashboard_source"; then
    echo "The optional career guide must remain available from the shared launch menu." >&2
    exit 1
fi

if ! rg -Fq 'MapCompass()' "$dashboard_source" \
    || ! rg -Fq 'MapScaleView()' "$dashboard_source" \
    || ! rg -Fq 'interactionModes: [.pan, .zoom]' "$dashboard_source"; then
    echo "The compact operations map must preserve pan, zoom, compass, and scale controls." >&2
    exit 1
fi

for layer_title in 'Réseau et lignes' 'Arrêts' 'Flotte' 'Incidents et travaux'; do
    if ! rg -Fq "Label(\"$layer_title\"" "$dashboard_source"; then
        echo "The compact map is missing the $layer_title layer control." >&2
        exit 1
    fi
done

if ! rg -Fq 'private func compactStopDetail' "$dashboard_source" \
    || ! rg -Fq 'private func compactBusDetail' "$dashboard_source" \
    || ! rg -Fq 'ScrollView {' "$dashboard_source" \
    || ! rg -Fq 'accessibilityLabel("Fermer le détail de l’arrêt")' "$dashboard_source" \
    || ! rg -Fq 'accessibilityLabel("Fermer le détail du bus")' "$dashboard_source"; then
    echo "Compact bus and stop details must scroll and expose an explicit close action." >&2
    exit 1
fi

if ! rg -Fq 'Button("Terminé") { isMobileLinePickerPresented = false }' "$dashboard_source" \
    || ! rg -Fq 'Button("Terminé") { isMobileMapLegendPresented = false }' "$dashboard_source" \
    || ! rg -Fq 'Button("Terminé") { isMobileMapEventsPresented = false }' "$dashboard_source" \
    || ! rg -Fq 'selectedDepotLineID = line.id' "$dashboard_source" \
    || ! rg -Fq 'fitMap(to: coordinates)' "$dashboard_source"; then
    echo "Line selection, map fitting, and dismissible map panels must remain available." >&2
    exit 1
fi

if sed -n '/\.overlay(alignment: \.bottomTrailing)/,/\.overlay(alignment: \.bottom)/p' "$dashboard_source" \
    | rg -Fq 'if usesCompactMobileNavigation'; then
    echo "Long disruption notices must stay in the compact event sheet, not cover the map." >&2
    exit 1
fi

if ! rg -Fq '.frame(width: 44, height: 44)' "$dashboard_source" \
    || ! rg -Fq '.accessibilityLabel("Acheter un bus")' "$dashboard_source" \
    || ! rg -Fq '.accessibilityLabel("Engager un conducteur")' "$dashboard_source" \
    || ! rg -Fq '.accessibilityLabel("Affecter un départ")' "$dashboard_source"; then
    echo "Compact empty-fleet actions must remain discoverable and have 44-point targets." >&2
    exit 1
fi

mobile_playback_controls=$(sed -n '/private var mobileSimulationControlBar:/,/private var depotLineSidebar:/p' "$dashboard_source")
if ! printf '%s\n' "$mobile_playback_controls" | rg -Fq '.frame(width: 44, height: 44)' \
    || [ "$(printf '%s\n' "$mobile_playback_controls" | rg -Fc '.frame(width: 44, height: 44)')" -lt 3 ] \
    || ! printf '%s\n' "$mobile_playback_controls" | rg -Fq 'accessibilityLabel("Vitesse de simulation :' \
    || ! printf '%s\n' "$mobile_playback_controls" | rg -Fq 'accessibilityLabel(simulation.isRunning ? "Mettre en pause" : "Reprendre la carrière")' \
    || ! printf '%s\n' "$mobile_playback_controls" | rg -Fq 'accessibilityLabel("Avancer au prochain événement")'; then
    echo "The iOS 17–25 playback fallback must keep speed, pause/resume, and next-event controls with 44-point targets." >&2
    exit 1
fi

if ! rg -Fq 'Text(simulatedAt.formatted(date: .abbreviated, time: .shortened))' "$playback_accessory_source" \
    || ! rg -Fq 'onSetSpeed(option)' "$playback_accessory_source" \
    || ! rg -Fq 'Button(action: onAdvanceToNextEvent)' "$playback_accessory_source" \
    || ! rg -Fq 'Button(action: onTogglePlayback)' "$playback_accessory_source" \
    || ! rg -Fq '.frame(width: 44, height: 44)' "$playback_accessory_source"; then
    echo "The iOS 26 playback accessory must keep simulated time, speed, pause/resume, and next-event controls." >&2
    exit 1
fi

for responsive_sheet in \
    '.platformSheetFrame(minWidth: 480, minHeight: 460)' \
    '.platformSheetFrame(minWidth: 500, minHeight: 380)' \
    '.platformSheetFrame(minWidth: 500, minHeight: 340)' \
    '.platformSheetFrame(minWidth: 520, minHeight: 340)' \
    '.platformSheetFrame(minWidth: 540, minHeight: 440)'; do
    if ! rg -Fq "$responsive_sheet" "$dashboard_source"; then
        echo "Compact inspection and staff sheets must adapt to iPhone width while retaining desktop dimensions." >&2
        exit 1
    fi
done

for responsive_sheet in \
    '.platformSheetFrame(minWidth: 1040, minHeight: 700)' \
    '.platformSheetFrame(minWidth: 720, minHeight: 640)' \
    '.platformSheetFrame(minWidth: 1120, minHeight: 680)'; do
    if ! rg -Fq "$responsive_sheet" "$depot_inspector_source"; then
        echo "Depot, line-roster, and regional-audit details must fit iPhone sheets." >&2
        exit 1
    fi
done

if ! rg -Fq 'if horizontalSizeClass == .compact {' "$depot_inspector_source" \
    || ! rg -Fq '.navigationDestination(isPresented: $isMobileDepotDetailPresented)' "$depot_inspector_source" \
    || ! rg -Fq 'selectedDepotDetail' "$depot_inspector_source"; then
    echo "The depot directory must navigate to its detail on compact iPhone screens instead of forcing a two-column layout." >&2
    exit 1
fi

if ! rg -Fq '.platformSheetFrame(minWidth: 860, minHeight: 620)' "$network_coverage_source" \
    || ! rg -Fq '.platformSheetFrame(minWidth: 760, minHeight: 620)' "$network_coverage_source" \
    || ! rg -Fq 'func platformSheetFrame(minWidth: CGFloat, minHeight: CGFloat)' "$dashboard_source"; then
    echo "Network and trip-review sheets must use the adaptive platform frame." >&2
    exit 1
fi

if ! rg -Fq '@Environment(\.horizontalSizeClass) private var horizontalSizeClass' "$dispatch_source" \
    || ! rg -Fq 'if horizontalSizeClass == .compact {' "$dispatch_source" \
    || ! rg -Fq '.navigationDestination(isPresented: $isCompactDispatchDetailPresented)' "$dispatch_source" \
    || ! rg -Fq 'isCompactDispatchDetailPresented = true' "$dispatch_source" \
    || ! rg -Fq '.safeAreaInset(edge: .bottom)' "$dispatch_source"; then
    echo "Compact course assignment must navigate from the departure list to a full-width detail with a reachable assign action." >&2
    exit 1
fi

if ! python3 - "$dispatch_source" <<'PY'
from pathlib import Path
import re
import sys

source = Path(sys.argv[1]).read_text()
dispatch = source.split("private struct TripDispatchView: View {", 1)[1]
dispatch = dispatch.split("private var departureList:", 1)[0]
guarded_inline_titles = re.findall(
    r"(?m)^\s*#if os\(iOS\)\s*\n\s*\.navigationBarTitleDisplayMode\(\.inline\)\s*\n\s*#endif\s*$",
    dispatch,
)
if len(guarded_inline_titles) != 2:
    raise SystemExit("Both compact dispatch title modifiers must be compiled only on iOS.")
PY
then
    echo "Compact dispatch must guard iOS-only navigation title APIs from the macOS build." >&2
    exit 1
fi
