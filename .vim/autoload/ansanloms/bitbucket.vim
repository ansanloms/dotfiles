" BitBucket を開く
function! ansanloms#bitbucket#open() range
  silent execute "!bb browse code" expand("%:p") "-l" a:firstline."-".a:lastline
endfunction
