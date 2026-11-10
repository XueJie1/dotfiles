#!/bin/sh
# Starts magpie for whichever Sway session is logging in.
#
# The shared config only calls this script; the per-session difference lives in
# the session launchers, which export MAGPIE_WEBKIT_COMPAT:
#   1  (sway-intel)  pass WEBKIT_DISABLE_* so WebKit skips the DMABUF renderer
#   0  (sway-nvidia) pass nothing and let WebKit pick its own path
#
# WebKitGTK checks whether these variables exist, not what they hold, so "0"
# would still mean "disabled". They are unset rather than set to 0.
set -eu
mkdir -p "$HOME/.local/state/sway"
log="$HOME/.local/state/sway/magpie.log"

# exec_always re-runs on every reload; do not stack a second copy.
# Match on the argv[0] basename only, so a shell quoting the path does not count.
for pid in $(pgrep -f 'magpie/magpie-linux-amd64' 2>/dev/null); do
    [ "$(basename "$(readlink -f "/proc/$pid/exe" 2>/dev/null)" 2>/dev/null)" = magpie-linux-amd64 ] \
        && exit 0
done

magpie="$HOME/workspace/magpie/magpie-linux-amd64"
if [ ! -x "$magpie" ]; then
    echo "$(date -Is) magpie binary missing: $magpie" >&2
    exit 1
fi

case "${MAGPIE_WEBKIT_COMPAT:-0}" in
    1)
        unset WEBKIT_DISABLE_DMABUF_RENDERER WEBKIT_DISABLE_COMPOSITING_MODE
        export WEBKIT_DISABLE_DMABUF_RENDERER=1
        export WEBKIT_DISABLE_COMPOSITING_MODE=1
        ;;
    *)
        unset WEBKIT_DISABLE_DMABUF_RENDERER WEBKIT_DISABLE_COMPOSITING_MODE
        ;;
esac

exec "$magpie" >>"$log" 2>&1
