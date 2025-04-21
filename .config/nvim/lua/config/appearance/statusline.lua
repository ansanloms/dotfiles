local utils = require("heirline.utils")
local conditions = require("heirline.conditions")

-- Terafox パレットを取得。
local palette = require("nightfox.palette").load("terafox")

-- 色設定。
local colors = {
  diag_warn = utils.get_highlight("DiagnosticWarn").fg,
  diag_error = utils.get_highlight("DiagnosticError").fg,
  diag_hint = utils.get_highlight("DiagnosticHint").fg,
  diag_info = utils.get_highlight("DiagnosticInfo").fg,
  diag_ok = utils.get_highlight("DiagnosticOk").fg,
  git_del = utils.get_highlight("diffRemoved").fg,
  git_add = utils.get_highlight("diffAdded").fg,
  git_change = utils.get_highlight("diffChanged").fg,
}

for color_name, color in pairs(palette) do
  if type(color) == "string" then
    colors[color_name] = color
  elseif type(color) == "table" then
    colors[color_name .. "_base"] = color["base"]
    colors[color_name .. "_bright"] = color["bright"]
    colors[color_name .. "_dim"] = color["dim"]
  end
end

local ViMode = {
  -- get vim current mode, this information will be required by the provider
  -- and the highlight functions, so we compute it only once per component
  -- evaluation and store it as a component attribute
  init = function(self)
    self.mode = vim.fn.mode(1) -- :h mode()
  end,

  -- Now we define some dictionaries to map the output of mode() to the
  -- corresponding string and color. We can put these into `static` to compute
  -- them at initialisation time.
  static = {
    names = { -- change the strings if you like it vvvvverbose!
      n = "N",
      no = "N?",
      nov = "N?",
      noV = "N?",
      ["no\22"] = "N?",
      niI = "Ni",
      niR = "Nr",
      niV = "Nv",
      nt = "Nt",
      v = "V",
      vs = "Vs",
      V = "V_",
      Vs = "Vs",
      ["\22"] = "^V",
      ["\22s"] = "^V",
      s = "S",
      S = "S_",
      ["\19"] = "^S",
      i = "I",
      ic = "Ic",
      ix = "Ix",
      R = "R",
      Rc = "Rc",
      Rx = "Rx",
      Rv = "Rv",
      Rvc = "Rv",
      Rvx = "Rv",
      c = "C",
      cv = "Ex",
      r = "...",
      rm = "M",
      ["r?"] = "?",
      ["!"] = "!",
      t = "T",
    },
    colors = {
      n = { fg = colors.blue_bright, bg = colors.blue_dim },
      i = { fg = colors.green_bright, bg = colors.green_dim },
      v = { fg = colors.magenta_bright, bg = colors.magenta_dim },
      V = { fg = colors.magenta_bright, bg = colors.magenta_dim },
      ["\22"] = { fg = colors.cyan_bright, bg = colors.cyan_dim },
      c = { fg = colors.orange_bright, bg = colors.orange_dim },
      s = { fg = colors.cyan_bright, bg = colors.cyan_dim },
      S = { fg = colors.cyan_bright, bg = colors.cyan_dim },
      ["\19"] = { fg = colors.magenta_bright, bg = colors.magenta_dim },
      R = { fg = colors.red_bright, bg = colors.red_dim },
      r = { fg = colors.red_bright, bg = colors.red_dim },
      ["!"] = { fg = colors.orange_bright, bg = colors.orange_dim },
      t = { fg = colors.white_bright, bg = colors.white_dim },
    },
  },

  -- We can now access the value of mode() that, by now, would have been
  -- computed by `init()` and use it to index our strings dictionary.
  -- note how `static` fields become just regular attributes once the
  -- component is instantiated.
  -- To be extra meticulous, we can also add some vim statusline syntax to
  -- control the padding and make sure our string is always at least 2
  -- characters long. Plus a nice Icon.
  provider = function(self)
    return " %2(" .. self.names[self.mode] .. "%) "
  end,

  -- Same goes for the highlight. Now the foreground will change according to the current mode.
  hl = function(self)
    local mode = self.mode:sub(1, 1) -- get only the first mode character
    return { fg = self.colors[mode].fg, bg = self.colors[mode].bg }
  end,

  -- Re-evaluate the component only on ModeChanged event!
  -- Also allows the statusline to be re-evaluated when entering operator-pending mode
  update = {
    "ModeChanged",
    pattern = "*:*",
    callback = vim.schedule_wrap(function()
      vim.cmd("redrawstatus")
    end),
  },
}

local Git = {
  condition = conditions.is_git_repo,

  init = function(self)
    self.status_dict = vim.b.gitsigns_status_dict
    self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
  end,

  hl = { fg = "orange" },

  { -- git branch name
    provider = function(self)
      return "" .. self.status_dict.head
    end,
    hl = { bold = true },
  },

  -- You could handle delimiters, icons and counts similar to Diagnostics
  {
    condition = function(self)
      return self.has_changes
    end,
    provider = "(",
  },
  {
    provider = function(self)
      local count = self.status_dict.added or 0
      return count > 0 and ("+" .. count)
    end,
    hl = { fg = "git_add" },
  },
  {
    provider = function(self)
      local count = self.status_dict.removed or 0
      return count > 0 and ("-" .. count)
    end,
    hl = { fg = "git_del" },
  },
  {
    provider = function(self)
      local count = self.status_dict.changed or 0
      return count > 0 and ("~" .. count)
    end,
    hl = { fg = "git_change" },
  },
  {
    condition = function(self)
      return self.has_changes
    end,
    provider = ")",
  },
}

local FileIcon = {
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(0)
    local filename = self.filename
    local extension = vim.fn.fnamemodify(filename, ":e")
    self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
  end,

  provider = function(self)
    return self.icon
  end,

  hl = function(self)
    return { fg = self.icon_color }
  end,
}

local FileName = {
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(0)
  end,

  provider = function(self)
    -- first, trim the pattern relative to the current directory. For other
    -- options, see :h filename-modifers
    local filename = vim.fn.fnamemodify(self.filename, ":.")
    if filename == "" then
      return "[No Name]"
    end

    -- now, if the filename would occupy more than 1/4th of the available
    -- space, we trim the file path to its initials
    -- See Flexible Components section below for dynamic truncation
    if not conditions.width_percent_below(#filename, 0.25) then
      filename = vim.fn.pathshorten(filename)
    end

    return filename
  end,

  hl = { fg = utils.get_highlight("Directory").fg },
}

local FileFlags = {
  {
    condition = function()
      return vim.bo.modified
    end,
    provider = "[+]",
    hl = { fg = "green" },
  },
  {
    condition = function()
      return not vim.bo.modifiable or vim.bo.readonly
    end,
    provider = "",
    hl = { fg = "orange" },
  },
}

local LSPActive = {
  condition = conditions.lsp_attached,
  update = { "LspAttach", "LspDetach" },

  provider = function()
    local names = {}
    for i, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
      table.insert(names, server.name)
    end
    return "[" .. table.concat(names, " ") .. "]"
  end,

  hl = { fg = "green", bold = true },
}

local Ruler = {
  -- %l = current line number
  -- %L = number of lines in the buffer
  -- %c = column number
  -- %P = percentage through file of displayed window
  provider = "%7(%l/%3L%):%2c %P",
}

local ScrollBar = {
  static = {
    sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
  },

  provider = function(self)
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_line_count(0)
    local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
    return string.rep(self.sbar[i], 2)
  end,

  hl = { fg = "blue_bright", bg = "blue_dim" },
}

local Navic = {
  condition = function()
    return require("nvim-navic").is_available()
  end,

  provider = function()
    return require("nvim-navic").get_location({ highlight = true })
  end,

  update = "CursorMoved",
}

local TablineFlags = {
  {
    condition = function(self)
      local wins = vim.api.nvim_tabpage_list_wins(self.tabpage)
      local active_win_id = vim.api.nvim_tabpage_get_win(self.tabpage)
      local buf_id = vim.api.nvim_win_get_buf(active_win_id)
      return vim.api.nvim_get_option_value("modified", { buf = buf_id })
    end,
    provider = "[+]",
    hl = function(self)
      return { fg = "green" }
    end,
  },
  {
    condition = function(self)
      local wins = vim.api.nvim_tabpage_list_wins(self.tabpage)
      local active_win_id = vim.api.nvim_tabpage_get_win(self.tabpage)
      local buf_id = vim.api.nvim_win_get_buf(active_win_id)

      return not vim.api.nvim_get_option_value("modifiable", { buf = buf_id })
        or vim.api.nvim_get_option_value("readonly", { buf = buf_id })
    end,

    provider = function(self)
      local wins = vim.api.nvim_tabpage_list_wins(self.tabpage)
      local active_win_id = vim.api.nvim_tabpage_get_win(self.tabpage)
      local buf_id = vim.api.nvim_win_get_buf(active_win_id)

      if vim.api.nvim_get_option_value("buftype", { buf = buf_id }) == "terminal" then
        return ""
      else
        return ""
      end
    end,

    hl = function(self)
      return { fg = "orange" }
    end,
  },
}

local TablineFileIcon = {
  init = function(self)
    local active_win_id = vim.api.nvim_tabpage_get_win(self.tabpage)
    local buf_id = vim.api.nvim_win_get_buf(active_win_id)
    local filepath = vim.api.nvim_buf_get_name(buf_id)
    local filename = vim.fn.fnamemodify(filepath, ":t")
    local extension = vim.fn.fnamemodify(filename, ":e")
    self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
  end,

  provider = function(self)
    return self.icon
  end,

  hl = function(self)
    return { fg = self.icon_color }
  end,
}

local Tabpage = {
  provider = function(self)
    local active_win_id = vim.api.nvim_tabpage_get_win(self.tabpage)
    local buf_id = vim.api.nvim_win_get_buf(active_win_id)
    local filepath = vim.api.nvim_buf_get_name(buf_id)
    local filename = vim.fn.fnamemodify(filepath, ":t")

    filename = filename == "" and "No Name" or filename

    return filename
  end,

  hl = function(self)
    if self.is_active then
      return { fg = utils.get_highlight("TabLineSel").fg }
    else
      return { fg = utils.get_highlight("TabLine").fg }
    end
  end,
}

local TablineBlock = utils.surround({ " ", " " }, function(self)
  if self.is_active then
    return utils.get_highlight("TabLineSel").bg
  else
    return utils.get_highlight("TabLine").bg
  end
end, { TablineFileIcon, Tabpage, TablineFlags })

local TabPages = {
  -- only show this component if there's 2 or more tabpages
  condition = function()
    return #vim.api.nvim_list_tabpages() >= 2
  end,
  utils.make_tablist(TablineBlock),
}

require("heirline").setup({
  statusline = {
    { ViMode, { provider = " " }, Git, { provider = " " }, FileIcon, { provider = " " }, FileName, FileFlags },
    { provider = "%=" },
    { LSPActive, { provider = " " }, Ruler, { provider = " " }, ScrollBar },
  },
  winbar = { Navic },
  tabline = { TabPages },
  opts = { colors = colors },
})
