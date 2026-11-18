#!/bin/bash
#
#  measure_activity.sh
#
#  For several builds in turn, round by round: launches the app and leaves it on its home
#  screen while recording every process with the Instruments Activity Monitor template and
#  capturing all of the device's network traffic. Two windows are read from each run,
#  measured from the app's launch:
#    discovery   5-35 s   (Vizbee's active scan: a probe every 2 s for the first 30 s)
#    idle       60-240 s  (passive scan: a probe every 60 s), no casting
#  Writes CPU and memory of the app and of mDNSResponder (the system Bonjour service, which
#  does Bonjour discovery for apps) to activity.csv, and network bytes to network.csv.
#  Runs where the app sent discovery probes (more than the few iOS sends itself) but no TV answered are listed in no_answer.csv.
#
#  Builds in ODD_ROUNDS_ONLY (default no-sdk google-cast-sdk) are measured in odd rounds only.
#
#  Usage: ./measure_activity.sh <device udid> <devicectl device id> <capture interface> <output dir> <rounds> <seconds> <label>=<path/to/VizbeeDemo.app> ...
#
set -uo pipefail

DEVICE=$1
DEVICECTL_ID=$2
INTERFACE=$3
OUT=$4
ROUNDS=$5
SECONDS_PER_RUN=$6
shift 6
TOOLS=$(cd "$(dirname "$0")" && pwd)
IDLE_END=$((SECONDS_PER_RUN - 10 < 240 ? SECONDS_PER_RUN - 10 : 240))
source "$TOOLS/device_app.sh"
ODD_ROUNDS_ONLY=${ODD_ROUNDS_ONLY-no-sdk google-cast-sdk}
mkdir -p "$OUT"

for round in $(seq 1 "$ROUNDS"); do
    for build in "$@"; do
        label=${build%%=*}
        [[ " $ODD_ROUNDS_ONLY " == *" $label "* ]] && [ $((round % 2)) -eq 0 ] && continue
        app=${build#*=}
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
        mkdir -p "$OUT/$label"
        xcrun devicectl device install app --device "$DEVICECTL_ID" "$app" > /dev/null
        stop_app "$DEVICECTL_ID"
        trace="$OUT/$label/run-$round.trace"
        pcap="$OUT/$label/run-$round.pcap"
        rm -f "$pcap"
        tcpdump -i "$INTERFACE" -n -s 1024 -w "$pcap" > /dev/null 2>&1 &
        capture=$!
        record_trace "$SECONDS_PER_RUN" "$trace" --template 'Activity Monitor' --device "$DEVICE" --all-processes &
        recorder=$!
        sleep 5
        xcrun devicectl device process launch --device "$DEVICECTL_ID" "$bundle_id" > /dev/null
        launch=$(date +%s.%N)
        wait "$recorder"
        recorded=$?
        kill "$capture"
        stop_app "$DEVICECTL_ID"
        [ "$recorded" -eq 0 ] || continue
        (
            "$TOOLS/discovery_check.sh" "$pcap" any > "${pcap%.pcap}.discovery.txt"
            if [ "$(awk '/^Probes:/ {print $2}' "${pcap%.pcap}.discovery.txt")" -gt 10 ] && ! grep -qE '^(SSDP|Cast) ' "${pcap%.pcap}.discovery.txt"; then
                echo "Warning: $label run $round sent discovery probes but no TV answered" >&2
                echo "$label,$round" >> "$OUT/no_answer.csv"
            fi
            export_table "$trace" activity-monitor-process-live "$trace.xml" || exit
            for window in "discovery 5 35" "idle 60 $IDLE_END"; do
                read -r scenario from to <<< "$window"
                /usr/bin/python3 -I "$TOOLS/process_summary.py" "$label" "$scenario" "$round" "$from" "$to" VizbeeDemo mDNSResponder < "$trace.xml" | tee -a "$OUT/activity.csv"
                /usr/bin/python3 -I "$TOOLS/net_summary.py" "$label" "$scenario" "$round" "$from" "$to" "$launch" "$pcap" >> "$OUT/network.csv"
            done
        ) &
    done
done
wait
