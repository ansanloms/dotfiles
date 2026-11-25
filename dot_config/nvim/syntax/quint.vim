" Quint の syntax は上流リポジトリ quint-co/quint のものを使う。
" lazy.nvim が clone した editor-plugins/vim/quint.vim を source する
" (plugin spec は lua/ansanloms/plugins/specs/quint.lua)。
let s:syntax_file = stdpath('data') .. '/lazy/quint/editor-plugins/vim/quint.vim'

if filereadable(s:syntax_file)
  execute 'source' fnameescape(s:syntax_file)
endif
