" Python import management
" Vim plugin
"
" Copyright (c) 2012, Phillip Berndt
" Use as you wish under the VIM license
"
" Maps a function to <C-i> in insert mode which automatically adds import
" statements if needed. Simply position the cursor over a module name and the
" import will be added. If there is no word under the cursor the user will be
" asked to enter a module name.
"
"
" Ideas for improvement:
"  * Somehow handle from .. import .. statements
"  * Perhaps do this automatically when a dot is entered?!
"    But this would require a check whether the word before
"    the dot is a module or a class/object
"  * Recognize strings at the top of the file and insert
"    imports below. Currently, only hash'ed comments are
"    recognized to cope with the shebang and encoding comment
"

function <SID>PythonInsert()
	let l:import = expand("<cword>")
	if l:import == ""
		let l:import = input("Module to import: ")
		if l:import == ""
			return
		endif
	end

	let l:oldpos = getpos(".")

	" First check if this already gets imported
	call cursor(1, 1)
	if search("^\[ \t\]*import.*" . l:import, "cn") != 0
		call setpos(".", l:oldpos)
		return
	end

	" Locate the first import line
	call cursor(1, 1)
	let l:firstImport = search("^\[ \t\]*import ", "cn")
	if l:firstImport == 0
		" Search for the first non-comment line and use that one
		call cursor(1, 1)
		let l:firstImport = 1
		while 1
			let l:firstImport += 1
			let l:found = search("^\[ \t\]*#", "", line("$"))
			if l:found == 0 || l:found > l:firstImport
				break
			end
		endwhile
	end
	if line("$") < l:firstImport
		let l:firstImport = line("$")
	end

	" Insert the new import
	call cursor(l:firstImport, 1)
	exe "normal I\<CR>\<ESC>"
	let l:oldpos[1] += 1
	call setline(l:firstImport, "import " . l:import)

	" Resort the imports
	call cursor(l:firstImport, 1)
	let l:lastImport = l:firstImport
	while 1
		let l:found = search("^\[ \t\]*import", "", line("$"))
		if l:found == 0 || l:found > l:lastImport + 1
			break
		end
		let l:lastImport += 1
	endwhile
	exe "normal :" . l:firstImport . "," . l:lastImport . "sort\<CR>"

	" Position the cursor where it was before
	let l:oldpos[2] += 1
	call setpos(".", l:oldpos)
endfunction
imap <C-i> <C-o>:call <SID>PythonInsert()<CR>


