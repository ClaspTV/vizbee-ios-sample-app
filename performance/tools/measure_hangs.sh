#!/bin/bash
#
#  measure_hangs.sh
#
#  Records launch and discovery with the Instruments Time Profiler template (which detects
#  hangs) for several builds in turn, round by round, and counts the hangs with hang_summary.py.
#
#  Usage: ./measure_hangs.sh <device udid> <devicectl device id> <output dir> <rounds> <seconds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
OUT=$3
ROUNDS=$4
SECONDS_PER_RUN=$5
shift 5
TOOLS=$(cd "$(dirname "$0")" && pwd)
source "$TOOLS/device_app.sh"
mkdir -p "$OUT"

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        app=${build#*=}
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
        mkdir -p "$OUT/$label"
        trace="$OUT/$label/run-$round.trace"
        for attempt in 1 2; do
            xcrun devicectl device install app --device "$DEVICECTL_ID" "$app" > /dev/null
            stop_app "$DEVICECTL_ID"
            record_trace "$SECONDS_PER_RUN" "$trace" --template 'Time Profiler' --device "$DEVICE" --launch -- "$bundle_id" && break
        done
        stop_app "$DEVICECTL_ID"
        (
            export_table "$trace" potential-hangs "$trace.hangs.xml" || exit
            /usr/bin/python3 -I "$TOOLS/hang_summary.py" "$label" "$round" < "$trace.hangs.xml" | tee -a "$OUT/hangs.csv"
        ) &
    done
done
wait
