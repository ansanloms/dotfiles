local launcher = require("telescope-launcher")

local M = {}

M.title = "Launcher"
M.tasks = {}

local current_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local config_files = vim.fn.glob(current_dir .. "/*.lua", false, true)

for _, file_path in ipairs(config_files) do
  local file_name = vim.fn.fnamemodify(file_path, ":t:r")

  if file_name ~= "init" then
    local config =require("config.launcher." .. file_name)

    table.insert(M.tasks, {
      name = config.title,
      execute = function ()
        launcher(config)()
      end
    })
  end
end

return M
