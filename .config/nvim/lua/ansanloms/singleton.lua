-- .config/nvim/lua/config/singleton.lua
-- zellij 環境で Neovim を singleton として動作させる
local M = {}

M.config = {
  ignore_patterns = {
    "^%-$", -- stdin
    "%.tmp$",
    "%.diff$",
    -- git
    "COMMIT_EDITMSG$", -- git commit
    "TAG_EDITMSG$", -- git tag -a
    "MERGE_MSG$", -- git merge
    "SQUASH_MSG$", -- git merge --squash
    "EDIT_DESCRIPTION$", -- git branch --edit-description
    "NOTES_EDITMSG$", -- git notes edit
    "git%-rebase%-todo$", -- git rebase -i
    "addp%-hunk%-edit%.diff$", -- git add -p (edit)
    -- claude code
    "/tmp/claude%-prompt",
  },
}

local function get_socket_path()
  local session_name = vim.env.ZELLIJ_SESSION_NAME

  if not session_name then
    return nil
  end

  return "/tmp/nvim-" .. session_name .. ".sock"
end

local function socket_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function is_server(socket_path)
  return vim.v.servername == socket_path
end

local function should_ignore(filepath)
  for _, pattern in ipairs(M.config.ignore_patterns) do
    if filepath:match(pattern) then
      return true
    end
  end

  return false
end

local function send_to_server(socket_path, files)
  for _, file in ipairs(files) do
    local abs_path = vim.fn.fnamemodify(file, ":p")
    vim.fn.system({ "nvim", "--server", socket_path, "--remote", abs_path })

    if vim.v.shell_error ~= 0 then
      return false
    end
  end
  return true
end

function M.setup()
  local socket_path = get_socket_path()

  if not socket_path then
    return
  end

  if not socket_exists(socket_path) then
    return
  end

  if is_server(socket_path) then
    return
  end

  -- ここからクライアント処理
  local args = vim.fn.argv()

  -- 引数なし: 通常起動
  if #args == 0 then
    return
  end

  -- ignore 対象が 1 つでもあれば通常起動
  for _, arg in ipairs(args) do
    if should_ignore(arg) then return end
  end

  -- サーバーにファイルを送信して終了
  if send_to_server(socket_path, args) then
    vim.cmd("quit")
  end
end

return M
