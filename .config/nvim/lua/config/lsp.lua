require("jetpack").load("nvim-lspconfig")
require("jetpack").load("cmp-nvim-lsp")

-- keyboard shortcut:
--vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>")
vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>")
vim.keymap.set("n", "gf", "<cmd>lua vim.lsp.buf.format()<CR>")
--vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>")
--vim.keymap.set("n", "gr", "<cmd>Lspsaga lsp_finder<CR>")
--vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
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
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

vim.lsp.config("denols", {
  filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json",
    "json5"
  },
  root_dir = require("lspconfig.util").root_pattern(
    "deno.json",
    "deno.jsonc"
  ),
})

vim.lsp.config("vue_ls", {
  filetypes = {
    "vue",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json",
    "json5"
  },
  root_dir = require("lspconfig.util").root_pattern(
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
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json",
    "json5"
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
        --{
        --  lintCommand = table.concat({
        --    vim.fn.stdpath("data") .. "/mason/packages/phpstan/phpstan",
        --    "analyse",
        --    "--no-progress",
        --    "--error-format",
        --    "json",
        --    "--no-ansi",
        --    [["${INPUT}"]],
        --    "|",
        --    "jq",
        --    "-r",
        --    [['.files | to_entries[] | .key as $filepath | .value.messages[] | "\($filepath):\(.line):\(.identifier) - \(.message)"']]
        --  }, " "),
        --  lintSource = "efm/phpstan",
        --  lintStdin = false,
        --  lintIgnoreExitCode = true,
        --  lintDebounce = "1s",
        --  lintFormats = {
        --    "%f:%l:%m"
        --  },
        --  rootmarkers = {
        --    "phpstan.neon",
        --    "phpstan.neon.dist",
        --    "composer.json",
        --  },
        --},
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
          rootmarkers = {
            "ecs.php",
            "composer.json",
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
  "denols",
  "vtsls",
  "vue_ls",
  "docker_language_server",
  "intelephense",
  --"jq",
  --"jsonls",
  "lua_ls",
  "efm"
})
