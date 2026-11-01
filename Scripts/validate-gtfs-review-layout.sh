#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
view="$project_root/TransportManagerIDFM/Features/NetworkCoverageAuditView.swift"
controls=$(sed -n '/private func issueList(_ issues:/,/private var routeNames:/p' "$view")
layout=$(printf '%s\n' "$controls" | sed -n '/ViewThatFits(in: .horizontal)/,/if displayMode == .motifs/p')

require_layout() {
    if ! printf '%s\n' "$layout" | grep -Fq "$1"; then
        printf 'FAIL: GTFS review layout is missing %s\n' "$1" >&2
        exit 1
    fi
}

require_layout 'ViewThatFits(in: .horizontal)'
require_layout 'HStack(spacing: 10)'
require_layout 'tripIssueSearchField(minimumWidth: 180)'
require_layout 'VStack(alignment: .leading, spacing: 8)'
require_layout 'tripIssueSearchField()'
require_layout '.frame(maxWidth: .infinity)'

for helper in 'private func displayModePicker' 'private var issueKindPicker' 'private func tripIssueSearchField' 'frame(minWidth: minimumWidth)'; do
    if ! printf '%s\n' "$controls" | grep -Fq "$helper"; then
        printf 'FAIL: GTFS review controls are missing %s\n' "$helper" >&2
        exit 1
    fi
done

printf 'PASS: course/motif controls provide a horizontal row and a stacked narrow-width fallback\n'
