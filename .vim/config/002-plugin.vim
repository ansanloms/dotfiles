" minpac {{{

" minpac の取得
if !isdirectory(expand("~/.vim/pack/minpac/opt/minpac"))
  call system("git clone https://github.com/k-takata/minpac.git " . expand("~/.vim/pack/minpac/opt/minpac"))
endif
packadd minpac

call minpac#init()

call minpac#add("https://github.com/k-takata/minpac.git", {"type": "opt"})

" }}}

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
  if has("win32")
    call singleton#enable()
  endif
catch
endtry


" git {{{

call minpac#add("https://github.com/airblade/vim-gitgutter.git")

" }}}

" AI chat {{[

call minpac#add("https://github.com/ansanloms/vim-ramble.git")

" }}}

" snippet {{{

call minpac#add("https://github.com/hrsh7th/vim-vsnip.git")
call minpac#add("https://github.com/hrsh7th/vim-vsnip-integ.git")

let g:vsnip_snippet_dir = expand("~/.vim/snippets")

let g:vsnip_filetypes = {}
let g:vsnip_filetypes.typescript = ["javascript"]
let g:vsnip_filetypes.vue = ["javascript", "typescript"]
let g:vsnip_filetypes.javascriptreact = ["javascript"]
let g:vsnip_filetypes.typescriptreact = ["javascript", "typescript"]

" }}}

" quickrun {{{

call minpac#add("https://github.com/thinca/vim-quickrun.git")

let g:quickrun_config = {}
let g:quickrun_config["_"] = {
\ "runner": "job",
\}

" }}}

" fuzzy finder {{{

call minpac#add("https://github.com/ansanloms/vim-bekken.git")
call minpac#add("https://github.com/ansanloms/vim-bekken-files.git")
call minpac#add("https://github.com/ansanloms/vim-bekken-buffer.git")
call minpac#add("https://github.com/ansanloms/vim-bekken-launcher.git")

if executable("rg")
  let g:bekken#files#get_file_list_cmd = ["rg", "--files"]
endif

" }}}
