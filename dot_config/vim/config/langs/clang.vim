augroup clang-setting
  autocmd!

  autocmd BufNewFile,BufRead *.c set filetype=c
  autocmd FileType c setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
augroup END
