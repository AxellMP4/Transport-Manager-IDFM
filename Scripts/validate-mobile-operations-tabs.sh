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
