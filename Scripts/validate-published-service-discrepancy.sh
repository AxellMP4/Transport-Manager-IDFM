#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
scratch_dir="$(mktemp -d "${TMPDIR:-/private/tmp}/tmidfm-service-notice.XXXXXX")"
trap 'rm -rf "$scratch_dir"' EXIT HUP INT TERM

swiftc \
    -module-cache-path "$scratch_dir/ModuleCache" \
    "$repo_root/TransportManagerIDFM/Domain/PublishedServiceDiscrepancy.swift" \
    "$repo_root/Scripts/PublishedServiceDiscrepancySmoke.swift" \
    -o "$scratch_dir/PublishedServiceDiscrepancySmoke"
"$scratch_dir/PublishedServiceDiscrepancySmoke"
