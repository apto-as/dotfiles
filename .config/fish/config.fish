set -x EDITOR nvim

# alias
alias vim='nvim'
alias g='git'
 
 
 # ----------
 # bobthefish config
 # ----------
 set -g theme_display_git_default_branch yes
 set -g theme_git_worktree_support yes
 set -g theme_display_vagrant yes
 set -g theme_display_docker_machine yes
 set -g theme_display_k8s_context yes
 set -g theme_display_virtualenv yes
 set -g theme_display_vi yes
 set -g theme_powerline_fonts no
 set -g theme_nerd_fonts yes
 set -g theme_color_scheme dracula
 set -g theme_newline_cursor yes

 # ----------
 # peco config
 # ----------
 function peco_select_history_order
   if test (count $argv) = 0
     set peco_flags --layout=top-down
   else
     set peco_flags --layout=bottom-up --query "$argv"
   end

   history|peco $peco_flags|read foo

   if [ $foo ]
     commandline $foo
   else
     commandline ''
   end
 end

 function fish_user_key_bindings
   bind \cr 'peco_select_history_order' # control + R
   bind \cx\ck peco_kill # control + X ~ control + K
 end
