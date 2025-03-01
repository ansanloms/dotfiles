function! s:GetTabLabel(bufnr) abort
  " ファイル名。
  let l:label = fnamemodify(bufname(a:bufnr), ":t")

  " ファイル名がないとき。
  if len(l:label) <= 0
    let l:label .= "[No Name]"
  endif

  " 変更ありのバッファに付ける。
  if getbufvar(a:bufnr, "&modified")
    let l:label .= "[+]"
  endif

  return l:label
endfunction

function! s:GetTabLine(tabpagenr) abort
  " カレントバッファ。
  let l:curbufnr = tabpagebuflist(a:tabpagenr)[tabpagewinnr(a:tabpagenr) - 1]

  " カレントタブページかどうかでハイライトを切り替える。
  let l:hi = a:tabpagenr is tabpagenr() ? "%#TabLineSel#" : "%#TabLine#"

  return "%" . a:tabpagenr . "T" . l:hi . " " . s:GetTabLabel(l:curbufnr) . " " . "%T%#TabLineFill#"
endfunction

function! ansanloms#tabline#tabline() abort
  let l:sep = ""  " タブ間の区切り

  return join(map(range(1, tabpagenr("$")), {_, val -> s:GetTabLine(val)}), l:sep) . l:sep . "%#TabLineFill#%T"
endfunction
