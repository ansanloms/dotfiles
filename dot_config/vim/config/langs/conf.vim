call minpac#add("https://github.com/vim-scripts/apachestyle.git")

augroup conf-setting
  autocmd!

  autocmd filetype apache setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
  autocmd filetype nginx setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
  autocmd filetype conf setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
augroup END
