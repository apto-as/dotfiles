# install miniforge (conda)
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh
bash Miniforge3-MacOSX-arm64.sh

# init miniforge to fish shell
miniforge3/bin/conda init fish

# install fisher and plugins
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish

# install nvm latest (require finsh-nvm)
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
