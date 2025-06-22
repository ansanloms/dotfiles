-- GraphQLの設定
local augroup_graphql = vim.api.nvim_create_augroup("graphql-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_graphql,
  pattern = "graphql",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
