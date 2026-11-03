augroup sql-setting
  autocmd!

  autocmd FileType sql setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " 折り返さない
  autocmd FileType sql setlocal nowrap

  " フォーマット指定
  if executable("sql-formatter")
    autocmd FileType sql setlocal formatprg=sql-formatter
  endif
augroup END

" quickrun - mysql
if executable("mysql")
  let g:quickrun_config["sql"] = {
  \ "type": "sql/mysql"
  \}

  " mysql
  let g:quickrun_config["sql/mysql"] = {
  \ "command": "mysql",
  \ "cmdopt": "--defaults-extra-file=" . expand("~/.mysql/local.conf"),
  \ "exec": ["%c %o < %s"]
  \}
endif
