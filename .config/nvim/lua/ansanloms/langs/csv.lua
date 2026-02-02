-- CSVの設定
local augroup_csv = vim.api.nvim_create_augroup("csv-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_csv,
  pattern = "csv",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
