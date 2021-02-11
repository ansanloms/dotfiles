" ssh
function! ansanloms#terminal#ssh(ssh)
  let l:cmd = "ssh " . a:ssh
  call term_start(l:cmd, {
  \ "term_name": l:cmd,
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" cmd
function! ansanloms#terminal#cmd()
  call term_start("cmd", {
  \ "term_name": "cmd",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" powershell
function! ansanloms#terminal#powershell()
  call term_start("powershell", {
  \ "term_name": "powershell",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" nyagos
function! ansanloms#terminal#nyagos()
  call term_start(expand($HOME . "/scoop/apps/nyagos/current/nyagos"), {
  \ "term_name": "NYAGOS",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" ubuntu
function! ansanloms#terminal#ubuntu()
  call term_start("Ubuntu", {
  \ "term_name": "WSL (Ubuntu)",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" debian
function! ansanloms#terminal#debian()
  call term_start("Debian", {
  \ "term_name": "WSL (Debian)",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" fedoraremix
function! ansanloms#terminal#fedoraremix()
  call term_start("fedoraremix", {
  \ "term_name": "WSL (Fedora)",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" sles12
function! ansanloms#terminal#sles12()
  call term_start("sles12", {
  \ "term_name": "WSL (SLES-12)",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" msys2
function! ansanloms#terminal#msys2()
  call term_start(expand("~/scoop/apps/msys2/current/msys2_shell.cmd") . " -msys -defterm -no-start", {
  \ "term_name": "MSYS2",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" mingw32
function! ansanloms#terminal#mingw32()
  call term_start(expand("~/scoop/apps/msys2/current/msys2_shell.cmd") . " -mingw32 -defterm -no-start", {
  \ "term_name": "MinGW-w64 Win32",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction

" mingw64
function! ansanloms#terminal#mingw64()
  call term_start(expand("~/scoop/apps/msys2/current/msys2_shell.cmd") . " -mingw64 -defterm -no-start", {
  \ "term_name": "MinGW-w64 Win64",
  \ "term_finish": "close",
  \ "curwin": 1
  \})
endfunction
