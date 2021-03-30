function! quickpick#pickers#oldfiles#open(...) abort
  call quickpick#open({
  \ "items": v:oldfiles,
  \ "on_accept": function("s:on_accept"),
  \})
endfunction

function! s:on_accept(data, name) abort
  call quickpick#close()
  execute "edit " . a:data["items"][0]
endfunction
