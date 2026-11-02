-- TypeScriptの設定
local augroup_typescript = vim.api.nvim_create_augroup("typescript-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_typescript,
  pattern = { "typescript", "typescriptreact", "typescript.tsx" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- quickrun - typescript
if vim.fn.executable("tsc") == 1 then
  local quickrun_config = vim.g.quickrun_config or {}
  quickrun_config["typescript"] = {
    type = "typescript/tsc",
  }

  quickrun_config["typescript/tsc"] = {
    command = "tsc",
    exec = { "%c --target esnext --module commonjs %o %s", "node %s:r.js" },
    tempfile = "%{tempname()}.ts",
    ["hook/sweep/files"] = { "%S:p:r.js" },
  }
  vim.g.quickrun_config = quickrun_config
end
