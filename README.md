# How to...
1. dotfiles install
```bash
git clone https://github.com/apto-as/dotfiles.git
sh dotfiles/run/initialize01_macos.sh

# after reboot
sh dotfiles/run/initialize02_macos.sh
fish dotfiles/run/initialize03.fish_
```

2. start nvim
```
:PlugInstall
:UpdateRemotePlugins
```

3. start tmux
```
C-b C-i
```

4. fastai install
```bash
conda create -n fastai python=3.xx # xx is any number
conda install pytorch torchvision torchaudio -c pytorch
conda install -c pytorch -c fastai fastai jupyter
pip intall mmdnn
```
