#!/bin/bash

set -u

# install base commands
sudo apt install -y wget curl ufw peco mosh golang nodejs tmux ffmpeg fzf ripgrep gcc

# install nvim fish
sudo add-apt-repository ppa:neovim-ppa/stable
sudo add-apt-repository ppa:fish-shell/release-3
sudo apt update
sudo apt install -y fish neovim

# install vim-plugin
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install ghq
go get github.com/x-motemen/ghq

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# install kitty exa
cargo install exa
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# change shell to fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

#dotfiles install
cd ~/dotfiles

cp .gitconfig ~/
cp .gitignore ~/
cp .tmux.conf ~/
cp .tmux.conf.osx ~/
cp .tmux.conf.powerline ~/
cp -RT .config/ ~/.config/

cd ~

# system reboot
sudo reboot
