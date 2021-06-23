function! ansanloms#terminal#terminal(cmd, name)
  call term_start(a:cmd, {
  \ "term_name": a:name,
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

function! ansanloms#terminal#ssh(destination)
  call ansanloms#terminal#terminal("ssh " . a:destination, a:destination)
endfunction
