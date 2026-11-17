#!/bin/bash
#
#  xcode_launch_rounds.sh
#
#  Runs Xcode's launch test (testLaunchPerformance, XCTApplicationLaunchMetric) for
#  several builds in turn, round by round, so drift on the device affects every build
#  the same way. Writes each launch duration to xcode_launch.csv.
#
#  Usage: ./xcode_launch_rounds.sh <device udid> <output dir> <rounds> <label>=<path/to/.xctestrun> ...
#
set -uo pipefail

DEVICE=$1
OUT=$2
ROUNDS=$3
shift 3
mkdir -p "$OUT"

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        xctestrun=${build#*=}
        result="$OUT/$label-$round.xcresult"
        rm -rf "$result"
        xcodebuild test-without-building -xctestrun "$xctestrun" -destination "id=$DEVICE" \
            -only-testing:VizbeeDemoUITests/VizbeeDemoUITests/testLaunchPerformance \
            -resultBundlePath "$result" > "$OUT/$label-$round.log" 2>&1
        values=$(grep -oE 'Duration \(AppLaunch\), s\] average: [0-9.]+, relative standard deviation: [0-9.]+%, values: \[[^]]+\]' "$OUT/$label-$round.log" | sed -E 's/.*values: \[([^]]+)\]/\1/')
        if [ -z "$values" ]; then
            echo "$label,$round,FAILED" | tee -a "$OUT/xcode_launch.csv"
            continue
        fi
        iteration=0
        for value in ${values//,/ }; do
            iteration=$((iteration + 1))
            echo "$label,$round,$iteration,$value" >> "$OUT/xcode_launch.csv"
        done
        echo "$label round $round: $values"
    done
done
