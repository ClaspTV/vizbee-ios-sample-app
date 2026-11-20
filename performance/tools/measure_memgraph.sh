#!/bin/bash
#
#  measure_memgraph.sh
#
#  For each build in MEMGRAPH_LABELS (default vizbee-sdk): saves two memory graphs of the app on the
#  device with Xcode's performance test diagnostics, for each scenario in MEMGRAPH_SCENARIOS
#  (default discovery idle cast), and compares them with memgraph_summary.py:
#    discovery  graphs after the first and the last of <cycles> active scans (app sent to the background and back)
#    idle       graphs 2 minutes and IDLE_MINUTES (default 30) minutes after launch (passive scans every 60 s)
#    cast       graphs after the first and after the last of <cycles> cast sessions to <tv name>
#  Appends one line per build and scenario to memgraph.csv: label, scenario, leaked objects before
#  and after, leaked bytes after, heap growth in bytes.
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
MEMGRAPH_SCENARIOS=${MEMGRAPH_SCENARIOS:-discovery idle cast}
mkdir -p "$OUT"

for build in "$@"; do
    label=${build%%=*}
    [[ " $MEMGRAPH_LABELS " == *" $label "* ]] || continue
    xctestrun=${build#*=}
    for scenario in $MEMGRAPH_SCENARIOS; do
        name="$label-$scenario"
        result="$OUT/$name.xcresult"
        rm -rf "$result" "$OUT/$name"
        case $scenario in
            discovery) test=testDiscoveryCyclesMemory; before=60; hold=0; casting=35; after=30 ;;
            idle) test=testIdleMemory; before=120; hold=$(( ${IDLE_MINUTES:-30} * 60 - 120 )); casting=0; after=0 ;;
            cast) test=testCastSessionsMemory; before=60; hold=0; casting=$SECONDS_PER_PHASE; after=$SECONDS_PER_PHASE ;;
        esac
        TEST_RUNNER_PERF_TV="$TV" TEST_RUNNER_PERF_CYCLES="$CYCLES" TEST_RUNNER_PERF_BEFORE_SECONDS=$before TEST_RUNNER_PERF_HOLD_SECONDS=$hold \
            TEST_RUNNER_PERF_CASTING_SECONDS=$casting TEST_RUNNER_PERF_AFTER_SECONDS=$after \
            xcodebuild test-without-building -xctestrun "$xctestrun" -destination "id=$DEVICE" \
            -only-testing:VizbeeDemoUITests/CastSessionTests/$test \
            -enablePerformanceTestsDiagnostics YES -resultBundlePath "$result" > "$OUT/$name.log" 2>&1 \
            || { echo "$name,FAILED: $(grep -m 1 -E 'error: ' "$OUT/$name.log" | sed 's/^.*error: //')"; continue; }
        mkdir -p "$OUT/$name/attachments"
        xcrun xcresulttool export attachments --path "$result" --output-path "$OUT/$name/attachments" > /dev/null 2>&1
        for archive in "$OUT/$name/attachments/"*.gz; do
            [ -e "$archive" ] && tar -xzf "$archive" -C "$OUT/$name"
        done
        before_graph=$(find "$OUT/$name" -name 'pre_*.memgraph' | head -1)
        after_graph=$(find "$OUT/$name" -name 'post_*.memgraph' | head -1)
        [ -n "$before_graph" ] && [ -n "$after_graph" ] || { echo "$name,FAILED: no memory graphs in $result"; continue; }
        rm -rf "$OUT/$name/attachments" "$result"
        /usr/bin/python3 -I "$TOOLS/memgraph_summary.py" "$before_graph" "$after_graph" > "$OUT/$name.txt"
        /usr/bin/python3 -I "$TOOLS/memgraph_summary.py" --csv "$label" "$scenario" "$before_graph" "$after_graph" | tee -a "$OUT/memgraph.csv"
    done
done
