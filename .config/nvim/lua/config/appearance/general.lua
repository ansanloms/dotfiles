-- 空白文字の表示。
-- とりあえず TAB / 行末スペース / 省略文字(右) / 省略文字(左) / nbsp
vim.opt.list = true
vim.opt.listchars = { tab = "| ", trail = "_", extends = ">", precedes = "<", nbsp = "%" }

-- 画面描画の設定。
vim.opt.cursorline = false -- カーソルライン表示を無効に
vim.opt.lazyredraw = true -- 遅延再描画を有効に
vim.opt.showcmd = false -- コマンド表示を無効に
vim.opt.ruler = false -- ルーラー表示を無効に

-- 行番号を表示する。
vim.opt.number = true

-- 行可視化。
vim.opt.cursorline = false

-- 列可視化。
vim.opt.cursorcolumn = false
vim.opt.relativenumber = false

-- 右側で折り返す。
vim.opt.wrap = true

-- 行の最後まで表示する。
vim.opt.display = "lastline"

-- インデントを付けて折り返し。
vim.opt.breakindent = true

-- 文字幅の設定。
vim.opt.ambiwidth = "single"

-- Nerd Fonts 関連の設定。
-- Nerd Fonts Seti-UI + Custom (0xe5fa-0xe62b,0xe62e は元々対応されてる)
-- Nerd Fonts Devicons (0xe700-0xe7c5 は元々対応されてる)
-- Nerd Fonts Material Design Icons
-- Nerd Fonts Codicons
vim.g.ambiwidth_add_list = {
  { 0xe62c, 0xe62d, 2 }, { 0xe62f, 0xe6b7, 2 },
  { 0xe7c6, 0xe8ef, 2 },
  { 0xf0001, 0xf1af0, 2 },
  { 0xea60, 0xec1e, 2 },
}

-- 上下の視界確保。
vim.opt.scrolloff = 4

-- 左右の視界確保。
vim.opt.sidescrolloff = 8

-- 左右スクロール値の設定。
vim.opt.sidescroll = 1

-- コマンドラインの行数。
vim.opt.cmdheight = 1

-- 括弧強調。
vim.opt.showmatch = true

-- 括弧のカーソルが飛ぶ時間(x0.1 秒)。
vim.opt.matchtime = 2

-- 補完メニューの高さ(0 なら無制限)。
vim.opt.pumheight = 0
