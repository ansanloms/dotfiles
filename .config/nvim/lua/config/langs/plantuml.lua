-- PlantUMLの設定
local augroup_plantuml = vim.api.nvim_create_augroup("plantuml-setting", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup_plantuml,
  pattern = "*.{pu,uml,puml,iuml,plantuml}",
  callback = function()
    vim.opt_local.filetype = "plantuml"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_plantuml,
  pattern = "plantuml",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- quickrun設定は後で対応
