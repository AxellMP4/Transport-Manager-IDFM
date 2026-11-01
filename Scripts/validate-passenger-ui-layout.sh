#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
gauge_source="$project_root/TransportManagerIDFM/Features/PassengerLoadGaugeView.swift"
report_source="$project_root/TransportManagerIDFM/Features/PassengerOperationsReportView.swift"

if ! rg -q '\.frame\(minWidth: 44, minHeight: 44\)' "$gauge_source"; then
    echo "FAIL: the moving-bus marker does not guarantee a 44-point hit target" >&2
    exit 1
fi

if rg -q 'caption2' "$gauge_source"; then
    echo "FAIL: the passenger-load gauge uses caption2-sized text" >&2
    exit 1
fi

adaptive_layout_count=$(rg -c 'ViewThatFits\(in: \.horizontal\)' "$report_source")
if [ "$adaptive_layout_count" -lt 3 ]; then
    echo "FAIL: the passenger report lacks adaptive layouts for its filters, titles, and disruption summary" >&2
    exit 1
fi

echo "PASS: passenger report tap target, readable gauge text, and compact-width fallbacks are present"
