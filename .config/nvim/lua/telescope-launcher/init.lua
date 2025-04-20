local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local launcher = function(config, opts)
  return function(opts)
    opts = opts or {}

    pickers.new(opts, {
      prompt_title = config.title,
      finder = finders.new_table {
        results = config.tasks,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          selection.value.execute()
        end)
        return true
      end,
    }):find()
  end
end

return launcher
