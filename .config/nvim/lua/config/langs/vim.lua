-- Vimスクリプトの設定

-- \ を入力した際のインデント量
vim.g.vim_indent_cont = 0

local augroup_vim = vim.api.nvim_create_augroup("vim-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_vim,
  pattern = "vim",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
    
    -- folding設定
    vim.opt_local.foldmethod = "marker"
  end,
})
