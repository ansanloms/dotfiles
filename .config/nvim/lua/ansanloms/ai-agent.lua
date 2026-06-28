-- zellij 経由で隣の "AI Agent" ペイン (Claude Code 等) へテキストを送り込む API。
--
-- 横で動かす AI エージェントは固定ではない (layout の $ZELLIJ_AI_AGENT 次第) ため、
-- 特定ツール名ではなくペイン TITLE "AI Agent" を対象とする。
-- フォーカスは動かさず --pane-id でペインを直接指定するため、nvim に居たまま送れる。
-- zellij 低レベル操作は require("zellij") に委譲する。
-- キーマップ等のバインドはこのモジュールでは行わない (mapping 側で定義する)。

local zellij = require("zellij")

local M = {}

-- 送信先ペインの TITLE。layout の `name "AI Agent"` に対応。
local TITLE = "AI Agent"

-- 指定行範囲のテキストを取得する。
local function lines_text(l1, l2)
  local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
  return table.concat(lines, "\n")
end

-- text を AI Agent ペインへ送る。submit=true なら末尾で Enter (CR) を送って確定する。
function M.send(text, submit)
  if not zellij.in_session() then
    vim.notify("ai-agent: not in a zellij session", vim.log.levels.ERROR)
    return
  end

  if vim.trim(text) == "" then
    vim.notify("ai-agent: nothing to send", vim.log.levels.WARN)
    return
  end

  local id, err = zellij.find_pane(TITLE)
  if not id then
    vim.notify("ai-agent: " .. err, vim.log.levels.ERROR)
    return
  end

  -- bracketed paste で一括投入する。途中の改行が誤って送信扱いされるのを防ぐ。
  local res = zellij.paste(id, text)
  if res.code ~= 0 then
    vim.notify("ai-agent: paste failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
    return
  end

  if submit then
    -- 13 = CR。AI エージェント側の送信を発火させる。
    local r = zellij.write(id, 13)
    if r.code ~= 0 then
      vim.notify("ai-agent: enter failed: " .. (r.stderr or ""), vim.log.levels.ERROR)
      return
    end
  end

  local lines = select(2, text:gsub("\n", "\n")) + 1
  vim.notify(
    ("ai-agent: %s %d line(s) to %s"):format(submit and "sent" or "pasted", lines, TITLE),
    vim.log.levels.INFO
  )
end

-- バッファ全体を送る。
function M.send_buffer(submit)
  M.send(lines_text(1, vim.api.nvim_buf_line_count(0)), submit)
end

-- 行範囲 [l1, l2] を送る。順不同で渡してよい。
function M.send_range(submit, l1, l2)
  if l1 > l2 then
    l1, l2 = l2, l1
  end
  M.send(lines_text(l1, l2), submit)
end

-- 現在のビジュアル選択を送る。charwise / linewise / blockwise いずれも、
-- 行全体ではなく選択した範囲そのものを取る。ビジュアルモードのキーマップから呼ぶ。
function M.send_selection(submit)
  local mode = vim.fn.mode()
  -- 念のため非ビジュアル時は charwise 扱いにフォールバックする。
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    mode = "v"
  end

  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })

  -- 選択範囲を取得した後でビジュアルモードを抜ける。先に抜けることで、
  -- 送信通知がモード遷移でメッセージ行から消されるのを防ぐ ("x" で同期実行)。
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)

  M.send(table.concat(lines, "\n"), submit)
end

return M
