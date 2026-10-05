-- GPU selection is set before Hyprland starts by ~/.zprofile and
-- ~/.config/hypr/gpu-login.sh. Changing it requires a new login session.

-- Clash Party proxy (mixed port).
hl.env("http_proxy", "http://127.0.0.1:7890")
hl.env("https_proxy", "http://127.0.0.1:7890")
hl.env("all_proxy", "socks5://127.0.0.1:7890")

-- Fcitx5 input method. GTK uses the native Wayland frontend;
-- Qt applications such as Quickshell use the Fcitx Qt frontend.
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- Use Chinese for applications launched by Hyprland/Quickshell.
-- LANGUAGE gives applications a fallback list; LC_MESSAGES controls UI text.
hl.env("LANG", "zh_CN.UTF-8")
hl.env("LANGUAGE", "zh_CN:zh")
hl.env("LC_MESSAGES", "zh_CN.UTF-8")

-- Keep X11/XWayland cursors consistent with Hyprland.
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
-- Override the previous desktop's generated Electron backend at login.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
