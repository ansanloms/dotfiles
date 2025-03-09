local wezterm = require("wezterm")
local act = wezterm.action

local config = {}

config.disable_default_key_bindings = true

config.leader = {
  key = ";",
  mods = "CTRL",
  timeout_milliseconds = 2000
}

config.keys = {
  {
    key = "q",
    mods = "LEADER",
    action = wezterm.action.ActivateCommandPalette,
  },

  -- タブの追加。
  {
    key = "c",
    mods = "LEADER",
    action = act.SpawnTab 'CurrentPaneDomain'
  },

  -- 次のタブ。
  {
    key = "n",
    mods = "LEADER",
    action = act.ActivateTabRelative(1)
  },

  -- 前のタブ。
  {
    key = "p",
    mods = "LEADER",
    action = act.ActivateTabRelative(1)
  },

  -- タブの一覧表示。
  {
    key = "w",
    mods = "LEADER",
    action = act.ShowTabNavigator
  },

  -- タブを閉じる。
  {
    key = "&",
    mods = "LEADER|SHIFT",
    action = act.CloseCurrentTab({ confirm = true }),
  },

  -- タブを左右に分割する。
  {
    key = "%",
    mods = "LEADER|SHIFT",
    action = act.SplitPane({
      direction = "Left",
      size = { Percent = 50 },
    }),
  },

  -- タブを上下に分割する。
  {
    key = '"',
    mods = "LEADER|SHIFT",
    action = act.SplitPane({
      direction = "Down",
      size = { Percent = 50 },
    }),
  },

  -- 次のペインを選択する。
  {
    key = "o",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Next"),
  },

  -- 前のペインを選択する。
  {
    key = ";",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Prev"),
  },

  -- ペインを選択する。
  {
    key = "=",
    mods = "LEADER",
    action = act.PaneSelect({
      mode = "Activate"
    }),
  },

  -- ペインを選択していれかえる。
  {
    key = "+",
    mods = "LEADER|SHIFT",
    action = act.PaneSelect({
      mode = "SwapWithActive"
    }),
  },

  -- コピーモード。
  {
    key = "w",
    mods = "LEADER|CTRL",
    action = act.ActivateCopyMode
  },
}

config.mouse_bindings = {
  -- コピーとペースト。
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act({ PasteFrom = "Clipboard" }),
  },
}

config.key_tables = {
  copy_mode = {
    { key = "Tab", mods = "NONE", action = act.CopyMode "MoveForwardWord" },
    { key = "Tab", mods = "SHIFT", action = act.CopyMode "MoveBackwardWord" },
    { key = "Enter", mods = "NONE", action = act.CopyMode "MoveToStartOfNextLine" },
    { key = "Escape", mods = "NONE", action = act.CopyMode "Close" },
    { key = "Space", mods = "NONE", action = act.CopyMode{ SetSelectionMode =  "Cell" } },
    { key = "$", mods = "NONE", action = act.CopyMode "MoveToEndOfLineContent" },
    { key = "$", mods = "SHIFT", action = act.CopyMode "MoveToEndOfLineContent" },
    { key = ",", mods = "NONE", action = act.CopyMode "JumpReverse" },
    { key = "0", mods = "NONE", action = act.CopyMode "MoveToStartOfLine" },
    { key = ";", mods = "NONE", action = act.CopyMode "JumpAgain" },
    { key = "F", mods = "NONE", action = act.CopyMode{ JumpBackward = { prev_char = false } } },
    { key = "F", mods = "SHIFT", action = act.CopyMode{ JumpBackward = { prev_char = false } } },
    { key = "G", mods = "NONE", action = act.CopyMode "MoveToScrollbackBottom" },
    { key = "G", mods = "SHIFT", action = act.CopyMode "MoveToScrollbackBottom" },
    { key = "H", mods = "NONE", action = act.CopyMode "MoveToViewportTop" },
    { key = "H", mods = "SHIFT", action = act.CopyMode "MoveToViewportTop" },
    { key = "L", mods = "NONE", action = act.CopyMode "MoveToViewportBottom" },
    { key = "L", mods = "SHIFT", action = act.CopyMode "MoveToViewportBottom" },
    { key = "M", mods = "NONE", action = act.CopyMode "MoveToViewportMiddle" },
    { key = "M", mods = "SHIFT", action = act.CopyMode "MoveToViewportMiddle" },
    { key = "O", mods = "NONE", action = act.CopyMode "MoveToSelectionOtherEndHoriz" },
    { key = "O", mods = "SHIFT", action = act.CopyMode "MoveToSelectionOtherEndHoriz" },
    { key = "T", mods = "NONE", action = act.CopyMode{ JumpBackward = { prev_char = true } } },
    { key = "T", mods = "SHIFT", action = act.CopyMode{ JumpBackward = { prev_char = true } } },
    { key = "V", mods = "NONE", action = act.CopyMode{ SetSelectionMode =  "Line" } },
    { key = "V", mods = "SHIFT", action = act.CopyMode{ SetSelectionMode =  "Line" } },
    { key = "^", mods = "NONE", action = act.CopyMode "MoveToStartOfLineContent" },
    { key = "^", mods = "SHIFT", action = act.CopyMode "MoveToStartOfLineContent" },
    { key = "b", mods = "NONE", action = act.CopyMode "MoveBackwardWord" },
    { key = "b", mods = "ALT", action = act.CopyMode "MoveBackwardWord" },
    { key = "b", mods = "CTRL", action = act.CopyMode "PageUp" },
    { key = "c", mods = "CTRL", action = act.CopyMode "Close" },
    { key = "d", mods = "CTRL", action = act.CopyMode{ MoveByPage = (0.5) } },
    { key = "e", mods = "NONE", action = act.CopyMode "MoveForwardWordEnd" },
    { key = "f", mods = "NONE", action = act.CopyMode{ JumpForward = { prev_char = false } } },
    { key = "f", mods = "ALT", action = act.CopyMode "MoveForwardWord" },
    { key = "f", mods = "CTRL", action = act.CopyMode "PageDown" },
    { key = "g", mods = "NONE", action = act.CopyMode "MoveToScrollbackTop" },
    { key = "g", mods = "CTRL", action = act.CopyMode "Close" },
    { key = "h", mods = "NONE", action = act.CopyMode "MoveLeft" },
    { key = "j", mods = "NONE", action = act.CopyMode "MoveDown" },
    { key = "k", mods = "NONE", action = act.CopyMode "MoveUp" },
    { key = "l", mods = "NONE", action = act.CopyMode "MoveRight" },
    { key = "m", mods = "ALT", action = act.CopyMode "MoveToStartOfLineContent" },
    { key = "o", mods = "NONE", action = act.CopyMode "MoveToSelectionOtherEnd" },
    { key = "q", mods = "NONE", action = act.CopyMode "Close" },
    { key = "t", mods = "NONE", action = act.CopyMode{ JumpForward = { prev_char = true } } },
    { key = "u", mods = "CTRL", action = act.CopyMode{ MoveByPage = (-0.5) } },
    { key = "v", mods = "NONE", action = act.CopyMode{ SetSelectionMode =  "Cell" } },
    { key = "v", mods = "CTRL", action = act.CopyMode{ SetSelectionMode =  "Block" } },
    { key = "w", mods = "NONE", action = act.CopyMode "MoveForwardWord" },
    { key = "y", mods = "NONE", action = act.Multiple{ { CopyTo =  "ClipboardAndPrimarySelection" }, { CopyMode =  "Close" } } },
    { key = "PageUp", mods = "NONE", action = act.CopyMode "PageUp" },
    { key = "PageDown", mods = "NONE", action = act.CopyMode "PageDown" },
    { key = "End", mods = "NONE", action = act.CopyMode "MoveToEndOfLineContent" },
    { key = "Home", mods = "NONE", action = act.CopyMode "MoveToStartOfLine" },
    { key = "LeftArrow", mods = "NONE", action = act.CopyMode "MoveLeft" },
    { key = "LeftArrow", mods = "ALT", action = act.CopyMode "MoveBackwardWord" },
    { key = "RightArrow", mods = "NONE", action = act.CopyMode "MoveRight" },
    { key = "RightArrow", mods = "ALT", action = act.CopyMode "MoveForwardWord" },
    { key = "UpArrow", mods = "NONE", action = act.CopyMode "MoveUp" },
    { key = "DownArrow", mods = "NONE", action = act.CopyMode "MoveDown" },
  },
  search_mode = {
    { key = "Enter", mods = "NONE", action = act.CopyMode "PriorMatch" },
    { key = "Escape", mods = "NONE", action = act.CopyMode "Close" },
    { key = "n", mods = "CTRL", action = act.CopyMode "NextMatch" },
    { key = "p", mods = "CTRL", action = act.CopyMode "PriorMatch" },
    { key = "r", mods = "CTRL", action = act.CopyMode "CycleMatchType" },
    { key = "u", mods = "CTRL", action = act.CopyMode "ClearPattern" },
    { key = "PageUp", mods = "NONE", action = act.CopyMode "PriorMatchPage" },
    { key = "PageDown", mods = "NONE", action = act.CopyMode "NextMatchPage" },
    { key = "UpArrow", mods = "NONE", action = act.CopyMode "PriorMatch" },
    { key = "DownArrow", mods = "NONE", action = act.CopyMode "NextMatch" },
  },
}

return config
