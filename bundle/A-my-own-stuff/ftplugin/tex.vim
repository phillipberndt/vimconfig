fun! InsertQuote()
	let last_start = match(getline('.'), '"`[^"]*\%' . col('.') . 'c')
	let last_end = match(getline('.'), '"' . "'" . '[^"]*\%' . col('.') . 'c')

	if last_start == -1
		return '"`'
	elseif last_start < last_end
		return '"`'
	else
		return '"' . "'"
	endif
endf

imap <M-2> <c-g>u<c-r>=InsertQuote()<cr>
