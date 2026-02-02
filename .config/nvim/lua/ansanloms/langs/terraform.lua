-- Terraformの設定
local augroup_terraform = vim.api.nvim_create_augroup("terraform-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_terraform,
  pattern = "terraform",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
