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
  { "https://github.com/tani/vim-jetpack.git", as = "vim-jetpack", opt = true },

  -- general:
  { "https://github.com/vim-jp/vimdoc-ja.git", as = "vimdoc-ja" },
  { "https://github.com/vim-denops/denops.vim.git", as = "denops.vim" },
  { "https://github.com/ansanloms/vim-ime-set.git", as = "vim-ime-set", requires = "denops.vim" },

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
      vim.keymap.set("n", "<leader>fl", launcher(require("config.launcher.init")), { desc = "Telescope launcher" })
    end
  },

  -- appearance:
  { "https://github.com/whatyouhide/vim-gotham.git", as = "vim-gotham" },
  { "https://github.com/EdenEast/nightfox.nvim.git", as = "nightfox.nvim" },
  { "https://github.com/rebelot/heirline.nvim.git", as = "heirline.nvim", requires = "nightfox.nvim" },
  { "https://github.com/nvim-treesitter/nvim-treesitter.git", as = "nvim-treesitter", run = ":TSUpdatl" },
  {
    "https://github.com/rbtnn/vim-ambiwidth.git",
    as = "vim-ambiwidth",
    setup = function()
      -- Nerd Fonts 関連の設定。
      -- Nerd Fonts Seti-UI + Custom (0xe5fa-0xe62b,0xe62e は元々対応されてる)
      -- Nerd Fonts Devicons (0xe700-0xe7c5 は元々対応されてる)
      -- Nerd Fonts Material Design Icons
      -- Nerd Fonts Codicons
      vim.g.ambiwidth_add_list = {
        { 0xe62c, 0xe62d, 2 }, { 0xe62f, 0xe6b7, 2 },
        { 0xe7c6, 0xe8ef, 2 },
        { 0xf0001, 0xf1af0, 2 },
        { 0xea60, 0xec1e, 2 },
      }
    end
  },

  -- ai-chat:
  {
    "https://github.com/ansanloms/vim-ramble.git",
    as = "vim-ramble",
    requires = "denops.vim",
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
        end
      })
    end },
})

for _, name in ipairs(jetpack.names()) do
  if not jetpack.tap(name) then
    jetpack.sync()
    break
  end
end
