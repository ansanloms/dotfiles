-- tmux 低レベル API。
--
-- nvim 設定内で tmux に依存する処理 (セッション検出 / socket パス導出 /
-- tmux コマンド実行 / ペイン操作) をここに集約する。
-- 各機能 (ai-agent 等) や singleton はこのモジュールを経由して tmux へ触る。

local M = {}

-- tmux セッション内で動いているか。
function M.in_session()
  return (vim.env.TMUX or "") ~= ""
end

-- tmux <args...> を同期実行し、vim.system の結果テーブルを返す。
-- opts は vim.system の第 2 引数へマージされる (stdin 等)。
function M.command(args, opts)
  local cmd = { "tmux" }
  vim.list_extend(cmd, args)
  return vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {})):wait()
end

-- 現在の tmux セッション名。tmux 外・取得失敗時は nil。
function M.session_name()
  if not M.in_session() then
    return nil
  end
  local res = M.command({ "display-message", "-p", "#S" })
  if res.code ~= 0 then
    return nil
  end
  local name = vim.trim(res.stdout or "")
  if name == "" then
    return nil
  end
  return name
end

-- tmux-workspace の `nvim --listen /tmp/nvim-<セッション名>.sock` に対応する
-- nvim socket パス。tmux 外なら nil。
function M.nvim_socket_path()
  local name = M.session_name()
  if not name then
    return nil
  end
  return "/tmp/nvim-" .. name .. ".sock"
end

-- セッション内の全ペインを { id, role, title } のリストで返す。
-- role は tmux-workspace が設定する user option @role (未設定なら "")。
function M.list_panes()
  local res = M.command({ "list-panes", "-s", "-F", "#{pane_id}\t#{@role}\t#{pane_title}" })
  if res.code ~= 0 then
    return nil, "list-panes failed: " .. (res.stderr or "")
  end

  local panes = {}
  for line in (res.stdout or ""):gmatch("[^\n]+") do
    local id, role, title = line:match("^([^\t]+)\t([^\t]*)\t(.*)$")
    if id then
      table.insert(panes, { id = id, role = role, title = title })
    end
  end
  return panes
end

-- @role が role に一致するペインの ID を返す。見つからなければ nil, err。
-- pane_title は実行中のアプリが OSC で書き換えるため、識別には使わない。
function M.find_pane(role)
  local panes, err = M.list_panes()
  if not panes then
    return nil, err
  end

  for _, pane in ipairs(panes) do
    if pane.role == role then
      return pane.id
    end
  end

  return nil, ("pane not found: @role=%s"):format(role)
end

-- bracketed paste でテキストを投入する (改行を本文として扱う)。
function M.paste(id, text)
  local res = M.command({ "load-buffer", "-b", "nvim-paste", "-" }, { stdin = text })
  if res.code ~= 0 then
    return res
  end
  return M.command({ "paste-buffer", "-d", "-p", "-b", "nvim-paste", "-t", id })
end

-- キーを送る。例: M.send_keys(id, "Enter")。
function M.send_keys(id, ...)
  local args = { "send-keys", "-t", id }
  for _, key in ipairs({ ... }) do
    table.insert(args, key)
  end
  return M.command(args)
end

return M
