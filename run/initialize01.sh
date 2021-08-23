#!/bin/bash

set -u

# install base commands
sudo apt install -y wget curl ufw peco mosh golang fish neovim nodejs tmux ffmpeg bat 

# install neovim develop version
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt install neovim/focal

# install vim-plugin
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

#nvidia-docker install
// install docker
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

# install ghq
go get github.com/x-motemen/ghq

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# install exa
wget https://github.com/ogham/exa/releases/download/v0.10.0/exa-linux-x86_64-v0.10.0.zip
unzip -d temp/ exa-linux-x86_64-v0.10.0.zip
sudo mv temp/bin/exa /usr/local/bin/
sudo mv temp/man/exa.1 /usr/share/man/man1/
sudo mv temp/man/exa_colors.5 /usr/share/man/man5/
sudo mv temp/completions/exa.fish /usr/share/fish/vendor_completions.d/
rm -rf temp/

# change shell to fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

#dotfiles install
sh ~/dotfiles/run/deploy.sh

# system reboot
sudo reboot
