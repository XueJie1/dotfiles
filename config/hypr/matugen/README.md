# Hyprland Matugen configuration

This configuration is exclusively for the end-4 Hyprland/Quickshell session.
Quickshell invokes it explicitly with `--config`; the default
`~/.config/matugen/config.toml` remains owned by the Niri session.

Only session-local outputs are generated:

- Quickshell generated color and wallpaper state
- Hyprland Lua colors
- Hyprlock colors

GTK, Qt/KDE application themes, Fuzzel, terminals, Niri and Waybar are omitted
because those targets are shared across desktop sessions.
