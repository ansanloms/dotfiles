-- AsciiDocの設定
local augroup_asciidoc = vim.api.nvim_create_augroup("asciidoc-setting", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup_asciidoc,
  pattern = "*.adoc",
  callback = function()
    vim.opt_local.filetype = "asciidoc"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_asciidoc,
  pattern = "asciidoc",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
