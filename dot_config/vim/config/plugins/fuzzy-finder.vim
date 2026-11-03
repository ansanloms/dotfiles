call minpac#add("https://github.com/ansanloms/vim-bekken.git")
call minpac#add("https://github.com/ansanloms/vim-bekken-files.git")
call minpac#add("https://github.com/ansanloms/vim-bekken-buffer.git")
call minpac#add("https://github.com/ansanloms/vim-bekken-launcher.git")

if executable("rg")
  let g:bekken#files#get_file_list_cmd = ["rg", "--files"]
endif

" launcher
nnoremap <silent> <C-e> :<C-u>call bekken#Run("launcher#select", globpath(expand("~/.config/vim/launcher"), "**/*.yaml", v:false, v:true), {})<CR>
vnoremap <silent> <C-e> :<C-u>call bekken#Run("launcher#select", globpath(expand("~/.config/vim/launcher"), "**/*.yaml", v:false, v:true), {})<CR>

let g:bekken_buffer#key_mappings = {
\ "\<CR>": { bufnr -> execute("buffer " .. bufnr) },
\ "\<C-s>": { bufnr -> execute("split | buffer " .. bufnr) },
\ "\<C-v>": { bufnr -> execute("vsplit | buffer " .. bufnr) },
\ "\<C-w>": { bufnr -> execute("split | wincmd w | buffer " .. bufnr) },
\ "\<C-l>": { bufnr -> execute("vsplit | wincmd l | buffer " .. bufnr) },
\}

let g:bekken_files#key_mappings = {
\ "\<CR>": { path -> execute("edit " .. path) },
\ "\<C-s>": { path -> execute("split | edit " .. path) },
\ "\<C-v>": { path -> execute("vsplit | edit " .. path) },
\ "\<C-w>": { path -> execute("split | wincmd w | edit " .. path) },
\ "\<C-l>": { path -> execute("vsplit | wincmd l | edit " .. path) },
\}

function! s:GetProjectDir() abort
  let l:dir_base = expand("%:h")
  if empty(l:dir_base)
    return getcwd()
  endif

  let l:project_dir = ansanloms#project#dir(l:dir_base)
  if empty(l:project_dir)
    return getcwd()
  endif

  return  l:project_dir
endfunction

" history
nnoremap <silent> <C-h> :<C-u>call bekken#Run("files#oldfiles", [g:bekken_files#key_mappings], { "filetype": { "selection": "bekken-selection-files" } })<CR>

" current files
nnoremap <silent> <C-l> :<C-u>call bekken#Run("files#list", [<SID>GetProjectDir(), g:bekken_files#key_mappings], { "filetype": { "selection": "bekken-selection-files" } })<CR>

" buffer
nnoremap <silent> <C-s> :<C-u>call bekken#Run("buffer", [v:false, g:bekken_buffer#key_mappings], { "filetype": { "selection": "bekken-selection-buffer" } })<CR>
