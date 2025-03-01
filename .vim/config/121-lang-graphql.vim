call minpac#add("https://github.com/jparise/vim-graphql.git")

augroup graphql-setting
  autocmd!

  autocmd FileType graphql setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
