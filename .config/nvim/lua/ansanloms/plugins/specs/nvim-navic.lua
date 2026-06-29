return {
  "SmiteshP/nvim-navic",
  config = function()
    require("nvim-navic").setup({
      lsp = {
        auto_attach = true,
        preference = { "vue_ls", "vtsls", "denols" },
      },
      highlight = true,
      depth_limit = 12,
    })
  end,
}
