-- clip-image (ホスト WSL) を実行し、キャプチャした PNG の絶対パスを
-- カーソル位置に挿入する API。clip-image は powershell 依存のためホスト専用。
-- 都度実行するので、押した瞬間の Windows クリップボードを確実にキャプチャする。
-- キーマップ等のバインドはこのモジュールでは行わない (mapping 側で定義する)。

local M = {}

-- clip-image の実体。PATH に依存せず叩けるよう絶対パスで解決する。
local cmd = vim.fn.expand("~/.local/bin/clip-image")

-- clip-image を実行し、保存先 PNG の絶対パスを返す。
-- 画像が無い等で失敗したら通知して nil を返す。
function M.path()
  -- リスト形式で渡し、シェルを介さず直接実行する (PATH / クォート非依存)。
  local out = vim.fn.systemlist({ cmd })
  if vim.v.shell_error ~= 0 then
    local msg = vim.trim(table.concat(out, "\n"))
    vim.notify(
      "clip-image: " .. (msg ~= "" and msg or "failed"),
      vim.log.levels.ERROR
    )
    return nil
  end

  local path = vim.trim(out[#out] or "")
  if path == "" then
    vim.notify("clip-image: empty path", vim.log.levels.ERROR)
    return nil
  end
  return path
end

-- ノーマルモード用。キャプチャ画像のパスをカーソル位置へ挿入する。
function M.put()
  local path = M.path()
  if path then
    vim.api.nvim_put({ path }, "c", true, true)
  end
end

-- clip-image が使えるか (= ホストか)。コンテナ等では false。
function M.available()
  return vim.fn.executable(cmd) == 1
end

return M
