" VSCode を開く
function! ansanloms#vscode#open()
  if !executable("code")
    echoerr "code command not found."
    return
  endif

  packadd vital.vim
  execute "!code --goto" expand("%:p").":".line(".").":".col(".") vital#vital#new().import("Prelude").path2project_directory(expand("%:p"))
endfunction
