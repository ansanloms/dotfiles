call minpac#add("https://github.com/ansanloms/vim-ramble.git")

augroup ramble-chat
  autocmd!

  autocmd FileType ramble-chat nnoremap <C-@> :<C-u>call denops#request("ramble", "chat", [bufnr()])<CR>
  autocmd FileType ramble-chat nnoremap <C-Space> :<C-u>call denops#request("ramble", "chat", [bufnr()])<CR>
augroup END
