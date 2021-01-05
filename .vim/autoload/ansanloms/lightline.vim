function! ansanloms#lightline#is_visible() abort
  return (60 <= winwidth(0)) && (&filetype !~? "help")
endfunction

function! ansanloms#lightline#statusline_mode() abort
  return ansanloms#statusline#statusline_mode()
endfunction

function! ansanloms#lightline#filename() abort
  return expand("%:p") != "" ? expand("%:p") : "[No Name]"
endfunction

function! ansanloms#lightline#tab() abort
  let [x, y, z] = [[], [], []]
  let nr = tabpagenr()
  let cnt = tabpagenr('$')

  for i in range(1, cnt)
    call add(i < nr ? x : i == nr ? y : z, (i > nr + 3 ? '%<' : '') . '%'. i . 'T%{lightline#onetab(' . i . ',' . (i == nr) . ')}' . (i == cnt ? '%T' : ''))
  endfor

  return [x, y, z]
endfunction

function! ansanloms#lightline#tabfilename(n) abort
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)
  let filepath = expand("#" . buflist[winnr - 1] . ":f")
  let filename = expand("#" . buflist[winnr - 1] . ":t")

  return filename !=# "" ? filename : "[No Name]"
endfunction
