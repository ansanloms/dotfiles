-- +-----------------+--------+--------+----------+----------------+--------+------+----------+
-- | コマンド        | NORMAL | INSERT | TERMINAL | コマンドライン | VISUAL | 選択 | 演算待ち |
-- +-----------------+--------+--------+----------+----------------+--------+------+----------+
-- | map  / noremap  | @      | -      | -        | -              | @      | @    | @        |
-- | nmap / nnoremap | @      | -      | -        | -              | -      | -    | -        |
-- | vmap / vnoremap | -      | -      | -        | -              | @      | @    | -        |
-- | omap / onoremap | -      | -      | -        | -              | -      | -    | @        |
-- | xmap / xnoremap | -      | -      | -        | -              | @      | -    | -        |
-- | smap / snoremap | -      | -      | -        | -              | -      | @    | -        |
-- | map! / noremap! | -      | @      | -        | @              | -      | -    | -        |
-- | imap / inoremap | -      | @      | -        | -              | -      | -    | -        |
-- | cmap / cnoremap | -      | -      | -        | @              | -      | -    | -        |
-- | tmap / tnoremap | -      | -      | @        | -              | -      | -    | -        |
-- +-----------------+--------+--------+----------+----------------+--------+------+----------+

-- Leader
vim.g.mapleader = ","

-- 検索などで飛んだらそこを真ん中に。
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "*", "*zz")
vim.keymap.set("n", "#", "#zz")
vim.keymap.set("n", "g*", "g*zz")
vim.keymap.set("n", "G", "Gzz")

-- 危険なコマンドは使わせない。
vim.keymap.set("n", "ZZ", "<Nop>")
vim.keymap.set("n", "ZQ", "<Nop>")

-- 検索のハイライト削除とポップアップを消す。
--vim.api.nvim_create_user_command("Clear", "nohlsearch | lua vim.api.nvim_win_close_all_popups()", {})
--vim.keymap.set("n", "<Esc><Esc>", ":<C-u>Clear<CR>", { silent = true })

-- very magic
vim.keymap.set("n", "/", "/\\v")

-- バッファ操作。
vim.keymap.set("n", "ft", ":<C-u>bprev<CR>")
vim.keymap.set("n", "<C-w>ft", "<C-w>:<C-u>bprev<CR>")
vim.keymap.set("t", "<C-w>ft", "<C-w>:<C-u>bprev<CR>")

vim.keymap.set("n", "fT", ":<C-u>bnext<CR>")
vim.keymap.set("n", "<C-w>fT", "<C-w>:<C-u>bnext<CR>")
vim.keymap.set("t", "<C-w>fT", "<C-w>:<C-u>bnext<CR>")

-- タブ操作。
vim.keymap.set("n", "gr", "gT")
vim.keymap.set("n", "<C-w>gr", "<C-w>gT")
vim.keymap.set("t", "<C-w>gr", "<C-w>gT")

-- ターミナル特殊キー対策。
vim.keymap.set("t", "<S-space>", "<space>")
vim.keymap.set("t", "<C-BS>", "<BS>")
vim.keymap.set("t", "<C-CR>", "<CR>")
