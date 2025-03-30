augroup typescript-setting
  autocmd!

  autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType typescriptreact setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
  autocmd FileType typescript.tsx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" quickrun - typescript
if executable("tsc")
  let g:quickrun_config["typescript"] = {
  \ "type": "typescript/tsc"
  \}

  let g:quickrun_config["typescript/tsc"] = {
  \ "command": "tsc",
  \ "exec": ["%c --target esnext --module commonjs %o %s", "node %s:r.js"],
  \ "tempfile": "%{tempname()}.ts",
  \ "hook/sweep/files": ["%S:p:r.js"],
  \}
endif
