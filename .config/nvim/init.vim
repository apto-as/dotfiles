let g:python3_host_prog = '~/miniconda3/bin/python'

"-------------------------------------------------------------------------------
" Dein
"-------------------------------------------------------------------------------
if &compatible
  set nocompatible " Be iMproved
endif
let s:dein_dir = expand('~/.cache/dein')
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  let g:rc_dir = expand('~/.config/nvim')
  let s:toml = g:rc_dir . '/dein.toml'
  let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'
  
  call dein#load_toml(s:toml,      {'lazy': 0})
  call dein#load_toml(s:lazy_toml, {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif
if dein#check_install()
  call dein#install()
endif

filetype plugin indent on
syntax enable

source ~/.vimrc
