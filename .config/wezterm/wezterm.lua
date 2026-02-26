local wezterm = require("wezterm")
local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

local target_triple = wezterm.target_triple or ""
local is_macos = target_triple:find("apple%-darwin") ~= nil
local is_windows = target_triple:find("windows") ~= nil

local function env_number(name, fallback)
	local raw = os.getenv(name)
	local parsed = raw and tonumber(raw) or nil
	if parsed == nil then
		return fallback
	end
	return parsed
end
-- Basic settings
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.check_for_updates = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.enable_tab_bar = false
-- Font configuration
local default_font_size = is_windows and 13 or 16
config.font_size = tonumber(os.getenv("WEZTERM_FONT_SIZE") or default_font_size)
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.bold_brightens_ansi_colors = true
config.force_reverse_video_cursor = true
if is_windows then
	-- Windows GPUs/drivers can show transient render artifacts with the default
	-- backend. OpenGL is generally more stable here.
	config.front_end = "OpenGL"
	-- Reverse video cursor occasionally leaves visual artifacts on Windows.
	config.force_reverse_video_cursor = false
end
local function resolve_theme_name()
	local value = (os.getenv("WEZTERM_THEME") or "dragon"):lower()
	local aliases = {
		wave = "wave",
		dragon = "dragon",
		["kanagawa-wave"] = "wave",
		["kanagawa-dragon"] = "dragon",
	}
	return aliases[value] or "dragon"
end

local themes = {
	wave = {
		foreground = "#dcd7ba",
		background = "#1f1f28",
		cursor_bg = "#c8c093",
		cursor_fg = "#c8c093",
		cursor_border = "#c8c093",
		selection_fg = "#c8c093",
		selection_bg = "#2d4f67",
		scrollbar_thumb = "#16161d",
		split = "#54546d",
		ansi = {
			"#090618",
			"#c34043",
			"#76946a",
			"#c0a36e",
			"#7e9cd8",
			"#957fb8",
			"#6a9589",
			"#c8c093",
		},
		brights = {
			"#727169",
			"#e82424",
			"#98bb6c",
			"#e6c384",
			"#7fb4ca",
			"#938aa9",
			"#7aa89f",
			"#dcd7ba",
		},
		indexed = {
			[16] = "#ffa066",
			[17] = "#ff5d62",
		},
	},
	dragon = {
		foreground = "#c5c9c5",
		background = "#181616",
		cursor_bg = "#c5c9c5",
		cursor_fg = "#181616",
		cursor_border = "#c5c9c5",
		selection_fg = "#c5c9c5",
		selection_bg = "#2d4f67",
		scrollbar_thumb = "#12120f",
		split = "#625e5a",
		ansi = {
			"#0d0c0c",
			"#c4746e",
			"#87a987",
			"#c4b28a",
			"#8ba4b0",
			"#a292a3",
			"#8ea4a2",
			"#c5c9c5",
		},
		brights = {
			"#727169",
			"#e46876",
			"#8a9a7b",
			"#c0a36e",
			"#7fb4ca",
			"#938aa9",
			"#7aa89f",
			"#c5c9c5",
		},
		indexed = {
			[16] = "#b6927b",
			[17] = "#b98d7b",
		},
	},
}

config.colors = themes[resolve_theme_name()] or themes.dragon
-- Window padding
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}
-- Window transparency and blur
local default_opacity = is_windows and 1.0 or 0.80
config.window_background_opacity = env_number("WEZTERM_WINDOW_OPACITY", default_opacity)
if is_macos then
	config.macos_window_background_blur = 60
end
config.text_background_opacity = env_number("WEZTERM_TEXT_OPACITY", default_opacity)
if is_windows then
	-- Disable transparency on Windows to avoid compositor repaint glitches.
	config.window_background_opacity = 1.0
	config.text_background_opacity = 1.0
end
-- Performance
config.scrollback_lines = 10000
config.enable_scroll_bar = false
-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
-- Key bindings
local keys = {
	{ key = "Enter", mods = "CTRL", action = wezterm.action({ SendString = "\x1b[13;5u" }) },
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b[13;2u" }) },
	-- Navigate splits (via physical Win+Shift)
	{ key = "h", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
	-- Split panes
	{ key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "_", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- Close pane
	{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
	-- Zoom pane
	{ key = "z", mods = "CTRL|SHIFT", action = wezterm.action.TogglePaneZoomState },
	{ key = "f", mods = "SHIFT|CTRL", action = wezterm.action.ToggleFullScreen },
}

if is_windows then
	-- Keep CapsLock->Escape only on Windows; macOS is handled by Karabiner.
	table.insert(keys, {
		key = "CapsLock",
		mods = "NONE",
		action = wezterm.action.SendKey({ key = "Escape" }),
	})
end

if is_macos then
	local mac_keys = {
		-- =====================================================
		-- NuPhy V3 fix: Physical Ctrl sends CMD to macOS.
		-- Map CMD+key -> Ctrl+key so terminal apps work naturally.
		-- =====================================================

		-- Tmux prefix: physical Ctrl+Space
		{ key = "Space", mods = "CMD", action = wezterm.action.SendKey({ key = "Space", mods = "CTRL" }) },

		-- Common terminal control characters
		{ key = "a", mods = "CMD", action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }) },
		{ key = "b", mods = "CMD", action = wezterm.action.SendKey({ key = "b", mods = "CTRL" }) },
		{ key = "c", mods = "CMD", action = wezterm.action.SendKey({ key = "c", mods = "CTRL" }) },
		{ key = "d", mods = "CMD", action = wezterm.action.SendKey({ key = "d", mods = "CTRL" }) },
		{ key = "e", mods = "CMD", action = wezterm.action.SendKey({ key = "e", mods = "CTRL" }) },
		{ key = "f", mods = "CMD", action = wezterm.action.SendKey({ key = "f", mods = "CTRL" }) },
		{ key = "g", mods = "CMD", action = wezterm.action.SendKey({ key = "g", mods = "CTRL" }) },
		{ key = "h", mods = "CMD", action = wezterm.action.SendKey({ key = "h", mods = "CTRL" }) },
		{ key = "j", mods = "CMD", action = wezterm.action.SendKey({ key = "j", mods = "CTRL" }) },
		{ key = "k", mods = "CMD", action = wezterm.action.SendKey({ key = "k", mods = "CTRL" }) },
		{ key = "l", mods = "CMD", action = wezterm.action.SendKey({ key = "l", mods = "CTRL" }) },
		{ key = "n", mods = "CMD", action = wezterm.action.SendKey({ key = "n", mods = "CTRL" }) },
		{ key = "o", mods = "CMD", action = wezterm.action.SendKey({ key = "o", mods = "CTRL" }) },
		{ key = "p", mods = "CMD", action = wezterm.action.SendKey({ key = "p", mods = "CTRL" }) },
		{ key = "r", mods = "CMD", action = wezterm.action.SendKey({ key = "r", mods = "CTRL" }) },
		{ key = "t", mods = "CMD", action = wezterm.action.SendKey({ key = "t", mods = "CTRL" }) },
		{ key = "u", mods = "CMD", action = wezterm.action.SendKey({ key = "u", mods = "CTRL" }) },
		{ key = "v", mods = "CMD", action = wezterm.action.SendKey({ key = "v", mods = "CTRL" }) },
		{ key = "w", mods = "CMD", action = wezterm.action.SendKey({ key = "w", mods = "CTRL" }) },
		{ key = "x", mods = "CMD", action = wezterm.action.SendKey({ key = "x", mods = "CTRL" }) },
		{ key = "z", mods = "CMD", action = wezterm.action.SendKey({ key = "z", mods = "CTRL" }) },
		{ key = "[", mods = "CMD", action = wezterm.action.SendKey({ key = "[", mods = "CTRL" }) },
		{ key = "]", mods = "CMD", action = wezterm.action.SendKey({ key = "]", mods = "CTRL" }) },
		{ key = "\\", mods = "CMD", action = wezterm.action.SendKey({ key = "\\", mods = "CTRL" }) },

		-- Physical Ctrl+Shift combos (CMD+SHIFT -> WezTerm actions)
		{ key = "f", mods = "CMD|SHIFT", action = wezterm.action.ToggleFullScreen },
		{ key = "h", mods = "CMD|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
		{ key = "l", mods = "CMD|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
		{ key = "k", mods = "CMD|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
		{ key = "j", mods = "CMD|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
		{ key = "|", mods = "CMD|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "_", mods = "CMD|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "w", mods = "CMD|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
		{ key = "z", mods = "CMD|SHIFT", action = wezterm.action.TogglePaneZoomState },
	}

	for _, key in ipairs(mac_keys) do
		table.insert(keys, key)
	end
end

config.keys = keys
-- Hyperlink rules
config.hyperlink_rules = {
	{ regex = "\\((\\w+://\\S+)\\)", format = "$1", highlight = 1 },
	{ regex = "\\[(\\w+://\\S+)\\]", format = "$1", highlight = 1 },
	{ regex = "\\{(\\w+://\\S+)\\}", format = "$1", highlight = 1 },
	{ regex = "<(\\w+://\\S+)>", format = "$1", highlight = 1 },
	{ regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0.9-]+)", format = "$1", highlight = 1 },
	{ regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b", format = "mailto:$0" },
}
-- Window size
config.initial_rows = 34
config.initial_cols = 135
return config
