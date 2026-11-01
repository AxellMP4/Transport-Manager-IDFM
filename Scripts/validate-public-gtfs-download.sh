#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(CDPATH= cd -- "$script_directory/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/public-gtfs-download-smoke.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

module_cache_directory="$temporary_directory/module-cache"
domain_source_directory="$temporary_directory/domain-sources"
mkdir -p "$module_cache_directory" "$domain_source_directory"

# Compile a stable snapshot so concurrent edits to unrelated domain files do
# not interrupt this focused smoke with swiftc's input-file-changed error.
cp "$repository_directory"/TransportManagerIDFM/Domain/*.swift "$domain_source_directory/"

valid_gtfs_directory="$temporary_directory/valid-gtfs"
incomplete_gtfs_directory="$temporary_directory/incomplete-gtfs"
invalid_tables_directory="$temporary_directory/invalid-tables-gtfs"
mkdir -p "$valid_gtfs_directory" "$incomplete_gtfs_directory" "$invalid_tables_directory"

cat > "$valid_gtfs_directory/routes.txt" <<'CSV'
route_id,route_type,route_short_name
route-1,3,1
CSV
cat > "$valid_gtfs_directory/trips.txt" <<'CSV'
trip_id,route_id,service_id
trip-1,route-1,weekday
CSV
cat > "$valid_gtfs_directory/stops.txt" <<'CSV'
stop_id,stop_name,stop_lat,stop_lon
stop-a,Arrêt A,48.800,2.300
stop-b,Arrêt B,48.810,2.310
CSV
cat > "$valid_gtfs_directory/stop_times.txt" <<'CSV'
trip_id,arrival_time,departure_time,stop_id,stop_sequence
trip-1,08:00:00,08:00:00,stop-a,1
trip-1,08:10:00,08:10:00,stop-b,2
CSV
cat > "$valid_gtfs_directory/calendar.txt" <<'CSV'
service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
weekday,1,1,1,1,1,0,0,20260101,20261231
CSV

cp "$valid_gtfs_directory/routes.txt" "$incomplete_gtfs_directory/routes.txt"
cat > "$invalid_tables_directory/routes.txt" <<'CSV'
route_key,mode
route-1,bus
CSV
cp "$valid_gtfs_directory/trips.txt" "$invalid_tables_directory/trips.txt"
cp "$valid_gtfs_directory/stops.txt" "$invalid_tables_directory/stops.txt"
cp "$valid_gtfs_directory/stop_times.txt" "$invalid_tables_directory/stop_times.txt"
cp "$valid_gtfs_directory/calendar.txt" "$invalid_tables_directory/calendar.txt"
zip -q -j "$temporary_directory/valid-gtfs.zip" "$valid_gtfs_directory"/*.txt
zip -q -j "$temporary_directory/incomplete-gtfs.zip" "$incomplete_gtfs_directory"/*.txt
zip -q -j "$temporary_directory/invalid-tables-gtfs.zip" "$invalid_tables_directory"/*.txt

swiftc \
    -swift-version 6 \
    -module-cache-path "$module_cache_directory" \
    -module-name TransportManagerIDFM \
    "$domain_source_directory"/*.swift \
    "$repository_directory/Scripts/PublishedGTFSFeedSmoke.swift" \
    -o "$temporary_directory/PublishedGTFSFeedSmoke"

"$temporary_directory/PublishedGTFSFeedSmoke" \
    "$temporary_directory/valid-gtfs.zip" \
    "$temporary_directory/incomplete-gtfs.zip" \
    "$temporary_directory/invalid-tables-gtfs.zip"
