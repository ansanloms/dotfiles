" hostsを開く
function! ansanloms#hosts#open()
  let l:hosts_path = expand("/etc/hosts")

  if has("mac")
    " mac
    let l:hosts_path = expand("/private/etc/hosts")
  elseif has("win32") || has("win64")
    " windows
    let l:hosts_path = expand("C:/Windows/System32/drivers/etc/hosts")
  endif

  silent execute "edit " . l:hosts_path
endfunction
