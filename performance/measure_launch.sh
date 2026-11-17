#!/bin/bash
#
#  measure_launch.sh
#
#  Installs a build on a device and records cold launches with the Instruments
#  App Launch template. Writes one .trace per run and a CSV with each launch phase.
#
#  Usage: ./measure_launch.sh <device udid> <path/to/VizbeeDemo.app> <label> <output dir> [runs] [cool down seconds]
#
set -euo pipefail

DEVICE=$1
APP=$2
LABEL=$3
OUT=$4
RUNS=${5:-10}
COOL_DOWN=${6:-20}
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
TOOLS=$(cd "$(dirname "$0")" && pwd)

mkdir -p "$OUT/$LABEL"
xcrun devicectl device install app --device "$DEVICE" "$APP" > /dev/null

# The first launch after an install is slower, so record one warm-up launch and discard it.
xcrun xctrace record --template 'App Launch' --device "$DEVICE" --time-limit 10s \
    --output "$OUT/$LABEL/warmup.trace" --launch -- "$BUNDLE_ID" > /dev/null

for run in $(seq 1 "$RUNS"); do
    sleep "$COOL_DOWN"
    trace="$OUT/$LABEL/launch-$run.trace"
    rm -rf "$trace"
    xcrun xctrace record --template 'App Launch' --device "$DEVICE" --time-limit 10s \
        --output "$trace" --launch -- "$BUNDLE_ID" > /dev/null
    # xctrace export sometimes crashes right after a recording, so retry it.
    for attempt in 1 2 3 4 5; do
        sleep 2
        xcrun xctrace export --input "$trace" --xpath '//table[@schema="life-cycle-period"]' > "$trace.xml" 2> /dev/null && break
    done
    /usr/bin/python3 -I "$TOOLS/launch_phases.py" "$LABEL" "$run" < "$trace.xml" >> "$OUT/launch.csv"
    tail -1 "$OUT/launch.csv"
done
