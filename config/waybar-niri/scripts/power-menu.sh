#!/usr/bin/env bash

set -euo pipefail

menu() {
    fuzzel --dmenu --no-sort --lines=6 --width=24 --prompt="$1"
}

selection="$(printf '%s\n' \
    '  锁屏' \
    '󰤄  挂起' \
    '󰍃  注销' \
    '󰜉  重启' \
    '  关机' | menu '电源选项：')" || exit 0

case "$selection" in
    *锁屏)
        exec hyprlock
        ;;
    *挂起)
        systemctl suspend
        ;;
    *注销)
        confirm="$(printf '%s\n' '取消' '确认注销' | menu '注销当前会话？')" || exit 0
        [ "$confirm" = '确认注销' ] && niri msg action quit --skip-confirmation
        ;;
    *重启)
        confirm="$(printf '%s\n' '取消' '确认重启' | menu '重启电脑？')" || exit 0
        [ "$confirm" = '确认重启' ] && systemctl reboot
        ;;
    *关机)
        confirm="$(printf '%s\n' '取消' '确认关机' | menu '关闭电脑？')" || exit 0
        [ "$confirm" = '确认关机' ] && systemctl poweroff
        ;;
esac
