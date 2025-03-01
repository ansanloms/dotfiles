augroup asciidoc-setting
  autocmd!

  autocmd BufNewFile,BufRead *.adoc set filetype=asciidoc
  autocmd FileType asciidoc setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
