# Dotfiles

2026-10-05 当前桌面配置：Sway、Niri、Hyprland、Waybar、Rofi、Quickshell、终端、主题和输入法。Sway Logout 使用 `swaymsg exit`。

- `config/` 对应 `~/.config/`。当前 Waybar 入口为 `waybar/sway/` 和 `waybar/niri/`。
- `local/bin/` 对应 `~/.local/bin/`，包含桌面会话及应用启动脚本。
- `home/` 是本次收集的 Shell 和 Xresources 快照，已移除密钥赋值，更新时需要手动检查。
- `snapshots/` 保留已有历史快照。

运行 `./update.sh` 收集当前桌面配置，再运行 `./sync.sh` 提交并上传 GitHub。恢复前请比较目标文件，并调整本机路径、显示器和 GPU 设置。壁纸、字体和指针主题需要另行安装。

缓存、会话数据、账户凭据及备份文件不收集。自编译 Rofi、高清 XWayland 指针补丁及构建说明在 `config/sway/`。
