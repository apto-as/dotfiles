#!/bin/bash

set -u

# install base commands
sudo apt install -y wget curl ufw peco mosh golang fish neovim nodejs tmux ffmpeg fzf ripgrep gcc

# install vim-plugin
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# nvidia-docker install
# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt install -y docker-compose

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt update
sudo apt install -y nvidia-docker2
sudo systemctl restart docker

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
sh ~/dotfiles/run/deploy.sh

# system reboot
sudo reboot
