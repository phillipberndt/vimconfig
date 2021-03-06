" VIMrc
" Phillip Berndt
"
version 7.0

" Use Pathogen. It's critical to call this before enabling filetype detection
filetype off
call pathogen#infect()
if v:version >= 801
	packadd termdebug
endif

" Define highlighting group for extra whitespace
highlight ExtraWhitespace ctermbg=darkgreen guibg=lightgreen
autocmd ColorScheme * highlight ExtraWhitespace ctermbg=darkgreen guibg=lightgreen

" Some general settings
filetype on						" Use filetype detection
filetype plugin indent on
syntax on						" Use syntax highlighting
set ignorecase					" Ignore case in searches
set nocompatible				" Disable vi compatible mode
set backspace=indent,eol,start  " Make backspace work as in other programs
set history=1000				" Use 1000 lines of history
set clipboard+=unnamed			" Add unnamed clipboard for yanking (see :help clipboard)
set grepprg=grep\ -nHi\ $*		" Grep program
set lsp=0						" Line spacing
set autochdir					" Change the cwd to the current file's directory
set wildmenu					" Enhanced tab completition
set ruler						" Show position	
set cmdheight=1					" Command line height
set number						" Line numbers
set lz							" Lazy redraw
set hid							" Change buffer without saving
set noerrorbells				" No noise
set t_vb=                       " Enable visual bell, but disable output. Only way to really disable bells.
set vb
set hlsearch					" Do highlight searches
set noerrorbells				" no blink
set laststatus=2				" Show status line
set fo=tcrqn					" See Help (complex)
set ai							" Auto indent
set si							" Smart indent
set tabstop=4					" I use tabs with a width of 4
set softtabstop=0
set shiftwidth=4
set noexpandtab
set nosmarttab
set wrap						" Enable wrapping
set lbr							" Wrap on whole words
set foldenable					" Enable folding using markers
set fdm=marker
set foldlevel=100
set iskeyword=@,-,\:,48-57,_,128-167,224-235 " Allow more for completion
"set guifont=DejaVu\ Sans\ Mono\ 9 " A nicer GUI font
set guifont=Inconsolata\ 11 " A nicer GUI font
set ffs=unix,dos,mac
set cm=blowfish2                " Use non-crap encryption

" Highlight extra whitespace
autocmd Syntax * syn match ExtraWhitespace /\s\+\%#\@<!$\| \+\ze\t/ containedin=ALL

" Encodings
set fileencodings=ucs-bom,utf-8,iso-8859-1,iso-8859-15
set termencoding=utf-8

" Some vim stuff
set helplang=en
set updatetime=2000
set viminfo='20,\"500

" Key mappings
map! <xHome> <Home>
map! <xEnd> <End>
map! <S-xF4> <S-F4>
map! <S-xF3> <S-F3>
map! <S-xF2> <S-F2>
map! <S-xF1> <S-F1>
map! <xF4> <F4>
map! <xF3> <F3>
map! <xF2> <F2>
map! <xF1> <F1>
map Q gq
map <xHome> <Home>
map <xEnd> <End>
map <S-xF4> <S-F4>
map <S-xF3> <S-F3>
map <S-xF2> <S-F2>
map <S-xF1> <S-F1>
map <xF4> <F4>
map <xF3> <F3>
map <xF2> <F2>
map <xF1> <F1>
nmap gr :exec ":!".getline(".")<CR>
vmap <tab> =
" Switch between tabs using ALT+[1-7]
map <M-1> 1gt
map <M-2> 2gt
map <M-3> 3gt
map <M-4> 4gt
map <M-5> 5gt
map <M-6> 6gt
map <M-7> 7gt
map <M-8> 8gt
map Y "+y
map P "+p
vnoremap < <gv
vnoremap > >gv

map <C-e> :NERDTreeToggle<CR>
map <C-b> ,be

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
let g:mapleader = ","

" Fast saving
nmap <leader>w :w!<cr>

" Save localvimrc decisions and use neater filename
let g:localvimrc_persistent=2
let g:localvimrc_name = ["lvimrc"]

" List mode: Highlight whitespace
set listchars=tab:>-,eol:¶
nmap <leader>l	:set list!<CR>

" Ctags: Use F7 to create a tag list, bind F8 to the tag window
" More important is :tag <tag> and g + left mouse in visual mode to jump to
" tags
nnoremap <silent> <F7> :!/usr/bin/ctags -R --c++-kinds=+p --fields=+iaS --extra=+q --PHP-kinds=cf --langmap=php:+.inc.module.install .<CR> :TlistUpdate<CR>
nnoremap <silent> <F9> :TlistSync<CR>
nnoremap <silent> <F8> :Tlist<CR>
let Tlist_Use_Right_Window = 1
set tags=./tags;,tags; " Search for tags file in every dir up towards root

" Spell features
set spelllang=de

" Ultisnips configuration
let g:UltiSnipsSnippetsDir="~/.vim/bundle/A-my-own-stuff/UltiSnips/"
map <C-s><C-e> :UltiSnipsEdit<CR>
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"

" Supertab
let g:SuperTabDefaultCompletionType = "context"

" Jedi (python completion)
let g:jedi#popup_on_dot = 0
autocmd FileType python setlocal completeopt-=preview

if has('python')
	let g:ctrlp_match_func = { 'match': 'pymatcher#PyMatch' }
endif
nnoremap <leader>. :CtrlPTag<cr>

" clang completion
let g:clang_complete_auto = 0
let g:clang_hl_errors = 1
let g:clang_snippets = 1
let g:clang_snippets_engine = "ultisnips"
let g:clang_library_path = "/usr/local/lib"
let g:clang_close_preview = 1

" Jump Back to last known cursor position
autocmd BufReadPost *
\ if ! exists("g:leave_my_cursor_position_alone") |
\     if line("'\"") > 0 && line ("'\"") <= line("$") |
\         exe "normal g'\"" |
\     endif |
\ endif

augroup filetype
autocmd BufNewFile,BufRead *.wiki	setf Wikipedia
autocmd BufNewFile,BufRead *itsalltext/*wiki*	setf Wikipedia
autocmd BufNewFile,BufRead *.module set filetype=php.drupal
autocmd BufNewFile,BufRead *.install set filetype=php.drupal
autocmd BufNewFile,BufRead *.tex set filetype=tex
autocmd BufNewFile,BufRead SConstruct set filetype=python
autocmd BufNewFile,BufRead SConscript set filetype=python
augroup END
