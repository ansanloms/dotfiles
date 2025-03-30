" 空白文字の表示
" とりあえず TAB / 行末スペース / 省略文字(右) / 省略文字(左) / nbsp
set list
set listchars=tab:\|\ ,trail:_,extends:>,precedes:<,nbsp:%

" 画面描画の設定
set nocursorline  " カーソルライン表示を無効に
set lazyredraw    " 遅延再描画を有効に
set noshowcmd     " コマンド表示を無効に
set noruler       " ルーラー表示を無効に

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
" - Nerd Fonts Seti-UI + Custom (0xe5fa-0xe62b,0xe62e は元々対応されてる)
" - Nerd Fonts Devicons (0xe700-0xe7c5 は元々対応されてる)
" - Nerd Fonts Material Design Icons
" - Nerd Fonts Codicons
let g:ambiwidth_add_list = [
\ [0xe62c, 0xe62d, 2], [0xe62f, 0xe6b7, 2],
\ [0xe7c6, 0xe8ef, 2],
\ [0xf0001, 0xf1af0, 2],
\ [0xea60, 0xec1e, 2],
\]

" 上下の視界確保
set scrolloff=4

" 左右の視界確保
set sidescrolloff=8

" 左右スクロール値の設定
set sidescroll=1

" コマンドラインの行数
set cmdheight=1

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

  if has("win32") && has("gui_running")
    autocmd guienter * silent! VimTweakSetAlpha 230
  endif
augroup END

" colorscheme
call minpac#add("https://github.com/whatyouhide/vim-gotham.git")
call minpac#add("https://github.com/EdenEast/nightfox.nvim")

" シンタックス ON
syntax enable
set background=dark

" True Color でのシンタックスハイライト
if (has("termguicolors"))
  set termguicolors
endif

"packadd! nightfox.nvim
"if has("gui_running")
"  lua require("nightfox").setup({
"  \ options = {
"  \   terminal_colors = false,
"  \ }
"  \})
"else
"  lua require("nightfox").setup({
"  \ options = {
"  \   transparent = true,
"  \ }
"  \})
"endif

"colorscheme terafox
colorscheme gotham
highlight! PreProc ctermfg=13 guifg=#888ca6

highlight! link StatusLineTerm StatusLine
highlight! link StatusLineTermNC StatusLineNC

if !has("gui_running")
  highlight! Normal guibg=NONE ctermbg=NONE
  highlight! NonText guibg=NONE ctermbg=NONE
  highlight! LineNr guibg=NONE ctermbg=NONE
  highlight! Folded guibg=NONE ctermbg=NONE
  highlight! EndOfBuffer guibg=NONE ctermbg=NONE

  " Inform vim how to enable undercurl in wezterm
  let &t_Cs = "\e[60m"
  " Inform vim how to disable undercurl in wezterm (this disables all underline modes)
  let &t_Ce = "\e[24m"
endif

if has("terminal") && exists("*term_setansicolors")
  let g:terminal_ansi_colors = repeat([0], 16)

  " gotham
  let g:terminal_ansi_colors[0] =  "#0a0f14"    " black
  let g:terminal_ansi_colors[1] =  "#c33027"    " dark red
  let g:terminal_ansi_colors[2] =  "#26a98b"    " dark green
  let g:terminal_ansi_colors[3] =  "#edb54b"    " brown
  let g:terminal_ansi_colors[4] =  "#195465"    " dark blue
  let g:terminal_ansi_colors[5] =  "#4e5165"    " dark magenta
  let g:terminal_ansi_colors[6] =  "#33859d"    " dark cyan
  let g:terminal_ansi_colors[7] =  "#98d1ce"    " light grey
  let g:terminal_ansi_colors[8] =  "#314051"    " dark grey
  let g:terminal_ansi_colors[9] =  "#d26939"    " red
  let g:terminal_ansi_colors[10] = "#081f2d"    " green
  let g:terminal_ansi_colors[11] = "#245361"    " yellow
  let g:terminal_ansi_colors[12] = "#093748"    " blue
  let g:terminal_ansi_colors[13] = "#888ba5"    " magenta
  let g:terminal_ansi_colors[14] = "#599caa"    " cyan
  let g:terminal_ansi_colors[15] = "#d3ebe9"    " white

  " Terafox
  "let g:terminal_ansi_colors[0] =  "#2f3239"    " black
  "let g:terminal_ansi_colors[1] =  "#e85c51"    " dark red
  "let g:terminal_ansi_colors[2] =  "#7aa4a1"    " dark green
  "let g:terminal_ansi_colors[3] =  "#fda47f"    " brown
  "let g:terminal_ansi_colors[4] =  "#5a93aa"    " dark blue
  "let g:terminal_ansi_colors[5] =  "#ad5c7c"    " dark magenta
  "let g:terminal_ansi_colors[6] =  "#a1cdd8"    " dark cyan
  "let g:terminal_ansi_colors[7] =  "#ebebeb"    " light grey
  "let g:terminal_ansi_colors[8] =  "#4e5157"    " dark grey
  "let g:terminal_ansi_colors[9] =  "#eb746b"    " red
  "let g:terminal_ansi_colors[10] = "#8eb2af"    " green
  "let g:terminal_ansi_colors[11] = "#fdb292"    " yellow
  "let g:terminal_ansi_colors[12] = "#73a3b7"    " blue
  "let g:terminal_ansi_colors[13] = "#b97490"    " magenta
  "let g:terminal_ansi_colors[14] = "#afd4de"    " cyan
  "let g:terminal_ansi_colors[15] = "#eeeeee"    " white
endif
