-- CSSの設定
local augroup_css = vim.api.nvim_create_augroup("css-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_css,
  pattern = "css",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
