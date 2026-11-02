-- 設定のホットリロード。
-- ansanloms 名前空間のモジュールキャッシュを破棄してから init.lua を再評価し、
-- nvim を再起動せずに設定変更を反映する。
local function reload()
  for name, _ in pairs(package.loaded) do
    if name:match("^ansanloms") then
      package.loaded[name] = nil
    end
  end

  dofile(vim.env.MYVIMRC)
  vim.notify("nvim config reloaded")
end

vim.api.nvim_create_user_command("Reload", reload, { desc = "Reload nvim config" })
