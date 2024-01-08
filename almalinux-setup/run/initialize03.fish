#!/usr/bin/env fish

sudo curl -s https://ohmyposh.dev/install.sh | sudo bash -s

mkdir ~/.posh/
cd ~/dotfiles/almalinux-setup/
cp -R .posh/ ~/.posh/
cd ~

oh-my-posh init fish --config ~/.posh/themes/tsuyoshi.omp.json | source

# fisher plugins install
fisher install oh-my-fish/plugin-peco
fisher install jethrokuan/z
fisher install decors/fish-ghq
fisher install jorgebucaran/fish-nvm
fisher install edc/bass
fisher install jethrokuan/fzf
fisher install dracula/fish
fisher install evanlucas/fish-kubectl-completions

# intall node latest
nvm install 'lts/*'
nvm use lts

# install neovim modules
pip install neovim
npm install -g neovim

npm install -g webtorrent-cli

# install aws ctl
#sudo apt install -y awscli
#npm install -g awsp
