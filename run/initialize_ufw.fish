#!/usr/bin/env fish

sudo ufw allow 49232
sudo ufw allow 49232/udp
sudo ufw allow 49233
sudo ufw allow 49233/udp
sudo ufw allow 49234
sudo ufw allow 49234/udp
sudo ufw allow 49235
sudo ufw allow 49235/udp
sudo ufw allow 5900
sudo ufw allow 5900/udp
sudo ufw allow 9999
sudo ufw allow 9999/udp
sudo ufw allow 60000:60001/udp

sudo ufw logging on
sudo ufw enable
sudo ufw status
