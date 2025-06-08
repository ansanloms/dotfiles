-- Stylusの設定
local augroup_stylus = vim.api.nvim_create_augroup("stylus-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_stylus,
  pattern = "stylus",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
