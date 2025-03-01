call minpac#add("https://github.com/aklt/plantuml-syntax.git")

augroup plantuml-setting
  autocmd!

  autocmd BufNewFile,BufRead *.{pu,uml,puml,iuml,plantuml} set filetype=plantuml
  autocmd FileType plantuml setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" quickrun - plantuml
if executable("plantuml")
  let g:quickrun_config["plantuml"] = {
  \ "type": "plantuml/svg"
  \}

  " svg 出力
  let g:quickrun_config["plantuml/svg"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "browser",
  \ "exec": (has("win32") || has("win64") ? "type" : "cat") . " %s | plantuml -tsvg -charset UTF-8 -pipe"
  \}
endif
