#!/usr/bin/env bash
# Linux / macOS helper: finds the projector's TLS ADB port over mDNS and connects.
#
# Requires platform-tools (adb). The script tries, in order:
#   1. The $ADB environment variable, if you set it.
#   2. `adb` on your PATH.
#
# If adb is not found, install Android platform-tools:
#   https://developer.android.com/tools/releases/platform-tools
# then either add it to PATH or export ADB=/full/path/to/adb before running.

set -e

if [ -n "$ADB" ] && [ -x "$ADB" ]; then
  : # use $ADB as-is
elif command -v adb >/dev/null 2>&1; then
  ADB=$(command -v adb)
else
  echo "ERROR: Could not find adb." >&2
  echo >&2
  echo "Install Android platform-tools:" >&2
  echo "  https://developer.android.com/tools/releases/platform-tools" >&2
  echo >&2
  echo "Then either add it to PATH or run with: ADB=/full/path/to/adb $0" >&2
  exit 2
fi
echo "Using adb: $ADB"

echo "Searching for ADB via mDNS..."
LINE=$("$ADB" mdns services 2>&1 | grep "_adb-tls-connect._tcp" | head -1 || true)

if [ -z "$LINE" ]; then
  echo "No ADB service found."
  echo "Make sure the HY300 ADB Opener app ran successfully on the projector,"
  echo "and that both are on the same Wi-Fi."
  exit 1
fi

IPPORT=$(echo "$LINE" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+' | head -1)
if [ -z "$IPPORT" ]; then
  echo "Could not parse mDNS output: $LINE"
  exit 1
fi

echo "Found $IPPORT"
echo "Connecting..."
"$ADB" connect "$IPPORT"
"$ADB" devices -l
