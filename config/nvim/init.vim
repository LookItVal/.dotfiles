"Vim-Plugs required for the rest of the configuration
" Should be installed already by init script
"     This will prep the scripts in vim, to install:
"     Open vim, enter the command          :PlugInstall
"     To update plugins,                   :PlugUpdate
"     To clear out unused plugins          :PlugClean
"     To see a list of plugins             :PlugList
"
" GitHub Copilot
"    To activate, enter the command        :Copilot setup
"    To deactivate, enter the command      :Copilot off
"    To see the status, enter the command  :Copilot status

call plug#begin(has('nvim') ? stdpath('data') . '/plugged' : '~/.vim/plugged')
Plug 'easymotion/vim-easymotion'
Plug 'projekt0n/github-nvim-theme' 
Plug 'github/copilot.vim'
Plug 'wojciechkepka/vim-github-dark' 
Plug 'ap/vim-css-color'
Plug 'vim-scripts/guicolorscheme.vim'
call plug#end()

colorscheme ghdark

" Quick Escape
imap kj <Esc>
imap jk <Esc>

" Easymotion
let mapleader=" "
let g:EasyMotion_do_mapping=" "
nmap <Leader><Leader> <Plug>(easymotion-overwin-f)
nmap <Leader>j <Plug>(easymotion-j)
nmap <Leader>k <Plug>(easymotion-k)
vmap <Leader><Leader> <Plug>(easymotion-overwin-f)
vmap <Leader>j <Plug>(easymotion-j)
vmap <Leader>k <Plug>(easymotion-k)

" Spell Check
" :set spelllang=en
" set spell
