let s:command = ""

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

function! s:get_items(...) abort
  packadd vital.vim
  let l:path = vital#vital#new().import("Prelude").path2project_directory(expand("%:p"))

  let l:command = ["rg", "--files", l:path, "--path-separator", "/"]

  let l:g = get(a:, 1, "")
  if l:g != ""
    let l:command = add(l:command, "-g")
    let l:command = add(l:command, "*" . l:g . "*")
  endif

  return split(system(join(l:command)))
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
