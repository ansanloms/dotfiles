local function dynamic_require(module)
  -- モジュールパスをファイルパスに変換。
  local module_path = module:gsub("%.", "/")
  local file_path = vim.fn.stdpath("config") .. "/lua/" .. module_path .. ".lua"

  if vim.fn.filereadable(file_path) == 1 then
    return require(module)
  end
end

-- general:
require("config.general")

-- mapping:
require("config.mapping")

-- plugins:
require("config.plugins")

-- langs:
require("config.langs")

-- appearance:
require("config.appearance.general")
require("config.appearance.colorscheme")
require("config.appearance.statusline")
--source ~/.config/vim/config/gui.vim
--source ~/.config/vim/config/statusline.vim
--source ~/.config/vim/config/appearance.vim


dynamic_require("temp")
dynamic_require("work")
