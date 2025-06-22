-- Vueの設定
local augroup_vue = vim.api.nvim_create_augroup("vue-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_vue,
  pattern = "vue",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- ハイライト行指定
vim.api.nvim_create_autocmd("FileType", {
  group = augroup_vue,
  pattern = "vue",
  callback = function()
    vim.cmd("syntax sync fromstart")
  end,
})
