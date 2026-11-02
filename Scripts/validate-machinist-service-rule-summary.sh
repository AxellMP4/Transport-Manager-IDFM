#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-machinist-rules.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

dashboard_source="$project_root/TransportManagerIDFM/Features/OperationsDashboardView.swift"
call_count=$(rg -F -o 'MachinistWorkRulesSummaryCard()' "$dashboard_source" | wc -l | tr -d '[:space:]')
if [ "$call_count" -lt 2 ]; then
    echo "ÉCHEC : le résumé commun des règles doit apparaître dans Personnel et dans l’affectation." >&2
    exit 1
fi

swiftc \
    -swift-version 6 \
    -module-cache-path "$temporary_directory/swift-modules" \
    -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
    -emit-executable \
    -module-name MachinistServiceRuleSummarySmoke \
    "$project_root/TransportManagerIDFM/Domain/MachinistServiceRuleSummary.swift" \
    "$project_root/Validation/MachinistServiceRuleSummarySmoke.swift" \
    -o "$temporary_directory/MachinistServiceRuleSummarySmoke"
"$temporary_directory/MachinistServiceRuleSummarySmoke"
