#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-market-inspection.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

market_view="$project_root/TransportManagerIDFM/Features/OperationsDashboardView.swift"
rg -Fq 'VehicleMarketDepotCompatibilityRules.presentation(for: energyReadiness)' "$market_view"
rg -Fq '.accessibilityIdentifier("vehicleMarketDepotCompatibility")' "$market_view"
rg -Fq '.searchable(' "$market_view"
rg -Fq 'VehicleMarketCatalog.matchesCatalogSearch(model, query: normalizedCatalogSearch)' "$market_view"
rg -Fq 'Label("Négocier", systemImage:' "$market_view"
rg -Fq '.accessibilityIdentifier("vehicleMarketNegotiationPrice")' "$market_view"
rg -Fq '.accessibilityIdentifier("vehicleMarketNegotiationResult")' "$market_view"
rg -Fq 'règles déterministes de jeu' "$market_view"

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"

swiftc \
  -swift-version 6 \
  -module-cache-path "$temporary_directory/swift-modules" \
  -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
  -emit-executable \
  -module-name VehicleMarketInspectionSmoke \
  "$project_root"/TransportManagerIDFM/Domain/*.swift \
  "$project_root/Validation/VehicleMarketInspectionSmoke.swift" \
  -o "$temporary_directory/VehicleMarketInspectionSmoke"

"$temporary_directory/VehicleMarketInspectionSmoke"
