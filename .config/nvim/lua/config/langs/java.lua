-- Javaの設定

-- Javaidを読み込み
if vim.fn.filereadable(vim.fn.expand("~/.config/vim/syntax/javaid.vim")) == 0 then
  vim.fn.system("curl https://fleiner.com/vim/syntax/javaid.vim -o " .. vim.fn.expand("~/.config/vim/syntax/javaid.vim"))
end

vim.g.java_highlight_all = 1

-- quickrun設定は後で対応

local augroup_java = vim.api.nvim_create_augroup("java-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_java,
  pattern = "java",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = false
  end,
})
