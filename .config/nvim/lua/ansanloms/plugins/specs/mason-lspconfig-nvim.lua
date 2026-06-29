return {
  "williamboman/mason-lspconfig.nvim",
  config = function()
    local ensure = {}

    if vim.fn.executable("node") == 1 then
      vim.list_extend(ensure, {
        "eslint",
        "vtsls",
        "vue_ls",
        "jsonls",
      })
    end

    if vim.fn.executable("deno") == 1 then
      vim.list_extend(ensure, {
        "denols",
      })
    end

    if vim.fn.executable("php") == 1 then
      vim.list_extend(ensure, {
        "phpactor",
      })
    end

    vim.list_extend(ensure, {
      "docker_language_server",
      "lua_ls",
      "efm",
    })

    require("mason-lspconfig").setup({
      ensure_installed = ensure,
    })
  end,
}
