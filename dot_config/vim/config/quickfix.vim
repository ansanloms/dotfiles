augroup quickfix-setting
  autocmd!

  " :grep で quickfix を開く
  autocmd QuickFixCmdPost *grep* call bekken#Run("quickfix#grep", [], { "filetype": { "selection": "bekken-selection-quickfix-grep" } })

  " ステータスラインを更新
  autocmd FileType qf setlocal statusline=%!ansanloms#statusline#quickfix()
augroup END
