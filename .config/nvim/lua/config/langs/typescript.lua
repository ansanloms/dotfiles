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

-- quickrun設定は後で対応
