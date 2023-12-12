#!/bin/bash

set -u

# setup anydesk repo
sudo tee /etc/yum.repos.d/anydesk.repo<<EOF
[anydesk]
name=AnyDesk CentOS - stable
baseurl=http://rpm.anydesk.com/centos/x86_64/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF

# install epel repo
sudo dnf config-manager --set-enabled powertools
sudo dnf install epel-release epel-next-release
sudo dnf install util-linux-user

# last update
sudo dnf update -y

# install base commands
sudo dnf group install -y "Development Tools"
sudo dnf install -y bind-utils net-tools rsync wget openssh-server curl ufw mosh nodejs tmux ripgrep ncdu

# install ffmpe almalinux9の場合
#sudo dnf config-manager --set-enabled crb
#sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y
#sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y
#sudo dnf install ffmpeg -y

# install ffmpeg almalinux8の場合
sudo dnf install -y https://download.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
sudo dnf install ffmpeg -y

# install peco
wget https://github.com/peco/peco/releases/download/v0.5.11/peco_linux_amd64.tar.gz
tar xvzf `basename $_`
rm $_
sudo mv peco_linux_amd64 /usr/local/bin
sudo ln -s /usr/local/bin/peco_linux_amd64/peco /usr/local/bin/peco

# install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# install develop base commands
sudo dnf install -y ninja-build gettext cmake unzip doxygen

# install nvim 
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim

# install fish
sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_8/shells:fish:release:3.repo
sudo dnf install -y fish

# install go
VERSION=1.21.5
wget https://storage.googleapis.com/golang/go${VERSION}.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go${VERSION}.linux-amd64.tar.gz
source ${HOME}/go

# install AstroNvim
git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim

# install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# install ghq
/usr/local/go/bin/go install github.com/x-motemen/ghq@latest

# install lazygit
/usr/local/go/bin/go install github.com/jesseduffield/lazygit@latest

# install tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# install kitty exa
cargo install exa

# install ranger
pip install ranger-fm

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

cd ~

# system reboot
sudo reboot
