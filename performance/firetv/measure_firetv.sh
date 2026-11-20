#!/bin/bash
#
#  measure_firetv.sh
#
#  Measures the Fire TV demo app (ClaspTV/vizbee-ftv-atv-demo-app, branches performance/no-sdk and
#  performance/vizbee-sdk) over ADB. Each build is installed once and the TV rebooted, then each round
#  restarts the app and measures:
#    idle       app on its home screen, no phone connected
#    connected  phone connected through Vizbee, app on its home screen (Vizbee builds only)
#    casting    video playing: cast from the iPhone for Vizbee builds, started on the TV for builds without the SDK
#  In each scenario it reads the app's CPU time, its main thread's CPU time and its threads from /proc over
#  WINDOW seconds, then its memory with dumpsys meminfo (3 samples, 10 s apart). dumpsys makes the app report
#  its heap, which costs CPU, so it never runs inside the CPU window. A window counts only if the app is in
#  the foreground at its start and end.
#  With SESSIONS > 0 it then casts SESSIONS times in a row (30 s of playback each) and reads the memory
#  10 to 40 s after each disconnect.
#  Appends to firetv.csv and sessions.csv in the output directory (see firetv_summary.py).
#
#  Usage: ./measure_firetv.sh <tv adb serial> <iphone udid> <iphone .xctestrun> <tv name> <output dir> <rounds> <label>=<path/to/app.apk> ...
#  Settings: WINDOW (default 120 s), SESSIONS (default 0), PACKAGE (default tv.vizbee.sccrendemo.firetv),
#  NO_SDK_LABELS (default no-sdk): builds without the SDK, which start the video on the TV instead of casting
#
set -uo pipefail

TV=$1
IPHONE=$2
XCTESTRUN=$3
TV_NAME=$4
OUT=$5
ROUNDS=$6
shift 6
HERE=$(cd "$(dirname "$0")" && pwd)
WINDOW=${WINDOW:-120}
SESSIONS=${SESSIONS:-0}
PACKAGE=${PACKAGE:-tv.vizbee.sccrendemo.firetv}
NO_SDK_LABELS=${NO_SDK_LABELS:-no-sdk}
MAIN=tv.vizbee.screendemo.ui.home.MainActivity
mkdir -p "$OUT"

tv() {
    adb -s "$TV" shell "$@" | tr -d '\r'
}

app_pid() {
    tv pidof "$PACKAGE"
}

in_front() {
    [[ "$(tv "dumpsys activity activities 2> /dev/null | grep -m 1 ResumedActivity")" == *"$1"* ]]
}

# With several profiles, Fire OS shows "Who's watching?" after a reboot or a wake: keep the focused (last used)
# profile. Right after boot the first press can be ignored, so press until it is gone.
dismiss_profile_picker() {
    for _ in 1 2 3 4 5 6; do
        in_front profilepicker || return 0
        tv input keyevent KEYCODE_DPAD_CENTER
        sleep 8
    done
    return 1
}

# Prints: uptime in s, app CPU ticks, main thread CPU ticks, threads
proc_sample() {
    tv "p=$1; cut -d' ' -f1 /proc/uptime; cut -d' ' -f14,15 /proc/\$p/stat; cut -d' ' -f14,15 /proc/\$p/task/\$p/stat; grep Threads /proc/\$p/status" \
        | awk 'NR==1{t=$1} NR==2{a=$1+$2} NR==3{m=$1+$2} NR==4{n=$2} END{print t, a, m, n}'
}

# Prints one line per sample: TOTAL PSS and TOTAL SWAP PSS in KB
memory_samples() {
    for _ in 1 2 3; do
        tv dumpsys meminfo -s "$1" | awk '/TOTAL PSS:/{for(i=1;i<=NF;i++){if($i=="PSS:"&&$(i-1)=="TOTAL")p=$(i+1); if($i=="PSS:"&&$(i-1)=="SWAP")s=$(i+1)}} END{print p, s}'
        sleep 10
    done
}

# Measures the running app for WINDOW seconds and appends one line to firetv.csv
measure() {
    local label=$1 round=$2 scenario=$3 pid before after
    pid=$(app_pid)
    [ -n "$pid" ] || { echo "$label,$round,$scenario,FAILED: app not running"; return 1; }
    in_front "$PACKAGE" || { echo "$label,$round,$scenario,FAILED: app not in front"; return 1; }
    before=$(proc_sample "$pid")
    sleep "$WINDOW"
    after=$(proc_sample "$pid")
    [ "$(app_pid)" = "$pid" ] || { echo "$label,$round,$scenario,FAILED: app restarted"; return 1; }
    in_front "$PACKAGE" || { echo "$label,$round,$scenario,FAILED: app not in front"; return 1; }
    memory_samples "$pid" > "$OUT/memory.tmp"
    /usr/bin/python3 -I "$HERE/firetv_summary.py" sample "$label" "$round" "$scenario" "$before" "$after" < "$OUT/memory.tmp" | tee -a "$OUT/firetv.csv"
}

wait_for_mark() {
    local log=$1 mark=$2 test=$3
    while kill -0 "$test" 2> /dev/null && ! grep -q "PERF_MARK $mark" "$log"; do
        sleep 1
    done
    grep -q "PERF_MARK $mark" "$log"
}

install_and_reboot() {
    adb -s "$TV" install -r "$1" > /dev/null || return 1
    # Fire OS registers an app's DIAL name (whisperplay.xml) reliably only at boot
    adb -s "$TV" reboot
    sleep 30
    until [ "$(adb -s "$TV" shell getprop sys.boot_completed 2> /dev/null | tr -d '\r')" = 1 ]; do
        adb connect "$TV" > /dev/null 2>&1
        sleep 5
    done
    tv svc power stayon true
    tv input keyevent KEYCODE_WAKEUP
    # The profile picker can take a few minutes after boot to appear
    for _ in $(seq 1 36); do
        in_front profilepicker && break
        sleep 5
    done
    dismiss_profile_picker
    sleep 30
}

launch_home() {
    dismiss_profile_picker
    tv am force-stop "$PACKAGE"
    tv am start -W -n "$PACKAGE/$MAIN" > /dev/null
    sleep 60
    dismiss_profile_picker || true
    in_front "$PACKAGE" || tv am start -W -n "$PACKAGE/$MAIN" > /dev/null
}

cast_test() {
    local log=$1 cycles=$2 connected=$3 casting=$4 after=$5
    TEST_RUNNER_PERF_TV="$TV_NAME" TEST_RUNNER_PERF_CYCLES="$cycles" TEST_RUNNER_PERF_BEFORE_SECONDS=20 \
        TEST_RUNNER_PERF_CONNECTED_SECONDS="$connected" TEST_RUNNER_PERF_CASTING_SECONDS="$casting" TEST_RUNNER_PERF_AFTER_SECONDS="$after" \
        xcodebuild test-without-building -xctestrun "$XCTESTRUN" -destination "id=$IPHONE" \
        -only-testing:VizbeeDemoUITests/CastSessionTests/testCastSession > "$log" 2>&1
}

adb connect "$TV" > /dev/null 2>&1
SCREENSAVER=$(tv settings get secure screensaver_enabled)
STAY_ON=$(tv settings get global stay_on_while_plugged_in)
tv settings put secure screensaver_enabled 0
# Without remote input the TV sleeps after 5 minutes, which sends the app to the background
tv svc power stayon true

HOLD=$((WINDOW + 60))
for build in "$@"; do
    label=${build%%=*}
    apk=${build#*=}
    install_and_reboot "$apk" || { echo "$label,FAILED: install"; continue; }
    for round in $(seq 1 "$ROUNDS"); do
        launch_home
        measure "$label" "$round" idle
        if [[ " $NO_SDK_LABELS " != *" $label "* ]]; then
            log="$OUT/$label-$round.log"
            cast_test "$log" 1 "$((HOLD + 20))" "$((HOLD + 30))" 10 &
            test=$!
            wait_for_mark "$log" connected "$test" && sleep 20 && measure "$label" "$round" connected
            wait_for_mark "$log" playing "$test" && sleep 30 && measure "$label" "$round" casting
            wait "$test" || echo "$label,$round,FAILED: cast test, see $log"
        else
            tv am start -W -n "$PACKAGE/$MAIN" --es guid bigbuck > /dev/null
            sleep 30
            measure "$label" "$round" casting
        fi
    done
done

if [ "$SESSIONS" -gt 0 ]; then
    for build in "$@"; do
        label=${build%%=*}
        apk=${build#*=}
        [[ " $NO_SDK_LABELS " == *" $label "* ]] && continue
        install_and_reboot "$apk" || continue
        launch_home
        log="$OUT/$label-sessions.log"
        cast_test "$log" "$SESSIONS" 0 30 45 &
        test=$!
        for session in $(seq 1 "$SESSIONS"); do
            wait_for_mark "$log" "disconnected $session" "$test" || break
            sleep 10
            pid=$(app_pid)
            memory_samples "$pid" | /usr/bin/python3 -I "$HERE/firetv_summary.py" session "$label" "$session" | tee -a "$OUT/sessions.csv"
        done
        wait "$test" || echo "$label,FAILED: sessions test, see $log"
    done
fi

tv settings put secure screensaver_enabled "${SCREENSAVER:-1}"
tv settings put global stay_on_while_plugged_in "${STAY_ON:-0}"
