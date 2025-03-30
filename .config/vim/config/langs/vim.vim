" \ を入力した際のインデント量
let g:vim_indent_cont = 0

augroup vim-setting
  autocmd!

  autocmd FileType vim setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " folding
  autocmd FileType vim setlocal foldmethod=marker
augroup END
