#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-zip-streaming.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

python3 - "$temporary_directory" <<'PY'
import pathlib
import random
import struct
import sys
import zipfile

directory = pathlib.Path(sys.argv[1])
payload = random.Random(20261024).randbytes(512_000)
(directory / "payload.bin").write_bytes(payload)
with zipfile.ZipFile(directory / "fixture.zip", "w", compression=zipfile.ZIP_DEFLATED) as archive:
    archive.write(directory / "payload.bin", "payload.bin")

def corrupt_entry_crc(source, destination, entry_name):
    data = bytearray(source.read_bytes())
    offset = 0
    while True:
        offset = data.find(b"PK\x01\x02", offset)
        if offset < 0:
            raise RuntimeError(f"Missing central directory entry {entry_name}")
        filename_length = struct.unpack_from("<H", data, offset + 28)[0]
        extra_length = struct.unpack_from("<H", data, offset + 30)[0]
        comment_length = struct.unpack_from("<H", data, offset + 32)[0]
        filename_start = offset + 46
        filename = data[filename_start:filename_start + filename_length].decode()
        if filename == entry_name:
            crc = struct.unpack_from("<I", data, offset + 16)[0]
            struct.pack_into("<I", data, offset + 16, crc ^ 1)
            destination.write_bytes(data)
            return
        offset += 46 + filename_length + extra_length + comment_length

corrupt_entry_crc(directory / "fixture.zip", directory / "corrupt-payload.zip", "payload.bin")

gtfs_entries = {
    "routes.txt": "route_id,route_type,route_short_name,route_long_name\nroute-1,3,1,Test line\n",
    "stops.txt": "stop_id,stop_name,stop_lat,stop_lon\nstop-a,A,48.1,2.1\nstop-b,B,48.2,2.2\n",
    "trips.txt": "trip_id,route_id,service_id\ntrip-1,route-1,service-1\n",
    "stop_times.txt": "trip_id,arrival_time,departure_time,stop_id,stop_sequence\ntrip-1,08:00:00,08:00:00,stop-a,1\ntrip-1,08:10:00,08:10:00,stop-b,2\n",
    "calendar.txt": "service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date\nservice-1,1,1,1,1,1,1,1,20261024,20261101\n",
}
with zipfile.ZipFile(directory / "gtfs-fixture.zip", "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for name, content in gtfs_entries.items():
        archive.writestr(name, content)
corrupt_entry_crc(directory / "gtfs-fixture.zip", directory / "corrupt-stop-times.zip", "stop_times.txt")
PY

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"
swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name TransportManagerIDFM \
    "$project_root"/TransportManagerIDFM/Domain/*.swift \
    "$project_root/Validation/ZIPArchiveStreamingSmoke.swift" \
    -o "$temporary_directory/ZIPArchiveStreamingSmoke"
"$temporary_directory/ZIPArchiveStreamingSmoke" \
    "$temporary_directory/fixture.zip" \
    "$temporary_directory/payload.bin" \
    "$temporary_directory/corrupt-payload.zip" \
    "$temporary_directory/gtfs-fixture.zip" \
    "$temporary_directory/corrupt-stop-times.zip"
