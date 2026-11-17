-- 三套会话由 ~/.local/bin/hypr-{intel,nvidia,both} 设置 HYPR_GPU。
local gpu = os.getenv("HYPR_GPU") or "nvidia"

local hdmi = {
	output = "HDMI-A-1",
	mode = "2560x1440@144",
	scale = 1.25,
	cm = "srgb",
	-- EDID 声称支持 HDR，但这块 HKC 面板实际不行。-1 强制关闭。
	supports_hdr = -1,
	supports_wide_color = -1,
}

local edp = {
	output = "eDP-1",
	mode = "1920x1080@165",
	scale = 1.25,
}

if gpu == "intel" then
	-- 只有核显：笔记本屏。
	hl.monitor({ output = "HDMI-A-1", disabled = true })
	edp.position = "0x0"
	hl.monitor(edp)
elseif gpu == "nvidia" then
	-- 只有独显：外接 HDMI。
	hl.monitor({ output = "eDP-1", disabled = true })
	hdmi.position = "0x0"
	hl.monitor(hdmi)
else
	-- 双卡双屏：HDMI 在左，笔记本屏在右（逻辑像素，2048 = 2560/1.25）。
	hdmi.position = "0x0"
	hl.monitor(hdmi)
	edp.position = "2048x144"
	hl.monitor(edp)
end

hl.config({
	input = {
		sensitivity = -0.625,
	},
	render = {
		-- 默认会在全屏客户端提交 HDR 时切 HDR，这块面板显示不了。
		cm_auto_hdr = 0,
	},
	misc = {
		-- 会话启动器优先用 start-hyprland；直接跑 Hyprland 时也别弹大红条。
		disable_watchdog_warning = true,
	},
})

if gpu == "nvidia" or gpu == "both" then
	-- 专有驱动的光标平面更新迟滞，改为在帧内绘制。
	hl.config({
		cursor = {
			no_hardware_cursors = true,
		},
	})
end
