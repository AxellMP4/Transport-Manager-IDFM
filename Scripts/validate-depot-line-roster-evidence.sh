#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-depot-roster.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules" "$temporary_directory/user-home"
app_bundle="$temporary_directory/DepotLineRosterEvidenceSmoke.app"
mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"
cat > "$app_bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>DepotLineRosterEvidenceSmoke</string>
  <key>CFBundleIdentifier</key>
  <string>org.transitcity.DepotLineRosterEvidenceSmoke</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
PLIST
for resource in \
  bords-de-marne-depot-roster.csv \
  bords-de-marne-depot-roster-rows.csv \
  bords-de-marne-depot-roster-claims.csv \
  bords-de-marne-depot-roster-documents.csv; do
  cp "$project_root/docs/data/$resource" "$app_bundle/Contents/Resources/$resource"
done

feed_directory="$temporary_directory/gtfs-fixture"
mkdir -p "$feed_directory"
cat > "$feed_directory/routes.txt" <<'CSV'
route_id,route_short_name,route_type
113,113,3
CSV
cat > "$feed_directory/stops.txt" <<'CSV'
stop_id,stop_name,stop_lat,stop_lon
STOP-A,Arrêt A,48.8500,2.3000
STOP-B,Arrêt B,48.8510,2.3010
CSV
cat > "$feed_directory/trips.txt" <<'CSV'
route_id,service_id,trip_id
113,SERVICE,TRIP-113
CSV
cat > "$feed_directory/stop_times.txt" <<'CSV'
trip_id,arrival_time,departure_time,stop_id,stop_sequence
TRIP-113,08:00:00,08:00:00,STOP-A,1
TRIP-113,08:10:00,08:10:00,STOP-B,2
CSV
cat > "$feed_directory/calendar.txt" <<'CSV'
service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
SERVICE,1,1,1,1,1,1,1,20261101,20261101
CSV
gtfs_archive="$temporary_directory/depot-line-coverage-fixture.zip"
zip -q -j "$gtfs_archive" "$feed_directory"/*.txt

swiftc \
  -swift-version 6 \
  -module-cache-path "$temporary_directory/swift-modules" \
  -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
  -emit-executable \
  -module-name DepotLineRosterEvidenceSmoke \
  "$project_root"/TransportManagerIDFM/Domain/*.swift \
  "$project_root/Validation/DepotLineRosterEvidenceSmoke.swift" \
  -o "$app_bundle/Contents/MacOS/DepotLineRosterEvidenceSmoke"

CFFIXED_USER_HOME="$temporary_directory/user-home" \
  "$app_bundle/Contents/MacOS/DepotLineRosterEvidenceSmoke" "$gtfs_archive"
