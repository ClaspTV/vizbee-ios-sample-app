# Shared helpers for the measurement scripts: find and stop the sample app on the device.
# Usage: source device_app.sh; app_pid <devicectl device id>; stop_app <devicectl device id>;
#        record_trace <seconds> <output.trace> <xctrace record options>; export_schema <trace> <schema> <output.xml>

app_pid() {
    xcrun devicectl device info processes --device "$1" 2> /dev/null | awk '/VizbeeDemo.app\/VizbeeDemo/ {print $1}' | head -1
}

stop_app() {
    local pid
    pid=$(app_pid "$1")
    [ -n "$pid" ] && xcrun devicectl device process terminate --device "$1" --pid "$pid" > /dev/null 2>&1
    sleep 3
}

# xctrace export sometimes crashes right after a recording, so retry it.
export_table() {
    local trace=$1 schema=$2 output=$3 attempt
    for attempt in 1 2 3 4 5; do
        sleep 2
        xcrun xctrace export --input "$trace" --xpath "//table[@schema=\"$schema\"]" --output "$output" > /dev/null 2>&1 && return 0
    done
    echo "Could not export $schema from $trace" >&2
    return 1
}

# Exports one table by schema name; Power Profiler's tables only export when selected by position.
export_schema() {
    local trace=$1 schema=$2 output=$3 index
    for _ in 1 2 3; do
        (xcrun xctrace export --input "$trace" --toc > "$output.toc" 2> /dev/null) 2> /dev/null && [ -s "$output.toc" ] && break
        sleep 2
    done
    index=$(/usr/bin/python3 -I -c "
import sys, xml.etree.ElementTree as ET
tables = ET.parse(sys.argv[1]).getroot().find('run').find('data').findall('table')
print(next(i for i, t in enumerate(tables, 1) if t.get('schema') == sys.argv[2]))" "$output.toc" "$schema")
    rm -f "$output.toc"
    for _ in 1 2 3; do
        (xcrun xctrace export --input "$trace" --xpath "//trace-toc[1]/run[1]/data[1]/table[$index]" > "$output" 2> /dev/null) 2> /dev/null && [ -s "$output" ] && return 0
        sleep 2
    done
    return 1
}

# Runs xctrace record for the given time, and stops it if it is still running 2 minutes
# after that (a recording can hang when the connection to the device stalls).
record_trace() {
    local seconds=$1 output=$2 recorder watchdog
    shift 2
    rm -rf "$output" "$output.timed-out"
    xcrun xctrace record --time-limit "${seconds}s" --output "$output" "$@" > "$output.log" 2>&1 &
    recorder=$!
    ( sleep $((seconds + ${SAVE_SECONDS:-120})); touch "$output.timed-out"; pkill -P "$recorder"; kill "$recorder"; sleep 10; pkill -9 -P "$recorder"; kill -9 "$recorder" ) > /dev/null 2>&1 &
    watchdog=$!
    wait "$recorder"
    pkill -P "$watchdog" 2> /dev/null
    kill "$watchdog" 2> /dev/null
    wait "$watchdog" 2> /dev/null
    if [ -e "$output.timed-out" ]; then
        rm -f "$output.timed-out"
        echo "Recording did not finish within $((seconds + ${SAVE_SECONDS:-120})) s, stopped: $output" >&2
        return 1
    fi
}
