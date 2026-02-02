-- Javaの設定
vim.g.java_highlight_all = 1

-- quickrun - java
vim.g.quickrun_config = vim.g.quickrun_config or {}
vim.g.quickrun_config["java"] = {
  ["hook/cd/directory"] = "%S:p:h",
  exec = {
    "javac -J-Dfile.encoding=UTF8 %o %s",
    "%c -Dfile.encoding=UTF8 %s:t:r %a",
  },
}

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
