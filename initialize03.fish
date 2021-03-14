#!/usr/bin/env fish

# fisher plugins install
fisher install oh-my-fish/theme-bobthefish
fisher install oh-my-fish/plugin-peco
fisher install jethrokuan/z
fisher install decors/fish-ghq
fisher install jorgebucaran/fish-nvm

# intall node latest
nvm install 'lts/*'
nvm use lts

# install neovim modules
pip install neovim
npm install -g neovim

# install nvim plugins
nvim

# install tmux plugins (Ctrl-T, Ctrl-I)
tmux
