
local augroup_kdl = vim.api.nvim_create_augroup("kdl-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_kdl,
  pattern = { "kdl" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})
