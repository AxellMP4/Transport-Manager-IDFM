#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-gtfs-intervals.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"

swiftc \
  -swift-version 6 \
  -module-cache-path "$temporary_directory/swift-modules" \
  -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
  -emit-executable \
  -module-name GTFSDepartureIntervalSmoke \
  "$project_root/TransportManagerIDFM/Domain/GTFSDepartureIntervalSummary.swift" \
  "$project_root/Validation/GTFSDepartureIntervalSmoke.swift" \
  -o "$temporary_directory/GTFSDepartureIntervalSmoke"

"$temporary_directory/GTFSDepartureIntervalSmoke"
