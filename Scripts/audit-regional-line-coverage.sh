#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
service_date=${1:-2026-11-02}
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-regional-coverage.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

gtfs_sha256_expected=e77435e98732a49c0b1e11581aedfc4ba8f30a5c6b27e0332b69746d5da7908d
line_references_sha256_expected=aaa19c09fed4dd5cbd146d39e6dd9f2fd375842bc76dfc5842323c69ea668249
line_documents_sha256_expected=0507f0f739ae94458dc073d17425ec482c8168ce8144f3642b695435b0e4f29c
geometry_archive_sha256_expected=36f947db84acf7fe09c0c1818743fced4111eac018ed4705fdf385232a1cbd94
geometry_geojson_sha256_expected=a5bc25ebccecb763d0329e4c05995c88e7594663e2a0cc80e3ae484e5dc4a497

set -- "$project_root"/docs/data/gtfs/idfm-gtfs-2026-10-31-part-*.bin
if [ "$#" -ne 18 ]; then
    echo "Expected 18 contiguous GTFS fragments for 2026-10-31; found $#" >&2
    exit 1
fi
cat "$@" > "$temporary_directory/idfm-gtfs-2026-10-31.zip"
gtfs_sha256_actual=$(shasum -a 256 "$temporary_directory/idfm-gtfs-2026-10-31.zip" | awk '{print $1}')
if [ "$gtfs_sha256_actual" != "$gtfs_sha256_expected" ]; then
    echo "GTFS SHA-256 mismatch: $gtfs_sha256_actual" >&2
    exit 1
fi
unzip -tq "$temporary_directory/idfm-gtfs-2026-10-31.zip"

line_references="$project_root/TransportManagerIDFM/Resources/IDFMSnapshots/idfm-lines-2026-10-20.csv"
line_documents="$project_root/TransportManagerIDFM/Resources/IDFMSnapshots/idfm-line-documents-2026-10-20.csv"
geometry_archive="$project_root/docs/data/geometries/idfm-route-geometries-2026-10-20.zip"
line_references_sha256_actual=$(shasum -a 256 "$line_references" | awk '{print $1}')
line_documents_sha256_actual=$(shasum -a 256 "$line_documents" | awk '{print $1}')
geometry_archive_sha256_actual=$(shasum -a 256 "$geometry_archive" | awk '{print $1}')
if [ "$line_references_sha256_actual" != "$line_references_sha256_expected" ]; then
    echo "Line-reference CSV SHA-256 mismatch: $line_references_sha256_actual" >&2
    exit 1
fi
if [ "$line_documents_sha256_actual" != "$line_documents_sha256_expected" ]; then
    echo "Line-document CSV SHA-256 mismatch: $line_documents_sha256_actual" >&2
    exit 1
fi
if [ "$geometry_archive_sha256_actual" != "$geometry_archive_sha256_expected" ]; then
    echo "Commercial geometry archive SHA-256 mismatch: $geometry_archive_sha256_actual" >&2
    exit 1
fi
unzip -tq "$geometry_archive"
unzip -p "$geometry_archive" idfm-bus-lines-2026-10-20.geojson > "$temporary_directory/idfm-bus-lines-2026-10-20.geojson"
geometry_geojson_sha256_actual=$(shasum -a 256 "$temporary_directory/idfm-bus-lines-2026-10-20.geojson" | awk '{print $1}')
if [ "$geometry_geojson_sha256_actual" != "$geometry_geojson_sha256_expected" ]; then
    echo "Commercial geometry GeoJSON SHA-256 mismatch: $geometry_geojson_sha256_actual" >&2
    exit 1
fi

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules" "$temporary_directory/domain"
cp "$project_root"/TransportManagerIDFM/Domain/*.swift "$temporary_directory/domain/"
swiftc \
    -O \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name RegionalCoverageMatrixAudit \
    "$temporary_directory"/domain/*.swift \
    "$project_root/Validation/RegionalCoverageMatrixAudit.swift" \
    -o "$temporary_directory/RegionalCoverageMatrixAudit"

output_path="$project_root/docs/data/coverage/idfm-regional-coverage-$service_date.json"
"$temporary_directory/RegionalCoverageMatrixAudit" \
    "$temporary_directory/idfm-gtfs-2026-10-31.zip" \
    "$line_references" \
    "$line_documents" \
    "$temporary_directory/idfm-bus-lines-2026-10-20.geojson" \
    "$geometry_archive" \
    "$output_path" \
    "$service_date"
