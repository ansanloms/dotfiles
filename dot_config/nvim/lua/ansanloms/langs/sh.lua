-- Shellスクリプトの設定

-- case文のインデント
vim.g.sh_indent_case_labels = 1

local augroup_sh = vim.api.nvim_create_augroup("sh-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_sh,
  pattern = "sh",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
