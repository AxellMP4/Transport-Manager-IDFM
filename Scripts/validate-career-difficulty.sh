#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-career-difficulty.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT

swiftc -module-cache-path "$temporary_directory/ModuleCache" \
    "$project_root/TransportManagerIDFM/Domain/CareerDifficulty.swift" \
    "$project_root/Validation/CareerDifficultySmoke.swift" \
    -o "$temporary_directory/CareerDifficultySmoke"
"$temporary_directory/CareerDifficultySmoke"

engine_source="$project_root/TransportManagerIDFM/Domain/SimulationEngine.swift"
dashboard_source="$project_root/TransportManagerIDFM/Features/OperationsDashboardView.swift"
require_source() {
    if ! rg -Fq "$1" "$2"; then
        echo "ÉCHEC : motif absent dans $2 : $1" >&2
        exit 1
    fi
}

require_source 'var careerDifficulty: CareerDifficulty? = nil' "$engine_source"
require_source 'careerDifficulty ?? .standard' "$engine_source"
require_source 'careerDifficulty: CareerDifficulty = .standard' "$engine_source"
require_source 'careerDifficulty.startingCashBalance(' "$engine_source"
require_source 'VehicleWorkshopPartCatalog.initialStockCostEuro' "$engine_source"
require_source 'id: "initial-workshop-parts"' "$engine_source"
require_source 'Picker("Difficulté de départ", selection: careerDifficultyBinding)' "$dashboard_source"
require_source 'session.effectiveCareerDifficulty.title' "$dashboard_source"
require_source 'simulation.updateEventFrequencies' "$dashboard_source"
require_source 'activeSession.breakdownFrequency = breakdownFrequency' "$engine_source"
require_source 'activeSession.trafficDisruptionFrequency = trafficDisruptionFrequency' "$engine_source"
echo "PASS : session, stock initial, sélecteur partagé et fréquences modifiables."
