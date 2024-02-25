-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = "AdventureTime"
-- config.color_scheme = "Vs Code Dark+ (Gogh)"
config.color_scheme = "Breeze (Gogh)"

config.font = wezterm.font("Agave Nerd Font")
config.font_size = 13
config.dpi = 109

local act = wezterm.action

config.keys = {
	{
		key = "Enter",
		mods = "ALT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "Enter",
		mods = "CTRL|ALT",
		action = act.ToggleFullScreen,
	},
}

-- and finally, return the configuration to wezterm
return config
