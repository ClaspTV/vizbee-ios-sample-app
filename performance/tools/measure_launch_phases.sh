#!/bin/bash
#
#  measure_launch_phases.sh
#
#  Records cold launches with the Instruments App Launch template for several builds in
#  turn, round by round, so drift on the device affects every build the same way. Each
#  build is installed, launched once to warm up (the first launch after an install is
#  slower, and is discarded), then launched once more and measured. Writes the launch time
#  and each launch phase to launch_phases.csv (see launch_phases.py).
#
#  Usage: ./measure_launch_phases.sh <device udid> <devicectl device id> <output dir> <rounds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
OUT=$3
ROUNDS=$4
shift 4
TOOLS=$(cd "$(dirname "$0")" && pwd)
COOL_DOWN=20
source "$TOOLS/device_app.sh"
mkdir -p "$OUT"

record_launch() {
    record_trace 10 "$2" --template 'App Launch' --device "$DEVICE" --launch -- "$1"
}

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        app=${build#*=}
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
        mkdir -p "$OUT/$label"
        xcrun devicectl device install app --device "$DEVICECTL_ID" "$app" > /dev/null
        stop_app "$DEVICECTL_ID"
        xcrun devicectl device process launch --device "$DEVICECTL_ID" "$bundle_id" > /dev/null
        sleep 10
        stop_app "$DEVICECTL_ID"
        sleep "$COOL_DOWN"
        trace="$OUT/$label/run-$round.trace"
        record_launch "$bundle_id" "$trace"
        stop_app "$DEVICECTL_ID"
        (
            export_table "$trace" life-cycle-period "$trace.xml" || exit
            /usr/bin/python3 -I "$TOOLS/launch_phases.py" "$label" "$round" < "$trace.xml" | tee -a "$OUT/launch_phases.csv"
        ) &
    done
done
wait
