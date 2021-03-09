#!/bin/bash

set -u

#apt-get install
sudo apt-get update \
  && sudo apt-get -y dist-upgrade \
  && sudo apt-get -y autoremove \
  && sudo apt-get autoclean

# install base commands
sudo apt install -y curl ufw peco mosh golang fish neovim tmux mosh

# install ghq
go get github.com/x-motemen/ghq

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

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

# change shell to fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

# system reboot
sudo reboot