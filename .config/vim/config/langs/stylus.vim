call minpac#add("https://github.com/iloginow/vim-stylus.git")

augroup stylus-setting
  autocmd!

  autocmd FileType stylus setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
