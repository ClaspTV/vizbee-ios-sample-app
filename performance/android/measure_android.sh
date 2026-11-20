#!/bin/bash
#
#  measure_android.sh
#
#  Measures the Android sample app (vizbee-android-sample-app, benchmark build) over ADB, for phones where the
#  docs/performance scripts can't run (no Perfetto before Android 9, older dumpsys meminfo format). For each build,
#  each round:
#    idle       app launched and left on its home screen, measured after 60 s
#    discovery  the instrumentation test opens the cast device list (the active scan), measured once it is shown
#               (only for builds given a test class)
#  In each scenario it reads the app's CPU time, its main thread's CPU time and its threads from /proc over WINDOW
#  seconds, then its memory with dumpsys meminfo (3 samples, 10 s apart, median of TOTAL PSS). dumpsys makes the
#  app report its heap, which costs CPU, so it never runs inside the CPU window. A window counts only if the app is
#  in the foreground at its start and end.
#  Appends to android.csv: label, round, scenario, CPU %, main-thread ms per min, threads, PSS MB.
#
#  Usage: ./measure_android.sh <output dir> <rounds> <label>=<app.apk>,<test.apk>[,<test class>] ...
#  Settings: WINDOW (default 60 s), ANDROID_SERIAL (the phone)
#
set -uo pipefail

OUT=$1
ROUNDS=$2
shift 2
WINDOW=${WINDOW:-60}
PKG=tv.vizbee.demo
mkdir -p "$OUT"

phone() {
    adb shell "$@" < /dev/null | tr -d '\r'
}

in_front() {
    [[ "$(phone "dumpsys activity activities 2> /dev/null | grep -m 1 mResumedActivity")" == *"$PKG/"* ]]
}

# Prints: uptime in s, app CPU ticks, main thread CPU ticks, threads
proc_sample() {
    phone "p=$1; cut -d' ' -f1 /proc/uptime; cut -d' ' -f14,15 /proc/\$p/stat; cut -d' ' -f14,15 /proc/\$p/task/\$p/stat; grep Threads /proc/\$p/status" \
        | awk 'NR==1{t=$1} NR==2{a=$1+$2} NR==3{m=$1+$2} NR==4{n=$2} END{print t, a, m, n}'
}

memory_mb() {
    for _ in 1 2 3; do
        phone dumpsys meminfo "$PKG" | awk '$1=="TOTAL" && $2 ~ /^[0-9]+$/ {print $2; exit}'
        sleep 10
    done | sort -n | sed -n 2p | awk '{printf "%.1f", $1/1024}'
}

measure() {
    local label=$1 round=$2 scenario=$3 pid before after
    pid=$(phone pidof "$PKG")
    [ -n "$pid" ] || { echo "$label,$round,$scenario,FAILED: app not running"; return 1; }
    in_front || { echo "$label,$round,$scenario,FAILED: app not in front"; return 1; }
    before=$(proc_sample "$pid")
    sleep "$WINDOW"
    after=$(proc_sample "$pid")
    [ "$(phone pidof "$PKG")" = "$pid" ] || { echo "$label,$round,$scenario,FAILED: app restarted"; return 1; }
    in_front || { echo "$label,$round,$scenario,FAILED: app not in front"; return 1; }
    read -r t0 c0 m0 _ <<< "$before"
    read -r t1 c1 m1 threads <<< "$after"
    echo "$label,$round,$scenario,$(echo "$t0 $c0 $m0 $t1 $c1 $m1" | awk '{printf "%.2f,%.0f", ($5-$2)/($4-$1), 1000*($6-$3)/100/(($4-$1)/60)}'),$threads,$(memory_mb)" | tee -a "$OUT/android.csv"
}

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        IFS=, read -r apk test_apk test_class <<< "${build#*=}"
        adb uninstall "$PKG" > /dev/null 2>&1
        adb uninstall "$PKG.test" > /dev/null 2>&1
        adb install "$apk" > /dev/null && adb install "$test_apk" > /dev/null || { echo "$label,$round,FAILED: install"; continue; }
        phone monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
        sleep 60
        measure "$label" "$round" idle
        [ -n "$test_class" ] || continue
        phone am force-stop "$PKG"
        log="$OUT/$label-$round-discovery.log"
        adb shell "am instrument -w -r -e scenario discovery -e actionWait 1000 -e settleTime 30000 -e measureDuration $(( (WINDOW + 60) * 1000 )) -e class $test_class#putInState $PKG.test/androidx.test.runner.AndroidJUnitRunner" < /dev/null > "$log" 2>&1 &
        test=$!
        while kill -0 "$test" 2> /dev/null && ! grep -q "status=ready" "$log"; do
            sleep 1
        done
        grep -q "status=ready" "$log" && measure "$label" "$round" discovery || echo "$label,$round,discovery,FAILED: see $log"
        wait "$test"
    done
done
