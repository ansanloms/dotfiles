call minpac#add("https://github.com/posva/vim-vue.git")

augroup vue-setting
  autocmd!

  autocmd FileType vue setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " ハイライト行指定
  autocmd FileType vue syntax sync fromstart
augroup END
