# install miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod 755 Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh

# init miniconda to fish shell
 ./miniconda3/bin/conda init fish

# install dein.vim
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
sh ./installer.sh ~/.cache/dein

# install fisher and plugins
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
fisher install oh-my-fish/theme-bobthefish
fisher install oh-my-fish/plugin-peco
fisher install jethrokuan/z
fisher install decors/fish-ghq
fisher install jorgebucaran/fish-nvm

# install nvm latest (require finsh-nvm)
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

# intall node latest
nvm install 'lts/*'
nvm use lts

# install neovim modules
pip install neovim
npm install -g neovim

# install nvim plugins
nvim

# install tmux plugins (Ctrl-T, Ctrl-I)
tmux
