function! ansanloms#tabline#tabline() abort
  let l:sep = ""  " タブ間の区切り
  return join(map(range(1, tabpagenr("$")), "ansanloms#tabline#tabpage_label(v:val)"), l:sep) . l:sep . "%#TabLineFill#%T"
endfunction

function! ansanloms#tabline#tabpage_label(tabpagenr) abort
  " タブページ内のバッファのリスト
  let l:bufnrs = tabpagebuflist(a:tabpagenr)

  " カレントタブページかどうかでハイライトを切り替える
  let l:hi = a:tabpagenr is tabpagenr() ? "%#TabLineSel#" : "%#TabLine#"

  " タブページ内に変更ありのバッファがあったら "+" を付ける
  let l:mod = len(filter(copy(l:bufnrs), "getbufvar(v:val, \"&modified\")")) ? "[+]" : ""

  " カレントバッファ
  let l:curbufnr = l:bufnrs[tabpagewinnr(a:tabpagenr) - 1]  " tabpagewinnr() は 1 origin

  " ファイルネーム
  let l:fname = fnamemodify(bufname(l:curbufnr), ":t")

  " ファイルネームがないとき
  let l:noname = "[No Name]"

  return "%" . a:tabpagenr . "T" . l:hi . " " . a:tabpagenr . ":" . (l:fname !=# "" ? l:fname : l:noname) . l:mod . " " . "%T%#TabLineFill#"
endfunction
