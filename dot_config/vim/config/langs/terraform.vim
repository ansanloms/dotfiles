call minpac#add("https://github.com/hashivim/vim-terraform.git")

augroup terraform-setting
  autocmd!

  autocmd FileType terraform setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
