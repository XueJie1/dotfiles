-- Dual-monitor layout: HDMI display on the left, laptop panel on the right.
-- Coordinates use logical pixels because both displays use 125% scaling.
-- greetd "Hyprland (NVIDIA only)" sets HYPRLAND_NVIDIA_ONLY and opens only the
-- RTX 3050, so eDP-1 is not a real output. Disable it if the Intel card leaks in.
if os.getenv("HYPRLAND_NVIDIA_ONLY") == "1" then
	hl.monitor({
		output = "eDP-1",
		disabled = true,
	})
else
	hl.monitor({
		output = "eDP-1",
		mode = "1920x1080@165",
		position = "2048x144",
		scale = 1.25,
	})
end

hl.monitor({
	output = "HDMI-A-1",
	mode = "2560x1440@144",
	position = "0x0",
	scale = 1.25,
	cm = "srgb",
	-- EDID on this HKC panel advertises HDR it cannot actually do.
	-- -1 forces it off; 0 would trust the EDID.
	supports_hdr = -1,
	supports_wide_color = -1,
})

hl.config({
	input = {
		sensitivity = -0.625,
	},
	render = {
		-- Default 1 modesets the output to HDR whenever a fullscreen
		-- client (Chrome) submits HDR. This panel cannot display it.
		cm_auto_hdr = 0,
	},
})
