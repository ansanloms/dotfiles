function! ansanloms#lightline#is_visible() abort
  return (60 <= winwidth(0)) && (&filetype !~? "help")
endfunction

function! ansanloms#lightline#filename() abort
  if expand("%:t") == ""
    return "[No Name]"
  endif

  " https://bitbucket.org/ns9tks/vim-fuzzyfinder/src/tip/autoload/fuf.vim
  let l:str = expand("%:p")
  let l:len = (winwidth(0) / 2) - len(expand("%:p:t"))
  let l:mask = "..."

  if l:len >= len(l:str)
    return l:str
  elseif l:len <= len(l:mask)
    return l:mask
  endif

  let l:head = (l:len - len(l:mask)) / 2
  let l:tail = l:len - len(l:mask) - l:head

  return (l:head > 0 ? l:str[: l:head - 1] : "") . l:mask . (l:tail > 0 ? l:str[-l:tail :] : "")
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
