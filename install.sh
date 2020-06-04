#!/bin/bash

set -u

echo ".....install start!"

sh ~/dotfiles/initialize.sh

chsh -s /bin/zsh

#Zprezto install
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

#vim-plug install
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#amix/vimrc install
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
ln -snfv ~/dotfiles/my_configs.vim ~/.vim_runtime/

#dotfiles install
sh ~/dotfiles/deploy.sh

#vim plug install
vim +PlugInstall

#tpm install
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo ".....install end!"
echo ".....next command"
echo "p10k configure"


