#!/bin/bash

set -u

# install base commands
sudo apt install -y wget curl ufw peco mosh nodejs tmux ffmpeg fzf ripgrep gcc ncdu

# install develop base commands
sudo apt install -y libopenblas-base libopenmpi-dev libomp-dev build-essential software-properties-common libopenblas-dev libssl-dev libpython3-dev python3-pip python3-dev python3-setuptools python3-wheel libjpeg-dev zlib1g-dev libavcodec-dev libavformat-dev libswscale-dev
sudo apt install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip doxygen
sudo apt install linux-tools-(uname -r)

# install nvim fish go
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo add-apt-repository ppa:fish-shell/release-3
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt update
sudo apt install -y fish neovim golang

# install packer nvim
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
 
# install AstroNvim
git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
git clone https://github.com/apto-as/astro-nvim-config.git ~/.config/nvim/lua/user

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# install ghq
go install github.com/x-motemen/ghq@latest

# install lazygit
go install github.com/jesseduffield/lazygit@latest

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# install kitty exa
cargo install exa
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# install ranger
pip install ranger-fm

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
