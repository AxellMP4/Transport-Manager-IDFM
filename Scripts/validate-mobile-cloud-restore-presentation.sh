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

app_source="$project_root/TransportManagerIDFM/TransportManagerIDFMApp.swift"
dashboard_source="$project_root/TransportManagerIDFM/Features/OperationsDashboardView.swift"
launch_menu_source="$project_root/TransportManagerIDFM/Features/GameLaunchMenuView.swift"

require_source 'CareerRestorePresentation(' "$launch_menu_source"
require_source 'statusMessage: syncStatus,' "$launch_menu_source"
require_source 'careerRestorePresentation.isPending' "$launch_menu_source"
require_source 'careerRestorePresentation.canStartNewCareer' "$launch_menu_source"
require_source 'careerRestorePresentation.canImportSave' "$launch_menu_source"
require_source 'await cloudSync.synchronize(with: simulation, library: library)' "$dashboard_source"
require_source 'Pour choisir, reprends la partie locale puis ouvre le menu iCloud dans la barre supérieure du tableau de bord.' "$launch_menu_source"

python3 - "$dashboard_source" <<'PY'
from pathlib import Path
import re
import sys

source = Path(sys.argv[1]).read_text()
pattern = re.compile(
    r"\\.onChange\\(of:\\s*simulation\\.session\\?\\.effectiveActiveDepotID\\)\\s*"
    r"\\{\\s*_,\\s*activeDepotID\\s+in(?P<body>.*?)\\n\\s*\\.onChange\\(of:\\s*selectedWorkspaceTab\\)",
    re.DOTALL,
)
match = pattern.search(source)
if match is None:
    raise SystemExit("FAIL : le tableau de bord doit suivre le dépôt actif de la carrière restaurée.")
if "selectedDepotID = activeDepotID" not in match.group("body"):
    raise SystemExit("FAIL : une restauration iCloud doit sélectionner le dépôt actif récupéré.")
if "selectedWorkspaceTab = .network" not in match.group("body"):
    raise SystemExit("FAIL : une restauration iCloud doit revenir à l’espace Réseau du dépôt.")
PY

swiftc -frontend -parse \
    "$app_source" \
    "$launch_menu_source" \
    "$dashboard_source"

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"
swiftc \
    -swift-version 6 \
    -D MOBILE_CLOUD_RESTORE_SMOKE \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$app_source" \
    "$project_root/Validation/MobileCloudRestorePresentationSmoke.swift" \
    -o "$temporary_directory/MobileCloudRestorePresentationSmoke"
"$temporary_directory/MobileCloudRestorePresentationSmoke"
