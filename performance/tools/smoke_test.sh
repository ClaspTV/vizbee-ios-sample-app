#!/bin/bash
#
#  smoke_test.sh
#
#  Installs and launches a build, checks that it is still running after 15 s and, when a
#  discovery type is given (ssdp, googlecast or any), that the app sent discovery probes and that
#  at least one TV answered. Writes the device's address and the TVs that answered to
#  discovery.txt. Fails if a check fails, so a crashing build, a missing Local Network
#  permission or a network without TVs is caught before any measurement.
#
#  Usage: ./smoke_test.sh <devicectl device id> <capture interface> <path/to/VizbeeDemo.app> <output dir> [ssdp|googlecast|any]
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
"$TOOLS/discovery_check.sh" "$OUT/smoke.pcap" "${CHECK:-any}" > "$OUT/discovery.txt"
probes=$(awk '/^Probes:/ {print $2}' "$OUT/discovery.txt")
answers=$(grep -cE '^(SSDP|Cast) ' "$OUT/discovery.txt" || true)
if [ -n "$CHECK" ] && [ "$probes" -eq 0 ]; then
    echo "FAILED: the app sent no $CHECK discovery probes. Allow Local Network access for the app on the device (and tap Allow if asked), then run again."
    exit 1
fi
if [ -n "$CHECK" ] && [ "$answers" -eq 0 ]; then
    echo "FAILED: no TV answered the $CHECK probes. Join the Wi-Fi network the TVs are on, switch the TVs on, and run again."
    exit 1
fi
echo "OK${CHECK:+, devices that answered: $answers}"
