
filetype on
filetype plugin indent on
filetype plugin on
syntax on

let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'
" let g:airline_theme = 'catppuccin_mocha'
let g:airline_theme = 'powerlineish'

" set termguicolors

" LEADER remap
"
"
let mapleader = ','
"
"
" more remaps
"
"
nnoremap / /\v
vnoremap / /\v
nnoremap <leader><space> :noh<cr>
nnoremap <tab> %
vnoremap <tab> %


set completeopt-=preview

set laststatus=2
set noshowmode

set showcmd
set ignorecase
set smartcase
set expandtab
set smarttab
set number
set noswapfile

syntax on 			     " enable color syntax
" syntax enable                        " Enable syntax highlights
set ttyfast                          " Faster refraw
" set mouse=nv                         " Mouse activated in Normal and Visual Mode
set shortmess+=I                     " No intro when starting Vim
set autoindent                       " Copy the indent of the current line into a new line
set smartindent                      " Smart... indent
set expandtab                        " Insert spaces instead of tabs
set softtabstop=2                    " ... and insert two spaces
set shiftwidth=2                     " Indent with two spaces
set incsearch			     " Increamental search, find as you type word
set hlsearch                         " Highlight search results
set cursorline                       " Highligt the cursor line
" set cursorcolumn                     " Highlight the column line
set showmatch                        " When a bracket is inserted, briefly jump to the matching one
set matchtime=3                      " ... during this time
set virtualedit=onemore              " Allow the cursor to move just past the end of the line
set history=100                      " Keep 100 undo
set wildmenu                         " Better command-line completion
set scrolloff=10                     " Always keep 10 lines after or before when scrolling
set sidescrolloff=5                  " Always keep 5 lines after or before when side scrolling

" testing more options == ================================================================
"
set gdefault                         " The substitute flag g is on
set hidden                           " Hide the buffer instead of closing when switching
set backspace=indent,eol,start       " The normal behaviour of backspace
" set showtabline=2                    " Always show tabs
set laststatus=2                     " Always show status bar
set number                           " Show the line number
" set relativenumber                 " sets line numbers before and after relative to cursor position
set updatetime=1000
set ignorecase                       " Search insensitive
set smartcase                        " ... but smart
set showbreak=↪
set encoding=utf-8                   " The encoding displayed.
set fileencoding=utf-8               " The encoding written to file.
set synmaxcol=300                    " Don't try to highlight long lines
"
" end testing more options  ===============================================================


set shiftwidth=4
set softtabstop=4
set scrolloff=8
set sidescrolloff=10

set timeoutlen=1000
set ttimeoutlen=0

set clipboard=unnamed
set clipboard^=unnamedplus

:noremap / :set hlsearch<CR>/

:noremap <F2> :set paste! nopaste?<CR>

:noremap <F3> :set nonumber! nonumber?<CR>

:noremap <F4> :set hlsearch! hlsearch?<CR>

set background=dark

function TrimWhitespace()
  %s/\s*$//
  ''
:endfunction
command! Trim call TrimWhitespace()


 map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
 \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
 \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

 map <C-n> :NERDTreeToggle<CR>


set hidden
let mapleader=","
nmap <leader>n :enew<cr>
nmap <leader><leader> :bnext<CR>
nmap <leader>. :bprevious<CR>
nmap <leader>l :ls<CR>


"-------- vim-plug - Minimalist Vim Plugin Manager {{{
"------------------------------------------------------
" https://github.com/junegunn/vim-plug
" Usage: add in new Plug <url> then save vimrc then do :PlugInstall
" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

Plug 'https://github.com/vimwiki/vimwiki.git'
Plug 'https://github.com/tomtom/tcomment_vim.git'
Plug 'https://github.com/suan/vim-instant-markdown.git'
" Plug 'suan/vim-instant-markdown', {'for': 'markdown'}
Plug 'https://github.com/altercation/vim-colors-solarized.git'
" Plug 'https://github.com/sirver/UltiSnips'    " snippet program only, no code snippet provided
Plug 'https://github.com/honza/vim-snippets'  " code snippet of many programming language
Plug 'https://github.com/tpope/vim-surround'  " :help surround
" Plug 'https://github.com/ctrlpvim/ctrlp.vim'

" - plugins added by me
" ---- NERDTree plugins
Plug 'preservim/nerdtree'
Plug 'PhilRunninger/nerdtree-visual-selection'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
" ---

Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'junegunn/vim-easy-align'
Plug 'https://github.com/ap/vim-css-color' " CSS Color Preview
Plug 'ycm-core/YouCompleteMe'

" color themes
Plug 'catppuccin/vim', { 'as': 'catppuccin' }
Plug 'ghifarit53/tokyonight-vim'
Plug 'casonadams/nord.vim'
Plug 'rafi/awesome-vim-colorschemes'
" Plug 'rainglow/vim'

call plug#end()

"}}}


" colorscheme config
" 

"" tokyonight specific
" let g:tokyonight_style = 'storm' " available: night, storm
" let g:tokyonight_enable_italic = 1

" colorscheme nord-light

colorscheme catppuccin_mocha



