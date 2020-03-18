" BitBucket を開く
function! ansanloms#bitbucket#open() range
  packadd vital.vim
  let l:path = vital#vital#new().import("Prelude").path2project_directory(expand("%:p"))
  execute "!git -C" l:path "bitbucket-browse" expand("%:p") a:firstline."-".a:lastline
endfunction
