#!/bin/bash
#
#  smoke_test.sh
#
#  Installs and launches a build, checks that it is still running after 15 s and, when a
#  discovery check is given, that the pattern appears in the device's network traffic.
#  Fails if either check fails, so a crashing build or a missing Local Network permission
#  is caught before any measurement.
#
#  Usage: ./smoke_test.sh <devicectl device id> <capture interface> <path/to/VizbeeDemo.app> <output dir> [discovery check]
#
set -uo pipefail

DEVICE=$1
INTERFACE=$2
APP=$3
OUT=$4
CHECK=${5:-}
TOOLS=$(cd "$(dirname "$0")" && pwd)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
source "$TOOLS/device_app.sh"
mkdir -p "$OUT"

xcrun devicectl device install app --device "$DEVICE" "$APP" > /dev/null
stop_app "$DEVICE"
tcpdump -i "$INTERFACE" -n -s 256 -w "$OUT/smoke.pcap" > /dev/null 2>&1 &
capture=$!
sleep 2
launch_output=$(xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID" 2>&1 || true)
if [[ "$launch_output" == *Locked* ]]; then
    kill "$capture"
    echo "FAILED: the device is locked. Unlock it, set Auto-Lock to Never, and run again."
    exit 1
fi
sleep 15
kill "$capture"
if [ -z "$(app_pid "$DEVICE")" ]; then
    echo "FAILED: the app is not running 15 s after launch (crash?). Check the device's crash logs."
    exit 1
fi
stop_app "$DEVICE"
if [ "$(tcpdump -r "$OUT/smoke.pcap" -n 2> /dev/null | wc -l)" -eq 0 ]; then
    echo "FAILED: the network capture is empty. Reconnect the device and run again."
    exit 1
fi
local_packets=$(tcpdump -r "$OUT/smoke.pcap" -n 2> /dev/null | grep -cE ' IP (10|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9.]+ > ' || true)
if [ "$local_packets" -eq 0 ]; then
    echo "FAILED: the device has no local network address (only 169.254.x.x or none). Join the Wi-Fi network the TVs are on, and run again."
    exit 1
fi
matches=$(tcpdump -r "$OUT/smoke.pcap" -n -v 2> /dev/null | grep -cF -- "$CHECK" || true)
if [ -n "$CHECK" ] && [ "$matches" -eq 0 ]; then
    echo "FAILED: no discovery traffic matching '$CHECK'. Allow Local Network access for the app on the device (and tap Allow if asked), then run again."
    exit 1
fi
echo "OK"
