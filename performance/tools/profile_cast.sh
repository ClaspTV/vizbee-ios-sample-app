#!/bin/bash
#
#  profile_cast.sh
#
#  For each build: runs one cast session (CastSessionTests) and, 30 s after the video starts playing on
#  the TV, records the app for <seconds> while capturing all of the device's network traffic.
#  TEMPLATE (default Time Profiler) picks the Instruments template. Writes <label>.trace, <label>.pcap and
#  <label>.xml: the time profile table, or for Power Profiler (iOS 26 or later) the app's power table,
#  summarised into energy.csv by energy_summary.py.
#
#  Usage: ./profile_cast.sh <device udid> <devicectl device id> <capture interface> <output dir> <tv name> <seconds> <label>=<path/to/.xctestrun> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
INTERFACE=$3
OUT=$4
TV=$5
SECONDS_TO_RECORD=$6
shift 6
TOOLS=$(cd "$(dirname "$0")" && pwd)
source "$TOOLS/device_app.sh"
TEMPLATE=${TEMPLATE:-Time Profiler}
mkdir -p "$OUT"

for build in "$@"; do
    label=${build%%=*}
    xctestrun=${build#*=}
    log="$OUT/$label.log"
    stop_app "$DEVICECTL_ID"
    TEST_RUNNER_PERF_TV="$TV" TEST_RUNNER_PERF_CYCLES=1 TEST_RUNNER_PERF_BEFORE_SECONDS=30 \
        TEST_RUNNER_PERF_CASTING_SECONDS=$((SECONDS_TO_RECORD + 60)) TEST_RUNNER_PERF_AFTER_SECONDS=10 \
        xcodebuild test-without-building -xctestrun "$xctestrun" -destination "id=$DEVICE" \
        -only-testing:VizbeeDemoUITests/CastSessionTests/testCastSession > "$log" 2>&1 &
    test=$!
    while kill -0 "$test" 2> /dev/null && ! grep -q 'PERF_MARK playing' "$log"; do
        sleep 2
    done
    pid=$(app_pid "$DEVICECTL_ID")
    if [ -z "$pid" ]; then
        wait "$test"
        echo "$label,FAILED: $(grep -m 1 -E 'error: ' "$log" | sed 's/^.*error: //')"
        continue
    fi
    sleep 30
    tcpdump -i "$INTERFACE" -n -s 1024 -w "$OUT/$label.pcap" > /dev/null 2>&1 &
    capture=$!
    record_trace "$SECONDS_TO_RECORD" "$OUT/$label.trace" --template "$TEMPLATE" --device "$DEVICE" --attach "$pid"
    kill "$capture" 2> /dev/null
    wait "$test"
    if [ "$TEMPLATE" = "Power Profiler" ]; then
        export_schema "$OUT/$label.trace" ProcessSubsystemPowerImpact "$OUT/$label.xml" \
            && /usr/bin/python3 -I "$TOOLS/energy_summary.py" "$label" 1 "$OUT/$label.xml" casting=0-"$SECONDS_TO_RECORD" | tee -a "$OUT/energy.csv"
    else
        for _ in 1 2 3; do
            (xcrun xctrace export --input "$OUT/$label.trace" --output "$OUT/$label.xml" \
                --xpath '/trace-toc/run[@number="1"]/data/table[@schema="time-profile"]' > /dev/null 2>&1) 2> /dev/null && break
            sleep 2
        done
    fi
    echo "$label,done"
done
