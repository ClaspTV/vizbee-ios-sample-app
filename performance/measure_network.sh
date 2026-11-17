#!/bin/bash
#
#  measure_network.sh
#
#  For several builds in turn, round by round: captures all of the device's network traffic
#  through an rvictl interface while the app runs under the Instruments Time Profiler template
#  (which records hangs). Network bytes are summed for discovery (5-35 s after launch) and
#  idle (60-240 s) with net_summary.py; hangs are counted with hang_summary.py.
#  Needs: rvictl -s <device udid> (creates rvi0) and tcpdump access to /dev/bpf (access_bpf group).
#
#  Usage: ./measure_network.sh <device udid> <devicectl device id> <output dir> <rounds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
OUT=$3
ROUNDS=$4
shift 4
TOOLS=$(cd "$(dirname "$0")" && pwd)
RECORD_SECONDS=245
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
        pcap="$OUT/$label/run-$round.pcap"
        rm -rf "$trace" "$pcap" "$OUT/$label/run-$round.launch"
        tcpdump -i rvi0 -n -s 128 -w "$pcap" > /dev/null 2>&1 &
        capture=$!
        sleep 2
        # Time the launch from the moment xctrace says it is launching the app.
        xcrun xctrace record --template 'Time Profiler' --device "$DEVICE" --time-limit "${RECORD_SECONDS}s" \
            --output "$trace" --launch -- "$bundle_id" 2>&1 | while IFS= read -r line; do
                case "$line" in *Launching*|*"Starting recording"*) [ -f "$OUT/$label/run-$round.launch" ] || date +%s.%N > "$OUT/$label/run-$round.launch" ;; esac
            done
        kill "$capture"
        stop_app
        launch=$(cat "$OUT/$label/run-$round.launch")
        /usr/bin/python3 -I "$TOOLS/net_summary.py" "$label" discovery "$round" 5 35 "$launch" "$pcap" | tee -a "$OUT/network.csv"
        /usr/bin/python3 -I "$TOOLS/net_summary.py" "$label" idle "$round" 60 240 "$launch" "$pcap" | tee -a "$OUT/network.csv"
        for attempt in 1 2 3 4 5; do
            sleep 2
            xcrun xctrace export --input "$trace" --xpath '//table[@schema="potential-hangs"]' --output "$trace.hangs.xml" > /dev/null 2>&1 && break
        done
        /usr/bin/python3 -I "$TOOLS/hang_summary.py" "$label" "$round" < "$trace.hangs.xml" | tee -a "$OUT/hangs.csv"
    done
done
