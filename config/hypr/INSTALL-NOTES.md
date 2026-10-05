# end-4/dots-hyprland installation notes

- Source repository: `~/.local/share/dots-hyprland`
- Installed revision: `42d0aae`
- Hyprland entry: `~/.config/hypr/hyprland.lua`
- Quickshell config: `~/.config/quickshell/ii`
- Python environment: `~/.local/state/quickshell/.venv`

The installation used the project's `--core` file set. Shared Niri-session
configuration such as `niri`, `waybar/niri`, `matugen`, `fuzzel`, terminal,
fontconfig, and desktop appearance settings was not copied from the project.

The system already provides `adw-gtk-theme`, so the source repository contains
a local dependency patch replacing `adw-gtk-theme-git` with the repository
package. Preserve or reapply that patch after pulling upstream changes.

The global setup step was intentionally skipped. It would change user groups,
enable system services, and modify GNOME/KDE appearance settings. As a result,
features requiring `ydotool` or direct I2C brightness access may need separate,
explicit setup later.

Matugen is isolated per desktop session. Niri keeps the default
`~/.config/matugen/config.toml`; Hyprland uses
`~/.config/hypr/matugen/config.toml` explicitly from Quickshell's wallpaper
script. Shared GTK, Qt/KDE, Fuzzel and terminal theming is disabled for the
Hyprland wallpaper workflow.

The previous broken `~/.config/hypr` symlink is preserved as
`~/.config/hypr.broken-link-backup-20260823`.
