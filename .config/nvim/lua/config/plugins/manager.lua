-- vim-jetpack のセットアップ。
local jetpackfile = vim.fn.stdpath("config") .. "/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim"
local jetpackurl = "https://raw.githubusercontent.com/tani/vim-jetpack/master/plugin/jetpack.vim"

if vim.fn.filereadable(jetpackfile) == 0 then
  vim.fn.system(string.format('curl -fsSLo %s --create-dirs %s', jetpackfile, jetpackurl))
end

vim.cmd("packadd vim-jetpack")

local jetpack = require("jetpack")

jetpack.begin(vim.fn.stdpath("config"))

jetpack.add("https://github.com/tani/vim-jetpack", {opt = true})
jetpack.add("https://github.com/rbtnn/vim-ambiwidth")

-- colorscheme:
jetpack.add("https://github.com/whatyouhide/vim-gotham")
jetpack.add("https://github.com/EdenEast/nightfox.nvim")
jetpack.add("https://github.com/rebelot/heirline.nvim")
