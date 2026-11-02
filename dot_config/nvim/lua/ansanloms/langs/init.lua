-- 言語固有の設定を読み込む。
-- langs/ ディレクトリ内の *.lua を走査して自動で require する
-- (init.lua 自身は除外)。新しい言語設定はファイルを置くだけで読み込まれる。
local langs_dir = vim.fn.stdpath("config") .. "/lua/ansanloms/langs"
for _, file in ipairs(vim.fn.readdir(langs_dir)) do
  local name = file:match("^(.+)%.lua$")
  if name and name ~= "init" then
    require("ansanloms.langs." .. name)
  end
end
