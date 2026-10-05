#!/bin/bash
# 自动同步脚本
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR" || exit 1

# 检查是否有变动
if [[ -n $(git status -s) ]]; then
    echo "[$(date)] Changes detected. Syncing to GitHub..."
    git add .
    git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    # 使用 SSH 方式推送
    git push origin main
    echo "[$(date)] Sync successful."
else
    echo "[$(date)] No changes detected."
fi
