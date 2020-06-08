function! ansanloms#statusline#statusline_mode() abort
  let l:mode_list = {
  \ "n":       "NORMAL"
  \ ,"i":      "INSERT"
  \ ,"R":      "REPLACE"
  \ ,"v":      "VISUAL"
  \ ,"V":      "V-LINE"
  \ ,"c":      "COMMAND"
  \ ,"\<C-v>": "V-BLOCK"
  \ ,"s":      "SELECT"
  \ ,"S":      "S-LINE"
  \ ,"\<C-s>": "S-BLOCK"
  \ ,"t":      "TERMINAL"
  \ ,"?":      "?"
  \}

  let l:current_mode = mode()
  return has_key(l:mode_list, l:current_mode) ? l:mode_list[l:current_mode] : (l:current_mode . "?")
endfunction

function! ansanloms#statusline#paste_mode() abort
  return (&paste) ? "(PASTE)" : ""
endfunction

function! ansanloms#statusline#filename() abort
  if expand("%:t") == ""
    return "[No Name]"
  endif

  " https://bitbucket.org/ns9tks/vim-fuzzyfinder/src/tip/autoload/fuf.vim
  let l:str = expand("%:p")
  let l:len = (winwidth(0) / 3) - len(expand("%:p:t"))
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
