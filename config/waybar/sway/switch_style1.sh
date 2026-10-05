#!/bin/bash
set -euo pipefail
"$HOME/.config/waybar/sway/launch_waybar.sh" 1
swaymsg gaps outer all set 0
swaymsg gaps inner all set 0
