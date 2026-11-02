#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-background-save.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

python3 - "$project_root/TransportManagerIDFM/Features/OperationsDashboardView.swift" <<'PY'
from pathlib import Path
import re
import sys

source = Path(sys.argv[1]).read_text()
pattern = re.compile(
    r"^(?P<indent>[ \t]*)\.onChange\(of:\s*scenePhase\)\s*\{\s*_,\s*newPhase\s+in(?P<body>.*?)\n(?P=indent)\}",
    re.DOTALL | re.MULTILINE,
)
match = pattern.search(source)
if "@Environment(\.scenePhase) private var scenePhase" not in source or match is None:
    raise SystemExit("FAIL : le tableau de bord doit observer la phase de sa scène.")
if "CareerLifecycleCheckpoint.shouldSave(for: newPhase)" not in match.group("body"):
    raise SystemExit("FAIL : le changement de phase doit appliquer la politique de checkpoint.")
if "CareerLifecycleCheckpoint.shouldSynchronize(for: newPhase)" not in match.group("body"):
    raise SystemExit("FAIL : le retour au premier plan doit appliquer la politique de synchronisation iCloud.")
if "simulation.save()" not in match.group("body"):
    raise SystemExit("FAIL : le passage en arrière-plan doit enregistrer la carrière localement.")
if "cloudSync.scheduleSynchronization(with: simulation, library: library)" not in match.group("body"):
    raise SystemExit("FAIL : le retour au premier plan doit programmer la synchronisation iCloud.")
if "pauseAndSave()" in match.group("body"):
    raise SystemExit("FAIL : le checkpoint d’arrière-plan ne doit pas modifier l’état de lecture.")
PY

swiftc \
    -swift-version 6 \
    -framework SwiftUI \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name BackgroundSaveCheckpointSmoke \
    "$project_root/TransportManagerIDFM/Features/CareerLifecycleCheckpoint.swift" \
    "$project_root/Validation/BackgroundSaveCheckpointSmoke.swift" \
    -o "$temporary_directory/BackgroundSaveCheckpointSmoke"
"$temporary_directory/BackgroundSaveCheckpointSmoke"
