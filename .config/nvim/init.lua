local function dynamic_require(module)
  -- モジュールパスをファイルパスに変換。
  local module_path = module:gsub("%.", "/")
  local file_path = vim.fn.stdpath("config") .. "/lua/" .. module_path .. ".lua"

  if vim.fn.filereadable(file_path) == 1 then
    return require(module)
  end
end

-- singleton:
require("ansanloms.singleton").setup()

-- general:
require("ansanloms.general")
require("ansanloms.im")
require("ansanloms.clipboard")

-- mapping:
require("ansanloms.mapping")

-- plugins:
require("ansanloms.plugins")

-- lsp:
require("ansanloms.lsp")

-- langs:
require("ansanloms.langs")

-- appearance:
require("ansanloms.appearance.general")
require("ansanloms.appearance.colorscheme")
require("ansanloms.appearance.statusline")

dynamic_require("temp")
dynamic_require("work")
