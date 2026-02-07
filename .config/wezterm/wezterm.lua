local wezterm = require("wezterm")
local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
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
config.font_size = 15.5
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.bold_brightens_ansi_colors = true
config.force_reverse_video_cursor = true
-- Kanagawa Wave color scheme
config.colors = {
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
		"#090618", "#c34043", "#76946a", "#c0a36e",
		"#7e9cd8", "#957fb8", "#6a9589", "#c8c093",
	},
	brights = {
		"#727169", "#e82424", "#98bb6c", "#e6c384",
		"#7fb4ca", "#938aa9", "#7aa89f", "#dcd7ba",
	},
	indexed = {
		[16] = "#ffa066",
		[17] = "#ff5d62",
	},
}
-- Window padding
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}
-- Window transparency and blur
config.window_background_opacity = 0.85
config.macos_window_background_blur = 60
config.text_background_opacity = 0.85
-- Performance
config.scrollback_lines = 10000
config.enable_scroll_bar = false
-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
-- Key bindings
config.keys = {
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

	-- =====================================================
	-- NuPhy V3 fix: Physical Ctrl sends CMD to macOS.
	-- Map CMD+key → Ctrl+key so terminal apps work naturally.
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

	-- Physical Ctrl+Shift combos (CMD+SHIFT → WezTerm actions)
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
