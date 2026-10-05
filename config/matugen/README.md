# Matugen 配置

`config.toml` 统一登记 Niri、Waybar、Fuzzel、Wlogout、Hyprlock、GTK、
Rofi、Btop、Fastfetch 和 Fcitx5 的模板输出。

Niri 与 Waybar 的模板分别放在各自目录中，便于和使用方一起维护；
`templates/` 保存其余应用的共享模板。更换壁纸时，
`../niri/scripts/change_wallpaper.sh` 会运行 Matugen 并刷新相关组件。
