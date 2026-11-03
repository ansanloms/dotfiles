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

    -- フォーマット指定。oxfmt は --stdin-filepath のファイル名から parser を推定する。
    if vim.fn.executable("npx") == 1 then
      local name = vim.api.nvim_buf_get_name(0)
      if name == "" then
        name = "stdin.json"
      end
      vim.opt_local.formatprg = "npx --yes oxfmt@0.75.0 --stdin-filepath " .. vim.fn.shellescape(name)
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
