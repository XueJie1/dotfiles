-- 每次 Hyprland 会话启动后运行一次。
hl.on("hyprland.start", function()
	-- 输入法
	hl.exec_cmd("pgrep -x fcitx5 >/dev/null || fcitx5 -d")
	-- 光标（覆盖 dots 默认的 Bibata 24）
	hl.exec_cmd("hyprctl setcursor fireflys-pixel-cursors 32")
	-- 截图/剪贴板之外的个人工具
	hl.exec_cmd("/home/cao/workspace/magpie/magpie-linux-amd64")
	hl.exec_cmd("stretchly")
end)
