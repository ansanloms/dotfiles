function! ansanloms#statusline#statusline() abort
  let l:s = " " . ansanloms#statusline#statusline_mode_minimum() . ansanloms#statusline#paste_mode() . " " . ansanloms#statusline#filename() . "%m%r%h%w%=" . " " . &filetype . " " . &fileformat . " " . &fileencoding

  if exists("*sky_color_clock#statusline()")
    let l:s = l:s . " " . "%#SkyColorClock#" . " " . sky_color_clock#statusline() . " "
  endif

  return l:s
endfunction

function! ansanloms#statusline#statusline_quickfix() abort
  return "%t" . (exists("w:quickfix_title") ? w:quickfix_title : "") . " " . "%=[%l/%L\ %p%%]"
endfunction

function! ansanloms#statusline#statusline_mode_minimum() abort
  let l:mode_list = {
  \ "n":       "N"
  \ ,"i":      "I"
  \ ,"R":      "R"
  \ ,"v":      "V"
  \ ,"V":      "V"
  \ ,"c":      "C"
  \ ,"\<C-v>": "V"
  \ ,"s":      "S"
  \ ,"S":      "S"
  \ ,"\<C-s>": "S"
  \ ,"t":      "T"
  \ ,"?":      "?"
  \}

  let l:current_mode = mode()
  return has_key(l:mode_list, l:current_mode) ? l:mode_list[l:current_mode] : (l:current_mode . "?")
endfunction

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
