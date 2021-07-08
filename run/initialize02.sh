# install miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod 755 Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh

# init miniconda to fish shell
 ./miniconda3/bin/conda init fish

# install fisher and plugins
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish

# install nvm latest (require finsh-nvm)
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
