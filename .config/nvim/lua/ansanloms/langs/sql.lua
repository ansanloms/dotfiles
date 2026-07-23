-- SQLの設定
local augroup_sql = vim.api.nvim_create_augroup("sql-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_sql,
  pattern = "sql",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true

    -- 折り返さない
    vim.opt_local.wrap = false

    -- フォーマット指定
    if vim.fn.executable("deno") == 1 then
      vim.opt_local.formatprg = "deno fmt --ext sql --unstable-sql -"
    end
  end,
})

-- quickrun - mysql
if vim.fn.executable("mysql") == 1 then
  local quickrun_config = vim.g.quickrun_config or {}
  quickrun_config["sql"] = {
    type = "sql/mysql",
  }

  -- mysql
  quickrun_config["sql/mysql"] = {
    command = "mysql",
    cmdopt = "--defaults-extra-file=" .. vim.fn.expand("~/.mysql/local.conf"),
    exec = { "%c %o < %s" },
  }
  vim.g.quickrun_config = quickrun_config
end
