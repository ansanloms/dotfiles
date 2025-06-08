-- JSONの設定

-- conceal 表示を無効にする
vim.g.vim_json_syntax_conceal = 0

local augroup_json = vim.api.nvim_create_augroup("json-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_json,
  pattern = "json",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true

    -- フォーマット指定
    if vim.fn.executable("python") == 1 then
      vim.opt_local.formatprg = "python -m json.tool"
    end
  end,
})

local augroup_json5 = vim.api.nvim_create_augroup("json5-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_json5,
  pattern = "json5",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

local augroup_jsonc = vim.api.nvim_create_augroup("jsonc-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_jsonc,
  pattern = "jsonc",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
