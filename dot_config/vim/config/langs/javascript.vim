call minpac#add("https://github.com/MaxMEllon/vim-jsx-pretty.git")

augroup javascript-setting
  autocmd!

  autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType javascriptreact setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType javascript.jsx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
