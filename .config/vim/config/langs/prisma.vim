call minpac#add("https://github.com/pantharshit00/vim-prisma.git")

augroup prisma-setting
  autocmd!

  autocmd FileType prisma setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
