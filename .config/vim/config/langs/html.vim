call minpac#add("https://github.com/mattn/emmet-vim.git")

augroup html-setting
  autocmd!

  autocmd FileType html setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" quickrun - html
if executable("w3m")
  let g:quickrun_config["html"] = {
  \ "type": "html/w3m"
  \}

  " text 出力
  let g:quickrun_config["html/w3m"] = {
  \ "command": "w3m",
  \ "cmdopt": "-dump",
  \ "exec": '%c %o %s'
  \}
endif
