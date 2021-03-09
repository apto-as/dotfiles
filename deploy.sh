#!/bin/bash

cd ~/dotfiles

cp .gitconfig ~/
cp .gitignore ~/
cp .tmux.conf ~/
cp .tmux.conf.osx ~/
cp .tmux.conf.powerline ~/
cp .vimrc ~/
cp .vimrc.osx ~/
cp -R .config/ ~/
cp -R .vim/ ~/
cp sshd/config ~/.ssh/
sudo cp sshd/sshd_config /etc/ssh/

cd ~

