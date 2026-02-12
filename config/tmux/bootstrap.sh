#!/usr/bin/env bash
# ============================================================================
# tmux Bootstrap - One-liner Setup
# Usage: curl -fsSL https://raw.githubusercontent.com/apto-as/dotfiles/main/config/tmux/bootstrap.sh | bash
# ============================================================================
set -euo pipefail

DOTFILES_REPO="https://github.com/apto-as/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
TMUX_CONF_DIR="$HOME/.config/tmux"
TPM_DIR="$HOME/.tmux/plugins/tpm"

info()  { printf "\033[34m[INFO]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[32m[OK]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[33m[WARN]\033[0m  %s\n" "$1"; }
err()   { printf "\033[31m[ERR]\033[0m   %s\n" "$1"; }

# --- Step 1: Install tmux ---
if command -v tmux &>/dev/null; then
    ok "tmux already installed ($(tmux -V))"
else
    info "Installing tmux..."
    if command -v brew &>/dev/null; then
        brew install tmux
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y tmux
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y tmux
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm tmux
    else
        err "No supported package manager found. Install tmux manually."
        exit 1
    fi
    ok "tmux installed ($(tmux -V))"
fi

# --- Step 2: Clone/update dotfiles ---
if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Updating dotfiles..."
    git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null || warn "Could not update dotfiles (non-fast-forward)"
    ok "Dotfiles up to date"
else
    info "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    ok "Dotfiles cloned to $DOTFILES_DIR"
fi

# --- Step 3: Symlink tmux config ---
mkdir -p "$(dirname "$TMUX_CONF_DIR")"
if [ -L "$TMUX_CONF_DIR" ]; then
    ok "tmux config symlink already exists"
elif [ -d "$TMUX_CONF_DIR" ]; then
    warn "Backing up existing tmux config to ${TMUX_CONF_DIR}.bak"
    mv "$TMUX_CONF_DIR" "${TMUX_CONF_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    ln -sf "$DOTFILES_DIR/config/tmux" "$TMUX_CONF_DIR"
    ok "tmux config symlinked (old config backed up)"
else
    ln -sf "$DOTFILES_DIR/config/tmux" "$TMUX_CONF_DIR"
    ok "tmux config symlinked"
fi

# --- Step 4: Install TPM ---
if [ -d "$TPM_DIR" ]; then
    ok "TPM already installed"
else
    info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    ok "TPM installed"
fi

# --- Step 5: Create secure directories ---
for dir in "$HOME/.tmux/plugins" "$HOME/.tmux/resurrect"; do
    mkdir -p "$dir"
    chmod 700 "$dir"
done
ok "Directories created with secure permissions"

# --- Step 6: Install TPM plugins (headless) ---
info "Installing tmux plugins..."
"$TPM_DIR/bin/install_plugins" 2>/dev/null || warn "Plugin install requires tmux server (run 'Ctrl+g → I' inside tmux)"

# --- Done ---
echo ""
printf "\033[32m✓ tmux setup complete!\033[0m\n"
echo ""
echo "  Start tmux:  tmux"
echo "  Prefix key:  Ctrl+g"
echo "  Layouts:     tcc (Claude Code) | tdev (dev) | tmon (monitor)"
echo ""
