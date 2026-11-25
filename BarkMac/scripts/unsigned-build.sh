#!/usr/bin/env bash
# Compile the Mac app and run its logic tests without an Apple Developer team.
# This does not launch the app, sign it, or contact a push server.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

if grep -RInE 'URLSession|registerForRemoteNotifications\(|URLRequest\(' \
  BarkMac/App BarkMac/Sources \
  --exclude=APNsTokenClient.swift \
  --exclude=LiveBarkRegisterTransport.swift
then
  echo "network and APNs calls must stay inside the gated clients" >&2
  exit 1
fi

if grep -nE 'registerForRemoteNotifications\(|URLSession' BarkMac/App/AppDelegate.swift; then
  echo "launch delegate must not request a token or open a session" >&2
  exit 1
fi

if find BarkMac \( -name '*.p8' -o -name 'AuthKey_*' \) | grep -q .; then
  echo "APNs key file must not be added" >&2
  exit 1
fi

if grep -RInE '5U8LBRXG3A|LH4T9V5U4R' \
  BarkMac/App BarkMac/Sources BarkMac/Tests BarkMac/Signing BarkMac/BarkMac.xcodeproj
then
  echo "official team or key id must not be added" >&2
  exit 1
fi

swift test --package-path BarkMac
xcodebuild \
  -project BarkMac/BarkMac.xcodeproj \
  -scheme BarkMac \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=- \
  build
