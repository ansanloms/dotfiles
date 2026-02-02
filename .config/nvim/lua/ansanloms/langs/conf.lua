-- 設定ファイル系の設定
local augroup_conf = vim.api.nvim_create_augroup("conf-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_conf,
  pattern = { "apache", "nginx", "conf" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})
