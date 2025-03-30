call minpac#add("https://github.com/stephpy/vim-yaml.git")

augroup yaml-setting
  autocmd!

  autocmd FileType yaml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
