#!/bin/bash
#
#  measure_idle_soak.sh
#
#  For each build in turn: launches the app, leaves it on the home screen for <minutes>, records it with the
#  Instruments Activity Monitor template, and appends the memory growth per minute (per passive scan) and
#  the CPU from minute 2 on to idle-soak.csv (see idle_slope.py).
#
#  Usage: ./measure_idle_soak.sh <device udid> <devicectl device id> <output dir> <rounds> <minutes> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
OUT=$3
ROUNDS=$4
MINUTES=$5
shift 5
TOOLS=$(cd "$(dirname "$0")" && pwd)
source "$TOOLS/device_app.sh"
mkdir -p "$OUT"

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        app=${build#*=}
        mkdir -p "$OUT/$label"
        trace="$OUT/$label/run-$round.trace"
        stop_app "$DEVICECTL_ID"
        xcrun devicectl device install app --device "$DEVICECTL_ID" "$app" > /dev/null 2>&1
        record_trace $((MINUTES * 60 + 15)) "$trace" --template 'Activity Monitor' --device "$DEVICE" --launch -- "$app" \
            || { echo "$label,$round,FAILED: recording"; continue; }
        export_table "$trace" activity-monitor-process-live "$trace.xml" || continue
        /usr/bin/python3 -I "$TOOLS/idle_slope.py" "$label" "$round" 2 "$MINUTES" < "$trace.xml" | tee -a "$OUT/idle-soak.csv"
    done
done
