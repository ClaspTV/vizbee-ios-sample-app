#!/bin/bash
#
#  measure_memgraph.sh
#
#  For each build in MEMGRAPH_LABELS (default vizbee-sdk): runs CastSessionTests/testCastSessionsMemory
#  with Xcode's performance test diagnostics, which save a memory graph of the app on the device
#  after the first cast session and another after the last. memgraph_summary.py then compares the two.
#
#  Usage: ./measure_memgraph.sh <device udid> <output dir> <tv name> <cycles> <seconds per phase> <label>=<path/to/.xctestrun> ...
#
set -uo pipefail

DEVICE=$1
OUT=$2
TV=$3
CYCLES=$4
SECONDS_PER_PHASE=$5
shift 5
TOOLS=$(cd "$(dirname "$0")" && pwd)
MEMGRAPH_LABELS=${MEMGRAPH_LABELS:-vizbee-sdk}
mkdir -p "$OUT"

for build in "$@"; do
    label=${build%%=*}
    [[ " $MEMGRAPH_LABELS " == *" $label "* ]] || continue
    xctestrun=${build#*=}
    result="$OUT/$label.xcresult"
    rm -rf "$result" "$OUT/$label"
    TEST_RUNNER_PERF_TV="$TV" TEST_RUNNER_PERF_CYCLES="$CYCLES" TEST_RUNNER_PERF_BEFORE_SECONDS=60 \
        TEST_RUNNER_PERF_CASTING_SECONDS="$SECONDS_PER_PHASE" TEST_RUNNER_PERF_AFTER_SECONDS="$SECONDS_PER_PHASE" \
        xcodebuild test-without-building -xctestrun "$xctestrun" -destination "id=$DEVICE" \
        -only-testing:VizbeeDemoUITests/CastSessionTests/testCastSessionsMemory \
        -enablePerformanceTestsDiagnostics YES -resultBundlePath "$result" > "$OUT/$label.log" 2>&1 \
        || { echo "$label,FAILED: $(grep -m 1 -E 'error: ' "$OUT/$label.log" | sed 's/^.*error: //')"; continue; }
    mkdir -p "$OUT/$label/attachments"
    xcrun xcresulttool export attachments --path "$result" --output-path "$OUT/$label/attachments" > /dev/null 2>&1
    for archive in "$OUT/$label/attachments/"*.gz; do
        [ -e "$archive" ] && tar -xzf "$archive" -C "$OUT/$label"
    done
    before=$(find "$OUT/$label" -name 'pre_*.memgraph' | head -1)
    after=$(find "$OUT/$label" -name 'post_*.memgraph' | head -1)
    [ -n "$before" ] && [ -n "$after" ] || { echo "$label,FAILED: no memory graphs in $result"; continue; }
    rm -rf "$OUT/$label/attachments" "$result"
    /usr/bin/python3 -I "$TOOLS/memgraph_summary.py" "$before" "$after" | tee "$OUT/$label.txt"
done
