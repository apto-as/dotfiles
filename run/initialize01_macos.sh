#!/bin/bash
set -u

# install base commands
/bin/bash -c “$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)”
eval “$(/opt/homebrew/bin/brew shellenv)”

xcode-select --install
arch -arm64 brew install wget peco mosh golang rust tree-sitter luajit fish neovim nodejs tmux lf ffmpeg bat ripgrep fzf exa gcc
arch -arm64 brew install --cask kitty hammerspoon

# install vim-plugin
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# install ghq
go get github.com/x-motemen/ghq

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# change shell to fish
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

#dotfiles install
sh ~/dotfiles/run/deploy.sh
echo ‘eval “$(/opt/homebrew/bin/brew shellenv)”’ >> ~/.config/fish/config.fish 

# system reboot
sudo reboot
