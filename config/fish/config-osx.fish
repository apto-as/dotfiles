set -gx LDFLAGS "-L/opt/homebrew/opt/libxml2/lib"
set -gx CPPFLAGS "-I/opt/homebrew/opt/libxml2/include"
set -gx TESSDATA_PREFIX "/opt/homebrew/share/tessdata/"

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"


if type -q eza
  alias ll "eza -l -g --icons"
  alias lla "ll -a"
end

set -gx HOMEBREW_PREFIX "/opt/homebrew";
set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
set -q PATH; or set PATH ''; set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH;
set -q MANPATH; or set MANPATH ''; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
set -q INFOPATH; or set INFOPATH ''; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;
