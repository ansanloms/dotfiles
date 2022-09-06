" 文字コード {{{

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

" }}}

" ディレクトリ {{{

if has("vim_starting")
  for dir in [
  \ "~/.vim"
  \ ,"~/.vim/autoload"
  \ ,"~/.vim/plugin"
  \ ,"~/.vim/backup"
  \ ,"~/.vim/view"
  \ ,"~/.vim/undo"
  \ ,"~/.vim/syntax"
  \ ,"~/.vim/pack"
  \ ,"~/.vim/logs"
  \]
    if !isdirectory(expand(dir))
      call mkdir(expand(dir), "p")
    endif
  endfor

  unlet dir
endif

" }}}

" 初期設定 {{{

" 読み込みディレクトリの追記
set runtimepath^=~/.vim

" パッケージディレクトリの追記
set packpath^=~/.vim

" }}}

" viminfo {{{

set viminfo=

" oldfiles の保存数
set viminfo+='10000

" コマンドライン履歴数
set viminfo+=:100

" レジスタの保存最大数
set viminfo+=<1000
set viminfo+=s10

" viminfo の保存先を変更
set viminfo+=n~/.vim/viminfo

" }}}

" backup / swapfile {{{

if isdirectory(expand("~/.vim/backup"))
  " バックアップ保存先
  set backupdir=~/.vim/backup

  " スワップファイル保存先
  set directory=~/.vim/backup

  " バックアップ有効
  set backup

  " 上書き前にバックアップ作成
  set writebackup

  " スワップファイル有効
  set swapfile
endif

" }}}

" mkview {{{

if isdirectory(expand("~/.vim/view"))
  " mkview 保存先
  set viewdir=~/.vim/view

  " :mkview で保存する設定
  " cursor ファイル／ウィンドウ内のカーソル位置
  " folds  手動で作られた折り畳み、折り畳みの開閉の区別、折り畳み
  set viewoptions=cursor

  augroup vim-view
    autocmd!

    " ファイルを閉じる際に mkview 実施
    autocmd BufWritePost * if expand("%") != "" && &buftype !~ "nofile" | mkview | endif

    " ファイルを開いたら読み込む
    autocmd BufRead * if expand("%") != "" && &buftype !~ "nofile" | silent loadview | endif
  augroup END
endif

" }}}

" undo {{{

if isdirectory(expand("~/.vim/undo"))
  " undo 管理先
  set undodir=~/.vim/undo

  " undo 機能を有効にする
  set undofile
endif

" }}}

" 他の vim が起動済ならそれを使う {{{

" http://tyru.hatenablog.com/entry/20130430/vim_resident

if argc() && (has("mac") || has("win32") || has("win64"))
  let s:running_vim_list = filter(split(serverlist(), "\n"), { v -> v:val !=? v:servername })

  if !empty(s:running_vim_list)
    silent execute
    \ (has("gui_running") ? "!gvim" : "!vim")
    \ "--servername" s:running_vim_list[0]
    \ "--remote-silent"
    \ join(map(argv(), { v -> shellescape(v:val, 1) }), " ")
    qa!
  endif

  unlet s:running_vim_list
endif

" }}}

" 基本設定 {{{

" コマンドの保存履歴数
set history=1000

" backspace の設定
set backspace=start,eol,indent

" C-v の矩形選択で行末より後ろもカーソルを置ける
set virtualedit=block

" クリップボード使用可能に設定
set clipboard=unnamed,autoselect,unnamedplus

" ヘルプ検索で日本語を優先
set helplang=ja,en

" カーソルを行頭行末で止まらないようにする
set whichwrap=b,s,h,l,<,>,[,]

" マウスは使わない
"set mouse-=a
set mouse=

" バッファ有効
set hidden

" filler: vimdiff で埋め立てを行う
" iwhite: vimdiff で空白を無視して比較する
" internal: 内部 diff ライブラリを使用(現代の Vim だと diff 内蔵してる)
set diffopt=filler,iwhite,internal

" beep 音を消す
set belloff=all

" テキストの整形方法
set formatoptions=croql

" }}}

" conceal {{{

if has("conceal")
  set conceallevel=0
  set concealcursor=
endif

" }}}

" スペルチェック
"set spell
"set spelllang+=cjk

" folding {{{

set foldmethod=indent
set foldcolumn=8
set foldnestmax=5
set foldlevelstart=99

" }}}

" 外部 grep {{{

if executable("rg")
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m,%f:%l:%m
elseif executable("ack")
  set grepprg=ack
endif

" }}}

" indent {{{

" オートインデント
set smartindent

" インデントをスペース4つ分に設定
set tabstop=4

" 自動インデントでずれる幅
set shiftwidth=4

" ソフト TAB の設定
"set expandtab
set noexpandtab

" ソフト TAB のスペースの数
set softtabstop=4

" }}}

" search {{{

" 大文字 / 小文字の区別なく検索する
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

" }}}

" completion {{{

" ファイルパス保管を bash と同じようにする
set wildmode=list:longest

" 補完時に表示されるプレビューウィンドウを表示しない
set completeopt=menuone

" }}}

" terminal {{{

if has("terminal")
  " 端末のエンコーディング
  set termencoding=utf-8

  " pty 指定
  set termwintype=conpty
endif

" }}}

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
call minpac#add("https://github.com/vim-jp/vital.vim.git", {"type": "opt"})
call minpac#add("https://github.com/junegunn/vim-easy-align.git")
call minpac#add("https://github.com/tyru/open-browser.vim.git")
call minpac#add("https://github.com/itchyny/vim-cursorword.git")
call minpac#add("https://github.com/mattn/vim-notification.git")

call minpac#add("https://github.com/itchyny/vim-parenmatch.git")
let g:loaded_matchparen = 1     " matchparenを無効にする

call minpac#add("https://github.com/vim-denops/denops.vim.git")

if executable("sudo")
  call minpac#add("https://github.com/lambdalisue/suda.vim.git")
endif

" }}}

" git {{{

call minpac#add("https://github.com/airblade/vim-gitgutter.git")
call minpac#add("https://github.com/lambdalisue/gina.vim.git")

let g:gina#command#blame#formatter#format = '%su%=%au %ti %ma%in'
let g:gina#command#blame#formatter#timestamp_months = 0
let g:gina#command#blame#formatter#timestamp_format1 = '%Y-%m-%d'
let g:gina#command#blame#formatter#timestamp_format2 = '%Y-%m-%d'

call minpac#add("https://github.com/lambdalisue/gin.vim.git")

augroup gina-setting
  autocmd!

  " 行番号を表示すると崩れるので出さない
  autocmd FileType gina-blame setlocal nonumber
augroup END

" }}}

" statusline {{{

" ステータスラインを常に表示
set laststatus=2

" 表示設定
"set statusline=%!ansanloms#statusline#statusline()

" }}}

" tabline {{{

" タブラインを常に表示
set showtabline=2

" タブラインの設定
"set tabline=%!ansanloms#tabline#tabline()

" }}}

" lightline {{{

call minpac#add("https://github.com/itchyny/lightline.vim.git")

call minpac#add("https://github.com/mopp/sky-color-clock.vim.git")

let g:sky_color_clock#datetime_format = "%Y.%m.%d (%a) %H:%M"     " 日付フォーマット
let g:sky_color_clock#enable_emoji_icon = 1                       " 絵文字表示

let g:lightline = {
\ "colorscheme": "nord",
\ "active": {
\   "left": [
\     ["mode", "readonly", "paste"],
\     ["gitbranch", "filename"],
\   ],
\   "right": [
\     ["sky_color_clock"],
\     ["fileformat", "fileencoding", "filetype"],
\   ]
\ },
\ "component_expand": {
\   "tabs": "ansanloms#lightline#tab"
\ },
\ "component_function": {
\   "mode": "ansanloms#statusline#mode_minimum",
\   "gitbranch": "gina#component#repo#branch",
\   "filename": "ansanloms#lightline#filename",
\ },
\ "component": {
\   "modified": "%{(ansanloms#lightline#is_visible() && &modifiable) ? (&modified ? '[+]' : '[-]') : ''}",
\   "readonly": "%{&readonly ? '' : ''}",
\   "fileformat": "%{ansanloms#lightline#is_visible() ? &fileformat : ''}",
\   "filetype": "%{ansanloms#lightline#is_visible() ? (strlen(&filetype) ? &filetype : 'no ft') : ''}",
\   "fileencoding": "%{ansanloms#lightline#is_visible() ? (&fileencoding !=# '' ? &fileencoding : &encoding) : ''}",
\   "sky_color_clock": "%#SkyColorClock#%{' ' . sky_color_clock#statusline() . ' '}%#SkyColorClockTemp# ",
\ },
\ "component_raw": {
\   "sky_color_clock": 1,
\ },
\ "tab_component_function": {
\   "filename": "ansanloms#lightline#tabfilename",
\   "modified": "lightline#tab#modified",
\   "readonly": "lightline#tab#readonly",
\   "tabnum": ""
\ },
\ "separator": {
\   "left": "",
\   "right": ""
\ },
\ "subseparator": {
\   "left": "",
\   "right": ""
\ },
\}

" quickrun {{{

call minpac#add("https://github.com/thinca/vim-quickrun.git")

let g:quickrun_config = {}
let g:quickrun_config["_"] = {
\ "runner": "job",
\}

" }}}

" quickpick {{{

call minpac#add("https://github.com/prabirshrestha/quickpick.vim.git")

call minpac#add("https://github.com/ansanloms/quickpick-oldfiles.vim.git")

call minpac#add("https://github.com/ansanloms/quickpick-launcher.vim.git")
call minpac#add("https://github.com/ansanloms/quickpick-launcher-selector.vim.git")

let g:quickpick_launcher_file = "~/.vim/launcher/conf"
let g:quickpick_launcher_maxheight = 15

call minpac#add("https://github.com/ansanloms/quickpick-buffer.vim.git")

call minpac#add("https://github.com/ansanloms/quickpick-mpc.vim.git")

if has("win32") || has("win64")
  let g:quickpick_mpc_command = "wsl mpc"
endif
let g:quickpick_mpc_format = "%artist%: %album% / [%disc%-]%track% %title%"
let g:quickpick_mpc_maxheight = 15

" }}}

" map {{{

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

command! OpenFilemanager call ansanloms#filemanager#open()
command! OpenVscode call ansanloms#vscode#open()
command! OpenPhpstorm call ansanloms#phpstorm#open()
command! -range OpenBitbucket <line1>,<line2>call ansanloms#bitbucket#open()

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

" tab
nnoremap gr gT
nnoremap <C-w>gr <C-w>gT
tnoremap <C-w>gr <C-w>gT

" launcher
nnoremap <C-e> :<C-u>call quickpick#pickers#launcher#selector#open("!")<CR>

" history
nnoremap <C-h> :<C-u>call quickpick#pickers#oldfiles#open()<CR>

" buffer
nnoremap <C-s> :<C-u>call quickpick#pickers#buffer#open("")<CR>

" list
nnoremap <C-p> :<C-u>call quickpick#pickers#list#open()<CR>

" タグジャンプの際に新しいタブで開く
nnoremap <C-]> :<C-u>tab stj <C-R>=expand("<cword>")<CR><CR>

" minpac
command! PackUpdate packadd minpac | source $MYVIMRC | call minpac#update("", {"do": "call minpac#status()"})
command! PackClean  packadd minpac | source $MYVIMRC | call minpac#clean()
command! PackStatus packadd minpac | source $MYVIMRC | call minpac#status()

" <S-space> とか押すと ^[[32;2u[ とかはいるやつの対策
" https://github.com/vim/vim/issues/6040
tnoremap <S-space> <space>
tnoremap <C-BS> <BS>
tnoremap <C-CR> <CR>

" }}}

" snippet {{{

call minpac#add("https://github.com/hrsh7th/vim-vsnip.git")
call minpac#add("https://github.com/hrsh7th/vim-vsnip-integ.git")

let g:vsnip_snippet_dir = expand("~/.vim/snippets")

" }}}

" lsp {{{

call minpac#add("https://github.com/prabirshrestha/asyncomplete.vim.git")
call minpac#add("https://github.com/prabirshrestha/asyncomplete-lsp.vim.git")
call minpac#add("https://github.com/prabirshrestha/vim-lsp.git")
call minpac#add("https://github.com/prabirshrestha/quickpick-lsp.vim.git")
call minpac#add("https://github.com/mattn/vim-lsp-settings.git")

" vim-lsp
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_echo_delay = 50
let g:lsp_diagnostics_highlights_enabled = 1
let g:lsp_diagnostics_highlights_delay = 50
let g:lsp_diagnostics_highlights_insert_mode_enabled = 0
let g:lsp_diagnostics_signs_enabled = 1
let g:lsp_diagnostics_signs_delay = 50
let g:lsp_diagnostics_signs_insert_mode_enabled = 0
let g:lsp_diagnostics_virtual_text_enabled = 1
let g:lsp_diagnostics_virtual_text_delay = 50

let g:lsp_completion_documentation_delay = 40
let g:lsp_document_highlight_delay = 100
let g:lsp_document_code_action_signs_delay = 100
let g:lsp_fold_enabled = 0
let g:lsp_text_edit_enabled = 1
let g:lsp_inlay_hints_enabled = 0

" 補完時にみる情報:
" 検索対象が定義されている箇所 / 検索対象が宣言されている箇所 / 検索対象が実装されている箇所 / 検索対象の型が定義されている箇所
let g:lsp_tagfunc_source_methods = [
\ "definition",
\ "declaration",
\ "implementation",
\ "typeDefinition"
\]

let g:lsp_diagnostics_signs_enabled = 1
let g:lsp_diagnostics_signs_error = {"text": "❌"}
let g:lsp_diagnostics_signs_warning = {"text": "⚠️"}
let g:lsp_diagnostics_signs_information = {"text": "❗"}
let g:lsp_diagnostics_signs_hint = {"text": "❓"}

let g:lsp_document_code_action_signs_enabled = 1
let g:lsp_document_code_action_signs_hint = {"text": "❓"}

" let g:lsp_log_verbose = 1
" let g:lsp_log_file = expand("/logs/vim-lsp.log")

" asyncomplete.vim
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 1
let g:asyncomplete_popup_delay = 200
let g:asyncomplete_matchfuzzy = 1

" let g:asyncomplete_log_file = expand("/logs/asyncomplete.log")

" vim-lsp-settings
let g:lsp_settings = {
\ "eslint-language-server": {
\   "allowlist": ["javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue"],
\ },
\ "efm-langserver": {
\   "disabled": v:false,
\ },
\}

let g:lsp_settings_filetype_typescript = ["typescript-language-server", "eslint-language-server", "deno"]
let g:lsp_settings_filetype_vue = ["volar-server", "eslint-language-server", "efm-langserver"]

augroup lsp-setting
  autocmd!

  autocmd User lsp_buffer_enabled setlocal omnifunc=lsp#complete
  autocmd User lsp_buffer_enabled setlocal signcolumn=yes
  autocmd User lsp_buffer_enabled setlocal tagfunc=lsp#tagfunc
  "autocmd User lsp_buffer_enabled setlocal foldmethod=expr
  "autocmd User lsp_buffer_enabled setlocal foldexpr=lsp#ui#vim#folding#foldexpr()
  "autocmd User lsp_buffer_enabled setlocal foldtext=lsp#ui#vim#folding#foldtext()

  autocmd User lsp_buffer_enabled nnoremap [lsp] <Nop>
  autocmd User lsp_buffer_enabled vnoremap [lsp] <Nop>
  autocmd User lsp_buffer_enabled nmap <Space>l [lsp]
  autocmd User lsp_buffer_enabled vmap <Space>l [lsp]
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]h <Plug>(lsp-hover)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]a <Plug>(lsp-code-action)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]f <plug>(lsp-document-format-sync)
  autocmd User lsp_buffer_enabled vmap <buffer> [lsp]f <plug>(lsp-document-range-format-sync)
  autocmd User lsp_buffer_enabled nmap <silent> [lsp]n <Plug>(lsp-next-error)
  autocmd User lsp_buffer_enabled nmap <silent> [lsp]p <Plug>(lsp-previous-error)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]d <Plug>(lsp-definition)
augroup END

" }}}

" Quickfix {{{

augroup quickfix-setting
  autocmd!

  " :grep で quickfix を開く
  "autocmd QuickFixCmdPost *grep* cwindow

  " ステータスラインを更新
  autocmd FileType qf setlocal statusline=%!ansanloms#statusline#quickfix()
augroup END

" }}}

" Java {{{

call minpac#add("https://github.com/vim-jp/vim-java.git")

if !filereadable(expand("~/.vim/syntax/javaid.vim"))
  call system("curl https://fleiner.com/vim/syntax/javaid.vim -o " . expand("~/.vim/syntax/javaid.vim"))
endif

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

  " インデントセット
  autocmd FileType java setlocal shiftwidth=4 tabstop=4 softtabstop=4 noexpandtab
augroup END

" }}}

" JavaScript / TypeScript {{{

call minpac#add("https://github.com/MaxMEllon/vim-jsx-pretty.git")

augroup javascript-setting
  autocmd!

  " インデントセット
  autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType javascriptreact setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType javascript.jsx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" quickrun - typescript
if executable("tsc")
  let g:quickrun_config["typescript"] = {
  \ "type": "typescript/tsc"
  \}

  let g:quickrun_config["typescript/tsc"] = {
  \ "command": "tsc",
  \ "exec": ["%c --target esnext --module commonjs %o %s", "node %s:r.js"],
  \ "tempfile": "%{tempname()}.ts",
  \ "hook/sweep/files": ["%S:p:r.js"],
  \}
endif

augroup typescript-setting
  autocmd!

  " インデントセット
  autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType typescriptreact setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType typescript.tsx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" markdown.mdx {{{

call minpac#add("https://github.com/jxnblk/vim-mdx-js.git")

augroup markdown-mdx-setting
  autocmd!

  " インデントセット
  autocmd FileType markdown.mdx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" vue {{{

call minpac#add("https://github.com/posva/vim-vue.git")

augroup vue-setting
  autocmd!

  " インデントセット
  autocmd FileType vue setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " ハイライト行指定
  autocmd FileType vue syntax sync fromstart
augroup END

" }}}

" PHP {{{

" case 文対応
let g:PHP_vintage_case_default_indent = 1

" 使用する DB
let g:sql_type_default = "mysql"

augroup php-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.ctp set filetype=php

  " インデントセット
  autocmd FileType php setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " ハイライト行指定
  autocmd FileType php syntax sync minlines=300 maxlines=500
augroup END

" }}}

" PHP vold {{{

call minpac#add("https://github.com/yukpiz/vim-volt-syntax.git")

augroup volt-setting
  autocmd!

  " インデントセット
  autocmd filetype volt setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab

  " ハイライト行指定
  autocmd filetype volt syntax sync minlines=300 maxlines=500
augroup END

" }}}

" markdown {{{

augroup markdown-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown

  " インデントセット
  autocmd FileType markdown setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" quickrun - markdown
if executable("pandoc")
  " css の取得
  if !filereadable(expand("~/.vim/markdown.css"))
    call system("curl https://gist.githubusercontent.com/tuzz/3331384/raw/d1771755a3e26b039bff217d510ee558a8a1e47d/github.css -o " . expand("~/.vim/markdown.css"))
  endif

  let g:quickrun_config["markdown"] = {
  \ "type": "markdown/pandoc"
  \}

  " html 出力
  let g:quickrun_config["markdown/pandoc"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "browser",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --css=" . expand("~/.vim/markdown.css") . " --metadata title=%s"
  \}

  " slidy 出力
  let g:quickrun_config["markdown/pandoc-slidy"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "browser",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=slidy --toc-depth=6 --metadata title=%s"
  \}

  " Word docx 出力
  let g:quickrun_config["markdown/pandoc-docx"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "null",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=docx --toc-depth=6 --highlight-style=zenburn --output=%s.docx"
  \}

  " 単一 markdown 出力
  let g:quickrun_config["markdown/pandoc-self-contained"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter/buffer/filetype": "markdown",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --no-highlight --metadata title=%s | pandoc --from html --to markdown --wrap none --markdown-headings=atx" . ' | sed -r -e "s/```\s*\{\.(.*)\}/```\1/g"'
  \}
endif

" }}}

" asciidoc {{{

augroup asciidoc-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.adoc set filetype=asciidoc

  " インデントセット
  autocmd FileType asciidoc setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" plantuml {{{

call minpac#add("https://github.com/aklt/plantuml-syntax.git")

augroup plantuml-setting
  autocmd!

  " 拡張子設定
  autocmd BufNewFile,BufRead *.{pu,uml,puml,iuml,plantuml} set filetype=plantuml

  " インデントセット
  autocmd FileType plantuml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" quickrun - plantuml
if executable("plantuml")
  let g:quickrun_config["plantuml"] = {
  \ "type": "plantuml/svg"
  \}

  " svg 出力
  let g:quickrun_config["plantuml/svg"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "browser",
  \ "exec": (has("win32") || has("win64") ? "type" : "cat") . " %s | plantuml -tsvg -charset UTF-8 -pipe"
  \}
endif

" }}}

" sh {{{

call minpac#add("https://github.com/vim-scripts/Super-Shell-Indent.git")
call minpac#add("https://github.com/vim-scripts/sh.vim.git")

let g:sh_indent_case_labels = 1

augroup sh-setting
  autocmd!

  " インデントセット
  autocmd FileType sh setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" Vim script {{{

" \ を入力した際のインデント量
let g:vim_indent_cont = 0

augroup vim-setting
  autocmd!

  " インデントセット
  autocmd FileType vim setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab

  " folding
  autocmd FileType vim setlocal foldmethod=marker
augroup END

" }}}

" sql {{{

" quickrun - mysql
if executable("mysql")
  let g:quickrun_config["sql"] = {
  \ "type": "sql/mysql"
  \}

  " mysql
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

" }}}

" html {{{

call minpac#add("https://github.com/mattn/emmet-vim.git")

" quickrun - html
if executable("w3m")
  let g:quickrun_config["html"] = {
  \ "type": "html/w3m"
  \}

  " text 出力
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

" }}}

" xml {{{

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

" }}}

" css {{{

augroup css-setting
  autocmd!

  " インデントセット
  autocmd FileType css setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" scss {{{

augroup scss-setting
  autocmd!

  " インデントセット
  autocmd FileType scss setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" stylus {{{

call minpac#add("https://github.com/iloginow/vim-stylus.git")

augroup stylus-setting
  autocmd!

  " インデントセット
  autocmd FileType stylus setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" json {{{

" conceal 表示を無効にする
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

" }}}

" json5 {{{

call minpac#add("https://github.com/gutenye/json5.vim.git")

augroup json5-setting
  autocmd!

  " インデントセット
  autocmd FileType json5 setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" apache conf {{{

call minpac#add("https://github.com/vim-scripts/apachestyle.git")

" }}}

" groovy {{{

call minpac#add("https://github.com/vim-scripts/groovyindent.git")

" }}}

" graphql {{{

" graphql
call minpac#add("https://github.com/jparise/vim-graphql.git")

augroup graphql-setting
  autocmd!

  " インデントセット
  autocmd FileType graphql setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" dart {{{

call minpac#add("https://github.com/dart-lang/dart-vim-plugin.git")

" }}}

" toml {{{

augroup toml-setting
  autocmd!

  " インデントセット
  autocmd FileType toml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" yaml {{{

call minpac#add("https://github.com/stephpy/vim-yaml.git")

augroup yaml-setting
  autocmd!

  " インデントセット
  autocmd FileType yaml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" prisma {{{

call minpac#add("https://github.com/pantharshit00/vim-prisma.git")

augroup prisma-setting
  autocmd!

  " インデントセット
  autocmd FileType prisma setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" python {{{

augroup python-setting
  autocmd!

  " インデントセット
  autocmd FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4 expandtab
augroup END

" }}}

" lua {{{

augroup lua-setting
  autocmd!

  " インデントセット
  autocmd FileType lua setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" }}}

" binary {{{

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

" }}}

" netrw {{{

" netrw は常にtree view
let g:netrw_liststyle = 3

" v でファイルを開くときは右側に開く(デフォルトが左側なので入れ替え)
let g:netrw_altv = 1

" o でファイルを開くときは下側に開く(デフォルトが上側なので入れ替え)
let g:netrw_alto = 1

" }}}

" 行末空白削除 {{{

augroup remove-dust
  autocmd!

  " ファイルを保存する直前に実施
  autocmd BufWritePre * call s:remove_dust()

  function! s:remove_dust()
    let l:cursor = getpos(".")
    keeppatterns %s/\s\+$//ge
    call setpos(".", cursor)
    unlet l:cursor
  endfunction
augroup END

" }}}

" ディレクトリ作成 {{{

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

" }}}

" お仕事用設定 {{{

if filereadable(expand("~/.vim/work.vim"))
  source ~/.vim/work.vim
endif

" }}}

" gVim {{{

if has("gui_running")
  if has("vim_starting")
    " フォント設定
    if has("win32") || has("win64")
      "set guifont=Cica:h12:cSHIFTJIS:qDRAFT
      set guifont=PlemolJP_Console_NF:h12:cSHIFTJIS:qDRAFT
    endif

    " 縦幅 デフォルトは 24
    set lines=60

    " 横幅 デフォルトは 80
    set columns=180
  endif

  " GUI オプション
  set guioptions=AcfiM!

  " 行間設定
  set linespace=0

  " カーソルを点滅させない
  set guicursor=a:blinkon0

  " 挿入モードの IME デフォルト
  set iminsert=0

  " 検索時の IME デフォルト
  set imsearch=-1
endif

" }}}

" appearance {{{

" 空白文字の表示
" とりあえず TAB / 行末スペース / 省略文字(右) / 省略文字(左) / nbsp
set list
set listchars=tab:\|\ ,trail:_,extends:>,precedes:<,nbsp:%

" 画面描画の設定
set lazyredraw    " コマンド実行時の画面描画をしない
set ttyfast       " 高速ターミナル接続

" True Color でのシンタックスハイライト
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
"set ambiwidth=double
set ambiwidth=single
call minpac#add("https://github.com/rbtnn/vim-ambiwidth.git")
let g:ambiwidth_cica_enabled = v:false

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

" 括弧のカーソルが飛ぶ時間(x0.1 秒)
set matchtime=2

" 補完メニューの高さ(0 なら無制限)
set pumheight=0

" gVim の背景を透過させる
call minpac#add("https://github.com/mattn/vimtweak.git")

augroup vimtweak-setting
  autocmd!

  autocmd guienter * silent! VimTweakSetAlpha 230
augroup END

" colorscheme
call minpac#add("https://github.com/cocopon/iceberg.vim.git")
call minpac#add("https://github.com/Rigellute/rigel.git")
call minpac#add("https://github.com/whatyouhide/vim-gotham.git")
call minpac#add("https://github.com/arcticicestudio/nord-vim.git")
call minpac#add("https://github.com/djjcast/mirodark.git")
call minpac#add("https://github.com/ansanloms/hilal.git")
call minpac#add("https://github.com/cormacrelf/vim-colors-github.git")
call minpac#add("https://github.com/danishprakash/vim-yami.git")
call minpac#add("https://github.com/fcpg/vim-orbital.git")
call minpac#add("https://github.com/ulwlu/elly.vim.git")
call minpac#add("https://github.com/gerardbm/vim-atomic.git")

" シンタックス ON
syntax enable

try
  set background=dark
  colorscheme nord

  " highlight CursorLine ctermfg=234 guibg=#2D3640
catch
endtry

" }}}
