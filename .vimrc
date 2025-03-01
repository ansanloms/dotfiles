let g:no_gvimrc_example = 1
let g:no_vimrc_example = 1

let g:loaded_getscriptPlugin = 1
let g:loaded_gzip = 1
let g:loaded_logiPat = 1
let g:loaded_manpager = 1
let g:loaded_matchparen = 1
let g:loaded_netrwPlugin = 1
let g:loaded_openPlugin = 1
let g:loaded_rrhelper = 1
let g:loaded_spellfile = 1
let g:loaded_tarPlugin = 1
let g:loaded_tohtml = 1
let g:loaded_tutor = 1
let g:loaded_vimballPlugin = 1
let g:loaded_zipPlugin = 1

call expand("~/.vim/config/*.vim", v:false, v:true)->sort()->foreach({_, path -> execute("source " .. path)})

" お仕事用設定 {{{

if filereadable(expand("~/.vim/work.vim"))
  source ~/.vim/work.vim
endif

" }}}

" 一時的設定 {{{

if filereadable(expand("~/.vim/temp.vim"))
  source ~/.vim/temp.vim
endif
