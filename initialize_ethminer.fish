#!/usr/bin/env fish

sudo add-apt-repository ppa:ethereum/ethereum
sudo apt update
sudo apt install -y ethereum

docker pull yuriba/eth-proxy
