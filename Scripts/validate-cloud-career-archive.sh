#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-cloud-archive.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules" "$temporary_directory/domain"
for source_file in "$project_root"/TransportManagerIDFM/Domain/*.swift; do
    cp "$source_file" "$temporary_directory/domain/"
done

swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$temporary_directory"/domain/*.swift \
    "$project_root/Validation/CloudCareerArchiveSmoke.swift" \
    -o "$temporary_directory/CloudCareerArchiveSmoke"
"$temporary_directory/CloudCareerArchiveSmoke"
