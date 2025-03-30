call minpac#add("https://github.com/jxnblk/vim-mdx-js.git")

augroup markdown-setting
  autocmd!

  autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown
  autocmd FileType markdown setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

augroup markdown-mdx-setting
  autocmd!

  autocmd FileType markdown.mdx setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
augroup END

" quickrun - markdown
if executable("pandoc")
  " css の取得
  if !filereadable(expand("~/.config/vim/markdown.css"))
    call system("curl https://gist.githubusercontent.com/tuzz/3331384/raw/d1771755a3e26b039bff217d510ee558a8a1e47d/github.css -o " . expand("~/.config/vim/markdown.css"))
  endif

  let g:quickrun_config["markdown"] = {
  \ "type": "markdown/pandoc"
  \}

  " html 出力
  let g:quickrun_config["markdown/pandoc"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "browser",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --css=" . expand("~/.config/vim/markdown.css") . " --metadata title=%s"
  \}

  " slidy 出力
  let g:quickrun_config["markdown/pandoc-slidy"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "browser",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=slidy --toc-depth=6 --metadata title=%s"
  \}

  " Word docx 出力
  let g:quickrun_config["markdown/pandoc-docx"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter": "null",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=docx --toc-depth=6 --highlight-style=zenburn --output=%s.docx"
  \}

  " 単一 markdown 出力
  let g:quickrun_config["markdown/pandoc-self-contained"] = {
  \ "hook/cd/directory": "%S:p:h",
  \ "outputter/buffer/filetype": "markdown",
  \ "exec": "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --no-highlight --metadata title=%s | pandoc --from html --to markdown --wrap none --markdown-headings=atx" . ' | sed -r -e "s/```\s*\{\.(.*)\}/```\1/g"'
  \}
endif
