#!/bin/bash
#
#  run.sh
#
#  Measures the performance impact of an SDK on a connected iOS device by comparing
#  Release builds of the sample app listed in variants.conf. See README.md.
#
#  Usage: performance/run.sh --device <udid> [--tv <name>] [--out <dir>] [--steps <step,step> | --steps mem-cpu-energy] [--from <step>]
#                            [--builds <label,label>] [--quick]
#
#  --steps mem-cpu-energy  memory, CPU and energy only: build,smoke,activity,energy,discovery-cycles,idle-soak,cast,leaks,memgraph,summary
#  --from <step>  resume: run the chosen steps from this one on, reusing the results already in --out
#  --builds       only these builds from variants.conf (the first one listed there stays the baseline),
#                 for example no-sdk,vizbee-sdk for a TV that only the Vizbee SDK can cast to (Fire TV)
#
#  Steps (default: all but launch-phases, in this order):
#    build       check out and build every variant (Release, app + launch test)
#    smoke       launch every build, check it stays up, sends discovery probes and a TV answers
#    launch      Xcode launch test (XCTApplicationLaunchMetric), round-robin
#    launch-phases  Instruments App Launch, round-robin, for the phase breakdown (not run by default; for optimisation)
#    activity    CPU, memory (app and mDNSResponder) and network for discovery and idle
#    energy      Instruments Power Profiler for discovery and idle: power impact and CPU instructions (iOS 26 or later)
#    discovery-cycles  memory growth over 10 active scans (app sent to the background and back), with Activity Monitor
#    idle-soak   memory growth per passive scan and CPU over 30 minutes on the home screen
#    hangs       Instruments Time Profiler hangs during launch and discovery
#    activity-hangs  activity with the Instruments Hangs instrument added (not run by default)
#    cast        CPU, memory, threads, ports and network before, while and after casting to --tv
#    leaks       memory growth over repeated cast sessions, and Instruments Leaks
#    memgraph    memory graphs after the first and last of repeated cast sessions: leaks, and which classes and regions grew
#    summary     summary.csv and summary.md from all the results
#
set -euo pipefail

PERF=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$PERF/.." && pwd)
TOOLS=$PERF/tools
DEVICE=""
OUT=""
STEPS=build,smoke,launch,activity,hangs,cast,leaks,memgraph,summary
FROM=""
BUILDS=""
TV=""
LAUNCH_ROUNDS=6
LAUNCH_PHASE_ROUNDS=10
ACTIVITY_ROUNDS=${ACTIVITY_ROUNDS:-5}
ACTIVITY_SECONDS=245
HANG_ROUNDS=3
HANG_SECONDS=60
CAST_ROUNDS=${CAST_ROUNDS:-3}
CAST_SECONDS=180
CYCLE_ROUNDS=1
CYCLES=10
CYCLE_SECONDS=30
SOAK_ROUNDS=${SOAK_ROUNDS:-1}
SOAK_MINUTES=${SOAK_MINUTES:-30}

while [ $# -gt 0 ]; do
    case "$1" in
        --device) DEVICE=$2; shift 2 ;;
        --tv) TV=$2; shift 2 ;;
        --out) OUT=$2; shift 2 ;;
        --steps) STEPS=$2; shift 2 ;;
        --from) FROM=$2; shift 2 ;;
        --builds) BUILDS=$2; shift 2 ;;
        --quick) LAUNCH_ROUNDS=1; LAUNCH_PHASE_ROUNDS=1; ACTIVITY_ROUNDS=1; ACTIVITY_SECONDS=80; HANG_ROUNDS=1; CAST_ROUNDS=1; CAST_SECONDS=90; CYCLE_ROUNDS=1; CYCLES=3; shift ;;
        *) echo "Unknown option $1"; exit 1 ;;
    esac
done
[ -n "$DEVICE" ] || { echo "Usage: performance/run.sh --device <udid> [--tv <name>] [--out <dir>] [--steps <steps>] [--quick]"; exit 1; }

[ "$STEPS" = mem-cpu-energy ] && STEPS=build,smoke,activity,energy,discovery-cycles,idle-soak,cast,leaks,memgraph,summary
[ -n "$FROM" ] && STEPS=$(echo "$STEPS" | tr ',' '\n' | sed -n "/^$FROM\$/,\$p" | paste -sd, -)
[ -n "$STEPS" ] || { echo "--from $FROM is not one of the chosen steps"; exit 1; }
log() { echo "[$(date +%H:%M:%S)] $*"; }
has_step() { [[ ",$STEPS," == *",$1,"* ]]; }
if [ -z "$TV" ] && { has_step cast || has_step leaks || has_step memgraph; }; then
    echo "The cast, leaks and memgraph steps need --tv <name>: part of the TV's name as the device list shows it"; exit 1
fi

# Device details, from the device's UDID.
DEVICE_JSON=$(mktemp)
xcrun devicectl list devices --json-output "$DEVICE_JSON" > /dev/null
read -r DEVICECTL_ID DEVICE_NAME < <(/usr/bin/python3 -I "$TOOLS/device_info.py" "$DEVICE" "$DEVICE_JSON" --short)
[ -n "$DEVICECTL_ID" ] || { echo "Device $DEVICE is not connected"; exit 1; }
OUT=${OUT:-$PERF/results/$(date +%Y-%m-%d)-$DEVICE_NAME}
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
/usr/bin/python3 -I "$TOOLS/device_info.py" "$DEVICE" "$DEVICE_JSON" > "$OUT/device.json"
rm -f "$DEVICE_JSON"
log "Device: $DEVICE_NAME ($DEVICE), results in $OUT"

# Variants: label, git ref and discovery check, from variants.conf.
LABELS=()
REFS=()
CHECKS=()
while read -r label ref check; do
    [ -z "$BUILDS" ] || [[ ",$BUILDS," == *",$label,"* ]] || continue
    LABELS+=("$label"); REFS+=("$ref"); CHECKS+=("$check")
done < <(grep -vE '^\s*(#|$)' "${VARIANTS:-$PERF/variants.conf}")
app_path() { echo "$OUT/build/$1/Build/Products/Release-iphoneos/VizbeeDemo.app"; }
xctestrun_path() { ls "$OUT/build/$1/Build/Products/"*.xctestrun | head -1; }
builds() { for label in "${LABELS[@]}"; do echo "$label=$("$1" "$label")"; done; }
log "Steps: $STEPS; builds: ${LABELS[*]}"
if ! has_step build; then
    for label in "${LABELS[@]}"; do
        [ -d "$(app_path "$label")" ] || { echo "No build for $label in $OUT/build: include the build step"; exit 1; }
    done
fi

# The device's network traffic is mirrored to the Mac through an rvictl interface.
# Entries left from an earlier connection stop capturing, so start a fresh one and check that packets arrive.
start_capture_interface() {
    [ -n "${RVI:-}" ] && return
    [ -r /dev/bpf0 ] || { echo "tcpdump needs read access to /dev/bpf* (the access_bpf group, installed with Wireshark's ChmodBPF)"; exit 1; }
    while [[ "$(rvictl -l)" == *"$DEVICE"* ]]; do rvictl -x "$DEVICE" > /dev/null 2>&1 || break; done
    RVI=$(rvictl -s "$DEVICE" 2>&1 | grep -oE 'interface rvi[0-9]+' | awk '{print $2}')
    [ -n "$RVI" ] || { echo "rvictl could not start a capture interface for $DEVICE"; exit 1; }
    packets=$(tcpdump -i "$RVI" -n -c 20 2> /dev/null & sleep 5; kill $! 2> /dev/null || true)
    [ -n "$packets" ] || { echo "No packets on $RVI: the device's network capture is not working. Reconnect the device and run again."; exit 1; }
}

# Stops the run when UI tests can't control the device (device locked, or UI Automation turned off).
ui_ready() {
    xcodebuild test-without-building -xctestrun "$(xctestrun_path "${LABELS[0]}")" -destination "id=$DEVICE" \
        -only-testing:VizbeeDemoUITests/VizbeeDemoUITests/testExample > "$OUT/ui-check.log" 2>&1 && return
    if grep -q "enabling automation mode" "$OUT/ui-check.log"; then
        log "UI tests can't control the device: unlock it, check Settings > Developer > Enable UI Automation, then resume with --from $1"
    else
        log "UI check failed, see $OUT/ui-check.log; resume with --from $1"
    fi
    exit 2
}

if has_step build; then
    git -C "$ROOT" fetch -q origin
    : > "$OUT/variants.csv"
    mkdir -p "$OUT/build"
    for i in "${!LABELS[@]}"; do
        label=${LABELS[$i]}
        source="$OUT/src/$label"
        log "Building $label from ${REFS[$i]}"
        git -C "$ROOT" worktree remove --force "$source" 2> /dev/null || true
        git -C "$ROOT" worktree add -q --detach "$source" "${REFS[$i]}"
        commit=$(git -C "$source" rev-parse HEAD)
        packages=$(/usr/bin/python3 -I "$TOOLS/package_versions.py" "$source")
        echo "$label,${REFS[$i]},$commit,$packages" >> "$OUT/variants.csv"
        xcodebuild build-for-testing -project "$source/VizbeeDemo.xcodeproj" -scheme VizbeeDemoLaunchTests \
            -configuration Release -destination "id=$DEVICE" -derivedDataPath "$OUT/build/$label" \
            -allowProvisioningUpdates > "$OUT/build/$label.log" 2>&1 \
            || { echo "Build failed for $label, see $OUT/build/$label.log"; exit 1; }
        git -C "$ROOT" worktree remove --force "$source"
    done
    rmdir "$OUT/src"
fi

if has_step smoke; then
    start_capture_interface
    for i in "${!LABELS[@]}"; do
        log "Smoke test: ${LABELS[$i]}"
        "$TOOLS/smoke_test.sh" "$DEVICECTL_ID" "$RVI" "$(app_path "${LABELS[$i]}")" "$OUT/smoke/${LABELS[$i]}" "${CHECKS[$i]}"
    done
fi

if has_step launch; then
    ui_ready launch
    log "Xcode launch test: $LAUNCH_ROUNDS rounds"
    "$TOOLS/xcode_launch_rounds.sh" "$DEVICE" "$OUT/launch" "$LAUNCH_ROUNDS" $(builds xctestrun_path)
fi

if has_step launch-phases; then
    log "Instruments App Launch: $LAUNCH_PHASE_ROUNDS rounds"
    "$TOOLS/measure_launch_phases.sh" "$DEVICE" "$DEVICECTL_ID" "$OUT/launch-phases" "$LAUNCH_PHASE_ROUNDS" $(builds app_path)
fi

if has_step activity; then
    start_capture_interface
    log "Activity and network: $ACTIVITY_ROUNDS rounds of $ACTIVITY_SECONDS s"
    "$TOOLS/measure_activity.sh" "$DEVICE" "$DEVICECTL_ID" "$RVI" "$OUT/activity" "$ACTIVITY_ROUNDS" "$ACTIVITY_SECONDS" $(builds app_path)
fi

if has_step activity-hangs; then
    start_capture_interface
    log "Activity and network with Hangs: $ACTIVITY_ROUNDS rounds of $ACTIVITY_SECONDS s"
    EXTRA_INSTRUMENT=Hangs "$TOOLS/measure_activity.sh" "$DEVICE" "$DEVICECTL_ID" "$RVI" "$OUT/activity-hangs" "$ACTIVITY_ROUNDS" "$ACTIVITY_SECONDS" $(builds app_path)
fi

if has_step energy; then
    if [ "$(/usr/bin/python3 -I -c 'import json, sys; print(int(json.load(open(sys.argv[1]))["os_version"].split(".")[0]))' "$OUT/device.json")" -ge 26 ]; then
        log "Energy: $ACTIVITY_ROUNDS rounds of $ACTIVITY_SECONDS s"
        "$TOOLS/measure_energy.sh" "$DEVICE" "$DEVICECTL_ID" "$OUT/energy" "$ACTIVITY_ROUNDS" "$ACTIVITY_SECONDS" $(builds app_path)
    else
        log "Energy skipped: Instruments Power Profiler needs iOS 26 or later on the device"
    fi
fi

if has_step discovery-cycles; then
    ui_ready discovery-cycles
    start_capture_interface
    log "Active scans: $CYCLES cycles per build"
    TEST=testDiscoveryCycles "$TOOLS/measure_cast.sh" "$DEVICE" "$RVI" "$OUT/discovery-cycles" 1 none "$CYCLES" 60 35 30 $(builds xctestrun_path)
fi

if has_step idle-soak; then
    log "Idle soak: $SOAK_ROUNDS rounds of $SOAK_MINUTES minutes"
    "$TOOLS/measure_idle_soak.sh" "$DEVICE" "$DEVICECTL_ID" "$OUT/idle-soak" "$SOAK_ROUNDS" "$SOAK_MINUTES" $(builds app_path)
fi

if has_step hangs; then
    log "Hangs: $HANG_ROUNDS rounds of $HANG_SECONDS s"
    "$TOOLS/measure_hangs.sh" "$DEVICE" "$DEVICECTL_ID" "$OUT/hangs" "$HANG_ROUNDS" "$HANG_SECONDS" $(builds app_path)
fi

if has_step cast; then
    ui_ready cast
    start_capture_interface
    log "Casting to $TV: $CAST_ROUNDS rounds"
    "$TOOLS/measure_cast.sh" "$DEVICE" "$RVI" "$OUT/cast" "$CAST_ROUNDS" "$TV" 1 60 "$CAST_SECONDS" "$CAST_SECONDS" $(builds xctestrun_path)
fi

if has_step leaks; then
    ui_ready leaks
    start_capture_interface
    log "Repeated cast sessions to $TV: $CYCLE_ROUNDS rounds of $CYCLES cycles"
    "$TOOLS/measure_cast.sh" "$DEVICE" "$RVI" "$OUT/cycles" "$CYCLE_ROUNDS" "$TV" "$CYCLES" 60 "$CYCLE_SECONDS" "$CYCLE_SECONDS" $(builds xctestrun_path)
    log "Leaks: $CYCLES cycles per build"
    "$TOOLS/measure_leaks.sh" "$DEVICE" "$DEVICECTL_ID" "$OUT/leaks" "$TV" "$CYCLES" "$CYCLE_SECONDS" $(builds xctestrun_path)
fi

if has_step memgraph; then
    ui_ready memgraph
    log "Memory graphs: $CYCLES cycles per build"
    "$TOOLS/measure_memgraph.sh" "$DEVICE" "$OUT/memgraph" "$TV" "$CYCLES" "$CYCLE_SECONDS" $(builds xctestrun_path)
fi

if has_step summary; then
    /usr/bin/python3 -I "$TOOLS/summarize.py" "$OUT" "${LABELS[@]}"
    log "Summary: $OUT/summary.md and $OUT/summary.csv"
fi
