call minpac#add("https://github.com/vim-scripts/groovyindent.git")

augroup groovy-setting
  autocmd!

  autocmd FileType groovy setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
