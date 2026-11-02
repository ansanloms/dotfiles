return {
  "hrsh7th/vim-vsnip",
  config = function()
    vim.g.vsnip_snippet_dir = vim.fn.expand("~/.config/nvim/snippets")

    vim.g.vsnip_filetypes = {}
    vim.g.vsnip_filetypes.typescript = { "javascript" }
    vim.g.vsnip_filetypes.vue = { "javascript", "typescript" }
    vim.g.vsnip_filetypes.javascriptreact = { "javascript" }
    vim.g.vsnip_filetypes.typescriptreact = { "javascript", "typescript" }
  end,
}
