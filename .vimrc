"-----------------------------------
" 文字コード設定
"-----------------------------------

if has("vim_starting")
  " vim 内部で通常使用する文字エンコーディング
  set encoding=utf-8

  " 既存ファイルを開く際の文字コード自動判別
  set fileencodings=utf-8,sjis,cp932,euc-jp,iso-2022-jp

  " 改行文字設定
  set fileformats=unix,mac,dos
endif

" set encoding の後に記述する
scriptencoding utf-8

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
  \ ,"~/.vim/syntax"
  \ ,"~/.vim/pack"
  \ ,"~/.vim/logs"
  \]
    if !isdirectory(expand(dir))
      call mkdir(iconv(expand(dir), &encoding, &termencoding), "p")
    endif
  endfor
endif

"-----------------------------------
" 各種パスの設定
"-----------------------------------

" 読み込みディレクトリの追記
set runtimepath^=~/.vim

" パッケージディレクトリの追記
set packpath^=~/.vim

" viminfoの保存先を変更
set viminfo+=n~/.vim/viminfo

"-----------------------------------
" バックアップファイルとスワップファイル設定
"-----------------------------------

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

"-----------------------------------
" mkviewの設定
"-----------------------------------

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

"-----------------------------------
" undo管理設定
"-----------------------------------

if isdirectory(expand("~/.vim/undo"))
  set undodir=~/.vim/undo
  set undofile
endif

"-----------------------------------
" 他のvimが起動済ならそれを使う
" http://tyru.hatenablog.com/entry/20130430/vim_resident
"-----------------------------------

if argc() && (has("mac") || has("win32") || has("win64"))
  let s:running_vim_list = filter(split(serverlist(), "\n"), "v:val !=? v:servername")

  if !empty(s:running_vim_list)
    silent execute
    \ (has("gui_running") ? "!gvim" : "!vim")
    \ "--servername" s:running_vim_list[0]
    \ "--remote-tab-silent"
    \ join(map(argv(), "shellescape(v:val, 1)"), " ")
    qa!
  endif

  unlet s:running_vim_list
endif

"-----------------------------------
" 基本設定
"-----------------------------------

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
"set mouse-=a
set mouse=

" バッファ有効
set hidden

" filler: vimdiffで埋め立てを行う
" iwhite: vimdiffで空白を無視して比較する
set diffopt=filler,iwhite

" conceal処理の設定
" 0: 通常通り表示(デフォルト)
" 1: conceal対象のテキストは代理文字(初期設定はスペース)に置換される
" 2: conceal対象のテキストは非表示になる
" 3: conceal対象のテキストは完全に非表示
if has("conceal")
  set conceallevel=0
  set concealcursor=
endif

" スペルチェック
"set spell
"set spelllang+=cjk

" fold設定
"set foldmethod=syntax
"set foldlevel=1
"set foldnestmax=2
"set foldcolumn=2
set nofoldenable

" 外部grepの設定
if executable("grep")
  set grepprg=grep\ -Hnd\ skip\ -r
  set grepformat=%f:%l:%m,%f:%l%m,%f\ \ %l%m
endif

" beep音を消す
set belloff=all

" 構文アイテムを検索する桁数の最大値
set synmaxcol=600

" テキストの整形方法
set formatoptions=croql

"-----------------------------------
" ステータスラインの設定
"-----------------------------------

" ステータスラインを常に表示
set laststatus=2

"-----------------------------------
" タブラインの設定
"-----------------------------------

" タブラインを常に表示
set showtabline=2

"-----------------------------------
" インデントの設定
"-----------------------------------

" オートインデント
set smartindent

" インデントをスペース4つ分に設定
set tabstop=4

" 自動インデントでずれる幅
set shiftwidth=4

" ソフトTABの設定
"set expandtab
set noexpandtab

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

" タグファイルの二分探索
set tagbsearch

"-----------------------------------
" 補完の設定
"-----------------------------------

" ファイルパス保管をbashと同じようにする
set wildmode=list:longest

" 補完時に表示されるプレビューウィンドウを消す
set completeopt=menuone

"-----------------------------------
" terminal 設定
"-----------------------------------

if has("terminal")
  " 端末のエンコーディング
  set termencoding="utf-8"

  " pty 指定
  set termwintype="conpty"
endif

"-----------------------------------
" プラグイン設定
"-----------------------------------

" minpacの取得
if !isdirectory(expand("~/.vim/pack/minpac/opt/minpac"))
  call system("git clone https://github.com/k-takata/minpac.git " . expand("~/.vim/pack/minpac/opt/minpac"))
endif

if exists("*minpac#init")
  call minpac#init()
  call minpac#add("https://github.com/k-takata/minpac.git", {"type": "opt"})

  " general
  call minpac#add("https://github.com/vim-jp/vimdoc-ja.git")
  call minpac#add("https://github.com/vim-jp/vital.vim.git", {"type": "opt"})
  call minpac#add("https://github.com/itchyny/vim-parenmatch.git")
  call minpac#add("https://github.com/thinca/vim-quickrun.git")
  call minpac#add("https://github.com/junegunn/vim-easy-align.git")
  call minpac#add("https://github.com/tyru/open-browser.vim.git")

  " git
  call minpac#add("https://github.com/tpope/vim-fugitive.git")

  " ctrlp
  call minpac#add("https://github.com/ctrlpvim/ctrlp.vim.git")
  call minpac#add("https://github.com/ansanloms/ctrlp-launcher.git")

  " sh
  call minpac#add("https://github.com/vim-scripts/Super-Shell-Indent.git", {"type": "opt"})
  call minpac#add("https://github.com/vim-scripts/sh.vim.git", {"type": "opt"})

  " php / volt
  call minpac#add("https://github.com/yukpiz/vim-volt-syntax.git", {"type": "opt"})

  " Java
  call minpac#add("https://github.com/vim-jp/vim-java.git", {"type": "opt"})
  if !filereadable(expand("~/.vim/syntax/javaid.vim"))
    call system("curl https://fleiner.com/vim/syntax/javaid.vim -o " . expand("~/.vim/syntax/javaid.vim"))
  endif

  " JavaScript / TypeScript
  call minpac#add("https://github.com/pangloss/vim-javascript.git", {"type": "opt"})
  call minpac#add("https://github.com/MaxMEllon/vim-jsx-pretty.git", {"type": "opt"})
  call minpac#add("https://github.com/leafgarland/typescript-vim.git", {"type": "opt"})

  " vue
  call minpac#add("https://github.com/posva/vim-vue.git", {"type": "opt"})

  " gradle
  call minpac#add("https://github.com/vim-scripts/groovyindent.git", {"type": "opt"})

  " plantuml
  call minpac#add("https://github.com/aklt/plantuml-syntax.git", {"type": "opt"})

  " toml
  call minpac#add("https://github.com/cespare/vim-toml.git", {"type": "opt"})

  " apache
  call minpac#add("https://github.com/vim-scripts/apachestyle.git", {"type": "opt"})

  " graphql
  call minpac#add("https://github.com/jparise/vim-graphql.git", {"type": "opt"})

  " html
  call minpac#add("https://github.com/mattn/emmet-vim.git")

  " yaml
  call minpac#add("https://github.com/stephpy/vim-yaml.git", {"type": "opt"})

  " powershell
  call minpac#add("https://github.com/PProvost/vim-ps1.git", {"type": "opt"})

  " appearance
  call minpac#add("https://github.com/mopp/sky-color-clock.vim.git")
  call minpac#add("https://github.com/mattn/vimtweak.git")
  call minpac#add("https://github.com/itchyny/vim-cursorword.git")

  " colorscheme
  call minpac#add("https://github.com/cocopon/iceberg.vim.git")
  call minpac#add("https://github.com/Rigellute/rigel.git")
  call minpac#add("https://github.com/whatyouhide/vim-gotham.git")
  call minpac#add("https://github.com/arcticicestudio/nord-vim.git")

  " lsp
  call minpac#add("https://github.com/prabirshrestha/asyncomplete.vim.git")
  call minpac#add("https://github.com/prabirshrestha/asyncomplete-lsp.vim.git")
  call minpac#add("https://github.com/prabirshrestha/vim-lsp.git")
  call minpac#add("https://github.com/mattn/vim-lsp-settings.git")

  " growi
  call minpac#add("https://github.com/ansanloms/vim-growi.git")
endif

" CtrlP
let g:ctrlp_use_caching = 1                                     " キャッシュを使用する
let g:ctrlp_cache_dir = expand("~/.cache/ctrlp")                " キャッシュディレクトリ
let g:ctrlp_clear_cache_on_exit = 0                             " 終了時にキャッシュを削除しない
let g:ctrlp_lazy_update = 1                                     " 遅延再描画
let g:ctrlp_max_height = 20                                     " 20行表示
let g:ctrlp_open_new_file = 1                                   " ファイルの新規作成時は別タブで開く
let g:ctrlp_launcher_file_list = ["~/.ctrlp-launcher", "~/.ctrlp-launcher-work", "~/.ctrlp-launcher-gcp"]  " ランチャーで読み込むファイルパス
let g:ctrlp_custom_ignore = '\v[\/](node_modules|build|git)$'   " 除外

" quickrun
let g:quickrun_config = {}
let g:quickrun_config["_"] = {
\ "runner": "job",
\}

" parenmatch
let g:loaded_matchparen = 1     " matchparenを無効にする

" sky-color-clock.vim
let g:sky_color_clock#datetime_format = "%Y.%m.%d (%a) %H:%M"     " 日付フォーマット
let g:sky_color_clock#enable_emoji_icon = 1                       " 絵文字表示

" vimtweak
augroup vimtweak-setting
  autocmd!

  autocmd guienter * silent! VimTweakSetAlpha 230
augroup END

"-----------------------------------
" ステータスラインの設定
"-----------------------------------

" ステータスラインを常に表示
set laststatus=2

" 表示設定
set statusline=%!ansanloms#statusline#statusline()

"-----------------------------------
" タブラインの設定
"-----------------------------------

" タブラインを常に表示
set showtabline=2

" タブラインの設定
set tabline=%!ansanloms#tabline#tabline()

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

" memoを設置するディレクトリ
if has("win32") || has("win64")
  let g:ansanloms_memo_base_dir = expand("c:/dev/work/memo")
endif

command! OpenFilemanager call ansanloms#filemanager#open()
command! OpenVscode call ansanloms#vscode#open()
command! OpenPhpstorm call ansanloms#phpstorm#open()
command! -range OpenBitbucket <line1>,<line2>call ansanloms#bitbucket#open()
command! OpenHosts call ansanloms#hosts#open()
command! Ctags call ansanloms#ctags#create()
command! -nargs=? Memo call ansanloms#memo#open(<f-args>)
command! MemoDaily call ansanloms#memo#open()
command! MemoList call ansanloms#memo#list()

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

" undo-branche
nnoremap u g-
nnoremap <C-r> g+

" バッファ
nnoremap <Leader>b :<C-u>ls<CR>:<C-u>buf<Space>

" CtrlPLauncher
nnoremap <C-e> :<C-u>CtrlPLauncher<CR>

" CtrlPMRUFile
nnoremap <C-h> :<C-u>CtrlPMRUFiles<CR>

" CtrlPBuffer
nnoremap <C-s> :<C-u>CtrlPBuffer<CR>

" タグジャンプの際に新しいタブで開く
nnoremap <C-]> :<C-u>tab stj <C-R>=expand("<cword>")<CR><CR>

" minpac
command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update("", {"do": "call minpac#status()"})
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()
command! PackStatus packadd minpac | source $MYVIMRC | call minpac#status()

" <S-space>とか押すと ^[[32;2u[ とかはいるやつの対策
" あんまよくわかってない
" 取り急ぎ鬱陶しいやつだけ
tnoremap <S-space> <space>
tnoremap <C-BS> <BS>
tnoremap <C-CR> <CR>

"-----------------------------------
" lsp の設定
"-----------------------------------

" vim-lsp
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_text_edit_enabled = 1
let g:lsp_signs_enabled = 1

let g:lsp_signs_error = {"text": "❌"}
let g:lsp_signs_warning = {"text": "⚠️"}
let g:lsp_signs_information = {"text": "❗"}
let g:lsp_signs_hint = {"text": "❓"}

" asyncomplete.vim
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 1
let g:asyncomplete_popup_delay = 200

augroup lsp-setting
  autocmd!

  autocmd User lsp_buffer_enabled setlocal omnifunc=lsp#complete
  autocmd User lsp_buffer_enabled setlocal signcolumn=yes
  autocmd User lsp_buffer_enabled setlocal tagfunc=lsp#tagfunc
  autocmd User lsp_buffer_enabled nmap <buffer> gD <plug>(lsp-definition)
  autocmd User lsp_buffer_enabled nmap <buffer> gd <Plug>(lsp-peek-definition)
  autocmd User lsp_buffer_enabled nmap <buffer> K <Plug>(lsp-hover)
augroup END

"-----------------------------------
" Quickfixの設定
"-----------------------------------
augroup quickfix-setting
  autocmd!

  " ステータスラインを更新
  autocmd FileType qf setlocal statusline=%!ansanloms#statusline#statusline_quickfix()
augroup END

"-----------------------------------
" Java の設定
"-----------------------------------

let g:java_highlight_all = 1

" quickrun - java
let g:quickrun_config["java"] = {
\ "hook/cd/directory": "%S:p:h",
\ "exec": [
\   "javac -J-Dfile.encoding=UTF8 %o %s",
\   "%c -Dfile.encoding=UTF8 %s:t:r %a"
\ ]
\}

augroup java-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{java} setlocal filetype=java

  " インデントセット
  autocmd FileType java setlocal shiftwidth=4 tabstop=4 softtabstop=4 noexpandtab
augroup END

"-----------------------------------
" JavaScript の設定
"-----------------------------------

augroup javascript-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.js setlocal filetype=javascript
  autocmd BufNewFile,BufRead *.jsx setlocal filetype=javascript.jsx

  " インデントセット
  autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType javascript.jsx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType javascript packadd vim-javascript
  autocmd FileType javascript packadd vim-jsx-pretty
  autocmd FileType javascript.jsx packadd vim-javascript
  autocmd FileType javascript.jsx packadd vim-jsx-pretty
augroup END

"-----------------------------------
" TypeScript の設定
"-----------------------------------

augroup typescript-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.ts setlocal filetype=typescript
  autocmd BufNewFile,BufRead *.tsx setlocal filetype=typescript.tsx

  " インデントセット
  autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType typescript.tsx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType typescript packadd vim-jsx-pretty
  autocmd FileType typescript packadd typescript-vim
  autocmd FileType typescript.tsx packadd vim-jsx-pretty
  autocmd FileType typescript.tsx packadd typescript-vim
augroup END

"-----------------------------------
" vue の設定
"-----------------------------------

augroup vue-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{vue} setlocal filetype=vue

  " インデントセット
  autocmd FileType vue setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType vue packadd vim-vue
augroup END

"-----------------------------------
" PHP の設定
"-----------------------------------

" case 文対応
let g:PHP_vintage_case_default_indent = 1

" 使用する DB
let g:sql_type_default = "mysql"

augroup php-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{php,ctp} set filetype=php

  " インデントセット
  autocmd FileType php setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " ハイライト行指定
  autocmd FileType php syntax sync minlines=300 maxlines=500

  " プラグイン読み込み
  autocmd FileType php packadd vimspector
augroup END

"-----------------------------------
" volt (PHP) の設定
"-----------------------------------

augroup volt-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.volt set filetype=volt

  " インデントセット
  autocmd filetype volt setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " ハイライト行指定
  autocmd filetype volt syntax sync minlines=300 maxlines=500

  " プラグイン読み込み
  autocmd FileType volt packadd vim-volt-syntax
augroup END

"-----------------------------------
" markdown の設定
"-----------------------------------

" quickrun - markdown
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

augroup markdown-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown

  " インデントセット
  autocmd FileType markdown setlocal shiftwidth=2 tabstop=2 softtabstop=2 noexpandtab
augroup END

"-----------------------------------
" plantuml の設定
"-----------------------------------

augroup plantuml-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{pu,uml,puml,iuml,plantuml} set filetype=plantuml

  " インデントセット
  autocmd FileType plantuml setlocal shiftwidth=2 tabstop=2 softtabstop=2 noexpandtab

  " プラグイン読み込み
  autocmd FileType plantuml packadd plantuml-syntax
augroup END

"-----------------------------------
" sh の設定
"-----------------------------------

let g:sh_indent_case_labels = 1

augroup sh-setting
  autocmd!

  " インデントセット
  autocmd FileType sh setlocal shiftwidth=2 tabstop=2 softtabstop=2 noexpandtab

  " プラグイン読み込み
  autocmd FileType sh packadd Super-Shell-Indent
  autocmd FileType sh packadd sh.vim
augroup END

"-----------------------------------
" Vim script の設定
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
" sql の設定
"-----------------------------------

" quickrun - mysql
if executable("mysql")
  let g:quickrun_config["sql"] = {
  \ "type": "sql/mysql"
  \}

  let g:quickrun_config["sql/mysql"] = {
  \ "command": "mysql",
  \ "cmdopt": "--defaults-extra-file=" . expand("~/.mysql/local.conf"),
  \ "exec": ["%c %o < %s"]
  \}
endif

augroup sql-setting
  autocmd!

  " インデントセット
  autocmd FileType sql setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " 折り返さない
  autocmd FileType sql setlocal nowrap

  " フォーマット指定
  if executable("sql-formatter")
    autocmd FileType sql setlocal formatprg=sql-formatter
  endif
augroup END

"-----------------------------------
" html の設定
"-----------------------------------

" quickrun - html
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

augroup html-setting
  autocmd!

  " インデントセット
  autocmd FileType html setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

"-----------------------------------
" xml の設定
"-----------------------------------

augroup xml-setting
  autocmd!

  " インデントセット
  autocmd FileType xml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " フォーマット指定
  if executable("xmllint")
    autocmd FileType xml setlocal formatprg=xmllint\ --format\ -
  elseif executable("python")
    autocmd FileType xml setlocal formatprg=python\ -c\ 'import\ sys;import\ xml.dom.minidom;s=sys.stdin.read();print(xml.dom.minidom.parseString(s).toprettyxml())'
  endif
augroup END

"-----------------------------------
" json の設定
"-----------------------------------

" conceal表示を無効にする
let g:vim_json_syntax_conceal = 0

" ダブルクォーテーションは常に表示
let g:vim_json_syntax_conceal = 0

augroup json-setting
  autocmd!

  " インデントセット
  autocmd FileType json setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " フォーマット指定
  if executable("python")
    autocmd FileType json setlocal formatprg=python\ -m\ json.tool
  endif
augroup END

"-----------------------------------
" apache conf の設定
"-----------------------------------

augroup apache-setting
  autocmd!

  " プラグイン読み込み
  autocmd FileType apache packadd apachestyle
augroup END

"-----------------------------------
" groovy の設定
"-----------------------------------

augroup groovy-setting
  autocmd!

  " プラグイン読み込み
  autocmd FileType groovy packadd groovyindent
augroup END

"-----------------------------------
" graphql の設定
"-----------------------------------

augroup graphql-setting
  autocmd!

  " インデントセット
  autocmd FileType graphql setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType graphql packadd vim-graphql
augroup END

"-----------------------------------
" toml の設定
"-----------------------------------

augroup toml-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{toml} setlocal filetype=toml

  " インデントセット
  autocmd FileType toml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType toml packadd vim-toml
augroup END

"-----------------------------------
" yaml の設定
"-----------------------------------

augroup yaml-setting
  autocmd!

  " インデントセット
  autocmd FileType yaml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType yaml packadd vim-yaml
augroup END

"-----------------------------------
" powershell の設定
"-----------------------------------

augroup powershell-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{ps1} setlocal filetype=ps1

  " プラグイン読み込み
  autocmd FileType ps1 packadd vim-ps1
augroup END

"-----------------------------------
" バイナリエディタの設定
"-----------------------------------

augroup binary-setting
  autocmd!
  autocmd BufReadPre  *.{bin,dll,exe} let &bin=1
  autocmd BufReadPost *.{bin,dll,exe} if &bin | %!xxd
  autocmd BufReadPost *.{bin,dll,exe} set ft=xxd | endif
  autocmd BufWritePre *.{bin,dll,exe} if &bin | %!xxd -r
  autocmd BufWritePre *.{bin,dll,exe} endif
  autocmd BufWritePost *.{bin,dll,exe} if &bin | %!xxd
  autocmd BufWritePost *.{bin,dll,exe} set nomod | endif
augroup END

"-----------------------------------
" netrw の設定
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
    let l:cursor = getpos(".")
    %s/\s\+$//ge
    call setpos(".", cursor)
    unlet l:cursor
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

" お仕事用設定
if filereadable(expand("~/.vim/work.vim"))
  source ~/.vim/work.vim
endif

"-----------------------------------
" gVim の設定
"-----------------------------------

if has("gui_running")
  if has("vim_starting")
    " フォント設定
    if has("win32") || has("win64")
      set guifont=Cica:h10:cSHIFTJIS:qDRAFT
      set renderoptions=type:directx,gamma:1.0,contrast:0,level:0.0,geom:1,renmode:5,taamode:1
    endif

    " 縦幅 デフォルトは24
    set lines=40

    " 横幅 デフォルトは80
    set columns=120
  endif

  " GUIオプション
  set guioptions=AcfiM!

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

" 空白文字の表示
" とりあえずTAB/行末スペース/省略文字(右)/省略文字(左)/nbsp
set list
set listchars=tab:\|\ ,trail:_,extends:>,precedes:<,nbsp:%

" 画面描画の設定
set lazyredraw    " コマンド実行時の画面描画をしない
set ttyfast       " 高速ターミナル接続

" True Colorでのシンタックスハイライト
if (has("termguicolors"))
  set termguicolors
endif

" 行番号を表示する
set number

" 行可視化
"set cursorline
set nocursorline

" 列可視化
"set cursorcolumn
set norelativenumber

" 相対行で表示
"set relativenumber

" 右側で折り返す
set wrap

" 行の最後まで表示する
set display=lastline

" インデントを付けて折り返し
set breakindent

" 文字幅の設定
" マルチバイト文字等でずれないようにする
set ambiwidth=single

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

try
  set background=dark
  colorscheme nord
catch
endtry
