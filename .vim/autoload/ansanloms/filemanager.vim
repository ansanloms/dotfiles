" ファイルマネージャを開く
function! ansanloms#filemanager#open()
  if has("win32") || has("win64")
    silent execute "!start explorer.exe /select," expand("%:p")
  elseif has("mac")
    silent execute "!open" expand("%:p")
  endif
endfunction
