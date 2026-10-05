-- Dual-monitor layout: HDMI display on the left, laptop panel on the right.
-- Coordinates use logical pixels because both displays use 125% scaling.
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@165",
	position = "2048x144",
	scale = 1.25,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "2560x1440@144",
	position = "0x0",
	scale = 1.25,
})

hl.config({
	input = {
		sensitivity = -0.3,
	},
})
