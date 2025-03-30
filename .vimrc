let g:no_gvimrc_example = 1
let g:no_vimrc_example = 1

let g:loaded_getscriptPlugin = 1
let g:loaded_gzip = 1
let g:loaded_logiPat = 1
let g:loaded_manpager = 1
let g:loaded_matchparen = 1
let g:loaded_netrwPlugin = 1
let g:loaded_openPlugin = 1
let g:loaded_rrhelper = 1
let g:loaded_spellfile = 1
let g:loaded_tarPlugin = 1
let g:loaded_tohtml = 1
let g:loaded_tutor = 1
let g:loaded_vimballPlugin = 1
let g:loaded_zipPlugin = 1

" init
source ~/.config/vim/config/init.vim

" mapping
source ~/.config/vim/config/mapping.vim

" plugins
source ~/.config/vim/config/plugins/manager.vim
source ~/.config/vim/config/plugins/general.vim
source ~/.config/vim/config/plugins/ime.vim
source ~/.config/vim/config/plugins/lsp.vim
source ~/.config/vim/config/plugins/ai-chat.vim
source ~/.config/vim/config/plugins/snippet.vim
source ~/.config/vim/config/plugins/fuzzy-finder.vim

" quickfix
source ~/.config/vim/config/quickfix.vim

" appearance
source ~/.config/vim/config/gui.vim
source ~/.config/vim/config/statusline.vim
source ~/.config/vim/config/appearance.vim

" langs
source ~/.config/vim/config/langs/clang.vim
source ~/.config/vim/config/langs/java.vim
source ~/.config/vim/config/langs/java.vim
source ~/.config/vim/config/langs/javascript.vim
source ~/.config/vim/config/langs/typescript.vim
source ~/.config/vim/config/langs/markdown.vim
source ~/.config/vim/config/langs/vue.vim
source ~/.config/vim/config/langs/php.vim
source ~/.config/vim/config/langs/asciidoc.vim
source ~/.config/vim/config/langs/plantuml.vim
source ~/.config/vim/config/langs/sh.vim
source ~/.config/vim/config/langs/vim.vim
source ~/.config/vim/config/langs/sql.vim
source ~/.config/vim/config/langs/html.vim
source ~/.config/vim/config/langs/xml.vim
source ~/.config/vim/config/langs/css.vim
source ~/.config/vim/config/langs/scss.vim
source ~/.config/vim/config/langs/stylus.vim
source ~/.config/vim/config/langs/json.vim
source ~/.config/vim/config/langs/conf.vim
source ~/.config/vim/config/langs/groovy.vim
source ~/.config/vim/config/langs/graphql.vim
source ~/.config/vim/config/langs/dart.vim
source ~/.config/vim/config/langs/toml.vim
source ~/.config/vim/config/langs/yaml.vim
source ~/.config/vim/config/langs/prisma.vim
source ~/.config/vim/config/langs/python.vim
source ~/.config/vim/config/langs/lua.vim
source ~/.config/vim/config/langs/powershell.vim
source ~/.config/vim/config/langs/mustache.vim
source ~/.config/vim/config/langs/terraform.vim
source ~/.config/vim/config/langs/rust.vim
source ~/.config/vim/config/langs/binary.vim


" お仕事用設定。
if filereadable(expand("~/.vim/work.vim"))
  source ~/.config/vim/work.vim
endif

" 一時的設定。
if filereadable(expand("~/.vim/temp.vim"))
  source ~/.config/vim/temp.vim
endif
