#!/usr/bin/env fish

sudo ufw allow 49233
sudo ufw allow 49233/udp
sudo ufw allow 4444
sudo ufw allow 4444/udp
sudo ufw allow 60000:60001/udp

sudo ufw logging on
sudo ufw enable
sudo ufw status
