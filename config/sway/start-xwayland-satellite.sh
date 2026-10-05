#!/bin/sh
set -eu
: "${DISPLAY:?Intel Sway launcher must set DISPLAY}"
mkdir -p "$HOME/.local/state/sway"
cursor_marker="$XDG_RUNTIME_DIR/sway-satellite-$WAYLAND_DISPLAY.cursor-hidpi"
satellite_binary="$HOME/.local/libexec/xwayland-satellite-hidpi"
if [ -x "$satellite_binary" ]; then
    printf '1\n' > "$cursor_marker"
else
    satellite_binary=/usr/bin/xwayland-satellite
    rm -f "$cursor_marker"
fi
# Update toolkit overrides before launching the independent X server.
"$HOME/.config/sway/sync-xcursor.py" --settings-only || true
"$satellite_binary" "$DISPLAY" >> "$HOME/.local/state/sway/satellite.log" 2>&1 &
satellite_pid=$!
display_file="$XDG_RUNTIME_DIR/sway-satellite-$WAYLAND_DISPLAY.display"
cleanup() {
    kill "$satellite_pid" 2>/dev/null || true
    if [ -f "$display_file" ] && [ "$(cat "$display_file")" = "$DISPLAY" ]; then
        rm -f "$display_file"
        rm -f "$cursor_marker"
    fi
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM
# Apply font DPI only once the independent X server is ready.
attempt=0
while [ "$attempt" -lt 50 ]; do
    if /usr/bin/xrdb -query >/dev/null 2>&1; then
        [ ! -f "$HOME/.Xresources" ] || /usr/bin/xrdb -merge "$HOME/.Xresources"
        printf '%s\n' "$DISPLAY" > "$display_file"
        "$HOME/.config/sway/sync-xcursor.py" --x11-only || true
        break
    fi
    kill -0 "$satellite_pid" 2>/dev/null || exit 1
    attempt=$((attempt + 1))
    sleep 0.1
done
if [ "$attempt" -ge 50 ]; then
    echo 'satellite did not become ready within 5 seconds' >&2
    exit 1
fi
wait "$satellite_pid"
