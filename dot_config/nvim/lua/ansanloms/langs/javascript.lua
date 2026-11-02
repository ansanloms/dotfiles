-- JavaScriptの設定
local augroup_javascript = vim.api.nvim_create_augroup("javascript-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_javascript,
  pattern = { "javascript", "javascriptreact", "javascript.jsx" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
