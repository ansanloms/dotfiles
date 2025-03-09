local wezterm = require("wezterm")
local config = {}

-- 画面サイズ。
config.initial_cols = 160
config.initial_rows = 40

-- フォント。
config.font = wezterm.font_with_fallback({
  { family = "Moralerspace Krypton HWNF", assume_emoji_presentation = false },
  { family = "Moralerspace Krypton HWNF", assume_emoji_presentation = true },
})
config.font_size = 10
config.adjust_window_size_when_changing_font_size = false

-- タイトルバーの設定。
config.window_decorations = "INTEGRATED_BUTTONS"

-- 外観。
--config.color_scheme = "Gotham (terminal.sexy)"
config.color_scheme = "terafox"

config.text_background_opacity = 0.25
config.enable_scroll_bar = true
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
  -- Gotham
  --ansi = {
  --  "#0a0f14",
  --  "#c33027",
  --  "#26a98b",
  --  "#edb54b",
  --  "#195465",
  --  "#4e5165",
  --  "#33859d",
  --  "#98d1ce",
  --},
  --brights = {
  --  "#314051",
  --  "#d26939",
  --  "#081f2d",
  --  "#245361",
  --  "#093748",
  --  "#888ba5",
  --  "#599caa",
  --  "#d3ebe9",
  --},
}

config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

-- 背景。
config.background = {
  {
    source = {
      Color = "#152528",
    },
    opacity = 0.9,
    width = "100%",
    height = "100%",
  },
  --{
  --  source = {
  --    File = wezterm.config_dir .. "/background.png",
  --  },
  --  opacity = 1,
  --  hsb = { brightness = 0.03 },
  --  attachment = {
  --    Parallax = 0.125
  --  },
  --},
}

-- タブまわりの設定。
config.tab_bar_at_bottom = true

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = tab.is_active and "#245361" or "#081f2d"
  local foreground = "#d3ebe9"
  local edge_background = "none"
  local edge_foreground = background

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = wezterm.nerdfonts.ple_left_half_circle_thick },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = " " .. wezterm.truncate_right((tab.tab_index + 1) .. ": " .. tab.active_pane.title, 36) .. " " },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = wezterm.nerdfonts.ple_right_half_circle_thick },
  }
end)

return config
