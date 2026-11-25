-- Quint の設定
vim.filetype.add({
  extension = {
    qnt = "quint",
  },
})

local augroup_quint = vim.api.nvim_create_augroup("quint-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_quint,
  pattern = "quint",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
    vim.opt_local.commentstring = "// %s"
  end,
})
