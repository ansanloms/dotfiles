-- CSSの設定
local augroup_css = vim.api.nvim_create_augroup("css-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_css,
  pattern = "css",
  callback = function()
  end,
})
