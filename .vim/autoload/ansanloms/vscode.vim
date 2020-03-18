" VSCode を開く
function! ansanloms#vscode#open()
  if !executable("code")
    echoerr "code command not found."
    return
  endif

  silent execute "!code --goto" expand("%:p").":".line(".").":".col(".")
endfunction
