set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'edkolev/tmuxline.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'vim-latex/vim-latex'
Plugin 'tpope/vim-sleuth'
Plugin 'tpope/vim-fugitive'
Plugin 'Valloric/MatchTagAlways'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'shime/vim-livedown' " markdown viewer
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'vimwiki/vimwiki'
Plugin 'airblade/vim-gitgutter'
Plugin 'mileszs/ack.vim'
Plugin 'AndrewRadev/linediff.vim'
Plugin 'chrisbra/csv.vim'
let hostname = substitute(system('hostname'), '\n', '', '')
if hostname == "boethiah"
  Plugin 'posva/vim-vue'
  Plugin 'udalov/kotlin-vim'
  Plugin 'hashivim/vim-terraform'
  Plugin 'google/vim-searchindex'
  Plugin 'leafgarland/typescript-vim'
endif

call vundle#end()
filetype plugin indent on

let mapleader = ","


" ================ Shortcuts ====================
" edit this file
:nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" re-source this file
:nnoremap <leader>sv :source $MYVIMRC<cr>


" https://github.com/skwp/dotfiles/blob/master/vimrc
" ================ General Config ====================
set backspace=indent,eol,start "Allow backspace in insert mode
set history=1000 "Store lots of :cmdline history
set showcmd "Show incomplete cmds down the bottom
set showmode "Show current mode down the bottom
set visualbell "No sounds
set autoread "Reload files changed outside vim

" ================ Persistent Undo ==================
" Keep undo history across sessions, by storing in file.
" Only works all the time.
if has('persistent_undo')
  silent !mkdir ~/.vim/undodir > /dev/null 2>&1
  set undodir=~/.vim/undodir
  set undofile
endif

" ===Remvoe silly temp files ===
set backupdir=~/.vim/tmp,.
set directory=~/.vim/tmp,.

" ============== Plugin Configs ===============
" ===The vimairline plugin stuff===
set laststatus=2
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_theme='wombat'

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
set hidden

" ===vim markdown preview settings===
let g:livedown_browser = "google-chrome"
map <C-P> :LivedownToggle<CR>

" === Tmuxline ===
"	\'c'    : '#H',
let g:tmuxline_preset = {
    \'a'    : '#S',
    \'b'    : '#W',
    \'win'  : '#I #W',
    \'cwin' : '#I #W',
    \'x'    : '#(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "time to empty|percentage" |xargs echo)',
    \'y'    : ['%Y-%m-%d', '%H:%M'],
    \'z'    : '#h',
    \'options': {
        \'status-justify': 'left'
    \}
\}

" === Syntastic ===
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_javascript_checkers=['eslint']
if executable('node_modules/.bin/eslint')
  let b:syntastic_javascript_eslint_exec = 'node_modules/.bin/eslint'
endif
let g:syntastic_mode_map = { 'mode': 'passive' }

let g:linuxsty_patterns = [ ]

" ===Nerdtree binding===
map <C-n> :NERDTreeToggle<CR>
let NERDTreeQuitOnOpen=1


" ============== Display stuff ============
syntax on
set scrolloff=5
set background=dark
" not sure what this one is?
set t_Co=256

" Set search hilight and colour
set hlsearch
set incsearch
hi Search cterm=NONE ctermfg=grey ctermbg=blue

" show trailing whitespace
:highlight ExtraWhitespace ctermbg=red guibg=red
:match ExtraWhitespace /\s\+\%#\@<!$/

" === Column Limit ===
" https://stackoverflow.com/a/21406581
augroup collumnLimit
  autocmd!
  autocmd BufEnter,WinEnter,FileType *
        \ highlight CollumnLimitSoft ctermbg=DarkGrey guibg=DarkGrey
  let softLimit = 80
  let softPattern =
        \ '\%<' . (softLimit+2) . 'v.\%>' . (softLimit+1) . 'v'
  autocmd BufEnter,WinEnter,FileType *
        \ let w:m1=matchadd('CollumnLimitSoft', softPattern, -1)


  autocmd BufEnter,WinEnter,FileType *
        \ highlight CollumnLimitHard ctermbg=DarkRed guibg=DarkRed
  let hardLimit = 120
  let hardPattern =
        \ '\%<' . (hardLimit+2) . 'v.\%>' . (hardLimit+1) . 'v'
  autocmd BufEnter,WinEnter,FileType *
        \ let w:m1=matchadd('CollumnLimitHard', hardPattern, -1)
augroup END


" ================ Wiki ===============
let g:vimwiki_list = [{'path': '~/sync/general/notes/vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]
let g:vimwiki_folding='expr'
let g:vimwiki_url_maxsave = 0

" =============== Search ==============
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
cnoreabbrev Ack Ack!
noremap <Leader>a :Ack! <cword>
noremap <Leader>s :Ack!<Space>
cnoreabbrev ag Ack!
cnoreabbrev aG Ack!
cnoreabbrev Ag Ack!
cnoreabbrev AG Ack!

" ================ Misc ===============
" disable folding, was an issue in tex stuff
set nofoldenable
set pastetoggle=<F3>

" Thing from robin for clipboard stuff
" Don't think it works
set clipboard=unnamedplus

" auto-complete thing
set wildmenu

" default tab settings, should get overridden...
command Tab set tabstop=4 noexpandtab shiftwidth=4
command NoTab set tabstop=4 expandtab shiftwidth=4 softtabstop=4
if get(g:, '_has_set_default_indent_settings', 0) == 0
  set expandtab
  set tabstop=4
  set shiftwidth=4
  let g:_has_set_default_indent_settings = 1
endif

autocmd BufNewFile,BufRead *.mjs set filetype=javascript

" Don't hide characters in markdown
let g:markdown_syntax_conceal = 0
let g:vimwiki_conceallevel=0

" auto remove whitespace
" http://stackoverflow.com/a/1618401/2423187
fun! StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
command StripTrailing call StripTrailingWhitespaces()

autocmd FileType typescript,javascript,html,css,perl,c,cpp,java,php,ruby,python autocmd BufWritePre <buffer> :call StripTrailingWhitespaces()


let g:gitgutter_enabled = 0

nnoremap <leader>n :call ToggleGutter()<cr>

function! ToggleGutter()
  if &number
    GitGutterDisable
    set nonumber
    set norelativenumber
  else
    set number
    set relativenumber
    GitGutterEnable
  endif
endfunction

set fileformat=unix
set fileformats=unix,dos
"set nobinary
