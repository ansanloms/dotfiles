function! ansanloms#terminal#terminal(cmd, name, ...)
  return term_start(a:cmd, extend({
  \ "term_name": a:name,
  \ "term_finish": "close",
  \ "curwin": 1
  \}, get(a:, 1, {})))
endfunction

function! ansanloms#terminal#ssh(destination)
  call ansanloms#terminal#terminal("ssh " . a:destination, a:destination)
endfunction
