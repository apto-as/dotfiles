function fish_user_key_bindings
  # peco
  bind \cr peco_select_history # Bind for peco select history to Ctrl+R
  bind \cf peco_change_directory # Bind for peco change directory to Ctrl+F
  
  # fzf
  bind \co __fzf_open --editor
  #bind \cr __fzf_reverse_isearch
  bind \c] __ghq_repository_search
  bind \cb __fzf_select_branch

end
