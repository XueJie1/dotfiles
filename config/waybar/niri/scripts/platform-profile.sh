#!/usr/bin/env bash

set -euo pipefail

profile_file=/sys/firmware/acpi/platform_profile
choices_file=/sys/firmware/acpi/platform_profile_choices

read_current() {
    [ -r "$profile_file" ] && tr -d '\n' < "$profile_file" || printf 'unavailable'
}

read_choices() {
    [ -r "$choices_file" ] && cat "$choices_file" || printf 'low-power quiet balanced balanced-performance performance'
}

show_status() {
    local current label icon tooltip
    current="$(read_current)"
    case "$current" in
        low-power)            icon='󰌪'; label='省电' ;;
        quiet)                icon='󰾆'; label='安静' ;;
        balanced)             icon='󰾅'; label='平衡' ;;
        balanced-performance) icon='󰓅'; label='平衡性能' ;;
        performance)          icon='󰓅'; label='性能' ;;
        *)                    icon='󰀦'; label='不可用' ;;
    esac
    printf -v tooltip '当前能效模式：%s (%s)\n点击切换' "$label" "$current"
    jq -cn --arg text "$icon $label" --arg tooltip "$tooltip" --arg class "$current" \
        '{text: $text, tooltip: $tooltip, class: $class}'
}

set_profile() {
    local requested="$1" supported
    supported=" $(read_choices) "
    case "$supported" in
        *" $requested "*) ;;
        *) notify-send '能效模式' "设备不支持：$requested"; return 1 ;;
    esac

    if [ -w "$profile_file" ]; then
        printf '%s\n' "$requested" > "$profile_file"
    elif command -v pkexec >/dev/null 2>&1 && printf '%s\n' "$requested" | pkexec tee "$profile_file" >/dev/null; then
        :
    else
        # Polkit 不可用时，打开可见终端执行用户指定的 sudo tee 方式。
        kitty --hold sh -c 'printf "%s\n" "$1" | sudo tee /sys/firmware/acpi/platform_profile >/dev/null' sh "$requested"
    fi

    notify-send '能效模式' "已切换为：$requested"
}

show_menu() {
    local current choices selection
    current="$(read_current)"
    choices="$(read_choices | tr ' ' '\n' | sed '/^$/d')"
    selection="$(printf '%s\n' "$choices" | fuzzel --dmenu --no-sort --lines=5 --width=30 \
        --select="$current" --prompt='能效模式：')" || exit 0
    [ -n "$selection" ] && [ "$selection" != "$current" ] && set_profile "$selection"
}

case "${1:---status}" in
    --status) show_status ;;
    --menu) show_menu ;;
    *) printf '用法：%s [--status|--menu]\n' "$0" >&2; exit 2 ;;
esac
