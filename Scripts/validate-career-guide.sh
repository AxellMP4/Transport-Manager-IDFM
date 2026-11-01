#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-career-guide.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"
swiftc \
    -swift-version 6 \
    -D CAREER_GUIDE_FLOW_SMOKE \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$project_root/TransportManagerIDFM/Features/CareerGuideModel.swift" \
    "$project_root/Validation/CareerGuideFlowSmoke.swift" \
    -o "$temporary_directory/CareerGuideFlowSmoke"
"$temporary_directory/CareerGuideFlowSmoke"
