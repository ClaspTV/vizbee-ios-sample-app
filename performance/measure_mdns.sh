#!/bin/bash
#
#  measure_mdns.sh
#
#  Records every process with the Instruments Activity Monitor template while each build runs,
#  so the CPU that mDNSResponder (the system Bonjour service) spends on the app's discovery can be
#  compared between builds. The app is launched 5 s into the recording; windows are measured from
#  the app's launch, the same as measure_activity.sh. Writes rows to processes.csv.
#
#  Usage: ./measure_mdns.sh <device udid> <devicectl device id> <output dir> <rounds> <seconds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
OUT=$3
ROUNDS=$4
RECORD_SECONDS=$5
shift 5
TOOLS=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT"

stop_app() {
    local pid
    pid=$(xcrun devicectl device info processes --device "$DEVICECTL_ID" 2> /dev/null | awk '/VizbeeDemo.app\/VizbeeDemo/ {print $1}' | head -1)
    [ -n "$pid" ] && xcrun devicectl device process terminate --device "$DEVICECTL_ID" --pid "$pid" > /dev/null 2>&1
    sleep 3
}

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        app=${build#*=}
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
        mkdir -p "$OUT/$label"
        xcrun devicectl device install app --device "$DEVICECTL_ID" "$app" > /dev/null
        stop_app
        trace="$OUT/$label/run-$round.trace"
        rm -rf "$trace"
        xcrun xctrace record --template 'Activity Monitor' --device "$DEVICE" --all-processes \
            --time-limit "${RECORD_SECONDS}s" --output "$trace" > /dev/null &
        recorder=$!
        sleep 5
        xcrun devicectl device process launch --device "$DEVICECTL_ID" "$bundle_id" > /dev/null
        wait $recorder
        stop_app
        for attempt in 1 2 3 4 5; do
            sleep 2
            xcrun xctrace export --input "$trace" --xpath '//table[@schema="activity-monitor-process-live"]' > "$trace.xml" 2> /dev/null && break
        done
        /usr/bin/python3 -I "$TOOLS/process_summary.py" "$label" discovery "$round" 5 35 VizbeeDemo mDNSResponder < "$trace.xml" | tee -a "$OUT/processes.csv"
        /usr/bin/python3 -I "$TOOLS/process_summary.py" "$label" idle "$round" 60 240 VizbeeDemo mDNSResponder < "$trace.xml" | tee -a "$OUT/processes.csv"
    done
done
