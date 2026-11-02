return {
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
}
