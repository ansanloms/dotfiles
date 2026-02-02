local M = {}

M.title = "📂 General"

M.tasks = {
  {
    name = "📄 Open Hosts",
    execute = function()
      if vim.fn.has("mac") == 1 then
        vim.cmd("edit " .. vim.fn.expand("/private/etc/hosts"))
      elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        vim.cmd("edit " .. vim.fn.expand("C:/Windows/System32/drivers/etc/hosts"))
      else
        vim.cmd("edit " .. vim.fn.expand("/etc/hosts"))
      end
    end,
  },
  {
    name = " Open current file by FileManager",
    execute = function()
      if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        vim.cmd("!start explorer.exe /select," .. vim.fn.expand("%:p"))
      elseif vim.fn.has("mac") == 1 then
        vim.cmd("!open " .. vim.fn.expand("%:p"))
      end
    end,
  },
  {
    name = " Open current file by BitBucket",
    execute = function()
      if vim.fn.executable("bb") == 1 then
        if vim.fn.line(".") == vim.fn.line("'<") then
          vim.cmd("!bb browse code " .. vim.fn.expand("%:p") .. " -l " .. vim.fn.line("'<") .. "-" .. vim.fn.line("'>"))
        else
          vim.cmd("!bb browse code " .. vim.fn.expand("%:p") .. " -l " .. vim.fn.line("."))
        end
      else
        vim.api.nvim_err_writeln("bb execute not found.")
      end
    end,
  },
  {
    name = " Open current file by VSCode",
    execute = function()
      if vim.fn.executable("code") == 1 then
        vim.cmd(
          "!code --goto "
            .. vim.fn.expand("%:p")
            .. ":"
            .. vim.fn.line(".")
            .. ":"
            .. vim.fn.col(".")
            .. " "
            .. vim.call("ansanloms#project#dir", vim.fn.expand("%:p"), vim.fn.expand("%:p"))
        )
      else
        vim.api.nvim_err_writeln("VSCode not found.")
      end
    end,
  },
  {
    name = " Open current file by PHPStorm",
    execute = function()
      if vim.fn.executable("phpstorm") == 1 then
        vim.cmd(
          "!start phpstorm "
            .. vim.call("ansanloms#project#dir", vim.fn.expand("%:p"), vim.fn.expand("%:p"))
            .. " --line "
            .. vim.fn.line(".")
            .. " --column "
            .. vim.fn.col(".")
            .. " "
            .. vim.fn.expand("%:p")
        )
      else
        vim.api.nvim_err_writeln("PHPStorm not found.")
      end
    end,
  },
}

return M
