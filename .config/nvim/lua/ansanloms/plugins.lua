-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- general:
  { "vim-jp/vimdoc-ja" },
  { "vim-denops/denops.vim" },
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
      vim.keymap.set("n", "<leader>fl", launcher(require("ansanloms.launcher")), { desc = "Telescope launcher" })
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
  },
  {
    "nvimdev/lspsaga.nvim",
    config = function()
      require("lspsaga").setup({})
    end,
  },

  -- appearance:
  {
    "whatyouhide/vim-gotham",
  },
  {
    "EdenEast/nightfox.nvim",
  },
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({
        install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
      })

      if vim.fn.executable("tree-sitter") == 1 then
        ts.install({
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
          "nix",
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
          generate = false,
          max_jobs = 4,
          summary = false,
        })
      end
    end,
  },
  { "nvim-treesitter/nvim-treesitter-context" },
  {
    "rbtnn/vim-ambiwidth",
    init = function()
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
        -- Font Logos @see https://github.com/lukas-w/font-logos
        -- 0xf315-0xf316 / 0xf31b-0xf31c は vim-ambiwidth 本体が常時定義済みの為、重複を避けて分割する。
        { 0xf300, 0xf314, 2 }, { 0xf317, 0xf31a, 2 }, { 0xf31d, 0xf381, 2 },
        -- Geometric Shapes @see https://www.unicode.org/charts/PDF/U25A0.pdf
        { 0x25a2, 0x25a9, 2 }, { 0x25ac, 0x25b3, 2 }, { 0x25b6, 0x25b7, 2 }, { 0x25bc, 0x25bd, 2 }, { 0x25c0, 0x25c1, 2 },
        { 0x25c8, 0x25c9, 2 }, { 0x25d0, 0x25d7, 2 }, { 0x25e2, 0x25e5, 2 }, { 0x25e7, 0x25ef, 2 }, { 0x25f0, 0x25ff, 2 },
        -- Mathematical Operators @see https://www.unicode.org/charts/PDF/U2200.pdf
        { 0x2200, 0x2265, 2 }, { 0x2268, 0x22ff, 2 },
        -- Miscellaneous Technical @see https://www.unicode.org/charts/PDF/U2300.pdf
        { 0x2300, 0x23FF, 2 },
        -- General Punctuation @see https://www.unicode.org/charts/PDF/U2000.pdf
        { 0x2025, 0x2027, 2 },
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
      require("gitsigns").setup({
        current_line_blame = true,
        current_line_blame_opts = {
          delay = 1000,
          virt_text_pos = "eol",
        },
        current_line_blame_formatter = "   <author>, <author_time:%Y/%m/%d %H:%M> - <summary>",
      })
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
    dependencies = { "vim-denops/denops.vim" },
    build = function()
      local dicts = {
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.L",
          name = "SKK-JISYO.L",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.jinmei",
          name = "SKK-JISYO.jinmei",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.fullname",
          name = "SKK-JISYO.fullname",
          encoding = "euc-jis-2004",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.geo",
          name = "SKK-JISYO.geo",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.propernoun",
          name = "SKK-JISYO.propernoun",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.station",
          name = "SKK-JISYO.station",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.law",
          name = "SKK-JISYO.law",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.assoc",
          name = "SKK-JISYO.assoc",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.edict2",
          name = "SKK-JISYO.edict2",
          encoding = "utf-8",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.itaiji",
          name = "SKK-JISYO.itaiji",
          encoding = "euc-jp",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.itaiji.JIS3_4",
          name = "SKK-JISYO.itaiji.JIS3_4",
          encoding = "euc-jis-2004",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.emoji",
          name = "SKK-JISYO.emoji",
          encoding = "utf-8",
        },
        {
          url = "https://github.com/ymrl/SKK-JISYO.emoji-ja/raw/refs/heads/master/SKK-JISYO.emoji-ja.utf8",
          name = "SKK-JISYO.emoji-ja",
          encoding = "utf-8",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/zipcode/SKK-JISYO.zipcode",
          name = "SKK-JISYO.zipcode",
          encoding = "euc-jis-2004",
        },
        {
          url = "https://github.com/skk-dev/dict/raw/refs/heads/master/zipcode/SKK-JISYO.office.zipcode",
          name = "SKK-JISYO.office.zipcode",
          encoding = "euc-jis-2004",
        },
        {
          url = "https://github.com/ansanloms/skk-dict-mountain/releases/latest/download/SKK-JISYO.mountain",
          name = "SKK-JISYO.mountain",
          encoding = "utf-8",
        },
      }

      local dictDir = vim.fn.expand(vim.fn.stdpath("data") .. "/skkeleton")
      if vim.fn.isdirectory(dictDir) == 0 then
        vim.fn.mkdir(dictDir, "p")
      end

      -- 辞書ファイルの文字コードから iconv の変換元コードへの対応表。
      -- skkeleton はロード時に euc-jp を pure-JS でデコードするため遅い。
      -- ビルド時に UTF-8 へ寄せておき、ロードをネイティブデコード経路に乗せる。
      -- euc-jis-2004 は TextDecoder が非対応で、UTF-8 化しておかないとロードに失敗する。
      local iconvFrom = {
        ["euc-jp"] = "EUC-JP",
        ["euc-jis-2004"] = "EUC-JISX0213",
        ["utf-8"] = false,
      }

      for _, dict in ipairs(dicts) do
        local filepath = vim.fn.expand(dictDir .. "/" .. dict.name)
        local from = iconvFrom[dict.encoding]

        if not from then
          -- 既に UTF-8。直接ダウンロードする。
          vim.system({
            "curl", "-L", "-f", "--silent", "--show-error",
            "-o", filepath, dict.url,
          }, { text = true }, function(result)
            vim.schedule(function()
              if result.code == 0 then
                vim.notify(string.format("[skkeleton] dict download succeeded: %s", dict.url), vim.log.levels.INFO)
              else
                vim.notify(string.format("[skkeleton] dict download failed: %s", dict.url), vim.log.levels.ERROR)
              end
            end)
          end)
        else
          -- ダウンロード後、iconv で UTF-8 へ変換する。
          local tmp = filepath .. ".raw"
          vim.system({
            "curl", "-L", "-f", "--silent", "--show-error",
            "-o", tmp, dict.url,
          }, { text = true }, function(dl)
            vim.schedule(function()
              if dl.code ~= 0 then
                vim.notify(string.format("[skkeleton] dict download failed: %s", dict.url), vim.log.levels.ERROR)
                return
              end
              vim.system({
                "iconv", "-f", from, "-t", "UTF-8", "-o", filepath, tmp,
              }, { text = true }, function(conv)
                vim.schedule(function()
                  vim.fn.delete(tmp)
                  if conv.code == 0 then
                    vim.notify(string.format("[skkeleton] dict converted to utf-8: %s", dict.name), vim.log.levels.INFO)
                  else
                    vim.notify(string.format("[skkeleton] dict iconv failed: %s", dict.name), vim.log.levels.ERROR)
                  end
                end)
              end)
            end)
          end)
        end
      end
    end,
    config = function()
      vim.fn["skkeleton#config"]({
        globalDictionaries = vim.tbl_map(function(path)
          -- ビルド時に全辞書を UTF-8 化済み。encoding を明示することで
          -- skkeleton 側の per-file エンコーディング判定 (encoding.detect) を省く。
          return { path, "utf-8" }
        end, vim.fs.find(function(name)
          -- 変換失敗時に残る .raw を辞書として拾わない。
          return not name:match("%.raw$")
        end, {
          path = vim.fn.expand(vim.fn.stdpath("data") .. "/skkeleton"),
          type = "file",
          limit = math.huge
        })),
        eggLikeNewline = true,
        keepState = true,
        showCandidatesCount = 2,
        registerConvertResult = true,
      })

      -- 辞書ロードは初回変換時まで遅延される (skkeleton の LazyCell)。
      -- 初期化完了直後に裏でロードを発火し、初回入力のレイテンシを起動直後へ移す。
      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-post",
        callback = function()
          vim.fn["skkeleton#notify_async"]("initialize", {})
        end,
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
    version = "1.*",
    config = function()
      require("blink.cmp").setup({
        -- fuzzy matcher 設定
        fuzzy = {
          implementation = "prefer_rust_with_warning",
        },

        -- スニペット設定（vim-vsnip を使用）
        snippets = {
          preset = "vsnip",
        },

        -- キーマッピング
        keymap = {
          preset = "none",
          ["<C-p>"] = { "select_prev", "fallback" },
          ["<C-n>"] = { "select_next", "fallback" },
          --["<C-k>"] = { "select_prev", "fallback" },
          --["<C-j>"] = { "select_next", "fallback" },
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
              return { "lsp", "path", "snippets" }
            end
          end,
          providers = {
            skkeleton = {
              name = "skkeleton",
              module = "blink-cmp-skkeleton",
            },
            path = {
              opts = {
                get_cwd = function(context)
                  local col = context.bounds.start_col - (context.bounds.length == 0 and 1 or 0)
                  local before = context.line:sub(1, col)

                  -- ./ や ../ で始まるパスはバッファのディレクトリ起点
                  if before:match('%./$') or before:match('%.%./$') then
                    return vim.fn.expand(('#%d:p:h'):format(context.bufnr))
                  end

                  -- それ以外（/ 含む）は pwd 起点
                  return vim.fn.getcwd()
                end,
                -- / をルート(/)ではなく get_cwd() 起点にする
                ignore_root_slash = true,
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
  {
    "yaegassy/nette-neon.vim"
  },
})
