#!/bin/bash
#
#  measure_energy.sh
#
#  Records each build with the Instruments Power Profiler from launch, round-robin, and appends the
#  app's power impact and CPU instructions in the discovery and idle windows to energy.csv
#  (see energy_summary.py). Power Profiler needs iOS 26 or later on the device.
#  Builds in ODD_ROUNDS_ONLY (default no-sdk google-cast-sdk) are measured in odd rounds only.
#
#  Usage: ./measure_energy.sh <device udid> <devicectl device id> <output dir> <rounds> <seconds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
OUT=$3
ROUNDS=$4
SECONDS_TO_RECORD=$5
shift 5
TOOLS=$(cd "$(dirname "$0")" && pwd)
source "$TOOLS/device_app.sh"
ODD_ROUNDS_ONLY=${ODD_ROUNDS_ONLY-no-sdk google-cast-sdk}
mkdir -p "$OUT"

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        app=${build#*=}
        [[ " $ODD_ROUNDS_ONLY " == *" $label "* ]] && [ $((round % 2)) -eq 0 ] && continue
        dir="$OUT/$label"
        mkdir -p "$dir"
        stop_app "$DEVICECTL_ID"
        xcrun devicectl device install app --device "$DEVICECTL_ID" "$app" > /dev/null 2>&1
        record_trace "$SECONDS_TO_RECORD" "$dir/run-$round.trace" --template "Power Profiler" --device "$DEVICE" --launch -- "$app" \
            || { echo "$label,$round,FAILED: recording"; continue; }
        export_schema "$dir/run-$round.trace" ProcessSubsystemPowerImpact "$dir/run-$round.xml" \
            || { echo "$label,$round,FAILED: export"; continue; }
        /usr/bin/python3 -I "$TOOLS/energy_summary.py" "$label" "$round" "$dir/run-$round.xml" discovery=5-35 idle=60-240 | tee -a "$OUT/energy.csv"
    done
done
