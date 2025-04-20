-- YAMLの設定
local augroup_yaml = vim.api.nvim_create_augroup("yaml-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_yaml,
  pattern = "yaml",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
