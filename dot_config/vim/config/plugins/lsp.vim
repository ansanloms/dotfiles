call minpac#add("https://github.com/prabirshrestha/asyncomplete.vim.git")
call minpac#add("https://github.com/prabirshrestha/asyncomplete-lsp.vim.git")
call minpac#add("https://github.com/prabirshrestha/vim-lsp.git")
call minpac#add("https://github.com/mattn/vim-lsp-settings.git")

let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_echo_delay = 50
let g:lsp_diagnostics_highlights_enabled = 1
let g:lsp_diagnostics_highlights_delay = 50
let g:lsp_diagnostics_highlights_insert_mode_enabled = 0
let g:lsp_diagnostics_signs_enabled = 1
let g:lsp_diagnostics_signs_delay = 50
let g:lsp_diagnostics_signs_insert_mode_enabled = 0
let g:lsp_diagnostics_virtual_text_enabled = 1
let g:lsp_diagnostics_virtual_text_delay = 50

let g:lsp_completion_documentation_delay = 40
let g:lsp_document_highlight_delay = 100
let g:lsp_document_code_action_signs_delay = 100
let g:lsp_fold_enabled = 0
let g:lsp_text_edit_enabled = 1
let g:lsp_inlay_hints_enabled = 1

let g:lsp_diagnostics_virtual_text_enabled = 0

" 補完時にみる情報:
" 検索対象が実装されている箇所 / 検索対象が定義されている箇所 / 検索対象が宣言されている箇所 / 検索対象の型が定義されている箇所
let g:lsp_tagfunc_source_methods = [
\ "implementation",
\ "definition",
\ "declaration",
\ "typeDefinition"
\]

let g:lsp_diagnostics_signs_enabled = 1
let g:lsp_diagnostics_signs_error = { "text": ">"  }
let g:lsp_diagnostics_signs_warning = { "text": "v" }
let g:lsp_diagnostics_signs_information = { "text": "!" }
let g:lsp_diagnostics_signs_hint = { "text": "?" }

let g:lsp_document_code_action_signs_enabled = 1
let g:lsp_document_code_action_signs_hint = { "text": "?" }

" asyncomplete.vim
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 1
let g:asyncomplete_popup_delay = 200
let g:asyncomplete_matchfuzzy = 1

" vim-lsp-settings
let g:lsp_settings = {
\ "eslint-language-server": {
\   "allowlist": ["javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue"],
\ },
\ "efm-langserver": {
\   "disabled": v:true,
\ },
\}

let g:lsp_settings_filetype_typescript = ["typescript-language-server", "eslint-language-server", "deno"]
let g:lsp_settings_filetype_vue = ["typescript-language-server", "volar-server", "eslint-language-server", "efm-langserver"]

augroup lsp-setting
  autocmd!

  autocmd User lsp_buffer_enabled setlocal omnifunc=lsp#complete
  autocmd User lsp_buffer_enabled setlocal signcolumn=yes
  autocmd User lsp_buffer_enabled setlocal tagfunc=lsp#tagfunc
  "autocmd User lsp_buffer_enabled setlocal foldmethod=expr
  "autocmd User lsp_buffer_enabled setlocal foldexpr=lsp#ui#vim#folding#foldexpr()
  "autocmd User lsp_buffer_enabled setlocal foldtext=lsp#ui#vim#folding#foldtext()

  autocmd User lsp_buffer_enabled nnoremap [lsp] <Nop>
  autocmd User lsp_buffer_enabled vnoremap [lsp] <Nop>
  autocmd User lsp_buffer_enabled nmap <Space>l [lsp]
  autocmd User lsp_buffer_enabled vmap <Space>l [lsp]
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]h <Plug>(lsp-hover)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]a <Plug>(lsp-code-action)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]d <Plug>(lsp-definition)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]i <Plug>(lsp-implementation)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]r <Plug>(lsp-references)
  autocmd User lsp_buffer_enabled nmap <buffer> [lsp]f <plug>(lsp-document-format-sync)
  autocmd User lsp_buffer_enabled vmap <buffer> [lsp]f <plug>(lsp-document-range-format-sync)
  autocmd User lsp_buffer_enabled nmap <silent> [lsp]n <Plug>(lsp-next-error)
  autocmd User lsp_buffer_enabled nmap <silent> [lsp]p <Plug>(lsp-previous-error)
augroup END
