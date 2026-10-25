#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
expected_sha256=7c5a06711fbe7cafaafd7ef02781ba1548a178e80326250131a63bbb829670bc
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-gtfs-audit.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

set -- "$project_root"/docs/data/gtfs/idfm-gtfs-2026-10-24-part-*.bin
if [ "$#" -ne 18 ]; then
    echo "Expected 18 contiguous embedded GTFS fragments; found $#" >&2
    exit 1
fi
cat "$@" > "$temporary_directory/idfm-gtfs-2026-10-24.zip"
actual_sha256=$(shasum -a 256 "$temporary_directory/idfm-gtfs-2026-10-24.zip" | awk '{print $1}')
if [ "$actual_sha256" != "$expected_sha256" ]; then
    echo "Embedded GTFS SHA-256 mismatch: $actual_sha256" >&2
    exit 1
fi
unzip -tq "$temporary_directory/idfm-gtfs-2026-10-24.zip"

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules" "$temporary_directory/domain"
cp "$project_root"/TransportManagerIDFM/Domain/*.swift "$temporary_directory/domain/"
swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$temporary_directory"/domain/*.swift \
    "$project_root/Validation/GTFSArchiveAudit.swift" \
    -o "$temporary_directory/GTFSArchiveAudit"
"$temporary_directory/GTFSArchiveAudit" "$temporary_directory/idfm-gtfs-2026-10-24.zip"
