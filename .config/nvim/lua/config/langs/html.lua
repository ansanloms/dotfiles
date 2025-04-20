-- HTMLの設定
local augroup_html = vim.api.nvim_create_augroup("html-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_html,
  pattern = "html",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- quickrun - html
if vim.fn.executable("w3m") == 1 then
  vim.g.quickrun_config = vim.g.quickrun_config or {}
  vim.g.quickrun_config["html"] = {
    type = "html/w3m"
  }

  -- text 出力
  vim.g.quickrun_config["html/w3m"] = {
    command = "w3m",
    cmdopt = "-dump",
    exec = "%c %o %s"
  }
end
