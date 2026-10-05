# Sway Waybar 配置

- `config1` / `style1.css`：样式一。
- `config2` / `style2.css`：样式二，Sway 登录时的默认样式。
- `launch_waybar.sh [1|2]`：检测温度传感器并启动或重启对应的用户服务。
- `switch_style1.sh` / `switch_style2.sh`：切换样式和边距。
- `Cava.sh`：音频频谱，由 Waybar 服务管理子进程，退出时一起清理。
- `wallpaper_random.sh` / `live_wallpaper.sh`：Sway 壁纸脚本。

Sway 使用一次性的 `exec` 启动 `sway-waybar@2.service`。服务强制原生 Wayland，
不加载 X11 指针适配库；异常退出后 2 秒恢复，30 秒内最多尝试 5 次。
会话结束后，Sway IPC 检查失败会停止重试。

配色通过 `reload_style_on_change` 监视 `colors.css`，换壁纸不再发送 SIGUSR2。
交互模块设置 `cursor: false`，避免 GTK3 旧 HAND2/ARROW 指针路径；
Waybar 0.15.0 会对此打印 unknown cursor option，但仍通过配置存在性禁用默认指针切换。
桌面指针仍由 Sway 控制，点击、滚动功能不受影响。

日志：`journalctl --user -u sway-waybar@2.service -b`
状态：`systemctl --user status sway-waybar@2.service`
重启：`~/.config/waybar/sway/launch_waybar.sh 2`

2026-10-05 排障：16:47 core 在 GTK Wayland 指针图像读取处访问失效地址；
16:58 另一次退出为 Wayland Error 22。前者已定位，后者的确切触发条件仍未确认。
备份：`~/.config/sway/backups/waybar-stability-20261005-171835/`。
