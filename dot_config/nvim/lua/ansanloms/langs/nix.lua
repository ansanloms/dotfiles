-- Nixの設定
local augroup_nix = vim.api.nvim_create_augroup("nix-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_nix,
  pattern = "nix",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true

    -- フォーマット指定
    if vim.fn.executable("nixfmt") == 1 then
      vim.opt_local.formatprg = "nixfmt"
    end
  end,
})
