set -gx LDFLAGS "-L/opt/homebrew/opt/libxml2/lib"
set -gx CPPFLAGS "-I/opt/homebrew/opt/libxml2/include"

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"


if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end

function set_bg_image
  echo "\
    tell application \"iTerm2\"
      tell current session of current window
        set background image to \"$argv[1]\"
      end tell
    end tell
  " | /usr/bin/osascript
end

function set_bg_image_path
  if test -d ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/$argv[1]/
    if test -f ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/$argv[1]/9dw_wallpaper_v6_$argv[2].png
      set_bg_image ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/$argv[1]/9dw_wallpaper_v6_$argv[2].png
    else
      set_bg_image (random choice ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/$argv[1]/*.png)
    end
  end
end

function sbx
  set len (count $argv)
  if test $len -eq 2
    set_bg_image_path "xxx$argv[1]" $argv[2]
  else if test $len -eq 1
    set_bg_image_path "xxx$argv[1]" '*'
  else 
    set_bg_image (random choice ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/xxx*/*.png)
  end
end

function sbxs
  set len (count $argv)
  if test $len -eq 2
    set_bg_image_path "xxx$argv[1]" "$argv[2]_S"
  else if test $len -eq 1
    set_bg_image_path "xxx$argv[1]" '*_S'
  else 
    set_bg_image (random choice ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/xxx*/*_S.png)
  end
end

function sba
  set len (count $argv)
  if test $len -eq 2
    set_bg_image_path "awesame$argv[1]" $argv[2]
  else if test $len -eq 1
    set_bg_image_path "awesame$argv[1]" '*'
  else 
    set_bg_image (random choice ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/awesame*/*.png)
  end
end

function sbas
  set len (count $argv)
  if test $len -eq 2
    set_bg_image_path "awesame$argv[1]" "$argv[2]_S"
  else if test $len -eq 1
    set_bg_image_path "awesame$argv[1]" '*_S'
  else 
    set_bg_image (random choice ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/awesame*/*_S.png)
  end
end

function sbd
  set len (count $argv)
  if test $len -eq 1
    set_bg_image_path "default" $argv[1]
  else 
    set_bg_image (random choice ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/default/*.png)
  end
end

function sbds
  set len (count $argv)
  if test $len -eq 1
    set_bg_image_path "default" "$argv[1]_S"
  else
    set_bg_image (random choice ~/Pictures/wallpaper/terminal_back_image/9dw_wallpaper_v6/default/*_S.png)
  end
end

set -gx HOMEBREW_PREFIX "/opt/homebrew";
set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
set -q PATH; or set PATH ''; set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH;
set -q MANPATH; or set MANPATH ''; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
set -q INFOPATH; or set INFOPATH ''; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;
