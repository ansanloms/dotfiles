let s:command = ""

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
\ "gtags"
\]

function! quickpick#pickers#list#open() abort
  call quickpick#open({
  \ "items": s:get_items(),
  \ "on_accept": function("s:on_accept"),
  \})

  inoremap <buffer><silent> <Plug>(quickpick-list-open-with-tab) <ESC>:<C-u>call <SID>open_with_command("tab split")<CR>
  nnoremap <buffer><silent> <Plug>(quickpick-list-open-with-tab) :<C-u>call <SID>open_with_command("tab split")<CR>

  inoremap <buffer><silent> <Plug>(quickpick-list-open-with-split) <ESC>:<C-u>call <SID>open_with_command("split")<CR>
  nnoremap <buffer><silent> <Plug>(quickpick-list-open-with-split) :<C-u>call <SID>open_with_command("split")<CR>

  inoremap <buffer><silent> <Plug>(quickpick-list-open-with-vsplit) <ESC>:<C-u>call <SID>open_with_command("vsplit")<CR>
  nnoremap <buffer><silent> <Plug>(quickpick-list-open-with-vsplit) :<C-u>call <SID>open_with_command("vsplit")<CR>

  if !hasmapto("<Plug>(quickpick-list-open-with-tab)")
    imap <silent> <buffer> <C-t> <Plug>(quickpick-list-open-with-tab)
    nmap <silent> <buffer> <C-t> <Plug>(quickpick-list-open-with-tab)
  endif

  if !hasmapto("<Plug>(quickpick-list-open-with-split)")
    imap <silent> <buffer> <C-s> <Plug>(quickpick-list-open-with-split)
    nmap <silent> <buffer> <C-s> <Plug>(quickpick-list-open-with-split)
  endif

  if !hasmapto("<Plug>(quickpick-list-open-with-vsplit)")
    imap <silent> <buffer> <C-v> <Plug>(quickpick-list-open-with-vsplit)
    nmap <silent> <buffer> <C-v> <Plug>(quickpick-list-open-with-vsplit)
  endif
endfunction

function! s:get_items() abort
  return split(system(join(["rg", "--files", s:get_project_path(expand("%:p")), "--path-separator", "/"])))
endfunction

function! s:on_accept(data, name) abort
  call quickpick#close()

  let l:cmd = "edit " . a:data["items"][0]
  if s:command != ""
    let l:cmd = s:command . " | " . l:cmd
    let s:command = ""
  endif

  execute l:cmd
endfunction

function! s:open_with_command(command) abort
  let s:command = a:command
  call feedkeys("\<CR>")
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
