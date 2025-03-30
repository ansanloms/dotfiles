call minpac#add("https://github.com/vim-jp/vim-java.git")

if !filereadable(expand("~/.config/vim/syntax/javaid.vim"))
  call system("curl https://fleiner.com/vim/syntax/javaid.vim -o " . expand("~/.config/vim/syntax/javaid.vim"))
endif

let g:java_highlight_all = 1

" quickrun - java
let g:quickrun_config["java"] = {
\ "hook/cd/directory": "%S:p:h",
\ "exec": [
\   "javac -J-Dfile.encoding=UTF8 %o %s",
\   "%c -Dfile.encoding=UTF8 %s:t:r %a"
\ ]
\}

augroup java-setting
  autocmd!

  autocmd FileType java setlocal shiftwidth=4 tabstop=4 softtabstop=4 noexpandtab
augroup END
