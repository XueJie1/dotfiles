-- XWayland 下的 Fcitx5 候选框不使用 Hyprland 的圆角裁剪。
hl.window_rule({
	match = { class = "^(Fcitx5|fcitx5|Fcitx|fcitx)$" },
	rounding = 0,
})

-- Hermes Desktop 的弹出式桌宠是一个透明 Electron 窗口。它和主窗口共用
-- class/title，所以不能只用普通的 class/title window rule：用窗口标题和
-- 桌宠的尺寸范围筛选后打一个静态 tag，再对 tag 应用桌宠专用规则。
--
-- 桌宠默认约为 240x300，缩放后仍保持窄而高；主 Hermes 窗口的最小尺寸为
-- 400x620 且比例不同。范围留出缩放余量，同时避免命中主窗口。
local function is_hermes_pet(window)
	if window == nil or window.address == nil then
		return false
	end

	local size = window.size or {}
	-- Hyprland Lua exposes vectors as `{ x = ..., y = ... }` (the indexed
	-- fallback keeps this tolerant of older bindings).
	local width = tonumber(size.x or size[1])
	local height = tonumber(size.y or size[2])

	if width == nil or height == nil or width <= 0 or height <= 0 then
		return false
	end

	local hermes_class = window.class == "Hermes" or window.class == "hermes"
	local pet_shape = width >= 220 and width <= 700
		and height >= 280 and height <= 860
		and height / width >= 1.15 and height / width <= 1.40

	return hermes_class and window.title == "Hermes" and pet_shape
end

local function mark_hermes_pet(window)
	if not is_hermes_pet(window) then
		return
	end

	local selector = "address:" .. window.address

	-- The Electron overlay is already always-on-top, but making it explicitly
	-- floating and pinned keeps the behavior correct under Hyprland as well.
	hl.dispatch(hl.dsp.window.float({ action = "set", window = selector }))
	hl.dispatch(hl.dsp.window.pin({ action = "set", window = selector }))
	hl.dispatch(hl.dsp.window.tag({ tag = "+hermes-pet", window = selector }))
end

hl.window_rule({
	name = "hermes-pet-overlay",
	match = { tag = "hermes-pet" },
	border_size = 0,
	no_shadow = true,
	no_initial_focus = true,
	no_follow_mouse = true,
})

-- window.open fires after Hyprland has populated the final class/title/size.
hl.on("window.open", mark_hermes_pet)

-- Re-apply the tag when this file is reloaded while the pet is already open.
for _, window in ipairs(hl.get_windows()) do
	mark_hermes_pet(window)
end
