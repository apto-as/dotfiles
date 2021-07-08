#!/bin/bash

cd ~/dotfiles

cp .gitconfig ~/
cp .gitignore ~/
cp .tmux.conf ~/
cp .tmux.conf.osx ~/
cp .tmux.conf.powerline ~/
cp -R .config/ ~/
cp ethminer/bin/* ~/ethminer/bin/ 
sudo cp sshd/sshd_config /etc/ssh/

cd ~

