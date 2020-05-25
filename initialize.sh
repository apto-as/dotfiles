#!/bin/bash

set -u

#apt-get install
sudo apt-get update \
  && sudo apt-get -y dist-upgrade \
  && sudo apt-get -y autoremove \
  && sudo apt-get autoclean

sudo apt-get install -y git
sudo apt-get install -y tree curl
sudo apt-get install -y vim
suto apt-get install -y tmux
sudo apt-get install -y imagemagick pdftk
sudo apt-get install -y peco
sudo apt-get install -y ufw
sudo apt-get install -y docker-compose
sudo gpasswd -a $USER docker


