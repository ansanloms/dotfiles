local jetpackfile = vim.fn.stdpath("data") .. "/site/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim"
local jetpackurl = "https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim"
if vim.fn.filereadable(jetpackfile) == 0 then
  vim.fn.system(string.format("curl -fsSLo %s --create-dirs %s", jetpackfile, jetpackurl))
end

vim.cmd("packadd vim-jetpack")

local jetpack = require("jetpack")
local jetpackPacker = require("jetpack.packer")

jetpackPacker.add({
  -- plugin manager:
  {
    "https://github.com/tani/vim-jetpack.git",
    as = "vim-jetpack",
    opt = true
  },

  -- general:
  {
    "https://github.com/vim-jp/vimdoc-ja.git",
    as = "vimdoc-ja"
  },
  {
    "https://github.com/vim-denops/denops.vim.git",
    as = "denops.vim"
  },
  {
    "https://github.com/yukimemi/hitori.vim.git",
    as = "hitori.vim",
    requires = "denops.vim",
    config = function()
      vim.g.hitori_opener = "edit"
    end,
  },

  -- telescope:
  { "https://github.com/nvim-lua/plenary.nvim.git", as = "plenary.nvim" },
  {
    "https://github.com/nvim-telescope/telescope.nvim.git",
    as = "telescope.nvim",
    requires = "plenary.nvim",
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
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope oldfiles" })
      vim.keymap.set("n", "<leader>fl", launcher(require("config.launcher")), { desc = "Telescope launcher" })
    end,
  },

  -- quickrun:
  {
    "https://github.com/thinca/vim-quickrun.git",
    as = "vim-quickrun",
  },

  -- snippet:
  {
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
  },
  {
    "https://github.com/hrsh7th/vim-vsnip-integ.git",
    as = "vim-vsnip-integ",
    requires = { "vim-vsnip" },
  },

  -- cmp:
  {
    "https://github.com/hrsh7th/cmp-vsnip.git",
    as = "cmp-vsnip",
    requires = { "vim-vsnip" },
  },
  {
    "https://github.com/hrsh7th/cmp-nvim-lsp.git",
    as = "cmp-nvim-lsp",
  },
  {
    "https://github.com/hrsh7th/nvim-cmp.git",
    as = "nvim-cmp",
    requires = { "cmp-vsnip", "cmp-nvim-lsp" },
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
  },

  -- lsp:
  {
    "https://github.com/neovim/nvim-lspconfig.git",
    as = "nvim-lspconfig",
  },
  {
    "https://github.com/williamboman/mason.nvim.git",
    as = "mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "https://github.com/williamboman/mason-lspconfig.nvim.git",
    as = "mason-lspconfig.nvim",
    requires = { "nvim-lspconfig", "mason.nvim", "cmp-nvim-lsp" },
  },

  -- ai-chat:
  {
    "https://github.com/ansanloms/vim-ramble.git",
    as = "vim-ramble",
    requires = { "denops.vim" },
    config = function()
      local augroupRambleChat = vim.api.nvim_create_augroup("ramble-chat", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = augroupRambleChat,
        pattern = "ramble-chat",
        callback = function()
          vim.keymap.set("n", "<C-@>", function()
            vim.fn["denops#request"]("ramble", "chat", { vim.api.nvim_get_current_buf() })
          end, { buffer = true })

          vim.keymap.set("n", "<C-Space>", function()
            vim.fn["denops#request"]("ramble", "chat", { vim.api.nvim_get_current_buf() })
          end, { buffer = true })
        end,
      })
    end,
  },

  -- appearance:
  {
    "https://github.com/whatyouhide/vim-gotham.git",
    as = "vim-gotham",
  },
  {
    "https://github.com/EdenEast/nightfox.nvim.git",
    as = "nightfox.nvim",
  },
  {
    "https://github.com/nvim-tree/nvim-web-devicons.git",
    as = "nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup()
    end,
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter.git",
    as = "nvim-treesitter",
    run = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
      })
    end,
  },
  {
    "https://github.com/nvim-treesitter/nvim-treesitter-context.git",
    as = "nvim-treesitter-context",
    requires = { "nvim-treesitter" },
  },
  {
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
  },
  {
    "https://github.com/rebelot/heirline.nvim.git",
    as = "heirline.nvim",
    requires = { "nightfox.nvim", "nvim-web-devicons" },
    config = function() end,
  },
  {
    "https://github.com/OXY2DEV/markview.nvim.git",
    as = "markview.nvim",
    requires = { "nvim-treesitter", "nvim-web-devicons" },
    config = function()
      require("markview").setup({
        preview = {
          enable = true,
          filetypes = {
            "markdown",
            "md",
            "ramble-chat",
          },
          ignore_buftypes = {},
        }
      })
    end,
  },
  {
    "https://github.com/lewis6991/gitsigns.nvim.git",
    as = "gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  {
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
  },
  {
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
  },
  {
    "https://github.com/petertriho/nvim-scrollbar.git",
    as = "nvim-scrollbar",
    config = function()
      require("scrollbar").setup()
    end,
  }
})

for _, name in ipairs(jetpack.names()) do
  if not jetpack.tap(name) then
    jetpack.sync()
    break
  end
end
