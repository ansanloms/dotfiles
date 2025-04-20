-- PHPの設定

-- case 文対応
vim.g.PHP_vintage_case_default_indent = 1

-- 使用する DB
vim.g.sql_type_default = "mysql"

local augroup_php = vim.api.nvim_create_augroup("php-setting", { clear = true })

-- 拡張子設定
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup_php,
  pattern = "*.ctp",
  callback = function()
    vim.opt_local.filetype = "php"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_php,
  pattern = "php",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    
    -- ハイライト行指定
    vim.cmd("syntax sync minlines=300 maxlines=500")
  end,
})

local augroup_php_volt = vim.api.nvim_create_augroup("php-volt-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_php_volt,
  pattern = "volt",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    
    -- ハイライト行指定
    vim.cmd("syntax sync minlines=300 maxlines=500")
  end,
})
