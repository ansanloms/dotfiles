local jetpackfile = vim.fn.stdpath("data") .. "/site/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim"
local jetpackurl = "https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim"
if vim.fn.filereadable(jetpackfile) == 0 then
  vim.fn.system(string.format("curl -fsSLo %s --create-dirs %s", jetpackfile, jetpackurl))
end

vim.cmd("packadd vim-jetpack")

local jetpack = require("jetpack")

require("jetpack.packer").startup(function(use)
  -- plugin manager:
  use({
    "https://github.com/tani/vim-jetpack.git",
    as = "vim-jetpack",
    opt = true
  })

  -- general:
  use({
    "https://github.com/vim-jp/vimdoc-ja.git",
    as = "vimdoc-ja"
  })
  use({
    "https://github.com/vim-denops/denops.vim.git",
    as = "denops.vim"
  })
  use({
    "https://github.com/yukimemi/hitori.vim.git",
    as = "hitori.vim",
    requires = { "denops.vim" },
    config = function()
      vim.g.hitori_opener = "edit"
    end,
  })
  use({
    "https://github.com/APZelos/blamer.nvim.git",
    as = "blamer.nvim",
    config = function()
      vim.g.blamer_enabled = true
    end,
  })

  -- telescope:
  use({
    "https://github.com/nvim-lua/plenary.nvim.git",
    as = "plenary.nvim"
  })
  use({
    "https://github.com/nvim-telescope/telescope.nvim.git",
    as = "telescope.nvim",
    requires = { "plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")
      local actions = require("telescope.actions")
      local launcher = require("telescope-launcher")

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<esc>"] = actions.close,
              --["<C-j>"] = actions.move_selection_next,
              --["<C-k>"] = actions.move_selection_previous,
            },
            n = {
              ["<esc>"] = actions.close,
              --["<C-j>"] = actions.move_selection_next,
              --["<C-k>"] = actions.move_selection_previous,
            },
          },
        },
      })

      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope oldfiles" })
      vim.keymap.set("n", "<leader>fl", launcher(require("config.launcher")), { desc = "Telescope launcher" })
    end,
  })

  -- quickrun:
  use({
    "https://github.com/thinca/vim-quickrun.git",
    as = "vim-quickrun",
  })

  -- snippet:
  use({
    "https://github.com/hrsh7th/vim-vsnip.git",
    as = "vim-vsnip",
    config = function()
      vim.g.vsnip_snippet_dir = vim.fn.expand("~/.config/nvim/snippets")

      vim.g.vsnip_filetypes = {}
      vim.g.vsnip_filetypes.typescript = { "javascript" }
      vim.g.vsnip_filetypes.vue = { "javascript", "typescript" }
      vim.g.vsnip_filetypes.javascriptreact = { "javascript" }
      vim.g.vsnip_filetypes.typescriptreact = { "javascript", "typescript" }
    end,
  })
  use({
    "https://github.com/hrsh7th/vim-vsnip-integ.git",
    as = "vim-vsnip-integ",
    requires = { "vim-vsnip" },
  })
  use({
    "https://github.com/hrsh7th/cmp-vsnip.git",
    as = "cmp-vsnip",
    requires = { "vim-vsnip" },
  })

  -- lsp:
  use({
    "https://github.com/neovim/nvim-lspconfig.git",
    as = "nvim-lspconfig",
  })
  use({
    "https://github.com/williamboman/mason.nvim.git",
    as = "mason.nvim",
    config = function()
      require("mason").setup()
    end,
  })
  use({
    "https://github.com/hrsh7th/cmp-nvim-lsp.git",
    as = "cmp-nvim-lsp",
  })
  use({
    "https://github.com/williamboman/mason-lspconfig.nvim.git",
    as = "mason-lspconfig.nvim",
    requires = { "nvim-lspconfig", "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "eslint",
          "prettier",
          "denols",
          "vtsls",
          "vue_ls",
          "docker_language_server",
          --"intelephense",
          "phpactor",
          --"phpcs",
          --"phpstan",
          --"jqls",
          --"jsonls",
          "lua_ls",
          --"sqls",
          "efm"
        },
      })
    end,
  })
  use({
    "https://github.com/nvimdev/lspsaga.nvim.git",
    as = "lspsaga.nvim",
    requires = { "nvim-lspconfig", },
    config = function()
      require("lspsaga").setup({})
    end,
  })

  -- appearance:
  use({
    "https://github.com/whatyouhide/vim-gotham.git",
    as = "vim-gotham",
  })
  use({
    "https://github.com/EdenEast/nightfox.nvim.git",
    as = "nightfox.nvim",
  })
  use({
    "https://github.com/nvim-tree/nvim-web-devicons.git",
    as = "nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup()
    end,
  })
  use({
    "https://github.com/nvim-treesitter/nvim-treesitter.git",
    as = "nvim-treesitter",
    branch = "main",
    run = function()
      require("nvim-treesitter").install({
        "awk",
        "bash",
        "c",
        "c_sharp",
        "clojure",
        "cpp",
        "css",
        "csv",
        "diff",
        "elixir",
        "elm",
        "erlang",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "go",
        "html",
        "http",
        "ini",
        "java",
        "javadoc",
        "javascript",
        "jq",
        "jsdoc",
        "json",
        "json5",
        "jsonc",
        "kdl",
        "kotlin",
        "latex",
        "lua",
        "luadoc",
        "make",
        "markdown",
        "markdown_inline",
        "mermaid",
        "nginx",
        "perl",
        "php",
        "phpdoc",
        "powershell",
        "prisma",
        "pug",
        "python",
        "robot",
        "robots",
        "rst",
        "ruby",
        "rust",
        "scss",
        "sql",
        "styled",
        "swift",
        "tmux",
        "toml",
        "tsv",
        "tsx",
        "twig",
        "typescript",
        "vim",
        "vimdoc",
        "vue",
        "xml",
        "yaml",
      }, {
        force = false,
        generate = true,
        max_jobs = 4,
        summary = false,
      })
    end,
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
      })
    end,
  })
  use({
    "https://github.com/nvim-treesitter/nvim-treesitter-context.git",
    as = "nvim-treesitter-context",
    requires = { "nvim-treesitter" },
  })
  use({
    "https://github.com/rbtnn/vim-ambiwidth.git",
    as = "vim-ambiwidth",
    setup = function()
      vim.g.ambiwidth_cica_enabled = false

      -- Nerd Fonts 関連の設定。
      vim.g.ambiwidth_add_list = {
        -- Seti-UI + Custom (0xe62e は元々対応されてる)
        { 0xe5fa,  0xe62d,  2 }, { 0xe62f, 0xe6b7, 2 },
        -- Devicons
        { 0xe700,  0xe8ef,  2 },
        -- Material Design Icons
        { 0xf0001, 0xf1af0, 2 },
        -- Codicons
        { 0xea60,  0xec1e,  2 },
        -- Octicons
        { 0xf400,  0xf533,  2 },
        -- Font Awesome
        { 0xed00,  0xedff,  2 }, { 0xee0c, 0xefce, 2 }, { 0xf000, 0xf2ff, 2 },
      }
    end,
  })
  use({
    "https://github.com/rebelot/heirline.nvim.git",
    as = "heirline.nvim",
    requires = { "nightfox.nvim", "nvim-web-devicons" },
  })
  use({
    "https://github.com/OXY2DEV/markview.nvim.git",
    as = "markview.nvim",
    requires = { "nvim-treesitter", "nvim-web-devicons" },
    config = function()
      require("markview").setup({
        preview = {
          enable = true,
          filetypes = {
            "markdown",
          },
          ignore_buftypes = {},
        }
      })
    end,
  })
  use({
    "https://github.com/lewis6991/gitsigns.nvim.git",
    as = "gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  })
  use({
    "https://github.com/SmiteshP/nvim-navic.git",
    as = "nvim-navic",
    requires = { "nvim-lspconfig" },
    config = function()
      require("nvim-navic").setup({
        lsp = {
          auto_attach = true,
        },
        highlight = true,
        depth_limit = 12,
      })
    end,
  })
  use({
    "https://github.com/shellRaining/hlchunk.nvim.git",
    as = "hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("hlchunk").setup({
        chunk = {
          enable = true
        },
        indent = {
          enable = true,
        }
      })
    end,
  })
  use({
    "https://github.com/petertriho/nvim-scrollbar.git",
    as = "nvim-scrollbar",
    config = function()
      require("scrollbar").setup()
    end,
  })

  -- skk
  use({
    "https://github.com/vim-skk/skkeleton.git",
    as = "skkeleton",
    requires = { "denops.vim" },
    run = function()
      -- @class Dictionary
      -- @field url string ダウンロード用の URL 。
      -- @field name string 辞書の名前またはファイル名。
      -- @field encoding string ファイルのエンコーディング("euc-jp" | "utf-8")。

      -- 辞書設定のリスト。
      -- @type Dictionary[]
      local dicts = {
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.L",
          name = "SKK-JISYO.L",
          encoding = "euc-jp"
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.jinmei",
          name = "SKK-JISYO.jinmei",
          encoding = "euc-jp"
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.fullname",
          name = "SKK-JISYO.fullname",
          encoding = "euc-jp"
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.geo",
          name = "SKK-JISYO.geo",
          encoding = "euc-jp"
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.propernoun",
          name = "SKK-JISYO.propernoun",
          encoding = "euc-jp"
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.station",
          name = "SKK-JISYO.station",
          encoding = "euc-jp"
        },
        {
          url = "https://raw.githubusercontent.com/skk-dev/dict/refs/heads/master/SKK-JISYO.emoji",
          name = "SKK-JISYO.emoji",
          encoding = "utf-8"
        },
        {
          url = "https://raw.githubusercontent.com/ymrl/SKK-JISYO.emoji-ja/master/SKK-JISYO.emoji-ja.utf8",
          name = "SKK-JISYO.emoji-ja",
          encoding = "utf-8"
        },
      }

      -- 辞書の保存先。
      local dictDir = vim.fn.expand(vim.fn.stdpath("data") .. "/skkeleton")
      if vim.fn.isdirectory(dictDir) == 0 then
        vim.fn.mkdir(dictDir, "p")
      end

      for _, dict in ipairs(dicts) do
        local filepath = vim.fn.expand(dictDir .. "/" .. dict.name)

        local result = vim.system({
          "curl",
          "-L",
          "-f",
          "--silent",
          "--show-error",
          "-o", filepath,
          dict.url
        }, { text = true }):wait()

        if result.code == 0 then
          vim.notify(string.format("[skkeleton] dict download succeeded: %s", dict.url), vim.log.levels.INFO)
        else
          vim.notify(string.format("[skkeleton] dict download failed: %s", dict.url), vim.log.levels.ERROR)
        end
      end
    end,
    config = function()
      vim.fn["skkeleton#config"]({
        globalDictionaries = vim.fs.find(function()
          return true
        end, {
          path = vim.fn.expand(vim.fn.stdpath("data") .. "/skkeleton"),
          type = "file",
          limit = math.huge
        }),
        eggLikeNewline = true,
        keepState = true,
        showCandidatesCount = 2,
        registerConvertResult = true,
      })

      vim.keymap.set(
        { "i", "c", "t" },
        [[<C-j>]],
        [[<Plug>(skkeleton-toggle)]],
        { noremap = true, desc = "skkeleton toggle" }
      )
    end,
  })
  use({
    "https://github.com/NI57721/skkeleton-state-popup.git",
    as = "skkeleton-state-popup",
    requires = { "skkeleton" },
    config = function()
      vim.fn["skkeleton_state_popup#config"]({
        labels = {
          input = {
            hira = "かな",
            kata = "カナ",
            hankata = "ｶﾅ",
            zenkaku = "Ａ"
          },
          ["input:okurinasi"] = {
            hira = "▽",
            kata = "▽",
            hankata = "▽",
            abbrev = "ab"
          },
          ["input:okuriari"] = {
            hira = "▽",
            kata = "▽",
            hankata = "▽"
          },
          henkan = {
            hira = "▼",
            kata = "▼",
            hankata = "▼",
            abbrev = "ab"
          },
          latin = "_A",
        },
        opts = {
          relative = "cursor",
          col = 0,
          row = 1,
          anchor = "NW",
          zindex = 100,
          style = "minimal",
        },
      })
      vim.fn["skkeleton_state_popup#enable"]()
    end,
  })
  use({
    "https://github.com/uga-rosa/cmp-skkeleton.git",
    as = "cmp-skkeleton",
    requires = { "skkeleton" },
  })

  -- cmp:
  use({
    "https://github.com/hrsh7th/nvim-cmp.git",
    as = "nvim-cmp",
    requires = { "cmp-vsnip", "cmp-nvim-lsp", "cmp-skkeleton" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "vsnip" },
          { name = "skkeleton" },
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-l>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        experimental = {
          ghost_text = true,
        },
      })
    end,
  })

  -- langs:
  use({
    "https://github.com/yukpiz/vim-volt-syntax.git",
    as = "vim-volt-syntax",
  })
  use({
    "https://github.com/hat0uma/csvview.nvim.git",
    as = "csvview.nvim",
    config = function()
      require("csvview").setup();
    end,
  })
end)

for _, name in ipairs(jetpack.names()) do
  if not jetpack.tap(name) then
    jetpack.sync()
    break
  end
end
