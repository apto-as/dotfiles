call plug#begin()

" tree icon
Plug 'ryanoasis/vim-devicons'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'

" bracket auto close
Plug 'cohama/lexima.vim'
Plug 'tpope/vim-surround'

" editorconfig
Plug 'editorconfig/editorconfig-vim'

" git
Plug 'tpope/vim-rhubarb'
Plug 'airblade/vim-gitgutter'

" emmet
Plug 'mattn/emmet-vim'

" js
Plug 'pangloss/vim-javascript'

" markdown
Plug 'tpope/vim-markdown'

call plug#end()

"" NERDTree
let g:NERDTreeChDirMode=1
let g:NERDTreeShowBookmarks=1
let g:nerdtree_tabs_focus_on_files=1
let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
let g:NERDTreeWinSize = 40
let NERDTreeShowHidden=1
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

"" GitGutter
let g:gitgutter_enabled = 1
set updatetime=100
let g:gitgutter_override_sign_column_highlight = 0
highlight clear SignColumn
highlight GitGutterAdd ctermfg=2
highlight GitGutterChange ctermfg=3
highlight GitGutterDelete ctermfg=1
highlight GitGutterChangeDelete ctermfg=4

"" vim-markdown
let g:vim_markdown_folding_disabled=1

"" line
set number

"" multibyte
set ambiwidth=double

"" clipboard
set clipboard+=unnamed

"" background
highlight! Normal ctermbg=NONE guibg=NONE
highlight! NonText ctermbg=NONE guibg=NONE
highlight! LineNr ctermbg=NONE guibg=NONE

