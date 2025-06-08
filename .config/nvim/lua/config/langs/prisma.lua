-- Prismaの設定
local augroup_prisma = vim.api.nvim_create_augroup("prisma-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_prisma,
  pattern = "prisma",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
