#!/bin/sh
set -eu
mkdir -p "$HOME/Pictures/Screenshots"
file="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S-%N).png"
if [ "${1:-region}" = region ]; then
    region=$(slurp) || exit 0
    grim -g "$region" "$file"
else
    grim "$file"
fi
wl-copy --type image/png < "$file"
command -v notify-send >/dev/null && notify-send '截图已保存并复制' "$file"
