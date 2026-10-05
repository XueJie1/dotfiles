# Sway X11 高清指针

基于 satellite 0.8.3 的 b5690b56d749526a05db9b9268d58bf8f700957f，
采用 Electronic-Mango/hidpi-cursor-scaling 的
11c53407fd5826ff13399a6acced972d7315738f 中指针 surface 修复，
另增加 Gtk/CursorThemeSize XSETTINGS，以逻辑大小乘 ceil(输出缩放) 加载图像。
上游分支：https://github.com/Electronic-Mango/xwayland-satellite/tree/hidpi-cursor-scaling
完整本地差异见 satellite.patch。安装二进制 ~/.local/libexec/xwayland-satellite-hidpi。

启动脚本自动选用该二进制，缺失时回退系统 satellite。设置变化在下次 Sway
登录生效，普通 reload 会重新同步主题与 Xresources，不会重启 X 服务器。
GTK/X11 自动读取 XSETTINGS 大小；Wayland GTK 保留逻辑大小。
Chrome 通过 sway-x11 启动。其它忽略 Xresources 或继承了逻辑 XCURSOR_SIZE 的
X11 程序可使用：sway-x11 程序名 参数。

用户已确认独立测试的箭头与输入指针明显更清晰且大小合适。
额外自动 GTK 验证在环境 XCURSOR_SIZE=24 时读取 XSETTINGS cursor size=48。
scaled_pointer_lock_position_hint 回归测试通过，Sway --validate 通过。

回退：从 ~/.config/sway/backups/xcursor-before-hidpi/ 恢复
sync-xcursor.py、start-xwayland-satellite.sh 到 ~/.config/sway/，
google-chrome-stable 到 ~/.local/bin/；下次登录使用系统 satellite。

整理后 sync-xcursor.py 是 ~/.local/bin/desktop-session 的链接，不再独立维护。
指针共享设置和应用入口统一在desktop-session，C连接适配在
~/.config/desktop-session/cursor-bridge/bridge.c；当前结构见笔记第15节。
