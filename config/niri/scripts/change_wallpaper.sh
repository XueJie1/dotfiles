#!/usr/bin/env bash

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 /path/to/wallpaper.jpg"
    exit 1
fi

WALLPAPER="$1"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/awww"

if [ ! -f "$WALLPAPER" ]; then
    echo "Wallpaper does not exist: $WALLPAPER" >&2
    exit 1
fi

mkdir -p "$CACHE_DIR"

# Ensure daemon is available. If it is running but stuck, restart it.
if ! pgrep -x "awww-daemon" > /dev/null; then
    nohup awww-daemon > /tmp/awww-daemon.log 2>&1 &
    sleep 1
fi

# 1. 设置壁纸
awww img "$WALLPAPER" --transition-type center

# 2. 触发 Matugen 更新所有配置
# 修复 A: 提前创建 Matugen 缓存文件夹，解决 [ERROR] failed to store cache
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/matugen"

# 修复 B: 添加 --source-color-index 0 参数跳过交互式提示，强制选择第一个主色调
if ! matugen image "$WALLPAPER" -m dark --source-color-index 0; then
    echo "matugen failed, keeping wallpaper change" >&2
fi

# 3. 修正 Niri 重载命令
niri msg action load-config-file

fcitx5-remote -r > /dev/null 2>&1 || (pkill fcitx5 && fcitx5 -d &)

echo "Wallpaper and input method theme updated"

# 4. 优雅刷新 Waybar
if pgrep -x "waybar" > /dev/null; then
    pkill -USR2 waybar
else
    waybar -c ~/.config/waybar/niri/config.jsonc -s ~/.config/waybar/niri/style.css &
fi

echo "Wallpaper changed successfully"
