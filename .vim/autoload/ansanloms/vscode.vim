let s:project_root_target = [
\ ".git",
\ ".bzr",
\ ".hg",
\ ".svn",
\ "build.xml",
\ "prj.el",
\ ".project",
\ "pom.xml",
\ "package.json",
\ "composer.json",
\ "import_map.json",
\ "Makefile",
\ "configure",
\ "Rakefile",
\ "NAnt.build",
\ "P4CONFIG",
\ "tags",
\ "gtags",
\ "vendor"
\]

" VSCode を開く
function! ansanloms#vscode#open()
  if !executable("code")
    echoerr "code command not found."
    return
  endif

  packadd vital.vim
  execute "!code --goto" expand("%:p").":".line(".").":".col(".") s:get_project_path(expand("%:p"))
endfunction

function! s:get_project_path(path) abort
  packadd vital.vim
  let l:v_filepath = vital#vital#new().import("System.Filepath")

  let l:path_list = l:v_filepath.split(a:path)

  for l:path_dir in copy(l:path_list)
    call remove(l:path_list, -1)

    let l:ftype = ""
    for l:target in s:project_root_target
      let l:ftype = getftype(v_filepath.join(l:path_list, l:target))

      if (l:ftype != "")
        break
      endif
    endfor

    if (l:ftype != "")
      break
    endif
  endfor

  if (l:ftype == "")
    let l:path_list = l:v_filepath.split(a:path)
    call remove(l:path_list, -1)
  endif

  return v_filepath.join(l:path_list)
endfunction
