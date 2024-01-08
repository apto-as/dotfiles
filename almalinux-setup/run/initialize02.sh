# install miniforge(conda)
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh
bash Miniforge3-$(uname)-$(uname -m).sh

# init miniconda to fish shell
 miniforge3/bin/conda init fish

# install fisher and plugins
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish

# install nvm latest (require finsh-nvm)
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

cd ~/dotfiles/almalinux-setup/
sudo cp sshd/sshd_config /etc/ssh/
cd ~/