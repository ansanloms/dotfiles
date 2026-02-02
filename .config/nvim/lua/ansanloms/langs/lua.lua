local augroup_lua = vim.api.nvim_create_augroup("lua-setting", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = augroup_lua,
  pattern = "lua",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
