let s:marks = [
\   ".git",
\   ".bzr",
\   ".hg",
\   ".svn",
\   "build.xml",
\   "prj.el",
\   ".project",
\   "pom.xml",
\   "package.json",
\   "Makefile",
\   "configure",
\   "Rakefile",
\   "NAnt.build",
\   "P4CONFIG",
\   "tags",
\   "gtags",
\   "deno.json",
\   "deno.jsonc",
\   "docker-compose.yml",
\   "docker-compose.yaml",
\   "compose.yml",
\   "compose.yaml",
\   "composer.json"
\ ]

function! s:is_project_directory(base_dir) abort
  if !isdirectory(a:base_dir)
    return v:false
  endif

  let l:entries = readdir(a:base_dir)
  for l:entry in l:entries
    if index(s:marks, l:entry) != -1
      return v:true
    endif
  endfor

  return v:false
endfunction

function! s:get_project_directory(base_dir) abort
  if s:is_project_directory(a:base_dir)
    return a:base_dir
  endif

  let l:next_base_dir = fnamemodify(a:base_dir, ":h")
  if l:next_base_dir ==# a:base_dir
    return v:null
  endif

  return s:get_project_directory(l:next_base_dir)
endfunction

function! ansanloms#project#dir(base_dir, default) abort
  let l:project_dir = s:get_project_directory(a:base_dir)

  return l:project_dir == v:null ? a:default : l:project_dir
endfunction
