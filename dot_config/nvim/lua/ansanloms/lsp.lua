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

local ok, blink = pcall(require, "blink.cmp")
vim.lsp.config("*", {
  capabilities = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities(),
})

vim.lsp.config("vue_ls", {
  filetypes = {
    "vue",
  },
  root_markers = {
    "vue.config.js",
    "vue.config.ts",
    "nuxt.config.js",
    "nuxt.config.ts",
  },
})

-- nix の vue-language-server パッケージ内の @vue/language-server を指す。
local vue_language_server_path = (function()
  local exe = vim.fn.exepath("vue-language-server")
  if exe == "" then
    return nil
  end
  local real = vim.uv.fs_realpath(exe)
  if not real then
    return nil
  end
  local path = vim.fs.dirname(vim.fs.dirname(real)) .. "/lib/language-tools/packages/language-server"
  if vim.fn.isdirectory(path) ~= 1 then
    vim.notify(
      "vue-language-server のパッケージ内に " .. path .. " が無く、Vue の TypeScript プラグインを読み込めない。",
      vim.log.levels.WARN
    )
    return nil
  end
  return path
end)()

vim.lsp.config("vtsls", {
  filetypes = {
    "vue",
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  settings = {
    -- @see https://github.com/vuejs/language-tools/wiki/Neovim
    vtsls = {
      tsserver = {
        globalPlugins = vue_language_server_path and {
          {
            name = "@vue/typescript-plugin",
            location = vue_language_server_path,
            languages = { "vue" },
            configNamespace = "typescript",
          }
        } or {},
      },
    },
  },
  root_markers = {
    "package.json",
  },
})

vim.lsp.config("jsonls", {
  filetypes = {
    "json",
    "json5"
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
    "nix",
  },
  settings = {
    rootMarkers = { ".git/" },
    languages = {
      php = {
        {
          -- ecs はプロジェクトの vendor/bin を使い、ecs.php が無いプロジェクトでは実行しない。
          lintCommand = table.concat({
            "vendor/bin/ecs",
            "check",
            [["${INPUT}"]],
            "--fix",
            "--quiet"
          }, " "),
          formatStdin = false,
          lintIgnoreExitCode = true,
          rootMarkers = { "ecs.php" },
          requireMarker = true,
        },
      },
      nix = {
        {
          -- statix: アンチパターンを lint(stdin で受け errfmt 形式で出力)
          lintCommand = "statix check --stdin --format=errfmt",
          lintStdin = true,
          lintFormats = { "<stdin>>%l:%c:%t:%n:%m" },
          lintIgnoreExitCode = true,
          -- nixfmt: 整形(stdin を受けて整形結果を stdout に出力)
          formatCommand = "nixfmt",
          formatStdin = true,
        },
      },
    }
  },
  init_options = {
    documentFormatting = true,
    documentRangeFormatting = true,
  },
})

-- quint: nvim-lspconfig に定義が無いため自前で書く。
vim.lsp.config("quint", {
  cmd = { "quint-language-server", "--stdio" },
  filetypes = { "quint" },
  root_markers = { ".git" },
})

vim.lsp.enable({
  "vtsls",
  "vue_ls",
  "docker_compose_language_service",
  "docker_language_server",
  "phpactor",
  "lua_ls",
  "efm",
  "tombi",
  "actionlint",
  "rust_analyzer",
  "quint",
})

-- eslint と jsonls は nvim-lspconfig の cmd が関数で、実行ファイルが無いと起動のたびにエラーが出る。
-- (ほかのサーバは実行ファイルが無ければ黙って起動しない)
if vim.fn.executable("vscode-eslint-language-server") == 1 then
  vim.lsp.enable("eslint")
end
if vim.fn.executable("vscode-json-language-server") == 1 then
  vim.lsp.enable("jsonls")
end
