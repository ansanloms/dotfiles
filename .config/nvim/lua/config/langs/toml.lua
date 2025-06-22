-- TOMLの設定
local augroup_toml = vim.api.nvim_create_augroup("toml-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_toml,
  pattern = "toml",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
