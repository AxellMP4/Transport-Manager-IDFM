#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-career-progression.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name CareerProgressionSmoke \
    "$project_root/TransportManagerIDFM/Domain/CareerProgression.swift" \
    "$project_root/Validation/CareerProgressionSmokeFixtures.swift" \
    "$project_root/Validation/CareerProgressionSmoke.swift" \
    -o "$temporary_directory/CareerProgressionSmoke"
"$temporary_directory/CareerProgressionSmoke"

engine_source="$project_root/TransportManagerIDFM/Domain/SimulationEngine.swift"
require_source() {
    if ! rg -Fq "$1" "$engine_source"; then
        echo "ÉCHEC : intégration de progression absente dans SimulationEngine.swift : $1" >&2
        exit 1
    fi
}

require_source 'var careerProgression: CareerProgressionState? = nil' \
    "$project_root/TransportManagerIDFM/Domain/SimulationEngine.swift"
require_source 'CareerProgressionCatalog.reconcile(session: &restoredSession)' \
    "$project_root/TransportManagerIDFM/Domain/SimulationEngine.swift"
require_source 'CareerProgressionCatalog.reconcile(session: &importedSession)' \
    "$project_root/TransportManagerIDFM/Domain/SimulationEngine.swift"
require_source 'CareerProgressionCatalog.reconcile(session: &exportSession)' \
    "$project_root/TransportManagerIDFM/Domain/SimulationEngine.swift"
require_source 'CareerProgressionCatalog.reconcile(session: &activeSession)' \
    "$project_root/TransportManagerIDFM/Domain/SimulationEngine.swift"
echo "PASS : état Codable optionnel et réconciliation au chargement, import, événement, sauvegarde et export."
