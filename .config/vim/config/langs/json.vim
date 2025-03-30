call minpac#add("https://github.com/gutenye/json5.vim.git")
call minpac#add("https://github.com/neoclide/jsonc.vim.git")

" conceal 表示を無効にする
let g:vim_json_syntax_conceal = 0

augroup json-setting
  autocmd!

  autocmd FileType json setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " フォーマット指定
  if executable("python")
    autocmd FileType json setlocal formatprg=python\ -m\ json.tool
  endif
augroup END

augroup json5-setting
  autocmd!

  autocmd FileType json5 setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

augroup jsonc-setting
  autocmd!

  autocmd FileType jsonc setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
