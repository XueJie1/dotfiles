-- 环境变量：代理、输入法、中文界面、光标。
-- 由 hyprland/env.lua 之后加载，所以这里的值覆盖上游默认。

-- Clash Party 代理（mixed 端口）。
hl.env("http_proxy", "http://127.0.0.1:7890")
hl.env("https_proxy", "http://127.0.0.1:7890")
hl.env("all_proxy", "socks5://127.0.0.1:7890")

-- Fcitx5：GTK 用原生 Wayland 前端，Qt（Quickshell 等）用 Fcitx Qt 前端。
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- 应用界面用中文。
hl.env("LANG", "zh_CN.UTF-8")
hl.env("LANGUAGE", "zh_CN:zh")
hl.env("LC_MESSAGES", "zh_CN.UTF-8")

-- 光标主题与大小（和 sway 会话保持一致）。
hl.env("XCURSOR_THEME", "fireflys-pixel-cursors")
hl.env("XCURSOR_SIZE", "32")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
