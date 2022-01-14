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

alias sbg0  "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.0_default01.png"
alias sbg01 "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.0_default01-1.png"
alias sbg1  "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.0_default16.png"
alias sbg11 "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.0_default16-1.png"
alias sbg2  "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.1_awesame01.png"
alias sbg21 "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.1_awesame01-1.png"
alias sbg3  "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.1_awesame02.png"
alias sbg31 "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.1_awesame02-1.png"
alias sbg4  "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.1_awesame03.png"
alias sbg41 "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.1_awesame03-1.png"
alias sbg5  "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.1_awesame04.png"
alias sbg6  "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.0_awesame01.png"
alias sbg61 "set_bg_image ~/Pictures/terminal/9dw_wallpaper_v2.0_awesame01-1.png"

set -gx HOMEBREW_PREFIX "/opt/homebrew";
set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
set -q PATH; or set PATH ''; set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH;
set -q MANPATH; or set MANPATH ''; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
set -q INFOPATH; or set INFOPATH ''; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;
