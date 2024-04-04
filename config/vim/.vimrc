call plug#begin()
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'preservim/nerdtree'
    Plug 'airblade/vim-gitgutter'
call plug#end()

highlight SignColumn ctermbg=black


"NERDTree config
nnoremap <C-n> :NERDTreeToggle<CR>
syntax on
filetype plugin indent on
set number
set relativenumber
set tabstop=4
set guifont=Monaco:h20
set visualbell
set laststatus=2

"for highlighting 120 column length
"set colorcolumn=80      

"Reformat lines which is more than 120 character long.
set tw=120
au BufRead,BufNewFile *.md setlocal textwidth=120
nnoremap gqa :g/./ normal gqq <Enter>

"don't pretend to be vi
set nocompatible

"custom status line
set statusline=%t\ \        "tail of the file name
set statusline+=%h\       "help file flag
set statusline+=%m\       "modified flag
set statusline+=%r\       "read only flag
set statusline+=type:%y\       "file type
"set statusline+=obsession:\ %{ObsessionStatus()}  Obsession status line
set statusline+=%=      "left/right separator
set statusline+=%c,     "cursor column
set statusline+=%l/%L   "cursor line/total lines
set statusline+=\ %P    "percent through file

"vim buffer line
set viminfo='100,<2000,s100,h 
set autoindent
set cindent
set shiftwidth=4
set softtabstop=4
set expandtab

"vim refresh time to 100ms
set updatetime=100

"no swp file
set noswapfile

"to run sheel command from vim
set shellcmdflag=-ic

"highlight the search result
set hlsearch

"spell checking
set spell spelllang=en_us

"make backspace key work
set backspace=indent,eol,start

"+++++++++++++++++++++++++++++++++
"key binding
"+++++++++++++++++++++++++++++++++
"tabe navigating 
inoremap <C-j>  <Esc>:tabprevious<CR>
inoremap <C-k>  <Esc>:tabnext<CR>
inoremap <C-h>  <Esc>:tabfirst<CR>
inoremap <C-l>  <Esc>:tablast<CR>
nnoremap <C-j>  gT
nnoremap <C-k>  gt
nnoremap <C-h>  :tabfirst<CR>
nnoremap <C-l>  :tablast<CR>
"set jj as <esc> key
inoremap jj <esc>
"write terminal command
nnoremap <C-t> :!
"replace the word under cursor with \s
:nnoremap <Leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>
"replace in visual block
:vnoremap <Leader>r :s/\%V//g 
"paste from clipboard
:inoremap <C-v> <Esc>"+p
"select "+" register to copy to clipboard
:nnoremap <C-c> "+
"copy the visually selected block to clipboard
:vnoremap <C-c> "+yy
"ctl+s to save in insert mode
:inoremap <C-a> <Esc>:w<Enter>a
"ctl+s to save in normal mode
:nnoremap <C-a> <Esc>:w<Enter>
"list function in normal mode

""indentation for html
autocmd Filetype html setlocal noexpandtab tabstop=2 sw=2 sts=2
autocmd Filetype xml setlocal noexpandtab tabstop=2 sw=2 sts=2
autocmd Filetype pug setlocal noexpandtab tabstop=2 sw=2 sts=2
autocmd Filetype handlebars setlocal noexpandtab tabstop=2 sw=2 sts=2
autocmd FileType markdown setlocal shiftwidth=2 softtabstop=2 expandtab



set foldmethod=manual
set foldcolumn=1
au BufWinLeave * mkview
au BufWinEnter * silent loadview

"spelling error highlight
hi clear SpellBad
hi SpellBad cterm=underline
hi SpellBad ctermfg=red

