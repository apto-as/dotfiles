#!/usr/bin/env fish

# fisher plugins install
fisher install oh-my-fish/plugin-peco
fisher install jethrokuan/z
fisher install decors/fish-ghq
fisher install jorgebucaran/fish-nvm
fisher install edc/bass
fisher install jethrokuan/fzf
fisher install dracula/fish  
fisher install IlanCosman/tide@v5

# intall node latest
nvm install 'lts/*'
nvm use lts

# install neovim modules
pip install neovim
npm install -g neovim

# install lsp
npm install -g typescript typescript-language-server
npm install -g pyright
npm install -g diagnostic-languageserver

# install pysen
pip install pysen

# install aws ctl
sudo apt install -y awscli
npm install -g awsp

# install nvim plugins
nvim

# install tmux plugins (Ctrl-B, Ctrl-I)
tmux
