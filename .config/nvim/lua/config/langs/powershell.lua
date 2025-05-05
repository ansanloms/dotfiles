-- PowerShellの設定
local augroup_powershell = vim.api.nvim_create_augroup("powershell-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_powershell,
  pattern = "ps1",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
