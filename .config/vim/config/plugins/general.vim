" general {{{

call minpac#add("https://github.com/vim-jp/vimdoc-ja.git")
call minpac#add("https://github.com/junegunn/vim-easy-align.git")
call minpac#add("https://github.com/tyru/open-browser.vim.git")
call minpac#add("https://github.com/itchyny/vim-cursorword.git")
call minpac#add("https://github.com/mattn/vim-notification.git")

call minpac#add("https://github.com/itchyny/vim-parenmatch.git")
let g:loaded_matchparen = 1     " matchparenを無効にする

call minpac#add("https://github.com/vim-denops/denops.vim.git")

call minpac#add("https://github.com/thinca/vim-singleton.git")
let g:singleton#opener = "edit"
try
  call singleton#enable()
catch
endtry

" }}}

" git {{{

call minpac#add("https://github.com/airblade/vim-gitgutter.git")

" }}}

" quickrun {{{

call minpac#add("https://github.com/thinca/vim-quickrun.git")

let g:quickrun_config = {}
let g:quickrun_config["_"] = {
\ "runner": "job",
\}

" }}}
