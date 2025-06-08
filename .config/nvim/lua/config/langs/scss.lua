-- SCSSの設定
local augroup_scss = vim.api.nvim_create_augroup("scss-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_scss,
  pattern = "scss",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
