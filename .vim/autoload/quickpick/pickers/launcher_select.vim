let s:bang = ""
let s:list = []

function! quickpick#pickers#launcher_select#open(bang) abort
  let s:bang = a:bang

  call quickpick#open({
  \ "items": s:get_items(),
  \ "on_accept": function("s:on_accept"),
  \})
endfunction

function! s:get_items() abort
  let l:config_file = get(g:, "quickpick_launcher_file", "~/.quickpick-launcher")
  let s:list = map(glob(l:config_file . "-*", v:true, v:true), { k, v, -> [strpart(v, strlen(expand(l:config_file . "-"))), strpart(v, strlen(expand(l:config_file . "-")))] })

  let s:list = [["(none)", ""]] + s:list
  return map(copy(s:list), { v -> v:val[0] })
endfunction

function! s:on_accept(data, name) abort
  let l:lines = filter(copy(s:list), { v -> v:val[0] == a:data["items"][0]} )
  call quickpick#close()
  call quickpick#pickers#launcher#open(s:bang, l:lines[0][1])
endfunction
