set laststatus=2
set statusline=%!ansanloms#statusline#statusline()

set showtabline=1
set tabline=%!ansanloms#tabline#tabline()

"call minpac#add("https://github.com/itchyny/lightline.vim.git")
"
"let g:lightline = {
"\ "colorscheme": "gotham",
"\ "active": {
"\   "left": [
"\     ["mode", "readonly", "paste"],
"\     ["filename"],
"\   ],
"\   "right": [
"\     ["fileformat", "fileencoding", "filetype"],
"\   ]
"\ },
"\ "component_expand": {
"\   "tabs": "ansanloms#lightline#tab"
"\ },
"\ "component_function": {
"\   "mode": "ansanloms#statusline#mode_minimum",
"\   "filename": "ansanloms#lightline#filename",
"\ },
"\ "component": {
"\   "modified": "%{(ansanloms#lightline#is_visible() && &modifiable) ? (&modified ? '[+]' : '[-]') : ''}",
"\   "readonly": "%{&readonly ? '' : ''}",
"\   "fileformat": "%{ansanloms#lightline#is_visible() ? &fileformat : ''}",
"\   "filetype": "%{ansanloms#lightline#is_visible() ? (strlen(&filetype) ? &filetype : 'no ft') : ''}",
"\   "fileencoding": "%{ansanloms#lightline#is_visible() ? (&fileencoding !=# '' ? &fileencoding : &encoding) : ''}",
"\ },
"\ "tab_component_function": {
"\   "filename": "ansanloms#lightline#tabfilename",
"\   "modified": "lightline#tab#modified",
"\   "readonly": "lightline#tab#readonly",
"\   "tabnum": ""
"\ },
"\ "separator": {
"\   "left": "",
"\   "right": ""
"\ },
"\ "subseparator": {
"\   "left": "",
"\   "right": ""
"\ },
"\}
