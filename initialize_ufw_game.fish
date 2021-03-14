#!/usr/bin/env fish

sudo ufw allow 49233
sudo ufw allow 49233/udp
sudo ufw allow 4444
sudo ufw allow 4444/udp
sudo ufw allow 60000:60001/udp
sudo ufw allow 27000:27100/udp
sudo ufw allow 27036
sudo ufw allow 27037
sudo ufw allow 3478/udp
sudo ufw allow 4379/udp
sudo ufw allow 4380/udp

sudo ufw logging on
sudo ufw enable
sudo ufw status
