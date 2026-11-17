# Shared helpers for the measurement scripts: find and stop the sample app on the device.
# Usage: source device_app.sh; app_pid <devicectl device id>; stop_app <devicectl device id>

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
