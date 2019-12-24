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
" 基本設定
"-----------------------------------

" defaults.vim の読み込み
if filereadable(expand($VIMRUNTIME . "/defaults.vim"))
  source $VIMRUNTIME/defaults.vim
endif

" 読み込みディレクトリの追記
set runtimepath^=~/.vim

" パッケージディレクトリの追記
set packpath^=~/.vim

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
" プラグイン設定
"-----------------------------------

" minpacの取得
if !isdirectory(expand("~/.vim/pack/minpac/opt/minpac"))
  call system("git clone https://github.com/k-takata/minpac.git " . expand("~/.vim/pack/minpac/opt/minpac"))
endif

if exists("*minpac#init")
  call minpac#init()
  call minpac#add("https://github.com/k-takata/minpac.git", {"type": "opt"})
  call minpac#add("https://github.com/vim-jp/vimdoc-ja.git")
  call minpac#add("https://github.com/morhetz/gruvbox.git")
  call minpac#add("https://github.com/pasela/edark.vim.git")
  call minpac#add("https://github.com/vim-jp/vital.vim.git", {"type": "opt"})
  call minpac#add("https://github.com/junegunn/vim-easy-align.git")
  call minpac#add("https://github.com/ctrlpvim/ctrlp.vim.git")
  call minpac#add("https://github.com/ansanloms/ctrlp-launcher.git")
  call minpac#add("https://github.com/ivalkeen/vim-ctrlp-tjump.git")
  call minpac#add("https://github.com/tpope/vim-fugitive.git")
  call minpac#add("https://github.com/tyru/open-browser.vim.git")
  call minpac#add("https://github.com/thinca/vim-quickrun.git")
  call minpac#add("https://github.com/prabirshrestha/vim-lsp.git")
  call minpac#add("https://github.com/prabirshrestha/asyncomplete.vim.git")
  call minpac#add("https://github.com/prabirshrestha/async.vim.git")
  call minpac#add("https://github.com/prabirshrestha/asyncomplete-lsp.vim.git")
  call minpac#add("https://github.com/vim-scripts/Super-Shell-Indent.git", {"type": "opt"})
  call minpac#add("https://github.com/vim-scripts/sh.vim.git", {"type": "opt"})
  call minpac#add("https://github.com/itchyny/vim-parenmatch.git")
  call minpac#add("https://github.com/yukpiz/vim-volt-syntax.git")
  call minpac#add("https://github.com/mattn/emmet-vim.git")
  call minpac#add("https://github.com/mopp/sky-color-clock.vim.git")
  call minpac#add("https://github.com/pangloss/vim-javascript.git", {"type": "opt"})
  call minpac#add("https://github.com/leafgarland/typescript-vim.git", {"type": "opt"})
  call minpac#add("https://github.com/MaxMEllon/vim-jsx-pretty.git", {"type": "opt"})
  call minpac#add("https://github.com/vim-jp/vim-java.git", {"type": "opt"})
  call minpac#add("https://github.com/vim-scripts/renamer.vim.git")
  call minpac#add("https://github.com/vim-scripts/groovyindent.git", {"type": "opt"})
  call minpac#add("https://github.com/cocopon/iceberg.vim.git")
  call minpac#add("https://github.com/vim-scripts/apachestyle.git", {"type": "opt"})
  call minpac#add("https://github.com/cespare/vim-toml.git")
  call minpac#add("https://github.com/twitvim/twitvim.git")
  call minpac#add("https://github.com/jparise/vim-graphql.git", {"type": "opt"})
  call minpac#add("https://github.com/ryanolsonx/vim-lsp-typescript.git", {"type": "opt"})
  call minpac#add("https://github.com/mattn/vimtweak.git")
  call minpac#add("https://github.com/liuchengxu/vista.vim.git")
  call minpac#add("https://github.com/mattn/webapi-vim.git")
  call minpac#add("https://github.com/aklt/plantuml-syntax.git", {"type": "opt"})
  call minpac#add("https://github.com/kaicataldo/material.vim.git")
  call minpac#add("https://github.com/itchyny/lightline.vim.git")
endif

" Align
let g:Align_xstrlen = 3 " 幅広文字に対応する

" CtrlP
let g:ctrlp_use_caching = 1                                     " キャッシュを使用する
let g:ctrlp_cache_dir = expand("~/.cache/ctrlp")                " キャッシュディレクトリ
let g:ctrlp_clear_cache_on_exit = 0                             " 終了時にキャッシュを削除しない
let g:ctrlp_lazy_update = 1                                     " 遅延再描画
let g:ctrlp_max_height = 20                                     " 20行表示
let g:ctrlp_open_new_file = 1                                   " ファイルの新規作成時は別タブで開く
let g:ctrlp_launcher_file_list = ["~/.ctrlp-launcher", "~/.ctrlp-launcher-work", "~/.ctrlp-launcher-gcp"]  " ランチャーで読み込むファイルパス
let g:ctrlp_tjump_only_silent = 0                               " タグジャンプ時にジャンプ先が1つしかない場合はCtrlPウィンドウを開かずジャンプしない
let g:ctrlp_custom_ignore = '\v[\/](node_modules|build|git)$'   " 除外

" quickrun
let g:quickrun_config = {}
let g:quickrun_config["_"] = {
\ "runner": "job",
\}

" quickrun - java
let g:quickrun_config["java"] = {
\ "hook/cd/directory": "%S:p:h",
\ "exec": [
\   "javac -J-Dfile.encoding=UTF8 %o %s",
\   "%c -Dfile.encoding=UTF8 %s:t:r %a"
\ ]
\}

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

" parenmatch
let g:loaded_matchparen = 1     " matchparenを無効にする

" sky-color-clock.vim
let g:sky_color_clock#datetime_format = "%Y.%m.%d (%a) %H:%M"     " 日付フォーマット
let g:sky_color_clock#enable_emoji_icon = 1                       " 絵文字表示

" vimtweak
autocmd guienter * silent! VimTweakSetAlpha 230

" vim-lsp
let g:lsp_signs_enabled = 1           " enable signs
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1 " enable echo under cursor when in normal mode

let g:lsp_signs_error = {"text": "✗"}
let g:lsp_signs_warning = {"text": "‼"}

let g:lsp_log_verbose = 1
let g:lsp_log_file = expand("~/.vim/logs/vim-lsp.log")

" for asyncomplete.vim log
let g:asyncomplete_log_file = expand("~/.vim/asyncomplete.log")

let g:asyncomplete_remove_duplicates = 1
let g:asyncomplete_smart_completion = 1
let g:asyncomplete_auto_popup = 1

" markdown

" foldさせない
let g:vim_markdown_folding_disabled = 1

" conceal設定
let g:vim_markdown_conceal = 0

let g:vim_markdown_liquid=1
let g:vim_markdown_math=0
let g:vim_markdown_frontmatter=1
let g:vim_markdown_toml_frontmatter=1
let g:vim_markdown_json_frontmatter=0

" vista
let g:vista_icon_indent = ["▸ ", ""]
let g:vista_sidebar_width = 60

let g:vista_default_executive = "ctags"

let g:vista_executive_for = {
\ "java": "vim_lsp",
\ "javascript": "vim_lsp",
\ "typescript": "vim_lsp",
\}

" material.vim
let g:material_theme_style = "darker"

let g:material_terminal_italics = 0

" lightline
let g:lightline = {
\ "colorscheme": "iceberg",
\ "active": {
\   "left": [
\     ["mode", "paste"],
\     ["gitbranch", "filename"],
\   ],
\   "right": [
\     ["sky_color_clock"],
\     ["percent"],
\     ["fileformat", "fileencoding", "filetype"],
\   ]
\ },
\ "component_function": {
\   "mode": "lightline#mode",
\   "gitbranch": "fugitive#head",
\   "filename": "LightlineFilename",
\ },
\ "component": {
\   "modified": "%{(LightlineIsVisible() && &modifiable) ? (&modified ? '[+]' : '[-]') : ''}",
\   "fileformat": "%{LightlineIsVisible() ? &fileformat : ''}",
\   "filetype": "%{LightlineIsVisible() ? (strlen(&filetype) ? &filetype : 'no ft') : ''}",
\   "fileencoding": "%{LightlineIsVisible() ? (&fileencoding !=# '' ? &fileencoding : &encoding) : ''}",
\   "sky_color_clock": "%#SkyColorClock#%{' ' . sky_color_clock#statusline() . ' '}%#SkyColorClockTemp# ",
\ },
\ "component_raw": {
\   "sky_color_clock": 1,
\ },
\ "separator": {
\   "left": "",
\   "right": ""
\ },
\ "subseparator": {
\   "left": "",
\   "right": ""
\ }
\}

function! LightlineIsVisible() abort
  return (60 <= winwidth(0)) && (&filetype !~? "help\|vista")
endfunction

function! LightlineFilename()
  if &filetype ==# "vista"
    return ""
  endif

  if expand("%:t") == ""
    return "[No Name]"
  endif

  " https://bitbucket.org/ns9tks/vim-fuzzyfinder/src/tip/autoload/fuf.vim
  let l:str = expand("%:p")
  let l:len = (winwidth(0)/2) - len(expand("%:p:t"))
  let l:mask = "..."

  if l:len >= len(l:str)
    return l:str
  elseif l:len <= len(l:mask)
    return l:mask
  endif

  let l:head = (l:len - len(l:mask)) / 2
  let l:tail = l:len - len(l:mask) - l:head

  return (l:head > 0 ? l:str[: l:head - 1] : "") . l:mask . (l:tail > 0 ? l:str[-l:tail :] : "")
endfunction

"-----------------------------------
" ステータスラインの設定
"-----------------------------------

" ステータスラインを常に表示
set laststatus=2

"" https://bitbucket.org/ns9tks/vim-fuzzyfinder/src/tip/autoload/fuf.vim
"" TODO: マルチバイト文字が崩れるのをなんとかする
"function! SnipMid(str, len, mask)
"  if a:len >= len(a:str)
"    return a:str
"  elseif a:len <= len(a:mask)
"    return a:mask
"  endif
"
"  let len_head = (a:len - len(a:mask)) / 2
"  let len_tail = a:len - len(a:mask) - len_head
"
"  return (len_head > 0 ? a:str[: len_head - 1] : "") . a:mask . (len_tail > 0 ? a:str[-len_tail :] : "")
"endfunction
"
"" モード取得
"function! StatuslineMode()
"  let mode_list = {
"  \ "n":       "NORMAL"
"  \ ,"i":      "INSERT"
"  \ ,"R":      "REPLACE"
"  \ ,"v":      "VISUAL"
"  \ ,"V":      "V-LINE"
"  \ ,"c":      "COMMAND"
"  \ ,"\<C-v>": "V-BLOCK"
"  \ ,"s":      "SELECT"
"  \ ,"S":      "S-LINE"
"  \ ,"\<C-s>": "S-BLOCK"
"  \ ,"t":      "TERMINAL"
"  \ ,"?":      "?"
"  \}
"  let current_mode = mode()
"  let paste_mode   = (&paste) ? "(PASTE)" : ""
"  if has_key(mode_list, current_mode)
"    return mode_list[current_mode] . paste_mode
"  endif
"  return current_mode.paste_mode . "?"
"endfunction
"
"set statusline=[%{StatuslineMode()}]                                                          " モード表示
"set statusline+=%{SnipMid(expand('%:p'),(winwidth(0)/2)-len(expand('%:p:t')),'...')}          " ファイルパス
"set statusline+=%m                                                                            " 修正フラグ
"set statusline+=%r                                                                            " 読み込み専用フラグ
"set statusline+=%h                                                                            " ヘルプバッファフラグ
"set statusline+=%w                                                                            " プレビューウィンドウフラグ
"set statusline+=%=                                                                            " 左寄せ項目と右寄せ項目の区切り
"set statusline+=[%{&filetype}]                                                                " ファイルタイプ
"set statusline+=[%{&fileformat}]                                                              " 改行コード
"set statusline+=[%{&fileencoding}]                                                            " 文字コード
"set statusline+=[%l/%L\ %p%%]                                                                 " 現在行数/全行数 カーソル位置までの割合
"set statusline+=%#SkyColorClock#\ %{sky_color_clock#statusline()}\  " <-- 行末にSP有          " 日付と月齢表示

"-----------------------------------
" タブラインの設定
"-----------------------------------

" タブラインを常に表示
set showtabline=2

"" タブラインの設定
"set tabline=%!MakeTabLine()
"
"function! MakeTabLine()
"  let sep = ""  " タブ間の区切り
"  return join(map(range(1, tabpagenr("$")), "s:tabpage_label(v:val)"), sep) . sep . "%#TabLineFill#%T"
"endfunction
"
"function! s:tabpage_label(tabpagenr)
"  " タブページ内のバッファのリスト
"  let bufnrs = tabpagebuflist(a:tabpagenr)
"
"  " カレントタブページかどうかでハイライトを切り替える
"  let hi = a:tabpagenr is tabpagenr() ? "%#TabLineSel#" : "%#TabLine#"
"
"  " タブページ内に変更ありのバッファがあったら "+" を付ける
"  let mod = len(filter(copy(bufnrs), "getbufvar(v:val, \"&modified\")")) ? "[+]" : ""
"
"  " カレントバッファ
"  let curbufnr = bufnrs[tabpagewinnr(a:tabpagenr) - 1]  " tabpagewinnr() は 1 origin
"  let fname = fnamemodify(bufname(curbufnr), ":t")
"
"  return "%" . a:tabpagenr . "T" . hi . " " . a:tabpagenr . ":" . fname . mod . " " . "%T%#TabLineFill#"
"endfunction

"-----------------------------------
" インデントの設定
"-----------------------------------

" オートインデント
set smartindent

" インデントをスペース4つ分に設定
set tabstop=4

" 自動インデントでずれる幅
set shiftwidth=4

" Insertモードで <Tab> を挿入するとき代わりに
" 適切な数の空白(ソフトTAB)を使わない
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
endif

"-----------------------------------
" functions
"-----------------------------------

" memoを設置するディレクトリ
if has("win32") || has("win64")
  let g:ansanloms_memo_base_dir = expand("c:/dev/work/memo")
endif

" 自分用関数群
function! AnsanlomsFunctions()
  let l:func = {}

  " ファイルマネージャで開く
  function! l:func.filemanager() dict
    if has("win32") || has("win64")
      silent execute "!start explorer.exe /select," expand("%:p")
    elseif has("mac")
      silent execute "!open" expand("%:p")
    endif
  endfunction

  " タグファイル生成
  function! l:func.ctags(...) dict
    if !executable("ctags")
      echoerr "ctags command not found"
      return
    endif

    packadd vital.vim
    let l:path = vital#vital#new().import("Prelude").path2project_directory(expand("%:p"))
    let l:ctags_cmd = "ctags --output-format=e-ctags -R -f " . l:path . "/tags " . l:path

    if &filetype == "php"
      let l:ctags_cmd = "ctags --languages=PHP --php-types=c+f+d --langmap=PHP:.php.inc.volt --output-format=e-ctags -R -f " . l:path . "/tags " . l:path
    endif

    echo l:ctags_cmd
    let l:job_ctags = job_start(l:ctags_cmd, {})
  endfunction

  " hostsを開く
  function! l:func.hosts() dict
    let l:hosts_path = expand("/etc/hosts")

    if has("mac")
      " mac
      let l:hosts_path = expand("/private/etc/hosts")
    elseif has("win32") || has("win64")
      " windows
      let l:hosts_path = expand("C:/Windows/System32/drivers/etc/hosts")
    endif

    execute "edit " . l:hosts_path
  endfunction

  " メモ関連
  let l:func.memo = {}

  " メモ関連: memoを設置するディレクトリを取得
  function! l:func.memo.dir() dict
    let l:memo_base_dir = get(g:, "ansanloms_memo_base_dir", expand("~/memo"))

    if !isdirectory(expand(l:memo_base_dir))
      call mkdir(l:memo_base_dir, "p")
    endif

    if !isdirectory(expand(l:memo_base_dir))
      echoerr l:memo_base_dir . " is not a directory."
    endif

    return l:memo_base_dir
  endfunction

  " メモ関連: 開く
  function! l:func.memo.open(...) dict
    execute "edit " . expand(self.dir()) . "/" . get(a:, "1", strftime("%Y%m%d")) . ".md"
  endfunction

  " メモ関連: CtrlPで開く
  function! l:func.memo.list() dict
    execute "CtrlP " . expand(self.dir())
  endfunction

  " ターミナル関連
  let l:func.terminal = {}

  " ssh
  function! l:func.terminal.ssh(ssh) dict
    let l:cmd = "ssh " . a:ssh
    call term_start(l:cmd, {
    \ "term_name": l:cmd,
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " cmd
  function! l:func.terminal.cmd() dict
    call term_start("cmd", {
    \ "term_name": "cmd",
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " powershell
  function! l:func.terminal.powershell() dict
    call term_start("powershell", {
    \ "term_name": "powershell",
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " nyagos
  function! l:func.terminal.nyagos() dict
    call term_start([$HOME . "/scoop/apps/nyagos/current/nyagos"], {
    \ "term_name": "NYAGOS",
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " ubuntu
  function! l:func.terminal.ubuntu() dict
    call term_start("Ubuntu", {
    \ "term_name": "WSL (Ubuntu)",
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " debian
  function! l:func.terminal.debian() dict
    call term_start("Debian", {
    \ "term_name": "WSL (Debian)",
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " fedoraremix
  function! l:func.terminal.fedoraremix() dict
    call term_start("fedoraremix", {
    \ "term_name": "WSL (Fedora)",
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " sles12
  function! l:func.terminal.sles12() dict
    call term_start("sles12", {
    \ "term_name": "WSL (SLES-12)",
    \ "term_finish": "close",
    \ "curwin": 1
    \})
  endfunction

  " default
  function! l:func.terminal.default() dict
    if has("win32") || has("win64")
      if executable("nyagos")
        call self.nyagos()
      else
        call self.cmd()
      endif
    endif
  endfunction

  " exec
  function! l:func.terminal.exec(...) dict
    call self[get(a:, "1", "default")]()
  endfunction

  return l:func
endfunction

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

" functions
command! OpenFilemanager call AnsanlomsFunctions().filemanager()
command! OpenHosts call AnsanlomsFunctions().hosts()
command! Ctags call AnsanlomsFunctions().ctags()
command! -nargs=? TermAlias call AnsanlomsFunctions().terminal.exec(<f-args>)

" Leaderの設定
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
nnoremap <silent> <Esc><Esc> :<C-u>nohlsearch<CR>

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

" CtrlPtjump
nnoremap <C-]> :<C-u>CtrlPtjump<CR>
vnoremap <C-]> :<C-u>CtrlPtjumpVisual<CR>

" タグジャンプの際に新しいタブで開く
"nnoremap <C-]> :<C-u>tab stj <C-R>=expand("<cword>")<CR><CR>

" minpac
command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update("", {"do": "call minpac#status()"})
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()
command! PackStatus packadd minpac | source $MYVIMRC | call minpac#status()

" libtermkeyのサポートを無効にする？
" https://gitlab.com/gnachman/iterm2/issues/3519
" <S-space>とか押すと ^[[32;2u[ とかはいるやつの対策
" あんまよくわかってない
" 取り急ぎ鬱陶しいやつだけ
tnoremap <S-space> <space>

"-----------------------------------
" Quickfixの設定
"-----------------------------------

augroup quickfix-setting
  autocmd!

  " ステータスラインを更新
  autocmd FileType qf setlocal statusline=%t%{exists('w:quickfix_title')\ ?\ '\ '.w:quickfix_title\ :\ ''}\ %=[%l/%L\ %p%%]
augroup END

"-----------------------------------
" Javaの設定
"-----------------------------------

let g:ansanloms_eclipse_workspace = expand("/dev/eclipse_workspace")

augroup java-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{java} setlocal filetype=java

  if !filereadable(expand("~/.vim/syntax/javaid.vim"))
    call system("curl https://fleiner.com/vim/syntax/javaid.vim -o " . expand("~/.vim/syntax/javaid.vim"))
  endif

  let g:java_highlight_all = 1

  " インデントセット
  autocmd FileType java setlocal shiftwidth=4 tabstop=4 softtabstop=4 noexpandtab

  if (has("win32") || has("win64"))
    " lombok
    let s:lombok_path = $HOME . "/scoop/apps/lombok/current/lombok.jar"
    " eclipse jdt の dir
    let s:eclipse_jdt_dir = $HOME . "/scoop/apps/eclipse-jdt-language-server/0.40.0"
    " eclipse jdt の config そのうちmacとかlinuxとか分ける必要あり
    let s:eclipse_jdt_config_dir = s:eclipse_jdt_dir . "/config_win"
    " equinox.launcher のパス バージョンごとに変わるのをどうにかしたい
    let s:eclipse_jdt_equinox_launcher_path = s:eclipse_jdt_dir . "/plugins/org.eclipse.equinox.launcher_1.5.400.v20190515-0925.jar"
    " workspace pleiadesのそれにのっかる
    let s:eclipse_workspace_dir = $HOME . "/scoop/apps/pleiades4.8-java-win-full/current/workspace"

    if executable("java") && filereadable(expand(s:eclipse_jdt_equinox_launcher_path)) && filereadable(expand(s:lombok_path))
      " vim-lsp の設定
      autocmd User lsp_setup call lsp#register_server({
      \ "name": "eclipse.jdt.ls",
      \ "cmd": {server_info->[
      \   "java",
      \   "-javaagent:" . expand(s:lombok_path),
      \   "-Xbootclasspath/a:" . expand(s:lombok_path),
      \   "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      \   "-Dosgi.bundles.defaultStartLevel=4",
      \   "-Declipse.product=org.eclipse.jdt.ls.core.product",
      \   "-Dlog.level=ALL",
      \   "-noverify",
      \   "-Dfile.encoding=UTF-8",
      \   "-Xmx1G",
      \   "-jar",
      \   expand(s:eclipse_jdt_equinox_launcher_path),
      \   "-configuration",
      \   expand(s:eclipse_jdt_config_dir),
      \   "-data",
      \   get(s:, "eclipse_workspace_dir", expand("~/workspace"))
      \ ]},
      \ "whitelist": ["java"],
      \})

      autocmd FileType java setlocal omnifunc=lsp#complete
      autocmd FileType java nnoremap <silent> <c-]> :<c-u>LspDefinition<CR>
    endif
  endif
augroup END

"-----------------------------------
" JavaScriptの設定
"-----------------------------------

augroup javascript-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{js,jsx} setlocal filetype=javascript

  " インデントセット
  autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType javascript packadd vim-javascript
  autocmd FileType javascript packadd vim-jsx-pretty

  " lsp
  if executable("typescript-language-server")
    autocmd User lsp_setup call lsp#register_server({
    \ "name": "javascript support using typescript-language-server",
    \ "cmd": {server_info->[&shell, &shellcmdflag, "typescript-language-server --stdio"]},
    \ "root_uri":{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), "package.json"))},
    \ "whitelist": ["javascript", "javascript.jsx"],
    \})

    autocmd FileType javascript setlocal omnifunc=lsp#complete
  endif
augroup END

"-----------------------------------
" TypeScriptの設定
"-----------------------------------

augroup typescript-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{ts,tsx} setlocal filetype=typescript

  " インデントセット
  autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType typescript packadd vim-jsx-pretty
  autocmd FileType typescript packadd vim-lsp-typescript
  autocmd FileType javascript packadd typescript-vim

  " lsp
  if executable("typescript-language-server")
    autocmd User lsp_setup call lsp#register_server({
    \ "name": "typescript-language-server",
    \ "cmd": {server_info->[&shell, &shellcmdflag, "typescript-language-server --stdio"]},
    \ "root_uri": {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), "tsconfig.json"))},
    \ "whitelist": ["typescript", "typescript.tsx"],
    \})

    autocmd FileType typescript setlocal omnifunc=lsp#complete
  endif
augroup END

"-----------------------------------
" PHPの設定
"-----------------------------------

" case文対応
let g:PHP_vintage_case_default_indent = 1

" 使用するDB
let g:sql_type_default = "mysql"

augroup php-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{php,ctp} set filetype=php

  " インデントセット
  autocmd FileType php setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " phpcbfを用いた更新
  if executable("phpcbf")
    autocmd FileType php nnoremap <silent><leader>pcf :w!<CR>:echo system("phpcbf --standard=PSR2 " . expand("%:p"))<CR>:e!<CR>
    autocmd FileType php nnoremap <silent><leader>pcd :w!<CR>:echo system("phpcbf --standard=PSR2 " . expand("%:p:h"))<CR>:e!<CR>
  endif

  autocmd FileType php setlocal omnifunc=lsp#complete

  " ハイライト行指定
  autocmd FileType php syntax sync minlines=300 maxlines=500
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
  autocmd filetype volt syntax sync minlines=300 maxlines=500
augroup END

"-----------------------------------
" markdownの設定
"-----------------------------------

augroup markdown-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown

  " インデントセット
  autocmd FileType markdown setlocal shiftwidth=2 tabstop=2 softtabstop=2 noexpandtab
augroup END

"-----------------------------------
" plantumlの設定
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
" shの設定
"-----------------------------------

augroup sh-setting
  autocmd!

  " インデントセット
  autocmd FileType sh setlocal shiftwidth=2 tabstop=2 softtabstop=2 noexpandtab

  " プラグイン読み込み
  autocmd FileType sh packadd Super-Shell-Indent
  autocmd FileType sh packadd sh.vim
  let g:sh_indent_case_labels=1
augroup END

"-----------------------------------
" VimScriptの設定
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
    autocmd FileType sql setlocal formatprg=sql-formatter
  endif
augroup END

"-----------------------------------
" htmlの設定
"-----------------------------------

augroup html-setting
  autocmd!

  " インデントセット
  autocmd FileType html setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

"-----------------------------------
" xmlの設定
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
" jsonの設定
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
" apache confの設定
"-----------------------------------

augroup apache-setting
  autocmd!

  " プラグイン読み込み
  autocmd FileType apache packadd apachestyle
augroup END

"-----------------------------------
" groovyの設定
"-----------------------------------

augroup groovy-setting
  autocmd!

  " プラグイン読み込み
  autocmd FileType groovy packadd groovyindent
augroup END

"-----------------------------------
" graphqlの設定
"-----------------------------------

augroup graphql-setting
  autocmd!

  " インデントセット
  autocmd FileType graphql setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " プラグイン読み込み
  autocmd FileType graphql packadd vim-graphql
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
      set guifont=Cica:h12:cSHIFTJIS:qDRAFT
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
set cursorline

" 列可視化
"set cursorcolumn

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
  set background=dark
  colorscheme iceberg
catch
endtry
