-- Pythonの設定
local augroup_python = vim.api.nvim_create_augroup("python-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_python,
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})
