if has("nvim")
  let g:plug_home = stdpath('data') . '/plugged'
endif

call plug#begin()

" github control
Plug 'lambdalisue/gina.vim'

" auto close parentheses and repea
Plug 'cohama/lexima.vim'

" powerful sintax color
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }

" searching
Plug 'junegunn/fzf', {'dir': '~/.fzf_bin', 'do': './install --all'}

" LSP and vscode like extentions
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" directory ui
Plug 'lambdalisue/fern.vim'
Plug 'yuki-yano/fern-preview.vim'
Plug 'lambdalisue/fern-git-status.vim'

" add vim develop font icons
Plug 'kyazdani42/nvim-web-devicons'

" theme and window control and powerline
Plug 'hoob3rt/lualine.nvim'
Plug 'dracula/vim', { 'as': 'dracula' } 
Plug 'simeji/winresizer'
Plug 'vim-jp/vimdoc-ja'

call plug#end()