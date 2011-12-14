" Make scripts executable automatically, but only if the file is newly created
"

function! <SID>SetExecutableBit()
	" This is taken from 
	" http://vim.wikia.com/wiki/Suppressing_file_changed_warnings_in_a_specific_buffer
	let $aucfile = expand("%")
	autocmd FileChangedShell $aucfile autocmd! FileChangedShell $aucfile
	silent !chmod a+x %
	checktime
endfunction


autocmd BufWritePre  * let b:isnewfile = !filereadable(expand("%"))
autocmd BufWritePost * if b:isnewfile == 1 | if getline(1) =~ "^#!" | call <SID>SetExecutableBit() | endif | endif
