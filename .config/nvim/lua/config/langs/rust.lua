-- Rustの設定
local augroup_rust = vim.api.nvim_create_augroup("rust-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_rust,
  pattern = "rust",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})
