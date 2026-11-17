#!/bin/bash
#
#  measure_activity.sh
#
#  For several builds in turn, round by round: launches the app and leaves it on its home
#  screen while recording every process with the Instruments Activity Monitor template and
#  capturing all of the device's network traffic. Two windows are read from each run,
#  measured from the app's launch:
#    discovery   5-35 s   (Vizbee's active scan: a probe every 2 s for the first 30 s)
#    idle       60-240 s  (passive scan: a probe every 60 s), no casting
#  Writes CPU and memory of the app and of mDNSResponder (the system Bonjour service, which
#  does Bonjour discovery for apps) to activity.csv, and network bytes to network.csv.
#
#  Usage: ./measure_activity.sh <device udid> <devicectl device id> <capture interface> <output dir> <rounds> <seconds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
INTERFACE=$3
OUT=$4
ROUNDS=$5
SECONDS_PER_RUN=$6
shift 6
TOOLS=$(cd "$(dirname "$0")" && pwd)
IDLE_END=$((SECONDS_PER_RUN - 10 < 240 ? SECONDS_PER_RUN - 10 : 240))
source "$TOOLS/device_app.sh"
mkdir -p "$OUT"

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        app=${build#*=}
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
        mkdir -p "$OUT/$label"
        xcrun devicectl device install app --device "$DEVICECTL_ID" "$app" > /dev/null
        stop_app "$DEVICECTL_ID"
        trace="$OUT/$label/run-$round.trace"
        pcap="$OUT/$label/run-$round.pcap"
        rm -rf "$trace" "$pcap"
        tcpdump -i "$INTERFACE" -n -s 128 -w "$pcap" > /dev/null 2>&1 &
        capture=$!
        xcrun xctrace record --template 'Activity Monitor' --device "$DEVICE" --all-processes \
            --time-limit "${SECONDS_PER_RUN}s" --output "$trace" > /dev/null 2>&1 &
        recorder=$!
        sleep 5
        xcrun devicectl device process launch --device "$DEVICECTL_ID" "$bundle_id" > /dev/null
        launch=$(date +%s.%N)
        wait "$recorder"
        kill "$capture"
        stop_app "$DEVICECTL_ID"
        export_table "$trace" activity-monitor-process-live "$trace.xml" || continue
        for window in "discovery 5 35" "idle 60 $IDLE_END"; do
            read -r scenario from to <<< "$window"
            /usr/bin/python3 -I "$TOOLS/process_summary.py" "$label" "$scenario" "$round" "$from" "$to" VizbeeDemo mDNSResponder < "$trace.xml" | tee -a "$OUT/activity.csv"
            /usr/bin/python3 -I "$TOOLS/net_summary.py" "$label" "$scenario" "$round" "$from" "$to" "$launch" "$pcap" >> "$OUT/network.csv"
        done
    done
done
