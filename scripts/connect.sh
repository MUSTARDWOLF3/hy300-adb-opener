#!/usr/bin/env bash
# Linux / macOS helper: finds the projector's TLS ADB port over mDNS and connects.
# Requires platform-tools (adb) on PATH.

set -e
ADB=${ADB:-adb}

echo "Searching for ADB via mDNS..."
LINE=$("$ADB" mdns services 2>&1 | grep "_adb-tls-connect._tcp" | head -1 || true)

if [ -z "$LINE" ]; then
  echo "No ADB service found. Make sure the HY300 ADB Opener app ran successfully"
  echo "on the projector, and that both are on the same Wi-Fi."
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
