call minpac#add("https://github.com/rust-lang/rust.vim.git")

augroup rust-setting
  autocmd!

  autocmd FileType rust setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
augroup END
