#!/usr/bin/env bash
# Local signed build. Not used by CI.
# Does not contact Apple: -allowProvisioningUpdates and
# -allowProvisioningDeviceRegistration are rejected.
# Refuses until BARK_MAC_ALLOW_SIGNING=1, and refuses bundle ids or team ids
# already written on the iOS or watch targets.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
local_config="BarkMac/Signing/Local.xcconfig"
ios_project="Bark.xcodeproj/project.pbxproj"

if [ "${BARK_MAC_ALLOW_SIGNING:-}" != "1" ]; then
  echo "Refusing to sign. No Apple account is contacted." >&2
  echo "Unsigned package: bash BarkMac/scripts/unsigned-build.sh" >&2
  exit 1
fi

if [ ! -f "$local_config" ]; then
  echo "Copy BarkMac/Signing/Local.xcconfig.example to Local.xcconfig and replace the placeholders." >&2
  exit 1
fi

if grep -q 'allowProvisioningUpdates\|allowProvisioningDeviceRegistration' "$local_config"; then
  echo "Local.xcconfig must not request provisioning updates." >&2
  exit 1
fi
if grep -q 'CODE_SIGN_STYLE = Automatic' "$local_config"; then
  echo "Automatic signing can register a bundle id from the Xcode app. Use Manual." >&2
  exit 1
fi

bundle="$(awk -F' = ' '/^PRODUCT_BUNDLE_IDENTIFIER = / { gsub(/[ ;]/, "", $2); print $2; exit }' "$local_config")"
team="$(awk -F' = ' '/^DEVELOPMENT_TEAM = / { gsub(/[ ;]/, "", $2); print $2; exit }' "$local_config")"

if [ -z "${bundle}" ] || [ "${bundle}" = "REPLACE_WITH_YOUR_MAC_BUNDLE_ID" ] || [ "${bundle}" = "local.barkmac.unsigned" ]; then
  echo "Set PRODUCT_BUNDLE_IDENTIFIER to a new macOS bundle id." >&2
  exit 1
fi
if [ -z "${team}" ] || [ "${team}" = "YOUR_TEAM_ID" ]; then
  echo "Set DEVELOPMENT_TEAM to your own 10-character Team ID." >&2
  exit 1
fi
if grep -q "PRODUCT_BUNDLE_IDENTIFIER = ${bundle};" "$ios_project"; then
  echo "That bundle id already belongs to an iOS or watch target." >&2
  exit 1
fi
if grep -q "DEVELOPMENT_TEAM = ${team};" "$ios_project"; then
  echo "That Team ID is already set on an existing target. Use your own." >&2
  exit 1
fi

echo "Manual sign requested. This command does not pass -allowProvisioningUpdates."
xcodebuild \
  -project BarkMac/BarkMac.xcodeproj \
  -scheme BarkMac \
  -destination 'platform=macOS' \
  -configuration Debug \
  -xcconfig "$local_config" \
  build
