#!/bin/bash

set -u

#apt-get install
sudo apt-get update \
  && sudo apt-get -y dist-upgrade \
  && sudo apt-get -y autoremove \
  && sudo apt-get autoclean

sudo apt-get install -y tree curl
sudo apt-get install -y ufw
sudo apt-get install -y vim
sudo apt-get install -y tmux
sudo apt-get install -y imagemagick pdftk
sudo apt-get install -y peco
sudo apt-get install -y docker-compose
sudo apt-get install -y mosh
sudo gpasswd -a $USER docker

#nvidia-docker install
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

