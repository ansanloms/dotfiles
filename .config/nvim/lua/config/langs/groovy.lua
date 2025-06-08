-- Groovyの設定
local augroup_groovy = vim.api.nvim_create_augroup("groovy-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_groovy,
  pattern = "groovy",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
