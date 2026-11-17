#!/bin/bash
#
#  measure_activity.sh
#
#  Records CPU and memory with the Instruments Activity Monitor template for several
#  builds in turn, round by round. Each run launches the app and leaves it on its home
#  screen, then reads two windows from the same recording:
#    discovery  5-35 s   Vizbee's active scan (a probe every 2 s for the first 30 s)
#    idle      60-240 s  passive scan (a probe every 60 s), no casting
#  Writes one row per window to activity.csv (see activity_summary.py).
#
#  Usage: ./measure_activity.sh <device udid> <output dir> <rounds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
OUT=$2
ROUNDS=$3
shift 3
TOOLS=$(cd "$(dirname "$0")" && pwd)
RECORD_SECONDS=245
mkdir -p "$OUT"

stop_app() {
    local pid
    pid=$(xcrun devicectl device info processes --device "$DEVICE" 2> /dev/null | awk '/VizbeeDemo.app\/VizbeeDemo/ {print $1}' | head -1)
    [ -n "$pid" ] && xcrun devicectl device process terminate --device "$DEVICE" --pid "$pid" > /dev/null 2>&1
    sleep 3
}

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        app=${build#*=}
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
        mkdir -p "$OUT/$label"
        xcrun devicectl device install app --device "$DEVICE" "$app" > /dev/null
        stop_app
        trace="$OUT/$label/run-$round.trace"
        rm -rf "$trace"
        xcrun xctrace record --template 'Activity Monitor' --device "$DEVICE" \
            --time-limit "${RECORD_SECONDS}s" --output "$trace" --launch -- "$bundle_id" > /dev/null
        # xctrace export sometimes crashes right after a recording, so retry it.
        for attempt in 1 2 3 4 5; do
            sleep 2
            xcrun xctrace export --input "$trace" --xpath '//table[@schema="activity-monitor-process-live"]' > "$trace.xml" 2> /dev/null && break
        done
        /usr/bin/python3 -I "$TOOLS/activity_summary.py" "$label" discovery "$round" 5 35 < "$trace.xml" | tee -a "$OUT/activity.csv"
        /usr/bin/python3 -I "$TOOLS/activity_summary.py" "$label" idle "$round" 60 240 < "$trace.xml" | tee -a "$OUT/activity.csv"
    done
done
