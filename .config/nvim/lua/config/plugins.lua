local jetpackfile = vim.fn.stdpath("data") .. "/site/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim"
local jetpackurl = "https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim"

if vim.fn.filereadable(jetpackfile) == 0 then
  vim.fn.system(string.format("curl -fsSLo %s --create-dirs %s", jetpackfile, jetpackurl))
end

vim.cmd("packadd vim-jetpack")

require("jetpack.packer").add({
  -- plugin manager:
  {
    "tani/vim-jetpack",
    opt = true
  },

  -- general:
  { "vim-jp/vimdoc-ja" },
  { "vim-denops/denops.vim" },
  {
    "yukimemi/hitori.vim",
    config = function()
      vim.g.hitori_opener = "edit"
      vim.g.hitori_ignore_patterns = {
        "\\.tmp$",
        "\\.diff$",
        "(COMMIT_EDIT|TAG_EDIT|MERGE_|SQUASH_)MSG$",
        "\\/tmp\\/claude-prompt",
      }
    end,
  },
  {
    "APZelos/blamer.nvim",
    config = function()
      vim.g.blamer_enabled = true
    end,
  },
  {
    "kevinhwang91/nvim-hlslens",
    config = function()
      require("hlslens").setup()
    end,
  },
  { "MunifTanjim/nui.nvim" },
  { "rcarriga/nvim-notify" },
  {
    "folke/noice.nvim",
    config = function()
      require("noice").setup({
        cmdline = {
          enabled = true,
          view = "cmdline_popup",
        },
        messages = {
          enabled = true,
          view = "notify",
          view_error = "notify",
          view_warn = "notify",
          view_history = "messages",
          view_search = "virtualtext",
        },
        lsp = {
          progress = {
            enabled = true,
            format = "lsp_progress",
            format_done = "lsp_progress_done",
            throttle = 1000 / 30,
            view = "mini",
          },
          hover = {
            enabled = true,
            silent = false,
            view = nil,
            opts = {},
          },
        },
      })
    end,
  },

  -- telescope:
  { "nvim-lua/plenary.nvim" },
  {
    "nvim-telescope/telescope.nvim",
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
            },
            n = {
              ["<esc>"] = actions.close,
            },
          },
        },
      })

      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope oldfiles" })
      vim.keymap.set("n", "<leader>fs", builtin.git_status, { desc = "Telescope git status" })
      vim.keymap.set("n", "<leader>fl", launcher(require("config.launcher")), { desc = "Telescope launcher" })
    end,
  },

  -- quickrun:
  { "thinca/vim-quickrun" },

  -- snippet:
  {
    "hrsh7th/vim-vsnip",
    config = function()
      vim.g.vsnip_snippet_dir = vim.fn.expand("~/.config/nvim/snippets")

      vim.g.vsnip_filetypes = {}
      vim.g.vsnip_filetypes.typescript = { "javascript" }
      vim.g.vsnip_filetypes.vue = { "javascript", "typescript" }
      vim.g.vsnip_filetypes.javascriptreact = { "javascript" }
      vim.g.vsnip_filetypes.typescriptreact = { "javascript", "typescript" }
    end,
  },

  -- lsp:
  { "neovim/nvim-lspconfig" },
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "eslint",
          "denols",
          "vtsls",
          "vue_ls",
          "docker_language_server",
          "phpactor",
          "jsonls",
          "lua_ls",
          "efm",
        },
      })
    end,
  },
  {
    "nvimdev/lspsaga.nvim",
    config = function()
      require("lspsaga").setup({})
    end,
  },

  -- appearance:
  { "whatyouhide/vim-gotham" },
  { "EdenEast/nightfox.nvim" },
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
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
  },
  { "nvim-treesitter/nvim-treesitter-context" },
  {
    "rbtnn/vim-ambiwidth",
    setup = function()
      vim.g.ambiwidth_cica_enabled = false

      vim.g.ambiwidth_add_list = {
        -- Seti-UI + Custom
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
  },
  { "rebelot/heirline.nvim" },
  {
    "OXY2DEV/markview.nvim",
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
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
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
  },
  {
    "shellRaining/hlchunk.nvim",
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
  },
  {
    "petertriho/nvim-scrollbar",
    config = function()
      require("scrollbar").setup()
    end,
  },

  -- skk:
  {
    "vim-skk/skkeleton",
    run = function()
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
  },
  {
    "NI57721/skkeleton-state-popup",
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
  },
  {
    "NI57721/skkeleton-henkan-highlight",
    config = function()
      vim.cmd("highlight SkkeletonHenkan gui=underline term=underline cterm=reverse")
    end,
  },
  { "Xantibody/blink-cmp-skkeleton" },

  -- cmp:
  {
    "saghen/blink.cmp",
    run = function()
      local plugin_path = vim.fn.stdpath("data") .. "/site/pack/jetpack/opt/blink.cmp"
      vim.api.nvim_echo({ { "[blink.cmp] Building Rust fuzzy matcher... (this may take a while)", "WarningMsg" } }, true,
        {})
      vim.cmd("redraw")

      local result = vim.system({
        "cargo", "build", "--release"
      }, { cwd = plugin_path, text = true }):wait()

      if result.code == 0 then
        vim.notify("[blink.cmp] Build succeeded!", vim.log.levels.INFO)
      else
        vim.notify("[blink.cmp] Build failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
      end
    end,
    config = function()
      require("blink.cmp").setup({
        -- スニペット設定（vim-vsnip を使用）
        snippets = {
          preset = "vsnip",
        },

        -- キーマッピング
        keymap = {
          preset = "none",
          ["<C-p>"] = { "select_prev", "fallback" },
          ["<C-n>"] = { "select_next", "fallback" },
          ["<C-k>"] = { "select_prev", "fallback" },
          ["<C-j>"] = { "select_next", "fallback" },
          ["<Up>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
          ["<C-l>"] = { "show", "fallback" },
          ["<C-e>"] = { "hide", "fallback" },
          ["<CR>"] = { "accept", "fallback" },
          ["<Space>"] = {} -- Required: Let skkeleton handle Space
        },

        -- 補完ソース
        sources = {
          default = function()
            if require("blink-cmp-skkeleton").is_enabled() then
              return { "skkeleton" }
            else
              return { "lsp", "path", "snippets", "buffer" }
            end
          end,
          providers = {
            skkeleton = {
              name = "skkeleton",
              module = "blink-cmp-skkeleton",
            },
            path = {
              opts = {
                -- pwd からのパス補完を有効にする（デフォルトはバッファのディレクトリ）
                get_cwd = function(_)
                  return vim.fn.getcwd()
                end,
                -- ドットファイル（隠しファイル）を補完候補に表示する
                show_hidden_files_by_default = true,
              },
            },
          },
        },

        -- 補完メニュー設定
        completion = {
          ghost_text = {
            enabled = true,
          },
          menu = {
            auto_show = true,
          },
        },

        -- シグネチャヘルプ（トリガー文字で自動表示）
        signature = {
          enabled = true,
          trigger = {
            enabled = true,
            show_on_trigger_character = true,
          },
        },
      })
    end,
  },

  -- langs:
  { "yukpiz/vim-volt-syntax" },
  {
    "hat0uma/csvview.nvim",
    config = function()
      require("csvview").setup()
    end,
  },
})

local jetpack = require("jetpack")
for _, name in ipairs(jetpack.names()) do
  if not jetpack.tap(name) then
    jetpack.sync()
    break
  end
end
