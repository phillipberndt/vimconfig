map <F5> :w\|:!python %<CR>

" PEP 8
setlocal tabstop=4
setlocal softtabstop=4
setlocal shiftwidth=4
" I break with PEP 8 on this, but tw=79 is really useless waste of display
" space on modern screens. Also, VIM sometimes fails to wrap to a good-looking
" and understandable format and I don't want to fix the wrapper script.
" setlocal textwidth=79
setlocal expandtab
setlocal nosmarttab
