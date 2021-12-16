brew install --cask miniconda

# init miniconda to fish shell
conda init fish

# install fisher and plugins
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish

# install nvm latest (require finsh-nvm)
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
