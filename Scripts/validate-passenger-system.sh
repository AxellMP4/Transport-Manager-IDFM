#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-passenger-system.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules" "$temporary_directory/domain"
mkdir -p "$temporary_directory/user-home"
cp "$project_root"/TransportManagerIDFM/Domain/*.swift "$temporary_directory/domain/"
swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$temporary_directory"/domain/*.swift \
    "$project_root/Validation/PassengerSystemSmoke.swift" \
    -o "$temporary_directory/PassengerSystemSmoke"
CFFIXED_USER_HOME="$temporary_directory/user-home" "$temporary_directory/PassengerSystemSmoke"
