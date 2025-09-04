vim.opt.encoding = "utf-8"
vim.opt.fileencodings = "utf-8,sjis,cp932,euc-jp,iso-2022-jp"
vim.opt.fileformats = "unix,mac,dos"

-- runtimepath と packpath の設定。
vim.opt.runtimepath:prepend("~/.config/nvim")
vim.opt.packpath:prepend("~/.config/nvim")

-- viminfo (shada) 設定。
vim.opt.shada = "'10000,:100,<1000,s10,n~/.config/nvim/shada"

-- バックアップ設定。
vim.opt.backupdir = vim.fn.expand(vim.fn.stdpath("data") .. "/backup")
vim.opt.backup = true
vim.opt.writebackup = true

-- スワップファイル設定。
vim.opt.directory = vim.fn.expand(vim.fn.stdpath("data") .. "/backup")
vim.opt.swapfile = true

-- mkview 設定。
vim.opt.viewdir = vim.fn.expand(vim.fn.stdpath("data") .. "/view")
vim.opt.viewoptions = "cursor"

-- mkview 自動保存読み込み。
local augroupMkview = vim.api.nvim_create_augroup("vim-mkview", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroupMkview,
  pattern = "*",
  callback = function()
    if vim.fn.expand("%") ~= "" and vim.bo.buftype:match("nofile") == nil then
      vim.cmd("mkview")
    end
  end,
})
vim.api.nvim_create_autocmd("BufRead", {
  group = augroupMkview,
  pattern = "*",
  callback = function()
    if vim.fn.expand("%") ~= "" and vim.bo.buftype:match("nofile") == nil then
      pcall(vim.cmd, "silent loadview")
    end
  end,
})

-- undo 設定。
vim.opt.undodir = vim.fn.expand(vim.fn.stdpath("data") .. "/undo")
vim.opt.undofile = true

-- 基本設定。
vim.opt.history = 1000
vim.opt.backspace = "start,eol,indent"
vim.opt.virtualedit = "block"
vim.opt.clipboard = "unnamed,unnamedplus" -- @todo https://github.com/neovim/neovim/issues/2325
vim.opt.helplang = "ja,en"
vim.opt.whichwrap = "b,s,h,l,<,>,[,]"
vim.opt.mouse = ""
vim.opt.hidden = true
vim.opt.diffopt = "filler,iwhite,internal"
vim.opt.belloff = "all"
vim.opt.formatoptions = "croql"

-- conceal 設定。
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""

-- folding 設定。
vim.opt.foldmethod = "indent"
vim.opt.foldcolumn = "8"
vim.opt.foldnestmax = 5
vim.opt.foldlevelstart = 99

-- 外部 grep 。
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep --no-heading"
  vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"
elseif vim.fn.executable("ack") == 1 then
  vim.opt.grepprg = "ack"
end

-- インデント設定。
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.softtabstop = 4

-- 検索設定。
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrapscan = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.tagbsearch = true

-- 補完設定。
vim.opt.wildmode = "list:longest"
vim.opt.completeopt = "menuone"
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0

-- 行末空白削除。
local augroupRemoveDust = vim.api.nvim_create_augroup("remove-dust", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroupRemoveDust,
  pattern = "*",
  callback = function()
    local cursor_pos = vim.fn.getpos(".")
    vim.cmd([[keeppatterns %s/\s\+$//ge]])
    vim.fn.setpos(".", cursor_pos)
  end,
})

-- ディレクトリ自動作成。
local augroupAutoMkdir = vim.api.nvim_create_augroup("auto-mkdir", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroupAutoMkdir,
  pattern = "*",
  callback = function()
    local dir = vim.fn.expand("<afile>:p:h")
    if string.sub(dir, 1, 6) == "scp://" or string.sub(dir, 1, 7) == "sftp://" then
      return
    end

    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(vim.fn.iconv(dir, vim.o.encoding, vim.o.termencoding), "p")
    end
  end,
})

-- 不要なプラグイン等を読み込ませない。
vim.g.no_gvimrc_example = 1
vim.g.no_vimrc_example = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_manpager = 1
-- vim.g.loaded_matchparen = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_openPlugin = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_spellfile = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tohtml = 1
vim.g.loaded_tutor = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_zipPlugin = 1
