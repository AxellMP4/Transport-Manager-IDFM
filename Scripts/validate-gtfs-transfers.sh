#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-gtfs-transfers.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM
mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules" "$temporary_directory/domain" "$temporary_directory/user-home"
cp "$project_root"/TransportManagerIDFM/Domain/*.swift "$temporary_directory/domain/"

create_feed() {
    feed_directory=$1
    include_transfers=$2
    mkdir -p "$feed_directory"
    cat > "$feed_directory/agency.txt" <<'CSV'
agency_id,agency_name,agency_url,agency_timezone
agency,Fixture Transit,https://example.test,Europe/Paris
CSV
    cat > "$feed_directory/routes.txt" <<'CSV'
route_id,agency_id,route_short_name,route_type
R1,agency,1,3
R2,agency,2,3
R3,agency,3,3
R4,agency,4,3
R5,agency,5,3
R6,agency,6,3
R7,agency,7,3
R8,agency,8,3
R9,agency,9,3
R10,agency,10,3
R11,agency,11,3
R12,agency,12,3
R13,agency,13,3
R14,agency,14,3
R15,agency,15,3
CSV
    cat > "$feed_directory/trips.txt" <<'CSV'
route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id
R1,service,TRIP-FROM,End,0,,
R2,service,TRIP-TO,End,0,,
R3,service,TRIP-BAN-TO,End,0,,
R4,service,TRIP-SPEC-FROM,End,0,,
R5,service,TRIP-SPEC-TO,End,0,,
R6,service,TRIP-PARENT-FROM,End,0,,
R7,service,TRIP-PARENT-TO,End,0,,
R8,service,TRIP-LINK4-FROM,End,0,,
R9,service,TRIP-LINK4-TO,End,0,,
R10,service,TRIP-LINK5-FROM,End,0,,
R11,service,TRIP-LINK5-TO,End,0,,
R12,service,TRIP-ZERO-FROM,End,0,,
R13,service,TRIP-ZERO-TO,End,0,,
R14,service,TRIP-TIMED-FROM,End,0,,
R15,service,TRIP-TIMED-TO,End,0,,
CSV
    cat > "$feed_directory/stops.txt" <<'CSV'
stop_id,stop_name,stop_lat,stop_lon,location_type,parent_station
FROM,From,48.8500,2.3000,0,
SRC_END,Source end,48.8510,2.3010,0,
TO,To,48.8520,2.3020,0,
DST_END,Destination end,48.8530,2.3030,0,
BAN_FROM,Banned from,48.8540,2.3040,0,
BAN_TO,Banned to,48.8550,2.3050,0,
SPEC_FROM,Specific from,48.8560,2.3060,0,
SPEC_END,Specific end,48.8570,2.3070,0,
SPEC_TO,Specific to,48.8580,2.3080,0,
SPEC_DEST_END,Specific destination end,48.8590,2.3090,0,
PARENT_FROM,Parent from,48.8600,2.3100,1,
PARENT_CHILD_FROM,Parent child from,48.8601,2.3101,0,PARENT_FROM
PARENT_FROM_END,Parent source end,48.8610,2.3110,0,
PARENT_TO,Parent to,48.8620,2.3120,1,
PARENT_CHILD_TO,Parent child to,48.8621,2.3121,0,PARENT_TO
PARENT_DEST_END,Parent destination end,48.8630,2.3130,0,
LINK4_FROM,Linked from,48.8640,2.3140,0,
LINK4_END,Linked source end,48.8650,2.3150,0,
LINK4_TO,Linked to,48.8660,2.3160,0,
LINK4_DEST_END,Linked destination end,48.8670,2.3170,0
LINK5_FROM,Linked type-5 from,48.8680,2.3180,0,
LINK5_END,Linked type-5 source end,48.8690,2.3190,0,
LINK5_TO,Linked type-5 to,48.8700,2.3200,0,
LINK5_DEST_END,Linked type-5 destination end,48.8710,2.3210,0
ZERO_FROM,Recommended from,48.8720,2.3220,0,
ZERO_END,Recommended source end,48.8730,2.3230,0,
ZERO_TO,Recommended to,48.8740,2.3240,0,
ZERO_DEST_END,Recommended destination end,48.8750,2.3250,0
TIMED_FROM,Timed from,48.8760,2.3260,0,
TIMED_END,Timed source end,48.8770,2.3270,0,
TIMED_TO,Timed to,48.8780,2.3280,0,
TIMED_DEST_END,Timed destination end,48.8790,2.3290,0
CSV
    cat > "$feed_directory/stop_times.txt" <<'CSV'
trip_id,arrival_time,departure_time,stop_id,stop_sequence
TRIP-FROM,08:00:00,08:00:00,FROM,1
TRIP-FROM,08:10:00,08:10:00,SRC_END,2
TRIP-TO,08:15:00,08:15:00,TO,1
TRIP-TO,08:25:00,08:25:00,DST_END,2
TRIP-BAN-TO,08:15:00,08:15:00,BAN_TO,1
TRIP-BAN-TO,08:25:00,08:25:00,DST_END,2
TRIP-SPEC-FROM,08:00:00,08:00:00,SPEC_FROM,1
TRIP-SPEC-FROM,08:10:00,08:10:00,SPEC_END,2
TRIP-SPEC-TO,08:15:00,08:15:00,SPEC_TO,1
TRIP-SPEC-TO,08:25:00,08:25:00,SPEC_DEST_END,2
TRIP-PARENT-FROM,08:00:00,08:00:00,PARENT_CHILD_FROM,1
TRIP-PARENT-FROM,08:10:00,08:10:00,PARENT_FROM_END,2
TRIP-PARENT-TO,08:15:00,08:15:00,PARENT_CHILD_TO,1
TRIP-PARENT-TO,08:25:00,08:25:00,PARENT_DEST_END,2
TRIP-LINK4-FROM,08:00:00,08:00:00,LINK4_FROM,1
TRIP-LINK4-FROM,08:10:00,08:10:00,LINK4_END,2
TRIP-LINK4-TO,08:15:00,08:15:00,LINK4_TO,1
TRIP-LINK4-TO,08:25:00,08:25:00,LINK4_DEST_END,2
TRIP-LINK5-FROM,08:00:00,08:00:00,LINK5_FROM,1
TRIP-LINK5-FROM,08:10:00,08:10:00,LINK5_END,2
TRIP-LINK5-TO,08:15:00,08:15:00,LINK5_TO,1
TRIP-LINK5-TO,08:25:00,08:25:00,LINK5_DEST_END,2
TRIP-ZERO-FROM,08:00:00,08:00:00,ZERO_FROM,1
TRIP-ZERO-FROM,08:10:00,08:10:00,ZERO_END,2
TRIP-ZERO-TO,08:15:00,08:15:00,ZERO_TO,1
TRIP-ZERO-TO,08:25:00,08:25:00,ZERO_DEST_END,2
TRIP-TIMED-FROM,08:00:00,08:00:00,TIMED_FROM,1
TRIP-TIMED-FROM,08:10:00,08:10:00,TIMED_END,2
TRIP-TIMED-TO,08:15:00,08:15:00,TIMED_TO,1
TRIP-TIMED-TO,08:25:00,08:25:00,TIMED_DEST_END,2
CSV
    cat > "$feed_directory/calendar.txt" <<'CSV'
service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
service,1,1,1,1,1,1,1,20261031,20261102
CSV
    if [ "$include_transfers" = yes ]; then
        cat > "$feed_directory/transfers.txt" <<'CSV'
from_stop_id,to_stop_id,from_route_id,to_route_id,from_trip_id,to_trip_id,transfer_type,min_transfer_time
FROM,TO,,,,,2,120
SPEC_FROM,SPEC_TO,,,,,3,
SPEC_FROM,SPEC_TO,R4,R5,,,2,45
BAN_FROM,BAN_TO,,,,,3,
PARENT_FROM,PARENT_TO,,,,,2,90
LINK4_FROM,LINK4_TO,,,TRIP-LINK4-FROM,TRIP-LINK4-TO,4,
,,,,TRIP-LINK5-FROM,TRIP-LINK5-TO,5,
ZERO_FROM,ZERO_TO,,,,,0,
TIMED_FROM,TIMED_TO,,,,,1,
NO_MIN_FROM,NO_MIN_TO,,,,,2,
,,,,,,3,
CSV
    fi
    zip -q -j "$temporary_directory/$(basename "$feed_directory").zip" "$feed_directory"/*.txt
}

create_feed "$temporary_directory/with-transfers" yes
create_feed "$temporary_directory/without-transfers" no

swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$temporary_directory"/domain/*.swift \
    "$project_root/Validation/GTFSTransfersSmoke.swift" \
    -o "$temporary_directory/GTFSTransfersSmoke"
CFFIXED_USER_HOME="$temporary_directory/user-home" "$temporary_directory/GTFSTransfersSmoke" \
    "$temporary_directory/with-transfers.zip" \
    "$temporary_directory/without-transfers.zip"
