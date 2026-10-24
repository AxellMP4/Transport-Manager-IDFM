#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-gtfs-provenance.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p \
  "$temporary_directory/swift-modules" \
  "$temporary_directory/clang-modules" \
  "$temporary_directory/domain" \
  "$temporary_directory/validation" \
  "$temporary_directory/fixture"

cp "$project_root"/TransportManagerIDFM/Domain/*.swift "$temporary_directory/domain/"
cp "$project_root"/Validation/GTFSProvenanceSmoke.swift "$temporary_directory/validation/"

cat > "$temporary_directory/fixture/routes.txt" <<'EOF'
route_id,route_type,route_short_name
route-1,3,1
EOF
cat > "$temporary_directory/fixture/trips.txt" <<'EOF'
route_id,service_id,trip_id,shape_id
route-1,weekday,trip-missing-stop-record,
route-1,weekday,trip-missing-coordinates,
route-1,weekday,trip-missing-stop-id,
EOF
cat > "$temporary_directory/fixture/stop_times.txt" <<'EOF'
trip_id,arrival_time,departure_time,stop_id,stop_sequence
trip-missing-stop-record,08:00:00,08:00:00,stop-a,1
trip-missing-stop-record,08:10:00,08:10:00,stop-not-in-feed,2
trip-missing-stop-record,08:20:00,08:20:00,stop-b,3
trip-missing-coordinates,09:00:00,09:00:00,stop-a,1
trip-missing-coordinates,09:10:00,09:10:00,stop-no-coordinates,2
trip-missing-coordinates,09:20:00,09:20:00,stop-b,3
trip-missing-stop-id,10:00:00,10:00:00,stop-a,1
trip-missing-stop-id,10:10:00,10:10:00,,2
trip-missing-stop-id,10:20:00,10:20:00,stop-b,3
EOF
cat > "$temporary_directory/fixture/stops.txt" <<'EOF'
stop_id,stop_name,stop_lat,stop_lon
stop-a,Arrêt A,48.800,2.300
stop-b,Arrêt B,48.810,2.310
stop-no-coordinates,Arrêt sans coordonnées,,
EOF
cat > "$temporary_directory/fixture/calendar.txt" <<'EOF'
service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
weekday,1,1,1,1,1,0,0,20260101,20261231
EOF

zip -q -j "$temporary_directory/missing-stop-records.zip" "$temporary_directory"/fixture/*.txt

swiftc \
  -swift-version 6 \
  -module-cache-path "$temporary_directory/swift-modules" \
  -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
  -emit-executable \
  -module-name TransportManagerIDFM \
  "$temporary_directory"/domain/*.swift \
  "$temporary_directory"/validation/GTFSProvenanceSmoke.swift \
  -o "$temporary_directory/GTFSProvenanceSmoke"

"$temporary_directory/GTFSProvenanceSmoke" "$temporary_directory/missing-stop-records.zip"
