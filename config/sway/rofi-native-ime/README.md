# Sway rofi with native Wayland input method support

Built from https://github.com/davatorium/rofi (next), commit
`1ad1df6b72d4c8b0e40e8ced1249ef8a8a6bc0ad`, on 2026-10-05.

The system rofi 2.0.0 lacks Wayland text-input-v3 support. The Sway
launcher uses this binary for fcitx5 Chinese input and native display scaling.
Other desktop sessions continue to use the system rofi.

Build options: `-Dxcb=disabled -Dwayland=enabled`.
The launcher disables click-to-exit to avoid the extra layer surface affecting
input method focus, and moves row selection to Alt+Return to free Ctrl+Space.

Theme: `~/.config/sway/rofi-launcher.rasi`.
