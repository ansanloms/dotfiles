call minpac#add("https://github.com/vim-scripts/Super-Shell-Indent.git")
call minpac#add("https://github.com/vim-scripts/sh.vim.git")

let g:sh_indent_case_labels = 1

augroup sh-setting
  autocmd!

  autocmd FileType sh setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END
