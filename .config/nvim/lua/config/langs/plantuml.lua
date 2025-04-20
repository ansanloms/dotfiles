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

-- quickrun - plantuml
if vim.fn.executable("plantuml") == 1 then
  vim.g.quickrun_config = vim.g.quickrun_config or {}
  vim.g.quickrun_config["plantuml"] = {
    type = "plantuml/svg"
  }

  -- svg 出力
  vim.g.quickrun_config["plantuml/svg"] = {
    ["hook/cd/directory"] = "%S:p:h",
    outputter = "browser",
    exec = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) and "type %s | plantuml -tsvg -charset UTF-8 -pipe" or "cat %s | plantuml -tsvg -charset UTF-8 -pipe"
  }
end
