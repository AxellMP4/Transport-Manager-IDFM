#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-market-pricing.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"

swiftc \
  -swift-version 6 \
  -module-cache-path "$temporary_directory/swift-modules" \
  -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
  -emit-executable \
  -module-name VehicleMarketPricingSmoke \
  "$project_root"/TransportManagerIDFM/Domain/*.swift \
  "$project_root/Validation/VehicleMarketPricingSmoke.swift" \
  -o "$temporary_directory/VehicleMarketPricingSmoke"

"$temporary_directory/VehicleMarketPricingSmoke"
