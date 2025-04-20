-- Markdownの設定
local augroup_markdown = vim.api.nvim_create_augroup("markdown-setting", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup_markdown,
  pattern = "*.{md,mdwn,mkd,mkdn,mark*}",
  callback = function()
    vim.opt_local.filetype = "markdown"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_markdown,
  pattern = "markdown",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

local augroup_markdown_mdx = vim.api.nvim_create_augroup("markdown-mdx-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_markdown_mdx,
  pattern = "markdown.mdx",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- quickrun設定は後で対応
