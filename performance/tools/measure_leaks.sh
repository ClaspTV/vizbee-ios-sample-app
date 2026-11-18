#!/bin/bash
#
#  measure_leaks.sh
#
#  For each build in LEAKS_LABELS (default vizbee-sdk): runs CastSessionTests for several cycles (connect, play, disconnect) and
#  attaches the Instruments Leaks template to the app once the test has launched it. The
#  recording stops halfway through the wait after the last disconnect, while the app is still
#  running, so the final heap check covers every session.
#
#  Usage: ./measure_leaks.sh <device udid> <devicectl device id> <output dir> <tv name> <cycles> <seconds per phase> <label>=<path/to/.xctestrun> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
OUT=$3
TV=$4
CYCLES=$5
SECONDS_PER_PHASE=$6
shift 6
TOOLS=$(cd "$(dirname "$0")" && pwd)
source "$TOOLS/device_app.sh"
LEAKS_LABELS=${LEAKS_LABELS:-vizbee-sdk}
mkdir -p "$OUT"
LIMIT=$((60 + CYCLES * (2 * SECONDS_PER_PHASE + 120) + 300))
SAVE_SECONDS=1200

for build in "$@"; do
    label=${build%%=*}
    [[ " $LEAKS_LABELS " == *" $label "* ]] || continue
    xctestrun=${build#*=}
    trace="$OUT/$label.trace"
    log="$OUT/$label.log"
    stop_app "$DEVICECTL_ID"
    TEST_RUNNER_PERF_TV="$TV" TEST_RUNNER_PERF_CYCLES="$CYCLES" TEST_RUNNER_PERF_BEFORE_SECONDS=60 \
        TEST_RUNNER_PERF_CASTING_SECONDS="$SECONDS_PER_PHASE" TEST_RUNNER_PERF_AFTER_SECONDS="$SECONDS_PER_PHASE" \
        xcodebuild test-without-building -xctestrun "$xctestrun" -destination "id=$DEVICE" \
        -only-testing:VizbeeDemoUITests/CastSessionTests/testCastSession > "$log" 2>&1 &
    test=$!
    pid=""
    for _ in $(seq 1 120); do
        grep -q 'PERF_MARK launched' "$log" && pid=$(app_pid "$DEVICECTL_ID")
        [ -n "$pid" ] && break
        sleep 1
    done
    if [ -z "$pid" ]; then
        wait "$test"
        echo "$label,FAILED: the app did not start"
        continue
    fi
    record_trace "$LIMIT" "$trace" --template Leaks --device "$DEVICE" --attach "$pid" &
    recorder=$!
    while kill -0 "$test" 2> /dev/null && ! grep -q "PERF_MARK disconnected $CYCLES " "$log"; do
        sleep 2
    done
    sleep $((SECONDS_PER_PHASE / 2))
    pkill -INT -f "xctrace record .*--output $trace"
    wait "$recorder"
    wait "$test"
    passed=$?
    if [ "$passed" -ne 0 ]; then
        echo "$label,FAILED: $(grep -m 1 -E 'error: |XCTAssert|failed' "$log" | sed 's/^.*error: //')"
    fi
    for table in "Leaks Leaks" "Allocations Statistics"; do
        read -r track detail <<< "$table"
        for _ in 1 2 3; do
            xcrun xctrace export --input "$trace" --output "$OUT/$label.$detail.xml" \
                --xpath "/trace-toc/run[@number=\"1\"]/tracks/track[@name=\"$track\"]/details/detail[@name=\"$detail\"]" > /dev/null 2>&1
            [ -s "$OUT/$label.$detail.xml" ] && break
        done
    done
    sessions=$(grep -c 'PERF_MARK end' "$log")
    /usr/bin/python3 -I "$TOOLS/leaks_summary.py" "$label" "$sessions" "$OUT/$label.Leaks.xml" "$OUT/$label.Statistics.xml" | tee -a "$OUT/leaks.csv"
done
