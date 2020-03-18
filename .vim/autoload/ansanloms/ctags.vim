" タグファイル生成
function! ansanloms#ctags#create()
  if !executable("ctags")
    echoerr "ctags command not found."
    return
  endif

  packadd vital.vim
  let l:path = vital#vital#new().import("Prelude").path2project_directory(expand("%:p"))
  let l:ctags_cmd = "ctags --output-format=e-ctags -R -f " . l:path . "/tags " . l:path

  if &filetype == "php"
    let l:ctags_cmd = "ctags --languages=PHP --php-types=c+f+d --langmap=PHP:.php.inc.volt --output-format=e-ctags -R -f " . l:path . "/tags " . l:path
  endif

  echo l:ctags_cmd
  let l:job_ctags = job_start(l:ctags_cmd, {})
endfunction
