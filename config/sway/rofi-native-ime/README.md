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

## 2026-11-10 patch: preedit + fcitx5 commit loop

Upstream ignored the text-input-v3 `preedit_string` event, so the pinyin being
composed never appeared in the entry. It also called
`zwp_text_input_v3_commit()` from inside the preedit callback; fcitx5 answers
every commit with a forced preedit update, so the two fed each other in an
endless loop and composition was reset on almost every key.

Changes in `source/wayland/display.c` and `include/wayland-internal.h`:

- Show the preedit after the committed text in the entry, without refiltering.
- On `commit_string`, drop the preedit and append the committed text normally.
- Do not send a commit from the preedit/commit callbacks.

The previous binary is kept as `bin/rofi.bak-2026-11-10`.

To rebuild: clone rofi at the commit above, `git submodule update --init
--recursive`, apply `wayland-preedit.patch`, then
`meson setup build -Dxcb=disabled -Dwayland=enabled && ninja -C build`.
