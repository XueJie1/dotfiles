-- Start session utilities once per Hyprland session.
hl.on("hyprland.start", function()
	hl.exec_cmd("$HOME/.local/bin/sync-desktop-x11 hyprland")
	hl.exec_cmd("pgrep -x fcitx5 >/dev/null || fcitx5 -d")
	hl.exec_cmd("/home/cao/workspace/magpie/magpie-linux-amd64")
end)
