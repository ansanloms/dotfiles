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
config.color_scheme = "Gotham (terminal.sexy)"
config.window_background_opacity = 0.9
config.text_background_opacity = 1.0
config.enable_scroll_bar = false
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
  ansi = {
    "#0a0f14",
    "#c33027",
    "#26a98b",
    "#edb54b",
    "#195465",
    "#4e5165",
    "#33859d",
    "#98d1ce",
  },
  brights = {
    "#314051",
    "#d26939",
    "#081f2d",
    "#245361",
    "#093748",
    "#888ba5",
    "#599caa",
    "#d3ebe9",
  },
}
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

-- 背景。
config.background = {
  {
    source = {
      File = wezterm.config_dir .. "/background.png",
    },
    opacity = 0.9,
    -- attachment = {
    --   Parallax = 0.125
    -- },
  },
}

-- タブまわりの設定。
config.tab_bar_at_bottom = true

function truncate_string_by_width(str, max_width)
  local current_width = 0
  local result = ""

  for _, codepoint in utf8.codes(str) do
    local char = utf8.char(codepoint)
    local char_width = codepoint <= 127 and 1 or 2

    if current_width + char_width > max_width then
      break
    end

    result = result .. char
    current_width = current_width + char_width
  end

  return result
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = tab.is_active and "#245361" or "#081f2d"
  local foreground = "#d3ebe9"
  local edge_background = "none"
  local edge_foreground = background

  local index = tab.tab_index + 1
  local pane = tab.active_pane
  local full_title = truncate_string_by_width(index .. ": " .. pane.title, 36)

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = wezterm.nerdfonts.ple_left_half_circle_thick },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = " " .. full_title .. " " },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = wezterm.nerdfonts.ple_right_half_circle_thick },
  }
end)

return config
