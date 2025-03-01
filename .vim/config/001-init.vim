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

" ディレクトリの作成と読み込み {{{

if has("vim_starting")
  for dir in [
  \ "~/.vim",
  \ "~/.vim/autoload",
  \ "~/.vim/plugin",
  \ "~/.vim/backup",
  \ "~/.vim/view",
  \ "~/.vim/undo",
  \ "~/.vim/syntax",
  \ "~/.vim/pack",
  \ "~/.vim/logs"
  \]
    if !isdirectory(expand(dir))
      call mkdir(expand(dir), "p")
    endif
  endfor

  unlet dir
endif

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

" backup {{{

" バックアップ保存先
set backupdir=~/.vim/backup

" バックアップ有効
set backup

" 上書き前にバックアップ作成
set writebackup

" }}}

" swapfile {{{

" スワップファイル保存先
set directory=~/.vim/backup

" スワップファイル有効
set swapfile

" }}}

" mkview {{{

" mkview 保存先
set viewdir=~/.vim/view

" :mkview で保存する設定
" - cursor: ファイル／ウィンドウ内のカーソル位置。
" - folds: 手動で作られた折り畳み、折り畳みの開閉の区別、折り畳み。
set viewoptions=cursor

augroup vim-mkview
  autocmd!

  " ファイルを閉じる際に mkview 実施
  autocmd BufWritePost * if expand("%") != "" && &buftype !~ "nofile" | mkview | endif

  " ファイルを開いたら読み込む
  autocmd BufRead * if expand("%") != "" && &buftype !~ "nofile" | silent loadview | endif
augroup END

" }}}

" undo {{{

" undo 管理先
set undodir=~/.vim/undo

" undo 機能を有効にする
set undofile

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
endif

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

augroup auto-mkdir
  autocmd!

  " ファイルを保存する直前に実施
  autocmd BufWritePre * call s:auto_mkdir(expand("<afile>:p:h"), v:cmdbang)

  function! s:auto_mkdir(dir, force)
    if a:dir[0:5] == "scp://"
      return
    endif

    if a:dir[0:6] == "sftp://"
      return
    endif

    if !isdirectory(a:dir)
      call mkdir(iconv(a:dir, &encoding, &termencoding), "p")
    endif
  endfunction
augroup END

" }}}
