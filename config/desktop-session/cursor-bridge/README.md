# Sway X11 cursor bridge

The bridge changes cursor environment only after a successful connection to
this Sway session's DISPLAY. Native Wayland and other desktops retain their sizes.
It reads desktop-session/x11.env; there are no application-specific size rules.

Source: bridge.c. Built binaries: ~/.local/lib/desktop-cursor/lib/cursor-bridge.so
and lib32/cursor-bridge.so. The ELF loader expands the literal $LIB token.
Activation is managed by ~/.local/bin/desktop-session; sway-intel exports the
same preload at login. Never install this in /etc/ld.so.preload.

Build: gcc -shared -fPIC -O2 bridge.c -ldl; add -m32 for the 32-bit version.
Build to a temporary path and rename; do not overwrite an in-use library.
DESKTOP_CURSOR_DEBUG=1 enables stderr diagnostics.

Theme expansion is part of the same desktop-session script:
  ~/.local/bin/desktop-session --expand-theme fireflys-pixel-cursors

Sandbox/static clients, custom cursors, mixed X11/Wayland processes and clients
bypassing the intercepted APIs may need separate investigation.
See ~/workspace/markdown/Sway-分数缩放与高清指针笔记.md section 15.
