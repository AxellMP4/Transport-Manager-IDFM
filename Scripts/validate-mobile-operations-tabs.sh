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
