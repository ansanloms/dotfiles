" VSCode を開く
function! ansanloms#vscode#open()
  if !executable("code")
    echoerr "code command not found."
    return
  endif

  packadd vital.vim
  execute "!code --goto" expand("%:p").":".line(".").":".col(".") ansanloms#project#dir(expand("%:p"), expand("%:p"))
endfunction
