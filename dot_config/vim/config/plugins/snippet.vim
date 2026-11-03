call minpac#add("https://github.com/hrsh7th/vim-vsnip.git")
call minpac#add("https://github.com/hrsh7th/vim-vsnip-integ.git")

let g:vsnip_snippet_dir = expand("~/.config/vim/snippets")

let g:vsnip_filetypes = {}
let g:vsnip_filetypes.typescript = ["javascript"]
let g:vsnip_filetypes.vue = ["javascript", "typescript"]
let g:vsnip_filetypes.javascriptreact = ["javascript"]
let g:vsnip_filetypes.typescriptreact = ["javascript", "typescript"]
