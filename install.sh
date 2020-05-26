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
for f in .??*; do
    [ "$f" = ".git" ] && continue
    [ "$f" = ".gitconfig.local.template" ] && continue
    [ "$f" = ".require_oh-my-zsh" ] && continue
    [ "$f" = ".gitmodules" ] && continue

    ln -snfv ~/dotfiles/"$f" ~/
done

#vim plug install
vim +PlugInstall

#tpm install
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo ".....install end!"
echo ".....next command"
echo "p10k configure"
echo "wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh"


