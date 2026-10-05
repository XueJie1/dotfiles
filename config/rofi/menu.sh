#!/bin/sh
# Both desktop menus use the same theme-selection policy.
case "${0##*/}" in
    launcher.sh) mode=launcher ;;
    powermenu.sh) mode=powermenu ;;
    *) echo "Use launcher.sh or powermenu.sh" >&2; exit 2 ;;
esac
case "${XDG_CURRENT_DESKTOP:-}" in
    *sway*) theme="$HOME/.config/sway/rofi-$mode.rasi" ;;
    *) theme="$HOME/.config/rofi/${mode}_theme.rasi" ;;
esac
if [ "$mode" = launcher ]; then
    case "${XDG_CURRENT_DESKTOP:-}" in
        *sway*)
            # This build supports Wayland text-input-v3 for fcitx5.
            exec "$HOME/.config/sway/rofi-native-ime/bin/rofi" \
                -no-click-to-exit -kb-row-select 'Alt+Return' \
                -show drun -modi drun -theme "$theme"
            ;;
    esac
    exec rofi -no-lazy-grab -show drun -modi drun -theme "$theme"
fi
exec rofi -show p -modi "p:$HOME/.config/rofi/off.sh" -theme "$theme"
