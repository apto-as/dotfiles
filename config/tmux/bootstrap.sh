#!/usr/bin/env bash
# ============================================================================
# tmux Bootstrap - One-liner Setup (with Zellij migration)
# Usage: curl -fsSL https://raw.githubusercontent.com/apto-as/dotfiles/main/config/tmux/bootstrap.sh | bash
# ============================================================================
set -euo pipefail

DOTFILES_REPO="https://github.com/apto-as/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
TMUX_CONF_DIR="$HOME/.config/tmux"
WEZTERM_CONF_DIR="$HOME/.config/wezterm"
TPM_DIR="$HOME/.tmux/plugins/tpm"

info()  { printf "\033[34m[INFO]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[32m[OK]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[33m[WARN]\033[0m  %s\n" "$1"; }
err()   { printf "\033[31m[ERR]\033[0m   %s\n" "$1"; }

# --- Step 0: Disable Zellij auto-start (migration) ---
if [ -n "${ZELLIJ:-}" ]; then
    warn "Running inside Zellij. Migrating to tmux..."
fi

ZELLIJ_CONF_DIR="$HOME/.config/zellij"
if [ -d "$ZELLIJ_CONF_DIR" ] || [ -L "$ZELLIJ_CONF_DIR" ]; then
    info "Zellij config found. Backing up and removing..."
    mv "$ZELLIJ_CONF_DIR" "${ZELLIJ_CONF_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    ok "Zellij config backed up (auto-start disabled)"
fi

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
    # Drop any local changes and sync to remote (bootstrap should be idempotent)
    git -C "$DOTFILES_DIR" fetch origin 2>/dev/null
    git -C "$DOTFILES_DIR" reset --hard origin/main 2>/dev/null && ok "Dotfiles updated" || {
        warn "Hard reset failed, trying pull..."
        git -C "$DOTFILES_DIR" checkout -- . 2>/dev/null || true
        git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null && ok "Dotfiles updated" || err "Failed to update dotfiles. Run 'cd ~/dotfiles && git pull' manually."
    }
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

# --- Step 3.5: Ensure WezTerm config is symlinked ---
if [ -d "$DOTFILES_DIR/config/wezterm" ]; then
    mkdir -p "$(dirname "$WEZTERM_CONF_DIR")"
    if [ -L "$WEZTERM_CONF_DIR" ]; then
        ok "WezTerm config symlink already exists"
    elif [ -d "$WEZTERM_CONF_DIR" ]; then
        warn "Backing up existing WezTerm config"
        mv "$WEZTERM_CONF_DIR" "${WEZTERM_CONF_DIR}.bak.$(date +%Y%m%d%H%M%S)"
        ln -sf "$DOTFILES_DIR/config/wezterm" "$WEZTERM_CONF_DIR"
        ok "WezTerm config symlinked (old config backed up)"
    else
        ln -sf "$DOTFILES_DIR/config/wezterm" "$WEZTERM_CONF_DIR"
        ok "WezTerm config symlinked"
    fi
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
"$TPM_DIR/bin/install_plugins" 2>/dev/null || warn "Plugin install requires tmux server (run 'Ctrl+q → I' inside tmux)"

# --- Done ---
echo ""
printf "\033[32m✓ tmux setup complete!\033[0m\n"
echo ""
echo "  Start tmux:  tmux"
echo "  Prefix key:  Ctrl+q"
echo "  Layouts:     tcc (Claude Code) | tdev (dev) | tmon (monitor)"
echo ""
if [ -n "${ZELLIJ:-}" ]; then
    warn "Restart WezTerm to switch from Zellij to tmux."
    echo "       (Zellij config backed up, WezTerm now configured for tmux)"
fi
