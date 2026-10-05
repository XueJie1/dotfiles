#!/usr/bin/env bash
set -euo pipefail

# Called by Hyprland so the service receives the current desktop environment.
: "${HYPRLAND_INSTANCE_SIGNATURE:?Run this from the Hyprland session}"
vars=()
for name in WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP \
    XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_RUNTIME_DIR PATH LANG LANGUAGE LC_MESSAGES \
    QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME QT_IM_MODULE XMODIFIERS SDL_IM_MODULE \
    XCURSOR_THEME XCURSOR_SIZE ILLOGICAL_IMPULSE_VIRTUAL_ENV \
    http_proxy https_proxy all_proxy no_proxy; do
    if [[ -v "$name" ]]; then vars+=("$name"); fi
done
systemctl --user import-environment "${vars[@]}"
systemctl --user reset-failed quickshell-ii.service 2>/dev/null || true
case "${1:-start}" in
    start) systemctl --user start quickshell-ii.service ;;
    restart) systemctl --user restart quickshell-ii.service ;;
    *) printf 'Usage: %s [start|restart]\n' "$0" >&2; exit 2 ;;
esac
