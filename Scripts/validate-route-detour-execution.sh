#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-route-detour.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules" "$temporary_directory/domain"
cp "$project_root"/TransportManagerIDFM/Domain/*.swift "$temporary_directory/domain/"
swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$temporary_directory"/domain/*.swift \
    "$project_root/Validation/RouteDetourExecutionSmoke.swift" \
    -o "$temporary_directory/RouteDetourExecutionSmoke"
"$temporary_directory/RouteDetourExecutionSmoke"
