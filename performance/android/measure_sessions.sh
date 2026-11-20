#!/bin/bash
#
#  measure_sessions.sh
#
#  Casts <sessions> times in a row from the Android sample app (vizbee-android-sample-app, benchmark build already
#  installed with its test APK) and, 10 s after each disconnect, reads the app's memory and object counts with
#  dumpsys meminfo (3 samples, 10 s apart): total PSS and the Views, ViewRootImpl, AppContexts and Activities
#  counts. A leaked screen shows up as object counts that keep growing from session to session.
#  After the last session it saves a heap dump (the benchmark build is debuggable).
#  Appends to sessions.csv in the output directory: label, session, PSS MB (median), Views, ViewRootImpl,
#  AppContexts, Activities.
#
#  Usage: ./measure_sessions.sh <label> <test class> <tv name> <sessions> <output dir>
#  The test class is tv.vizbee.demo.CastSessionsBenchmarkHelper (Vizbee) or
#  tv.vizbee.demo.ChromecastCastSessionsBenchmarkHelper (Google Cast).
#
set -uo pipefail

LABEL=$1
TEST_CLASS=$2
TV=$3
SESSIONS=$4
OUT=$5
PKG=tv.vizbee.demo
mkdir -p "$OUT"
LOG="$OUT/$LABEL-instrument.log"

sample() {
    for _ in 1 2 3; do
        adb shell dumpsys meminfo "$PKG" < /dev/null | tr -d '\r' | awk '
            /TOTAL/ && !t {t=$2}
            /Views:/ {v=$2; r=$4}
            /AppContexts:/ {c=$2; a=$4}
            END {print t, v, r, c, a}'
        sleep 10
    done | sort -n | sed -n 2p
}

adb shell am force-stop "$PKG" < /dev/null
adb shell "am instrument -w -r -e sessions $SESSIONS -e deviceName '$TV' -e class $TEST_CLASS#castSessions $PKG.test/androidx.test.runner.AndroidJUnitRunner" < /dev/null > "$LOG" 2>&1 &
test=$!
for session in $(seq 1 "$SESSIONS"); do
    while kill -0 "$test" 2> /dev/null && ! grep -q "INSTRUMENTATION_STATUS: session=$session\$" "$LOG"; do
        sleep 2
    done
    grep -q "INSTRUMENTATION_STATUS: session=$session\$" "$LOG" || { echo "$LABEL,FAILED at session $session, see $LOG"; break; }
    sleep 10
    read -r pss views roots contexts activities <<< "$(sample)"
    echo "$LABEL,$session,$(echo "scale=1; $pss / 1024" | bc),$views,$roots,$contexts,$activities" | tee -a "$OUT/sessions.csv"
done
if grep -q "INSTRUMENTATION_STATUS: session=$SESSIONS\$" "$LOG"; then
    adb shell am dumpheap "$PKG" "/data/local/tmp/$LABEL.hprof" < /dev/null
    sleep 15
    adb pull "/data/local/tmp/$LABEL.hprof" "$OUT/" > /dev/null 2>&1 && adb shell rm "/data/local/tmp/$LABEL.hprof" < /dev/null
fi
wait "$test"
