local wezterm = require "wezterm";

local config = wezterm.config_builder()

-- 設定の自動再読み込み。
-- https://wezterm.org/config/lua/config/automatically_reload_config.html
config.automatically_reload_config = true

config.use_ime = true

config.initial_cols = 160
config.initial_rows = 40
config.window_padding = {
  left = "0px",
  right = "0px",
  top = "0px",
  bottom = "0px",
}

config.font = wezterm.font("Moralerspace Krypton HWNF")
config.font_size = 12
config.adjust_window_size_when_changing_font_size = false
config.color_scheme = "terafox"

config.default_prog = { "pwsh" }

config.window_decorations = "RESIZE"

return config
