#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(CDPATH= cd -- "$script_directory/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/public-gtfs-download-smoke.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

module_cache_directory="$temporary_directory/module-cache"
mkdir -p "$module_cache_directory"

swiftc \
    -module-cache-path "$module_cache_directory" \
    -parse-as-library \
    "$repository_directory/TransportManagerIDFM/Domain/PublicGTFSFeed.swift" \
    "$repository_directory/Scripts/PublishedGTFSFeedSmoke.swift" \
    -o "$temporary_directory/PublishedGTFSFeedSmoke"

"$temporary_directory/PublishedGTFSFeedSmoke"
