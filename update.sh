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
    hypr
    waybar
    mako
    tofi
    alacritty
    fish
    fcitx5
    fontconfig
)

for dir in "${DIRS[@]}"; do
    src="$CONFIG_DIR/$dir"
    dst="$DEST/$dir"

    if [[ ! -d "$src" ]]; then
        echo "跳过 $dir（源目录 $src 不存在）"
        continue
    fi

    echo "同步 $dir ..."
    rm -rf "$dst"
    cp -r "$src" "$dst"
done

echo "✅ 配置文件已同步到 $DEST"
echo "运行 ./sync.sh 提交并推送到 GitHub"
