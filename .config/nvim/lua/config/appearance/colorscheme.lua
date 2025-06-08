require("jetpack").load("nightfox.nvim")

-- シンタックス ON
vim.cmd("syntax enable")
vim.opt.background = "dark"

-- True Color でのシンタックスハイライト。
if vim.fn.has("termguicolors") == 1 then
  vim.opt.termguicolors = true
end

--vim.cmd("colorscheme gotham")
--vim.api.nvim_set_hl(0, "PreProc", { fg = "#888ca6" })
--vim.api.nvim_set_hl(0, "StatusLineTerm", { link = "StatusLine" })
--vim.api.nvim_set_hl(0, "StatusLineTermNC", { link = "StatusLineNC" })
--if vim.fn.has("gui_running") == 0 then
--  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
--  vim.api.nvim_set_hl(0, "NonText", { bg = "NONE", ctermbg = "NONE" })
--  vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE", ctermbg = "NONE" })
--  vim.api.nvim_set_hl(0, "Folded", { bg = "NONE", ctermbg = "NONE" })
--  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", ctermbg = "NONE" })
--end

if vim.fn.has("gui_running") == 1 then
  require("nightfox").setup({
    options = {
      terminal_colors = false,
    },
  })
else
  require("nightfox").setup({
    options = {
      transparent = true,
    },
  })
end

vim.cmd("colorscheme terafox")

if vim.fn.has("terminal") == 1 and vim.fn.exists("*term_setansicolors") == 1 then
  vim.g.terminal_ansi_colors = {}

  -- gotham:
  --vim.g.terminal_ansi_colors = {
  --  "#0a0f14", "#c33027", "#26a98b", "#edb54b",
  --  "#195465", "#4e5165", "#33859d", "#98d1ce",
  --  "#314051", "#d26939", "#081f2d", "#245361",
  --  "#093748", "#888ba5", "#599caa", "#d3ebe9"
  --}

  -- terafox'
  vim.g.terminal_ansi_colors = {
    "#2f3239",
    "#e85c51",
    "#7aa4a1",
    "#fda47f",
    "#5a93aa",
    "#ad5c7c",
    "#a1cdd8",
    "#ebebeb",
    "#4e5157",
    "#eb746b",
    "#8eb2af",
    "#fdb292",
    "#73a3b7",
    "#b97490",
    "#afd4de",
    "#eeeeee",
  }
end
