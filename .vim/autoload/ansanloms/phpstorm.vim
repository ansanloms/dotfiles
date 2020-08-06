" phpstorm を開く
function! ansanloms#phpstorm#open()
  if !executable("phpstorm")
    echoerr "phpstorm command not found."
    return
  endif

  packadd vital.vim
  execute "!start phpstorm" vital#vital#new().import("Prelude").path2project_directory(expand("%:p")) "--line" line(".") "--column" col(".") expand("%:p")
endfunction
