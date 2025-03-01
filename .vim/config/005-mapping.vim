" +-----------------+--------+--------+----------+----------------+--------+------+----------+
" | コマンド        | NORMAL | INSERT | TERMINAL | コマンドライン | VISUAL | 選択 | 演算待ち |
" +-----------------+--------+--------+----------+----------------+--------+------+----------+
" | map  / noremap  | @      | -      | -        | -              | @      | @    | @        |
" | nmap / nnoremap | @      | -      | -        | -              | -      | -    | -        |
" | vmap / vnoremap | -      | -      | -        | -              | @      | @    | -        |
" | omap / onoremap | -      | -      | -        | -              | -      | -    | @        |
" | xmap / xnoremap | -      | -      | -        | -              | @      | -    | -        |
" | smap / snoremap | -      | -      | -        | -              | -      | @    | -        |
" | map! / noremap! | -      | @      | -        | @              | -      | -    | -        |
" | imap / inoremap | -      | @      | -        | -              | -      | -    | -        |
" | cmap / cnoremap | -      | -      | -        | @              | -      | -    | -        |
" | tmap / tnoremap | -      | -      | @        | -              | -      | -    | -        |
" +-----------------+--------+--------+----------+----------------+--------+------+----------+

" Leader
let g:mapleader = ","

" 検索などで飛んだらそこを真ん中に
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap G Gzz

" 危険なコマンドは使わせない
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" 検索のハイライト削除
" ポップアップを消す
command! Clear nohlsearch | call popup_clear()
nnoremap <silent> <Esc><Esc> :<C-u>Clear<CR>

" very magic
nnoremap / /\v

" バッファ前
nnoremap ft :<C-u>bprev<CR>
nnoremap <C-w>ft <C-w>:<C-u>bprev<CR>
tnoremap <C-w>ft <C-w>:<C-u>bprev<CR>

" バッファ次
nnoremap fT :<C-u>bnext<CR>
nnoremap <C-w>fT <C-w>:<C-u>bnext<CR>
tnoremap <C-w>fT <C-w>:<C-u>bnext<CR>

" バッファ次
nnoremap fr :<C-u>bnext<CR>
nnoremap <C-w>fr <C-w>:<C-u>bnext<CR>
tnoremap <C-w>fr <C-w>:<C-u>bnext<CR>

" タブ次
nnoremap gr gT
nnoremap <C-w>gr <C-w>gT
tnoremap <C-w>gr <C-w>gT

" launcher
nnoremap <silent> <C-e> :<C-u>call bekken#Run("launcher#select", globpath(expand("~/.vim/launcher"), "**/*.yaml", v:false, v:true), {})<CR>
vnoremap <silent> <C-e> :<C-u>call bekken#Run("launcher#select", globpath(expand("~/.vim/launcher"), "**/*.yaml", v:false, v:true), {})<CR>

let g:bekken_buffer#key_mappings = {
\ "\<CR>": { bufnr -> execute("buffer " .. bufnr) },
\ "\<C-s>": { bufnr -> execute("split | buffer " .. bufnr) },
\ "\<C-v>": { bufnr -> execute("vsplit | buffer " .. bufnr) },
\ "\<C-w>": { bufnr -> execute("split | wincmd w | buffer " .. bufnr) },
\ "\<C-l>": { bufnr -> execute("vsplit | wincmd l | buffer " .. bufnr) },
\}

let g:bekken_files#key_mappings = {
\ "\<CR>": { path -> execute("edit " .. path) },
\ "\<C-s>": { path -> execute("split | edit " .. path) },
\ "\<C-v>": { path -> execute("vsplit | edit " .. path) },
\ "\<C-w>": { path -> execute("split | wincmd w | edit " .. path) },
\ "\<C-l>": { path -> execute("vsplit | wincmd l | edit " .. path) },
\}

" history
nnoremap <silent> <C-h> :<C-u>call bekken#Run("files#oldfiles", [g:bekken_files#key_mappings], { "filetype": { "selection": "bekken-selection-files" } })<CR>

" current files
nnoremap <silent> <C-l> :<C-u>call bekken#Run("files#list", [ansanloms#project#dir(expand("%:h"), expand("%:h")), g:bekken_files#key_mappings], { "filetype": { "selection": "bekken-selection-files" } })<CR>

" buffer
nnoremap <silent> <C-s> :<C-u>call bekken#Run("buffer", [v:false, g:bekken_buffer#key_mappings], { "filetype": { "selection": "bekken-selection-buffer" } })<CR>

" タグジャンプの際に新しいタブで開く
"nnoremap <C-]> :<C-u>tab stj <C-R>=expand("<cword>")<CR><CR>

" <S-space> とか押すと ^[[32;2u[ とかはいるやつの対策
" https://github.com/vim/vim/issues/6040
tnoremap <S-space> <space>
tnoremap <C-BS> <BS>
tnoremap <C-CR> <CR>
