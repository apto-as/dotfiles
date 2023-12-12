set -gx EDITOR nvim
set -x LANG ja_JP.UTF-8

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# CUDA
set -gx PATH /usr/local/cuda/bin/ $PATH
set -gx LD_LIBRARY_PATH /usr/local/cuda/lib64 $LD_LIBRARY_PATH

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

# Rust
set -gx PATH $HOME/.cargo/bin $PATH

# NVM for MacOS
nvm use lts > /dev/null

# NVM for Linux
# set --universal nvm_default_version v16

# alias
alias vim nvim
alias g git
alias ls "exa -ahl"
alias la "exa -ahl --git --icons"
command -qv nvim && alias vim nvim

#-----------
# exa config and function
#-----------
function cd
  if test (count $argv) -eq 0
    cd $HOME
    return 0
  else if test (count $argv) -gt 1
    printf "%s\n" (_ "Too many args for cd command")
    return 1
  end
  # Avoid set completions.
  set -l previous $PWD

  if test "$argv" = "-"
    if test "$__fish_cd_direction" = "next"
      nextd
    else
      prevd
    end
    return $status
  end
  builtin cd $argv
  set -l cd_status $status
  # Log history
  if test $cd_status -eq 0 -a "$PWD" != "$previous"
    set -q dirprev[$MAX_DIR_HIST] and set -e dirprev[1]
    set -g dirprev $dirprev $previous
    set -e dirnext
    set -g __fish_cd_direction prev
  end

  if test $cd_status -ne 0
    return 1
  end
  pwd
  exa -ahl --git --icons
  return $status
end

# FZF OPTIONS
function fzf
    command fzf --height 30% --reverse --border $argv
end

switch (uname)
  case Darwin
    source (dirname (status --current-filename))/config-osx.fish
  case Linux
    # Do nothing
  case '*'
    source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
  source $LOCAL_CONFIG
end

