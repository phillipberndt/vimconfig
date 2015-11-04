"" Highlight merge failure comments on leader+m

let b:mergeCommentMatchState = 0
function! <SID>HighlightMergeComments()
	" highlight DiffText
	if b:mergeCommentMatchState == 0
		hi MergeComment gui=bold guibg=Red term=reverse cterm=bold ctermbg=9
		match MergeComment /\(<<<<<<<\|=======\|>>>>>>>\).*/
		let b:mergeCommentMatchState = 1
	else
		match none
		let b:mergeCommentMatchState = 0
	endif
endfunction
nmap <leader>m :call <SID>HighlightMergeComments()<cr>
