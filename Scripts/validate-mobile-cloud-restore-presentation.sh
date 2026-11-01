#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-mobile-cloud-restore.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

require_source() {
    expected=$1
    source_file=$2
    if ! rg --fixed-strings --quiet "$expected" "$source_file"; then
        printf 'FAIL: expected source wiring not found: %s in %s\n' "$expected" "$source_file" >&2
        exit 1
    fi
}

require_source 'isInitialCareerRestorePending || cloudSync.isSyncing' "$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift"
require_source 'cloudRestorePresentation.canStartNewCareer' "$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift"
require_source '.disabled(!cloudRestorePresentation.canImportSave)' "$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift"
require_source 'Pour choisir, reprends la partie locale puis ouvre le menu iCloud dans la barre supérieure du tableau de bord.' "$project_root/TransportManagerIDFM/Features/GameLaunchMenuView.swift"

swiftc -frontend -parse \
    "$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift" \
    "$project_root/TransportManagerIDFM/Features/GameLaunchMenuView.swift"

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"
swiftc \
    -swift-version 6 \
    -D MOBILE_CLOUD_RESTORE_SMOKE \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift" \
    "$project_root/Validation/MobileCloudRestorePresentationSmoke.swift" \
    -o "$temporary_directory/MobileCloudRestorePresentationSmoke"
"$temporary_directory/MobileCloudRestorePresentationSmoke"
