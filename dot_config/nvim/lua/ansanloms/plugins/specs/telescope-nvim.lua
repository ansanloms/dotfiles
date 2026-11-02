return {
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
}
