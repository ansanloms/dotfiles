call minpac#add("https://github.com/yukpiz/vim-volt-syntax.git")

 " case 文対応
let g:PHP_vintage_case_default_indent = 1

" 使用する DB
let g:sql_type_default = "mysql"

augroup php-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.ctp set filetype=php

  autocmd FileType php setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " ハイライト行指定
  autocmd FileType php syntax sync minlines=300 maxlines=500
augroup END

augroup php-volt-setting
  autocmd!

  autocmd filetype volt setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " ハイライト行指定
  autocmd filetype volt syntax sync minlines=300 maxlines=500
augroup END
