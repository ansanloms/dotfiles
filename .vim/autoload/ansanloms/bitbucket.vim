" BitBucket を開く
function! ansanloms#bitbucket#open() range
  packadd vital.vim
  let l:path = vital#vital#new().import("Prelude").path2project_directory(expand("%:p"))
  silent execute "!bb browse code" expand("%:p") "-l" a:firstline."-".a:lastline
endfunction
