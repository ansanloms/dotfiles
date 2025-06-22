-- keyboard shortcut:
vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
vim.keymap.set("n", "gf", "<cmd>lua vim.lsp.buf.format()<CR>")
--vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
--vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
--vim.keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
vim.keymap.set("n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
vim.keymap.set("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>")
vim.keymap.set("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>")
vim.keymap.set("n", "g]", "<cmd>lua vim.diagnostic.goto_next()<CR>")
vim.keymap.set("n", "g[", "<cmd>lua vim.diagnostic.goto_prev()<CR>")

vim.diagnostic.config({
  virtual_text = {
    format = function(diagnostic)
      return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
    end,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "󰋇",
      [vim.diagnostic.severity.HINT] = "󰌵",
    },
  },
})

vim.lsp.config("*", {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover,
  {
    border = "shadow",
    -- border = border
    -- width = 100,
  }
)

vim.lsp.config("denols", {
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json"
  },
  root_dir = function(bufnr, callback)
    local found_dirs = vim.fs.find({
      "deno.json",
      "deno.jsonc",
    }, {
      upward = true,
      path = vim.fs.dirname(vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))),
    })
    if #found_dirs > 0 then
      return callback(vim.fs.dirname(found_dirs[1]))
    end
  end,
})

vim.lsp.config("vue_ls", {
  filetypes = {
    "vue",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json"
  },
  root_dir = function(bufnr, callback)
    local found_dirs = vim.fs.find({
      "vue.config.js",
      "vue.config.ts",
      "nuxt.config.js",
      "nuxt.config.ts",
    }, {
      upward = true,
      path = vim.fs.dirname(vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))),
    })
    if #found_dirs > 0 then
      return callback(vim.fs.dirname(found_dirs[1]))
    end
  end,
  init_options = {
    vue = {
      hybridMode = false,
    },
  },
  settings = {
    typescript = {
      inlayHints = {
        enumMemberValues = {
          enabled = true,
        },
        functionLikeReturnTypes = {
          enabled = true,
        },
        propertyDeclarationTypes = {
          enabled = true,
        },
        parameterTypes = {
          enabled = true,
          suppressWhenArgumentMatchesName = true,
        },
        variableTypes = {
          enabled = true,
        },
      },
    },
  },
})

-- volar(vue_ls) が text_document.version を考慮してないっぽいので、もう version 確認せず更新かける。
-- @see https://github.com/neovim/neovim/issues/12970#issuecomment-794837542
-- @see https://github.com/neovim/neovim/blob/release-0.11/runtime/lua/vim/lsp/util.lua#L428-L460
vim.lsp.util.apply_text_document_edit = function(text_document_edit, index, position_encoding)
  local text_document = text_document_edit.textDocument
  local bufnr = vim.uri_to_bufnr(text_document.uri)
  if position_encoding == nil then
    vim.notify_once(
      "apply_text_document_edit must be called with valid position encoding",
      vim.log.levels.WARN
    )
    return
  end

  vim.lsp.util.apply_text_edits(text_document_edit.edits, bufnr, position_encoding)
end

vim.lsp.enable(require("mason-lspconfig").get_installed_servers())
