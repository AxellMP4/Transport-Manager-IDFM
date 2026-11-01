#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/transitcity-depot-roster.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

mkdir -p "$temporary_directory/swift-modules" "$temporary_directory/clang-modules"
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

swiftc \
  -swift-version 6 \
  -module-cache-path "$temporary_directory/swift-modules" \
  -Xcc "-fmodules-cache-path=$temporary_directory/clang-modules" \
  -emit-executable \
  -module-name DepotLineRosterEvidenceSmoke \
  "$project_root"/TransportManagerIDFM/Domain/*.swift \
  "$project_root/Validation/DepotLineRosterEvidenceSmoke.swift" \
  -o "$app_bundle/Contents/MacOS/DepotLineRosterEvidenceSmoke"

"$app_bundle/Contents/MacOS/DepotLineRosterEvidenceSmoke"
