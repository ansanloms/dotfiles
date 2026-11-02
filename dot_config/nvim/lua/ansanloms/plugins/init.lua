-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- プラグイン spec は specs/ 配下の各ファイルが return する。
-- lazy.nvim の import 機構が specs/ 内の *.lua を自動で読み込むため、
-- 新しいプラグインはファイルを置くだけで読み込まれる。
--
-- 各ファイルの return は次のどちらでもよい (lazy が [1] の型で自動判別する)。
--   - 単一プラグイン: return { "owner/repo", config = ... }       (原則こちら。1 プラグイン 1 ファイル)
--   - 複数プラグイン: return { { "owner/a" }, { "owner/b" } }      (関連プラグインをまとめたい場合)
-- ファイル名のドットは不可 (require のモジュール区切りと衝突する)。`.` は `-` に置換する。
require("lazy").setup({
  spec = {
    { import = "ansanloms.plugins.specs" },
  },
})
