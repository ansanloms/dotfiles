" ファイルマネージャを開く
function! ansanloms#filemanager#open(path)
  if has("win32") || has("win64")
    silent execute "!start explorer.exe /select," a:path
  elseif has("mac")
    silent execute "!open" a:path
  endif
endfunction
