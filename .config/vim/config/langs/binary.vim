augroup binary-setting
  autocmd!
  autocmd BufReadPre  *.{bin,dll,exe} let &bin=1
  autocmd BufReadPost *.{bin,dll,exe} if &bin | %!xxd
  autocmd BufReadPost *.{bin,dll,exe} set ft=xxd | endif
  autocmd BufWritePre *.{bin,dll,exe} if &bin | %!xxd -r
  autocmd BufWritePre *.{bin,dll,exe} endif
  autocmd BufWritePost *.{bin,dll,exe} if &bin | %!xxd
  autocmd BufWritePost *.{bin,dll,exe} set nomod | endif
augroup END
