-- SQLの設定
local augroup_sql = vim.api.nvim_create_augroup("sql-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_sql,
  pattern = "sql",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
    
    -- 折り返さない
    vim.opt_local.wrap = false
    
    -- フォーマット指定
    if vim.fn.executable("sql-formatter") == 1 then
      vim.opt_local.formatprg = "sql-formatter"
    end
  end,
})

-- quickrun設定は後で対応
