require("jetpack").load("nvim-lspconfig")
require("jetpack").load("blink.cmp")

local util = require("lspconfig.util")

-- keyboard shortcut:
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "gf", vim.lsp.buf.format)
--vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
--vim.keymap.set("n", "gr", "<cmd>Lspsaga lsp_finder<CR>")
--vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
--vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
vim.keymap.set("n", "gD", "<cmd>Lspsaga peek_definition<CR>")
--vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
--vim.keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
--vim.keymap.set("n", "gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
vim.keymap.set("n", "gn", "<cmd>Lspsaga rename<CR>")
--vim.keymap.set("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>")
vim.keymap.set("n", "ga", "<cmd>Lspsaga code_action<CR>")
--vim.keymap.set("n", "ge", "<cmd>lua vim.diagnostic.open_float()<CR>")
vim.keymap.set("n", "ge", "<cmd>Lspsaga show_line_diagnostics<CR>")
--vim.keymap.set("n", "g]", "<cmd>lua vim.diagnostic.goto_next()<CR>")
vim.keymap.set("n", "g]", "<cmd>Lspsaga diagnostic_jump_next<CR>")
--vim.keymap.set("n", "g[", "<cmd>lua vim.diagnostic.goto_prev()<CR>")
vim.keymap.set("n", "g[", "<cmd>Lspsaga diagnostic_jump_prev<CR>")

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
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.config("denols", {
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx"
  },
  root_dir = util.root_pattern(
    "deno.json",
    "deno.jsonc"
  ),
})

vim.lsp.config("vue_ls", {
  filetypes = {
    "vue"
  },
  root_dir = util.root_pattern(
    "vue.config.js",
    "vue.config.ts",
    "nuxt.config.js",
    "nuxt.config.ts"
  ),
})

vim.lsp.config("vtsls", {
  filetypes = {
    "vue",
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx"
  },
  settings = {
    -- @see https://github.com/vuejs/language-tools/wiki/Neovim
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
            languages = { "vue" },
            configNamespace = "typescript",
          }
        },
      },
    },
  },
  root_dir = util.root_pattern(
    "package.json"
  ),
})

vim.lsp.config("jsonls", {
  filetypes = {
    "json",
    "json5"
  },
})

vim.lsp.config("intelephense", {
  filetypes = {
    "php",
    "volt"
  },
})

vim.lsp.config("phpactor", {
  filetypes = {
    "php",
    "volt"
  },
  root_markers = {
    "composer.json",
    ".phpactor.json",
    ".phpactor.yml"
  },
})

vim.lsp.config("efm", {
  filetypes = {
    "php",
  },
  settings = {
    rootMarkers = { ".git/" },
    languages = {
      php = {
        {
          lintCommand = table.concat({
            vim.fn.stdpath("data") .. "/mason/packages/easy-coding-standard/vendor/bin/ecs",
            "check",
            [["${INPUT}"]],
            "--fix",
            "--quiet"
          }, " "),
          formatStdin = false,
          lintIgnoreExitCode = true,
          root_markers = {
            "ecs.php",
            "composer.json"
          },
        },
      }
    }
  },
  init_options = {
    documentFormatting = true,
    documentRangeFormatting = true,
  },
})

vim.lsp.enable({
  "eslint",
  "docker_language_server",
  "intelephense",
  "lua_ls",
  "efm"
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("lsp-start-vue", { clear = true }),
  pattern = "vue",
  callback = function()
    vim.lsp.start(vim.lsp.config.vtsls)
    vim.lsp.start(vim.lsp.config.vue_ls)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("lsp-start-node-or-deno", { clear = true }),
  pattern = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  callback = function()
    -- node
    if vim.fn.findfile("package.json", ".;") ~= "" then
      vim.lsp.start(vim.lsp.config.vtsls)
      return
    end

    -- deno
    vim.lsp.start(vim.lsp.config.denols)
  end,
})
