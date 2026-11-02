-- just の設定
local augroup_just = vim.api.nvim_create_augroup("just-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_just,
  pattern = "just",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true

    -- フォーマット指定。
    if vim.fn.executable("just") == 1 then
      vim.opt_local.formatprg = "just --format --justfile " .. vim.fn.expand('%:p')
    end
  end,
})
