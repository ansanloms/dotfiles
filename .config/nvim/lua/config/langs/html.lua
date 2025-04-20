-- HTMLの設定
local augroup_html = vim.api.nvim_create_augroup("html-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_html,
  pattern = "html",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- quickrun設定は後で対応
