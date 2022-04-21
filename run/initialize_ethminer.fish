#!/usr/bin/env fish

sudo ufw allow 4444
sudo ufw allow 4444/udp

sudo add-apt-repository ppa:ethereum/ethereum
sudo apt update
sudo apt install -y ethereum

cd ~/dotfiles
cp ethminer/bin/* ~/ethminer/bin/ 
cd ~/

docker pull yuriba/eth-proxy


