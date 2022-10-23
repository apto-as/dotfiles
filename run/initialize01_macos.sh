#!/bin/bash
set -u

# install base commands
/bin/bash -c “$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)”
eval “$(/opt/homebrew/bin/brew shellenv)”

xcode-select --install
arch -arm64 brew install wget peco mosh golang rust tree-sitter luajit fish neovim nodejs tmux lf ffmpeg bat ripgrep fzf exa gcc ranger ncdu
brew install jesseduffield/lazygit/lazygit

# install AstroNvim
git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
git clone https://github.com/apto-as/astro-nvim-config.git ~/.config/nvim/lua/user

# install ghq
go get github.com/x-motemen/ghq

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# change shell to fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

#dotfiles install
cd ~/dotfiles

cp .gitconfig ~/
cp .gitignore ~/
cp .tmux.conf ~/
cp .tmux.conf.osx ~/
cp .tmux.conf.powerline ~/
cp -RT .config/ ~/.config/
sudo cp sshd/sshd_config /etc/ssh/

cd ~
echo ‘eval “$(/opt/homebrew/bin/brew shellenv)”’ >> ~/.config/fish/config.fish 

# system reboot
sudo reboot
