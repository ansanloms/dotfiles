-- zellij 低レベル API。
--
-- nvim 設定内で zellij に依存する処理 (セッション検出 / socket パス導出 /
-- `zellij action` 実行 / ペイン操作) をここに集約する。
-- 各機能 (ai-agent 等) や singleton はこのモジュールを経由して zellij へ触る。

local M = {}

-- 現在の zellij セッション名。zellij 外なら nil。
function M.session_name()
  local name = vim.env.ZELLIJ_SESSION_NAME
  if name == nil or name == "" then
    return nil
  end
  return name
end

-- zellij セッション内で動いているか。
function M.in_session()
  return (vim.env.ZELLIJ or "") ~= ""
end

-- layout の `nvim --listen /tmp/nvim-${ZELLIJ_SESSION_NAME}.sock` に対応する
-- nvim socket パス。zellij 外なら nil。
function M.nvim_socket_path()
  local name = M.session_name()
  if not name then
    return nil
  end
  return "/tmp/nvim-" .. name .. ".sock"
end

-- zellij action <args...> を同期実行し、vim.system の結果テーブルを返す。
function M.action(args)
  local cmd = { "zellij", "action" }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { text = true }):wait()
end

-- list-panes をパースして { id, kind, title } のリストを返す。
-- 出力形式: "PANE_ID  TYPE  TITLE" (1 行目はヘッダ)。
function M.list_panes()
  local res = M.action({ "list-panes" })
  if res.code ~= 0 then
    return nil, "list-panes failed: " .. (res.stderr or "")
  end

  local panes = {}
  for line in (res.stdout or ""):gmatch("[^\n]+") do
    local id, kind, title = line:match("^(%S+)%s+(%S+)%s+(.+)$")
    if id and id ~= "PANE_ID" then
      table.insert(panes, { id = id, kind = kind, title = vim.trim(title) })
    end
  end
  return panes
end

-- TITLE が title に一致する端末ペインの ID を返す。見つからなければ nil, err。
function M.find_pane(title)
  local panes, err = M.list_panes()
  if not panes then
    return nil, err
  end

  for _, pane in ipairs(panes) do
    if pane.kind == "terminal" and pane.title == title then
      return pane.id
    end
  end

  return nil, ("pane not found: %s"):format(title)
end

-- bracketed paste でテキストを投入する (改行を本文として扱う)。
function M.paste(id, text)
  return M.action({ "paste", "--pane-id", id, "--", text })
end

-- 生バイト列を送る。例: M.write(id, 13) で CR (Enter)。
function M.write(id, ...)
  local args = { "write", "--pane-id", id }
  for _, byte in ipairs({ ... }) do
    table.insert(args, tostring(byte))
  end
  return M.action(args)
end

return M
