-- バイナリファイルの設定
local augroup_binary = vim.api.nvim_create_augroup("binary-setting", { clear = true })

vim.api.nvim_create_autocmd("BufReadPre", {
  group = augroup_binary,
  pattern = "*.{bin,dll,exe}",
  callback = function()
    vim.opt_local.bin = true
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup_binary,
  pattern = "*.{bin,dll,exe}",
  callback = function()
    if vim.opt_local.bin:get() then
      vim.cmd("%!xxd")
      vim.opt_local.filetype = "xxd"
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup_binary,
  pattern = "*.{bin,dll,exe}",
  callback = function()
    if vim.opt_local.bin:get() then
      vim.cmd("%!xxd -r")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup_binary,
  pattern = "*.{bin,dll,exe}",
  callback = function()
    if vim.opt_local.bin:get() then
      vim.cmd("%!xxd")
      vim.opt_local.modified = false
    end
  end,
})
