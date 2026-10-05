#!/bin/bash
# 将 ~/.config 下的配置文件同步到 dotfiles 仓库
# 用法：cd ~/dotfiles && ./update.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
DEST="$DOTFILES_DIR/config"

if [[ ! -d "$DEST" ]]; then
    mkdir -p "$DEST"
fi

DIRS=(
    sway
    niri
    hypr
    quickshell
    waybar
    rofi
    mako
    dunst
    tofi
    fuzzel
    alacritty
    kitty
    fish
    fcitx5
    fontconfig
    matugen
    swaylock
    wlogout
    btop
    cava
    fastfetch
    yazi
    mpv
    nvim
    environment.d
    xdg-desktop-portal
)

for dir in "${DIRS[@]}"; do
    src="$CONFIG_DIR/$dir"
    dst="$DEST/$dir"

    if [[ ! -d "$src" ]]; then
        echo "跳过 $dir（源目录 $src 不存在）"
        continue
    fi

    echo "同步 $dir ..."
    # Replace legacy repository links, without following them into live config.
    if [[ -L "$dst" ]]; then
        unlink "$dst"
    fi
    mkdir -p "$dst"
    rsync -a --delete --delete-excluded \
        --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
        --exclude='*.log' --exclude='*.bak*' --exclude='*.old' \
        --exclude='backups' --exclude='backup' --exclude='archive' \
        --exclude='cache' --exclude='mpvpaper_thumbnails' \
        --exclude='fish_variables' --exclude='cached_layouts' \
        "$src/" "$dst/"
done

mkdir -p "$DEST/systemd/user" "$DEST/desktop-session/cursor-bridge" "$DOTFILES_DIR/local/bin"
for service in sway-waybar@.service niri-wallpaper.service quickshell-ii.service; do
    [[ ! -f "$CONFIG_DIR/systemd/user/$service" ]] || cp -p "$CONFIG_DIR/systemd/user/$service" "$DEST/systemd/user/"
done
rsync -a "$CONFIG_DIR/desktop-session/cursor-bridge/" "$DEST/desktop-session/cursor-bridge/"
for script in desktop-session sway-intel sway-nvidia sway-x11 sync-desktop-x11 sync-gtk-cursor google-chrome-stable; do
    [[ ! -e "$HOME/.local/bin/$script" ]] || cp -Pp "$HOME/.local/bin/$script" "$DOTFILES_DIR/local/bin/"
done

echo "✅ 配置文件已同步到 $DEST"
echo "运行 ./sync.sh 提交并推送到 GitHub"
