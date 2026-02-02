-- @todo https://github.com/neovim/neovim/issues/2325
vim.opt.clipboard = "unnamed,unnamedplus"

-- @see https://github.com/neovim/neovim/discussions/28010#discussioncomment-9877494
local function paste()
  return {
    vim.fn.split(vim.fn.getreg(""), "\n"),
    vim.fn.getregtype(""),
  }
end

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = paste,
    ["*"] = paste,
  },
}
