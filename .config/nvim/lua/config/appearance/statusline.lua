require("jetpack").load("heirline.nvim")

local utils = require("heirline.utils")

-- Terafox パレットを取得。
local palette = require("nightfox.palette").load("terafox")

-- 色設定。
local colors = {
  diag_warn = utils.get_highlight("DiagnosticWarn").fg,
  diag_error = utils.get_highlight("DiagnosticError").fg,
  diag_hint = utils.get_highlight("DiagnosticHint").fg,
  diag_info = utils.get_highlight("DiagnosticInfo").fg,
  diag_ok = utils.get_highlight("DiagnosticOk").fg,
  git_del = utils.get_highlight("diffRemoved").fg,
  git_add = utils.get_highlight("diffAdded").fg,
  git_change = utils.get_highlight("diffChanged").fg,
}

for color_name, color in pairs(palette) do
  if type(color) == "string" then
    colors[color_name] = color
  elseif type(color) == "table" then
    colors[color_name .. "_base"] = color["base"]
    colors[color_name .. "_bright"] = color["bright"]
    colors[color_name .. "_dim"] = color["dim"]
  end
end

require("heirline").setup({
  --statusline = StatusLine,
  --winbar = WinBar,
  --tabline = TabLine,
  --statuscolumn = StatusColumn,
  opts = { colors = colors }
})
