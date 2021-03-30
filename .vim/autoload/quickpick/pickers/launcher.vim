let s:list = []
let s:profile = ""
let s:bang = ""

function! quickpick#pickers#launcher#open(bang, ...) abort
  let s:bang = a:bang
  let s:profile = get(a:000, 0, "")

  call quickpick#open({
  \ "items": s:get_items(),
  \ "on_accept": function("s:on_accept"),
  \})
endfunction

function! s:get_items() abort
  let l:config_file = get(g:, "quickpick_launcher_file", "~/.quickpick-launcher")
  if !empty(s:profile)
    let l:config_file .= "-" . s:profile
  endif
  let l:file = fnamemodify(expand(l:config_file), ":p")
  let s:list = filereadable(l:file) ? filter(map(readfile(l:file), { v -> split(iconv(v:val, "utf-8", &encoding), "\\t\\+")} ), { v -> len(v:val) > 0 && v:val[0]!~"^#"} ) : []
  if empty(s:bang)
    let s:list += [["--edit-menu--", printf("botright split %s", fnameescape(l:config_file))]]
  endif
  return map(copy(s:list), { v -> v:val[0] })
endfunction

function! s:on_accept(data, name) abort
  let l:lines = filter(copy(s:list), { v -> v:val[0] == a:data["items"][0]} )
  call quickpick#close()
  if len(l:lines) > 0 && len(l:lines[0]) > 1
    let l:cmd = l:lines[0][1]
    if l:cmd =~ "^!"
      silent exe l:cmd
    else
      exe l:cmd
    endif
  endif
endfunction
