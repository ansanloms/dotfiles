" terminal
function! ansanloms#terminal#terminal(cmd, name)
  call term_start(a:cmd, {
  \ "term_name": a:name,
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" ssh
function! ansanloms#terminal#ssh(destination)
  call ansanloms#terminal#terminal("ssh " . a:destination, a:destination)
endfunction

" cmd
function! ansanloms#terminal#cmd()
  call ansanloms#terminal#terminal("cmd", "cmd")
endfunction

" powershell
function! ansanloms#terminal#powershell()
  call ansanloms#terminal#terminal("powershell", "powershell")
endfunction

" nyagos
function! ansanloms#terminal#nyagos()
  call ansanloms#terminal#terminal(expand("~/scoop/apps/nyagos/current/nyagos"), "NYAGOS")
endfunction

" wsl
function! ansanloms#terminal#wsl(distribution)
  call ansanloms#terminal#terminal("wsl -d " . a:distribution, "WSL (" . a:distribution . ")")
endfunction

" msys2
function! ansanloms#terminal#msys2()
  call ansanloms#terminal#terminal(expand("~/scoop/apps/msys2/current/msys2_shell.cmd") . " -msys -defterm -no-start", "MSYS2")
endfunction

" mingw32
function! ansanloms#terminal#mingw32()
  call ansanloms#terminal#terminal(expand("~/scoop/apps/msys2/current/msys2_shell.cmd") . " -mingw32 -defterm -no-start", "MinGW-w64 32bit")
endfunction

" mingw64
function! ansanloms#terminal#mingw64()
  call ansanloms#terminal#terminal(expand("~/scoop/apps/msys2/current/msys2_shell.cmd") . " -mingw64 -defterm -no-start", "MinGW-w64 64bit")
endfunction
