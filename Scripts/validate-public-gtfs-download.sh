#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(CDPATH= cd -- "$script_directory/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/public-gtfs-download-smoke.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

module_cache_directory="$temporary_directory/module-cache"
mkdir -p "$module_cache_directory"

valid_gtfs_directory="$temporary_directory/valid-gtfs"
incomplete_gtfs_directory="$temporary_directory/incomplete-gtfs"
mkdir -p "$valid_gtfs_directory" "$incomplete_gtfs_directory"

printf 'route_id,agency_id,route_short_name,route_long_name,route_type\n' > "$valid_gtfs_directory/routes.txt"
printf 'trip_id,route_id,service_id\n' > "$valid_gtfs_directory/trips.txt"
printf 'stop_id,stop_name,stop_lat,stop_lon\n' > "$valid_gtfs_directory/stops.txt"
printf 'trip_id,arrival_time,departure_time,stop_id,stop_sequence\n' > "$valid_gtfs_directory/stop_times.txt"
cp "$valid_gtfs_directory/routes.txt" "$incomplete_gtfs_directory/routes.txt"
zip -q -j "$temporary_directory/valid-gtfs.zip" "$valid_gtfs_directory"/*.txt
zip -q -j "$temporary_directory/incomplete-gtfs.zip" "$incomplete_gtfs_directory"/*.txt

swiftc \
    -module-cache-path "$module_cache_directory" \
    -parse-as-library \
    "$repository_directory/TransportManagerIDFM/Domain/ZIPArchiveReader.swift" \
    "$repository_directory/TransportManagerIDFM/Domain/PublicGTFSFeed.swift" \
    "$repository_directory/Scripts/PublishedGTFSFeedSmoke.swift" \
    -o "$temporary_directory/PublishedGTFSFeedSmoke"

"$temporary_directory/PublishedGTFSFeedSmoke" \
    "$temporary_directory/valid-gtfs.zip" \
    "$temporary_directory/incomplete-gtfs.zip"
