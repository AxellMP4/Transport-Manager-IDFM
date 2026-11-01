#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
view="$project_root/TransportManagerIDFM/Features/GTFSRouteTimetableGridView.swift"
header=$(sed -n '/Text("Course")/,/ForEach(group.trips)/p' "$view")
trip_rows=$(sed -n '/ForEach(group.trips) { trip in/,/\.background(trip.id/p' "$view")

if printf '%s\n' "$header" | grep -Fq '.lineLimit(2)'; then
    printf 'FAIL: stop names are capped at two lines\n' >&2
    exit 1
fi

if printf '%s\n' "$header" | grep -Fq 'height: 42'; then
    printf 'FAIL: stop-name headers have a fixed height\n' >&2
    exit 1
fi

for requirement in \
    '.fixedSize(horizontal: false, vertical: true)'; do
    if ! printf '%s\n' "$header" | grep -Fq "$requirement"; then
        printf 'FAIL: timetable stop headers are missing %s\n' "$requirement" >&2
        exit 1
    fi
done

if ! grep -Fq 'ScrollView(.horizontal)' "$view"; then
    printf 'FAIL: the stop table no longer supports horizontal scrolling\n' >&2
    exit 1
fi

for requirement in \
    '.accessibilityLabel("Course \(trip.tripID)")' \
    '.accessibilityLabel("\(visit.stopName), \(serviceTime(visit.scheduledAt))")'; do
    if ! printf '%s\n' "$trip_rows" | grep -Fq "$requirement"; then
        printf 'FAIL: timetable cells are missing %s\n' "$requirement" >&2
        exit 1
    fi
done

printf 'PASS: stop headers grow with Dynamic Type, horizontal scrolling remains, and VoiceOver gets full course and stop/time labels\n'
