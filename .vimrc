scriptencoding utf-8

"-----------------------------------
" 文字コード設定
"-----------------------------------

if has("vim_starting")
  " vim内部で通常使用する文字エンコーディング
  set encoding=utf-8

  " 既存ファイルを開く際の文字コード自動判別
  set fileencodings=utf-8,sjis,cp932,euc-jp,iso-2022-jp

  " 改行文字設定
  set fileformats=unix,mac,dos
endif

"-----------------------------------
" ディレクトリ作成
"-----------------------------------

if has("vim_starting")
  for dir in [
  \ "~/.vim"
  \ ,"~/.vim/autoload"
  \ ,"~/.vim/backup"
  \ ,"~/.vim/view"
  \ ,"~/.vim/undo"
  \ ,"~/.vim/pack"
  \]
    if !isdirectory(expand(dir))
      call mkdir(iconv(expand(dir), &encoding, &termencoding), "p")
    endif
  endfor
endif

"-----------------------------------
" 基本設定
"-----------------------------------

" defaults.vim の読み込み
if filereadable(expand($VIMRUNTIME . "/defaults.vim"))
  source $VIMRUNTIME/defaults.vim
endif

" viモードの廃止
" .vimrcがある時点で廃止される
"set nocompatible

if has("win32") || has("win64")
  " 読み込みディレクトリの追記
  set runtimepath^=~/.vim

  " パッケージディレクトリの追記
  set packpath^=~/.vim
endif

" viminfoの保存先を変更
set viminfo+=n~/.vim/viminfo

" コマンドの保存履歴数
set history=1000

" backspaceの設定
" start:    ノーマルモードに移った後に挿入モードに入っても[Backspace]で自由に文字を削除できるようにする
" eol:      行頭で[Backspace]を押したときに行の連結を可能にする
" indent:   オートインデントモードのインデントも削除可能にする
set backspace=start,eol,indent

" C-vの矩形選択で行末より後ろもカーソルを置ける
set virtualedit=block

" クリップボード使用可能に設定
set clipboard=unnamed

" ヘルプ検索で日本語を優先
set helplang=ja,en

" カーソルを行頭行末で止まらないようにする
set whichwrap=b,s,h,l,<,>,[,]

" マウスは使わない
set mouse=

" バッファ有効
set hidden

" filler: vimdiffで埋め立てを行う
" iwhite: vimdiffで空白を無視して比較する
set diffopt=filler,iwhite

" タグファイルの二分探索
set tagbsearch

" conceal処理の設定
" 0: 通常通り表示(デフォルト)
" 1: conceal対象のテキストは代理文字(初期設定はスペース)に置換される
" 2: conceal対象のテキストは非表示になる
" 3: conceal対象のテキストは完全に非表示
if has("conceal")
  set conceallevel=1
  set concealcursor=
endif

" スペルチェック
"set spell
set nospell
set spelllang+=cjk

" fold設定
set foldmethod=syntax
set foldlevel=1
set foldnestmax=2
set foldcolumn=2

" スクリプト実行中に画面を描画しない
set lazyredraw

" 外部grepの設定
if executable("grep")
  set grepprg=grep\ -Hnd\ skip\ -r
  set grepformat=%f:%l:%m,%f:%l%m,%f\ \ %l%m
endif

" beep音を消す
set belloff=all

"-----------------------------------
" プラグイン設定
"-----------------------------------

" minpacの取得
if !isdirectory(expand("~/.vim/pack/minpac/opt/minpac"))
  call system("git clone https://github.com/k-takata/minpac.git " . expand("~/.vim/pack/minpac/opt/minpac"))
endif

if exists("*minpac#init")
  call minpac#init()

  " minpac
  " プラグイン管理
  call minpac#add("https://github.com/k-takata/minpac.git", {"type": "opt"})

  " vimdoc-ja
  " 日本語ヘルプ
  call minpac#add("https://github.com/vim-jp/vimdoc-ja.git")

  " vim-midoronuma
  " カラースキーム
  call minpac#add("https://github.com/ansanloms/vim-midoronuma.git")

  " vital.vim
  " vimライブラリ群
  call minpac#add("https://github.com/vim-jp/vital.vim.git", {"type": "opt"})

  " Align.vim
  " 整形を行う
  " 本家にはカーソルがファイル末尾に飛ぶバグがあるので修正版を使用する
  call minpac#add("https://github.com/todesking/vim-align.git", {"branch": "xstrlen-fix"})

  " CtrlP
  " 多機能セレクタ
  call minpac#add("https://github.com/ctrlpvim/ctrlp.vim.git")

  " ctrlp-launcher
  " CtrlPでのランチャ
  call minpac#add("https://github.com/mattn/ctrlp-launcher.git")

  " vim-fugitive
  " vimからgit操作を行う
  call minpac#add("https://github.com/tpope/vim-fugitive.git")

  " open-browser.vim
  " 指定URLをブラウザで開く
  call minpac#add("https://github.com/tyru/open-browser.vim.git")

  " quickrun
  " 編集のプログラムをその場で実行する
  call minpac#add("https://github.com/thinca/vim-quickrun.git")

  " vim-watchdogs
  " シンタックスチェックを行う
  call minpac#add("https://github.com/osyo-manga/vim-watchdogs.git")

  " vim-markdown
  " markdownのシンタックス
  call minpac#add("https://github.com/rcmdnk/vim-markdown.git", {"type": "opt"})

  " vim-markdown-quote-syntax
  " markdownのコードブロックのハイライト設定
  call minpac#add("https://github.com/joker1007/vim-markdown-quote-syntax.git")

  " sh.vim
  " shのindent
  call minpac#add("https://github.com/vim-scripts/sh.vim--Cla.git", {"type": "opt"})

  " vim-json
  " json のシンタックス
  call minpac#add("https://github.com/elzr/vim-json.git", {"type": "opt"})

  " parenmatch
  " matchparenの代替
  call minpac#add("https://github.com/itchyny/vim-parenmatch.git")

  " vim-singleton
  " vimの多重起動を防ぐ
  call minpac#add("https://github.com/thinca/vim-singleton.git", {"type": "opt"})

  " vim-volt-syntax
  " volt 用シンタックス
  call minpac#add("https://github.com/yukpiz/vim-volt-syntax.git")

  " emmet-vim
  " emmet
  call minpac#add("https://github.com/mattn/emmet-vim.git")

  " sky-color-clock.vim
  " 時間と月齢を表示
  call minpac#add("https://github.com/mopp/sky-color-clock.vim.git")
endif

" Align関連
" 幅広文字に対応する
let g:Align_xstrlen = 3

" CtrlP関連
" キャッシュを使用する
let g:ctrlp_use_caching = 1

" キャッシュディレクトリ
let g:ctrlp_cache_dir = $HOME."/.cache/ctrlp"

" 終了時にキャッシュを削除しない
let g:ctrlp_clear_cache_on_exit = 0

" 20行表示
let g:ctrlp_max_height = 20

" ファイルの新規作成時は別タブで開く
let g:ctrlp_open_new_file = 1

" quickrun関連
let g:quickrun_config = {}

" 設定
let g:quickrun_config["_"] = {
\ "runner": "job",
\}

" java
let g:quickrun_config["java"] = {
\ "hook/cd/directory": "%S:p:h",
\ "exec": [
\   "javac -J-Dfile.encoding=UTF8 %o %s",
\   "%c -Dfile.encoding=UTF8 %s:t:r %a"
\ ]
\}

" html
if executable("w3m")
  " text 出力
  let g:quickrun_config["html"] = {
  \ "type": "html/w3m"
  \}

  let g:quickrun_config["html/w3m"] = {
  \ "command": "w3m",
  \ "cmdopt": "-dump",
  \ "exec": '%c %o %s'
  \}
endif

" markdown
if executable("pandoc")
  " cssの取得
  if !filereadable(expand("~/.vim/markdown.css"))
    call system("curl https://gist.githubusercontent.com/tuzz/3331384/raw/d1771755a3e26b039bff217d510ee558a8a1e47d/github.css -o " . expand("~/.vim/markdown.css"))
  endif

  " html 出力
  let g:quickrun_config["markdown"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "type": "markdown/pandoc",
  \ "outputter": "null",
  \ "exec": "pandoc %s --standalone --toc-depth=6 --to=html5 --css=" . expand("~/.vim/markdown.css") . " --output=%s.html"
  \}

  " slidy 出力
  let g:quickrun_config["markdown-slidy"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "type": "markdown/pandoc",
  \ "outputter": "null",
  \ "exec": "pandoc %s --standalone --self-contained --toc-depth=6 --to=slidy --output=%s-slidy.html"
  \}

  " html 出力 (1つのファイルに纏める)
  let g:quickrun_config["markdown-html"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "type": "markdown/pandoc",
  \ "outputter": "null",
  \ "exec": "pandoc %s --standalone --self-contained --toc-depth=6 --to=html5 --css=" . expand("~/.vim/markdown.css") . " --output=%s-standalone.html"
  \}

  " Word docx 出力
  let g:quickrun_config["markdown-docx"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "null",
  \ "type": "markdown/pandoc",
  \ "exec": "pandoc %s --standalone --self-contained --toc-depth=6 --to=docx --highlight-style=zenburn --output=%s.docx"
  \}
endif

" watchdogs関連
" 書き込み後にシンタックスチェックを行う
let g:watchdogs_check_BufWritePost_enable = 1

" 一定時間キー入力がなかった場合にシンタックスチェックを行う
" バッファに書き込み後、1度だけ行われる
let g:watchdogs_check_CursorHold_enable = 1

" watchdogs 設定
let g:quickrun_config["watchdogs_checker/_"] = {
\ "runner": "job",
\}

" watchdogs 設定 - java
let g:quickrun_config["java/watchdogs_checker"] = {
\ "command": "javac",
\ "cmdopt": join([
\   "-J-Dfile.encoding=UTF8",
\   "-Xlint:all",
\   "-deprecation",
\ ]),
\ "exec": "%c %o %S",
\ "errorformat": "%A%f:%l: %m,%-Z%p^,%+C%.%#,%-G%.%#",
\}

" watchdogs 設定 - javascript
if executable("eslint")
  let g:quickrun_config["javascript/watchdogs_checker"] = {
  \ "type" : "watchdogs_checker/eslint",
  \}
endif

" watchdogs 設定 - php
let g:quickrun_config["php/watchdogs_checker"] = {
\ "command": "php",
\ "cmdopt": join([
\   "-l",
\   "-d error_reporting=E_ALL",
\   "-d display_errors=1",
\   "-d display_startup_errors=1",
\   "-d log_errors=0",
\   "-d xdebug.cli_color=0",
\ ]),
\ "exec": "%c %o %s:p",
\ "errorformat": "%m\ in\ %f\ on\ line\ %l"
\}

" vim-markdown-quote-syntax 関連
let g:markdown_quote_syntax_filetypes = {
\ "css" : {
\   "start" : "css",
\ },
\ "php" : {
\   "start" : "php",
\ },
\}

" parenmatch関連
" matchparenを無効にする
let g:loaded_matchparen = 1

" vim-singleton関連
if (has("clientserver"))
  try
    packadd! vim-singleton
    call singleton#enable()
  catch
  endtry
endif

" sky-color-clock.vim関連

" 日付フォーマット
let g:sky_color_clock#datetime_format = "%Y.%m.%d (%a) %H:%M"

" 絵文字表示
let g:sky_color_clock#enable_emoji_icon = 1

"-----------------------------------
" ステータスラインの設定
"-----------------------------------

" ステータスラインを常に表示
set laststatus=2

" https://bitbucket.org/ns9tks/vim-fuzzyfinder/src/tip/autoload/fuf.vim
" TODO: マルチバイト文字が崩れるのをなんとかする
function! SnipMid(str, len, mask)
  if a:len >= len(a:str)
    return a:str
  elseif a:len <= len(a:mask)
    return a:mask
  endif

  let len_head = (a:len - len(a:mask)) / 2
  let len_tail = a:len - len(a:mask) - len_head

  return (len_head > 0 ? a:str[: len_head - 1] : "") . a:mask . (len_tail > 0 ? a:str[-len_tail :] : "")
endfunction

" モード取得
function! StatuslineMode()
  let a:mode_list = {
  \ "n":       "NORMAL"
  \ ,"i":      "INSERT"
  \ ,"R":      "REPLACE"
  \ ,"v":      "VISUAL"
  \ ,"V":      "V-LINE"
  \ ,"c":      "COMMAND"
  \ ,"\<C-v>": "V-BLOCK"
  \ ,"s":      "SELECT"
  \ ,"S":      "S-LINE"
  \ ,"\<C-s>": "S-BLOCK"
  \ ,"t":      "TERMINAL"
  \ ,"?":      "?"
  \}
  let a:current_mode = mode()
  let a:paste_mode   = (&paste) ? "(PASTE)" : ""
  if has_key(a:mode_list, a:current_mode)
    return a:mode_list[a:current_mode].a:paste_mode
  endif
  return a:current_mode.a:paste_mode."?"
endfunction

set statusline=[%{StatuslineMode()}]                                                    " モード表示
set statusline+=%{SnipMid(expand('%:p'),(winwidth(0)/2)-len(expand('%:p:t')),'...')}    " ファイルパス
set statusline+=%m                                                                      " 修正フラグ
set statusline+=%r                                                                      " 読み込み専用フラグ
set statusline+=%h                                                                      " ヘルプバッファフラグ
set statusline+=%w                                                                      " プレビューウィンドウフラグ
set statusline+=%=                                                                      " 左寄せ項目と右寄せ項目の区切り
set statusline+=[%{&filetype}]                                                          " ファイルタイプ
set statusline+=[%{&fileformat}]                                                        " 改行コード
set statusline+=[%{&fileencoding}]                                                      " 文字コード
set statusline+=[%l/%L\ %p%%]                                                           " 現在行数/全行数 カーソル位置までの割合
set statusline+=%#SkyColorClock#\ %{sky_color_clock#statusline()}\  " <-- 行末にSP有    " 日付と月齢表示

"-----------------------------------
" タブラインの設定
"-----------------------------------

" タブラインを常に表示
set showtabline=2

" タブラインの設定
set tabline=%!MakeTabLine()

function! MakeTabLine()
  let sep = ""  " タブ間の区切り
  return join(map(range(1, tabpagenr("$")), "s:tabpage_label(v:val)"), sep) . sep . "%#TabLineFill#%T"
endfunction

function! s:tabpage_label(tabpagenr)
  " タブページ内のバッファのリスト
  let bufnrs = tabpagebuflist(a:tabpagenr)

  " カレントタブページかどうかでハイライトを切り替える
  let hi = a:tabpagenr is tabpagenr() ? "%#TabLineSel#" : "%#TabLine#"

  " タブページ内に変更ありのバッファがあったら "+" を付ける
  let mod = len(filter(copy(bufnrs), "getbufvar(v:val, \"&modified\")")) ? "[+]" : ""

  " カレントバッファ
  let curbufnr = bufnrs[tabpagewinnr(a:tabpagenr) - 1]  " tabpagewinnr() は 1 origin
  let fname = fnamemodify(bufname(curbufnr), ":t")

  return "%" . a:tabpagenr . "T" . hi . " " . a:tabpagenr . ":" . fname . mod . " " . "%T%#TabLineFill#"
endfunction

"-----------------------------------
" インデントの設定
"-----------------------------------

" インデントをスペース4つ分に設定
set tabstop=4

" オートインデント
set smartindent

" 自動インデントでずれる幅
set shiftwidth=4

" Insertモードで <Tab> を挿入するとき代わりに
" 適切な数の空白を使う(ソフトTAB)
set expandtab
"set noexpandtab

" ソフトTABのスペースの数
set softtabstop=4

"-----------------------------------
" 検索の設定
"-----------------------------------

" 大文字/小文字の区別なく検索する
set ignorecase

" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase

" 検索時に最後まで行ったら最初に戻る
set wrapscan

" インクリメンタルサーチを有効
set incsearch

" 検索結果をハイライト表示
set hlsearch

"-----------------------------------
" 補完の設定
"-----------------------------------

" ファイルパス保管をbashと同じようにする
set wildmode=list:longest

" 補完時に表示されるプレビューウィンドウを消す
set completeopt=menuone

"-----------------------------------
" mapの設定
"-----------------------------------

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

" Leaderの設定
let g:mapleader = ","

" 検索などで飛んだらそこを真ん中に
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz
nnoremap G Gzz

" 危険なコマンドは使わせない
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" メモ関連セットアップ
function! s:memo_setup()
  let l:memo_dir = $HOME . "/memo"

  if exists("g:memo_dir")
    let l:memo_dir = g:memo_dir
  else
    let g:memo_dir = l:memo_dir
  endif

  if !isdirectory(expand(l:memo_dir))
    call mkdir(l:memo_dir, "p")
  endif

  if !isdirectory(expand(l:memo_dir))
    echo l:memo_dir . " is not a directory."
  endif
endfunction

" メモを開く
function! s:memo_open(...)
  call s:memo_setup()
  let l:memo_filename = ""

  if a:0 >= 1
    if a:0 >= 2
      let l:memo_filename = a:1
    else
      let l:memo_filename = strftime("%Y%m%d") . "_" . a:1
    endif
  else
    let l:memo_filename = strftime("%Y%m%d")
  endif

  execute "tabnew " . expand(g:memo_dir) . "/" . l:memo_filename . ".md"
endfunction

" メモ一覧をCtrlPで表示
function! s:memo_list()
  call s:memo_setup()
  execute "CtrlP " . expand(g:memo_dir)
endfunction

" メモ管理ディレクトリを設定
if has("win32") || has("win64")
  " windows
  let g:memo_dir = "C:/dev/memo"
endif

command! -nargs=* Memo call s:memo_open(<f-args>)
command! -nargs=0 MemoList call s:memo_list()
command! -nargs=* Report call s:memo_open("report/" . strftime("%Y%m%d") 1)

nnoremap <Leader>memo :<C-u>Memo memo 1<CR>
nnoremap <Leader>report :<C-u>execute ":Memo report/" . strftime("%Y%m%d") . " 1"<CR>

" hostsを開く
function! s:open_hosts()
  let l:hosts_path = "/etc/hosts"

  if has("mac")
    " mac
    let l:hosts_path = "/private/etc/hosts"
  elseif has("win32") || has("win64")
    " windows
    let l:hosts_path = "C:/Windows/System32/drivers/etc/hosts"
  endif

  execute "tabnew " . l:hosts_path
endfunction

command! -nargs=0 Hosts call s:open_hosts()
nnoremap <Leader>hosts :<C-u>Hosts<CR>

" タグジャンプの際に新しいタブで開く
nnoremap <C-]> :<C-u>tab stj <C-R>=expand("<cword>")<CR><CR>

" 検索のハイライト削除
nnoremap <silent> <Esc><Esc> :<C-u>nohlsearch<CR>

" tagファイルの作成
function! s:create_tagfile()
  packadd vital.vim

  let l:path = vital#of("vital").import("Prelude").path2project_directory(expand("%:p"))
  let l:optfunc = {}

  let l:job_ctags = job_start("ctags -R -f " . l:path . "/tags " . l:path, {
  \})
endfunction
command! -nargs=0 Ctags call s:create_tagfile()

" ファイルマネージャで開く
function! s:open_by_file_manager()
  if has("win32") || has("win64")
    call system("explorer.exe /select," . expand("%:p"))
  endif
endfunction
command! -nargs=0 OpenByFileManager call s:open_by_file_manager()
nnoremap <Leader>fm :<C-u>OpenByFileManager<CR>

" very magic
nnoremap / /\v

" undo-branche
nnoremap u g-
nnoremap <C-r> g+

" バッファ
nnoremap <Leader>b :<C-u>ls<CR>:<C-u>buf<Space>

" CtrlPLauncher
nnoremap <C-e> :<C-u>CtrlPLauncher<CR>

" CtrlPMRUFile
nnoremap <C-h> :<C-u>CtrlPMRUFiles<CR>

" プラグインを更新する
command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update()

" プラグインを削除する
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()

" 端末モード時に右クリックでクリップボードの内容をペースト
"tnoremap <RightMouse> <C-w>"+

"-----------------------------------
" terminal 設定
"-----------------------------------

if has("terminal")
  " 端末のエンコーディング
  set termencoding="utf-8"

  if executable("nyagos")
    " nyagos起動
    function! TermNyagos()
      tabnew    " 新規タブで端末起動
      call term_start(
      \ ["nyagos"],
      \ {
      \   "term_name":    "NYAGOS",
      \   "term_finish":  "close",
      \   "curwin":       1
      \ }
      \)
    endfunction
    nnoremap <Leader>nyagos :<C-u>call TermNyagos()<CR>
  endif
endif

"-----------------------------------
" Quickfixの設定
"-----------------------------------

augroup quickfix-setting
  autocmd!

  " ステータスラインを更新
  autocmd FileType qf setlocal statusline=%t%{exists('w:quickfix_title')\ ?\ '\ '.w:quickfix_title\ :\ ''}\ %=[%l/%L\ %p%%]
augroup END

"-----------------------------------
" JavaScriptの設定
"-----------------------------------

augroup javascript-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.js setlocal filetype=javascript

  " インデントセット
  autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

"-----------------------------------
" PHPの設定
"-----------------------------------

" SQLをハイライト表示
let g:php_sql_query = 0

" HTMLをハイライト表示
let g:php_htmlInStrings = 0

" Baselibメソッドのハイライト表示
let g:php_baselib = 0

" ショートタグを使わない
let g:php_noShortTags = 1

" ] や ) の対応エラーをハイライトする
let g:php_parent_error_close = 0
let g:php_parent_error_open = 0

" case文対応
let g:PHP_vintage_case_default_indent = 1

" 使用するDB
let g:sql_type_default = "mysql"

augroup php-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.php set filetype=php

  " インデントセット
  autocmd FileType php setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " phpcbfを用いた更新
  if executable("phpcbf")
    autocmd FileType php nnoremap <silent><leader>pcf :w!<CR>:echo system("phpcbf --standard=PSR2 " . expand("%:p"))<CR>:e!<CR>
    autocmd FileType php nnoremap <silent><leader>pcd :w!<CR>:echo system("phpcbf --standard=PSR2 " . expand("%:p:h"))<CR>:e!<CR>
  endif

  " ハイライト行指定
  autocmd FileType php syntax sync minlines=500 maxlines=1000
augroup END

"-----------------------------------
" voltの設定
"-----------------------------------

augroup volt-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.volt set filetype=volt

  " インデントセット
  autocmd filetype volt setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " ハイライト行指定
  autocmd filetype volt syntax sync minlines=500 maxlines=1000
augroup END

"-----------------------------------
" markdownの設定
"-----------------------------------

" foldさせない
let g:vim_markdown_folding_disabled = 1

" conceal設定
let g:vim_markdown_conceal = 0

augroup markdown-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown

  " インデントセット
  autocmd FileType markdown setlocal shiftwidth=2 tabstop=2 softtabstop=2 noexpandtab

  " プラグイン読み込み
  autocmd FileType markdown packadd! vim-markdown
augroup END

"-----------------------------------
" shの設定
"-----------------------------------

augroup sh-setting
  autocmd!

  " インデントセット
  autocmd FileType sh setlocal shiftwidth=2 tabstop=2 softtabstop=2 noexpandtab

  " プラグイン読み込み
  autocmd FileType sh packadd! sh.vim--Cla
augroup END

"-----------------------------------
" vimの設定
"-----------------------------------

" \ を入力した際のインデント量
let g:vim_indent_cont = 0

augroup vim-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{vim,vimrc} setlocal filetype=vim

  " インデントセット
  autocmd FileType vim setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

"-----------------------------------
" sqlの設定
"-----------------------------------

augroup sql-setting
  autocmd!

  " インデントセット
  autocmd FileType sql setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " フォーマット指定
  if executable("sql-formatter")
    autocmd FileType sql setlocal formatexpr=
    autocmd FileType sql setlocal formatprg=sql-formatter
  endif
augroup END

"-----------------------------------
" jsonの設定
"-----------------------------------

" conceal表示を無効にする
let g:vim_json_syntax_conceal = 0

" ダブルクォーテーションは常に表示
let g:vim_json_syntax_conceal = 0

augroup json-setting
  autocmd!

  " プラグイン読み込み
  autocmd FileType json packadd! vim-json
augroup END

"-----------------------------------
" netrwの設定
"-----------------------------------

" netrwは常にtree view
let g:netrw_liststyle = 3

" v でファイルを開くときは右側に開く(デフォルトが左側なので入れ替え)
let g:netrw_altv = 1

" o でファイルを開くときは下側に開く(デフォルトが上側なので入れ替え)
let g:netrw_alto = 1

"-----------------------------------
" その他設定
"-----------------------------------

" 行末空白削除
augroup remove-dust
  autocmd!

  " ファイルを保存する直前に実施
  autocmd BufWritePre * call s:remove_dust()

  function! s:remove_dust()
    let cursor = getpos(".")
    %s/\s\+$//ge
    call setpos(".", cursor)
    unlet cursor
  endfunction
augroup END

" ディレクトリ作成
augroup vimrc-auto-mkdir
  autocmd!

  " ファイルを保存する直前に実施
  autocmd BufWritePre * call s:auto_mkdir(expand("<afile>:p:h"), v:cmdbang)

  function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir)
      call mkdir(iconv(a:dir, &encoding, &termencoding), "p")
    endif
  endfunction
augroup END

" バックアップファイルとスワップファイル設定
if isdirectory(expand("~/.vim/backup"))
  set backupdir=~/.vim/backup
  set directory=~/.vim/backup

  " バックアップ作成
  set backup

  " 上書き前にバックアップ作成
  set writebackup

  " スワップファイル作成
  set swapfile
endif

" mkviewの設定
if isdirectory(expand("~/.vim/view"))
  " 保存先
  set viewdir=~/.vim/view

  " :mkviewで保存する設定
  set viewoptions=cursor,folds

  augroup vim-view
    autocmd!

    " ファイルを閉じる際に mkview 実施
    autocmd BufWritePost * if expand("%") != "" && &buftype !~ "nofile" | mkview | endif

    " ファイルを開いたら読み込む
    autocmd BufRead * if expand("%") != "" && &buftype !~ "nofile" | silent loadview | endif
  augroup END
endif

" undo管理設定
if isdirectory(expand("~/.vim/undo"))
  set undodir=~/.vim/undo
  set undofile
endif

"-----------------------------------
" gvimの設定
"-----------------------------------

if has("gui_running")
  if has("vim_starting")
    " フォント設定
    if has("win32") || has("win64")
      set guifont=Cica:h12
      set printfont=Cica:h8
    endif

    " 縦幅 デフォルトは24
    set lines=40

    " 横幅 デフォルトは80
    set columns=120
  endif

  " GUIオプション
  set guioptions=AcfiM

  " 行間設定
  set linespace=0

  " カーソルを点滅させない
  set guicursor=a:blinkon0

  " 挿入モードのIMEデフォルト
  set iminsert=0

  " 検索時のIMEデフォルト
  set imsearch=-1
endif

"-----------------------------------
" 表示の設定
"-----------------------------------

" renderoptions
if has("win32") || has("win64")
  set rop=type:directx,renmode:5
endif

" 空白文字の表示
" とりあえずTAB/行末スペース/省略文字(右)/省略文字(左)/nbsp
set list
set listchars=tab:\|\ ,trail:_,extends:>,precedes:<,nbsp:%

" 行番号を表示する
set number

" 行可視化
set nocursorline

" 列可視化
set nocursorcolumn

" 相対行で表示
set norelativenumber

" 右側で折り返す
set wrap

" 行の最後まで表示する
set display=lastline

" インデントを付けて折り返し
set breakindent

" 文字幅の設定
" マルチバイト文字等でずれないようにする
set ambiwidth=double

" 上下の視界確保
set scrolloff=4

" 左右の視界確保
set sidescrolloff=8

" 左右スクロール値の設定
set sidescroll=1

" コマンドラインの行数
set cmdheight=2

" 括弧強調
set showmatch

" 括弧のカーソルが飛ぶ時間(x0.1秒)
set matchtime=2

" 補完メニューの高さ
set pumheight=20

" シンタックスON
syntax enable

" 背景設定
" カラースキーム設定
try
  set t_Co=16
  colorscheme midoronuma
catch
endtry
