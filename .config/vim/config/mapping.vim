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

" 検索などで飛んだらそこを真ん中に。
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap G Gzz

" 危険なコマンドは使わせない。
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" 検索のハイライト削除。
" ポップアップを消す。
command! Clear nohlsearch | call popup_clear()
nnoremap <silent> <Esc><Esc> :<C-u>Clear<CR>

" very magic
nnoremap / /\v

" バッファ前。
nnoremap ft :<C-u>bprev<CR>
nnoremap <C-w>ft <C-w>:<C-u>bprev<CR>
tnoremap <C-w>ft <C-w>:<C-u>bprev<CR>

" バッファ次。
nnoremap fT :<C-u>bnext<CR>
nnoremap <C-w>fT <C-w>:<C-u>bnext<CR>
tnoremap <C-w>fT <C-w>:<C-u>bnext<CR>

" タブ次。
nnoremap gr gT
nnoremap <C-w>gr <C-w>gT
tnoremap <C-w>gr <C-w>gT

" タグジャンプの際に新しいタブで開く。
"nnoremap <C-]> :<C-u>tab stj <C-R>=expand("<cword>")<CR><CR>

" <S-space> とか押すと ^[[32;2u[ とかはいるやつの対策。
" https://github.com/vim/vim/issues/6040
tnoremap <S-space> <space>
tnoremap <C-BS> <BS>
tnoremap <C-CR> <CR>
