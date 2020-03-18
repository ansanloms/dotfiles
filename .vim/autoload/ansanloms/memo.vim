" memo を設置するディレクトリを取得
function! s:dir()
  let l:memo_base_dir = get(g:, "ansanloms_memo_base_dir", expand("~/memo"))

  if !isdirectory(expand(l:memo_base_dir))
    call mkdir(l:memo_base_dir, "p")
  endif

  if !isdirectory(expand(l:memo_base_dir))
    echoerr l:memo_base_dir . " is not a directory."
  endif

  return l:memo_base_dir
endfunction

" メモ関連: 開く
function! ansanloms#memo#open(...)
  execute "edit " . expand(s:dir()) . "/" . get(a:, "1", strftime("%Y%m%d")) . ".md"
endfunction

" メモ関連: CtrlPで開く
function! ansanloms#memo#list()
  execute "CtrlP " . expand(s:dir())
endfunction
