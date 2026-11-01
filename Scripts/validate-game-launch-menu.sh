#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/game-launch-menu.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

swiftc -module-cache-path "$temporary_directory/module-cache" \
  -o "$temporary_directory/GameLaunchMenuFlowSmoke" \
  "$project_root/TransportManagerIDFM/Domain/GameLaunchMenuFlow.swift" \
  "$project_root/Validation/GameLaunchMenuFlowSmoke.swift"
"$temporary_directory/GameLaunchMenuFlowSmoke"
