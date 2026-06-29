return {
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
}
