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

-- @todo https://github.com/neovim/neovim/issues/2325
-- VimEnter 後に設定することで shada 復元時の OSC 52 copy 発火を防ぐ。
-- shada 読み込みフェーズで clipboard=unnamed,unnamedplus が有効だと unnamed register の
-- 内容が即座に + register に sync され OSC 52 copy が走り、起動時に意図しないペーストが発生する。
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.opt.clipboard = "unnamed,unnamedplus"
  end,
})
