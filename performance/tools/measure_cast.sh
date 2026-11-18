#!/bin/bash
#
#  measure_cast.sh
#
#  For several builds in turn, round by round: runs CastSessionTests (connect to a TV, play a
#  video on it, disconnect, repeated for the given number of cycles) while recording every
#  process with the Instruments Activity Monitor template and capturing all of the device's
#  network traffic. The windows come from the marks the test prints (see cast_windows.py):
#  before connecting, while casting and after disconnecting, in each cycle.
#  Writes CPU, memory, threads and Mach ports of the app and of mDNSResponder to activity.csv,
#  and network bytes to network.csv.
#
#  Builds in ODD_ROUNDS_ONLY (default no-sdk google-cast-sdk) are measured in odd rounds only.
#
#  Usage: ./measure_cast.sh <device udid> <capture interface> <output dir> <rounds> <tv name> <cycles> <before s> <casting s> <after s> <label>=<path/to/.xctestrun> ...
#
set -uo pipefail

DEVICE=$1
INTERFACE=$2
OUT=$3
ROUNDS=$4
TV=$5
CYCLES=$6
BEFORE=$7
CASTING=$8
AFTER=$9
shift 9
TOOLS=$(cd "$(dirname "$0")" && pwd)
source "$TOOLS/device_app.sh"
ODD_ROUNDS_ONLY=${ODD_ROUNDS_ONLY-no-sdk google-cast-sdk}
mkdir -p "$OUT"
LIMIT=$((BEFORE + CYCLES * (CASTING + AFTER + 60) + 120))

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        [[ " $ODD_ROUNDS_ONLY " == *" $label "* ]] && [ $((round % 2)) -eq 0 ] && continue
        xctestrun=${build#*=}
        mkdir -p "$OUT/$label"
        trace="$OUT/$label/run-$round.trace"
        pcap="$OUT/$label/run-$round.pcap"
        log="$OUT/$label/run-$round.log"
        rm -f "$pcap"
        tcpdump -i "$INTERFACE" -n -s 1024 -w "$pcap" > /dev/null 2>&1 &
        capture=$!
        record_trace "$LIMIT" "$trace" --template 'Activity Monitor' --device "$DEVICE" --all-processes &
        recorder=$!
        sleep 5
        TEST_RUNNER_PERF_TV="$TV" TEST_RUNNER_PERF_CYCLES="$CYCLES" TEST_RUNNER_PERF_BEFORE_SECONDS="$BEFORE" \
            TEST_RUNNER_PERF_CASTING_SECONDS="$CASTING" TEST_RUNNER_PERF_AFTER_SECONDS="$AFTER" \
            xcodebuild test-without-building -xctestrun "$xctestrun" -destination "id=$DEVICE" \
            -only-testing:VizbeeDemoUITests/CastSessionTests/testCastSession > "$log" 2>&1
        passed=$?
        pkill -INT -f "xctrace record .*--output $trace"
        wait "$recorder"
        recorded=$?
        kill "$capture"
        if [ "$passed" -ne 0 ]; then
            echo "$label,$round,FAILED: $(grep -m 1 -E 'error: |XCTAssert|failed' "$log" | sed 's/^.*error: //')"
            continue
        fi
        [ "$recorded" -eq 0 ] || continue
        export_table "$trace" activity-monitor-process-live "$trace.xml" || continue
        windows=$(/usr/bin/python3 -I "$TOOLS/cast_windows.py" < "$log") || { echo "$label,$round,NO_MARKS"; continue; }
        launch=$(awk '$1 == "launch" {print $2}' <<< "$windows")
        while read -r window from to; do
            [ "$window" = launch ] && continue
            /usr/bin/python3 -I "$TOOLS/process_summary.py" "$label" "$window" "$round" "$from" "$to" VizbeeDemo mDNSResponder < "$trace.xml" | tee -a "$OUT/activity.csv"
            /usr/bin/python3 -I "$TOOLS/net_summary.py" "$label" "$window" "$round" "$from" "$to" "$launch" "$pcap" >> "$OUT/network.csv"
        done <<< "$windows"
    done
done
