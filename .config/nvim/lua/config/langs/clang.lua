-- C言語の設定
local augroup_clang = vim.api.nvim_create_augroup("clang-setting", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup_clang,
  pattern = "*.c",
  callback = function()
    vim.opt_local.filetype = "c"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_clang,
  pattern = "c",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})
