call plug#begin()
    Plug 'preservim/nerdtree'
    Plug 'junegunn/fzf', {'do': { -> fzf#install()}}
    Plug 'junegunn/fzf.vim'
    Plug 'junegunn/goyo.vim'
    Plug 'tpope/vim-fugitive'
    Plug 'airblade/vim-gitgutter'
call plug#end()

" NERDTree config
nnoremap <C-n> :NERDTreeToggle<CR>

set mouse=a
set number
set relativenumber
" Allows you to switch between buffers without saving changes. When you switch buffers, Neovim hides the current buffer instead of closing it.
set hidden
" Highlights the current line by displaying a horizontal line across the entire width of the window.
set cursorline
" Converts tab characters to spaces when you press the Tab key. It helps maintain consistent indentation across different systems.
set expandtab
set autoindent
set smartindent
set shiftwidth=4
set tabstop=4
set encoding=utf8
set history=5000
" Allows Neovim to use the system clipboard for copy-paste operations. With this setting, anything
" you yank or delete in Neovim is also available in the system clipboard, making it accessible to
" other applications.
set clipboard=unnamedplus

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

"set jj as <esc> key
inoremap jj <esc>

