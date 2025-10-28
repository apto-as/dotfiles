#!/usr/bin/env bash
# ============================================================================
# installers/neovim.sh - Neovim + LazyVim Installation
# Purpose: Install Neovim and bootstrap LazyVim configuration
# ============================================================================

install_neovim() {
    log_info "Setting up Neovim..."

    # Install Neovim
    if ! command_exists nvim; then
        log_info "Installing Neovim..."
        case "${DETECTED_OS}" in
            macos)
                brew install neovim
                ;;
            linux)
                log_warn "Please install Neovim manually for Linux"
                return 1
                ;;
        esac
    else
        log_success "Neovim already installed"
    fi

    # Install LazyVim prerequisites
    install_lazyvim_prerequisites

    # Bootstrap LazyVim (will run on first nvim launch)
    log_info "LazyVim will bootstrap on first launch"
}

install_lazyvim_prerequisites() {
    log_info "Installing LazyVim prerequisites..."

    local -a prerequisites=(
        "ripgrep"    # Required by Telescope
        "fd"         # Fast file finder
        "node"       # LSP servers
    )

    for pkg in "${prerequisites[@]}"; do
        if ! is_installed "${pkg}"; then
            log_info "Installing ${pkg}..."
            brew install "${pkg}"
        else
            log_debug "${pkg} already installed"
        fi
    done

    log_success "LazyVim prerequisites installed"
}

# Bootstrap LazyVim plugins (headless)
bootstrap_lazyvim() {
    local nvim_config="${HOME}/.config/nvim"

    # Check if LazyVim is already initialized
    if [[ -f "${nvim_config}/lazy-lock.json" ]]; then
        log_success "LazyVim already initialized"
        return 0
    fi

    log_info "Bootstrapping LazyVim (this may take a minute)..."

    # Run headless Neovim to trigger lazy.nvim bootstrap
    nvim --headless "+Lazy! sync" +qa 2>&1 | grep -v "^$" | while read -r line; do
        log_debug "nvim: ${line}"
    done

    if [[ -f "${nvim_config}/lazy-lock.json" ]]; then
        log_success "LazyVim bootstrapped successfully"
    else
        log_warn "LazyVim bootstrap may not be complete. Please run :Lazy sync manually."
    fi
}

# Verify Neovim installation
verify_neovim() {
    if command_exists nvim; then
        local version
        version=$(nvim --version | head -1)
        log_success "✓ Neovim verification: ${version}"

        # Check if config exists
        if [[ -f "${HOME}/.config/nvim/init.lua" ]]; then
            log_success "✓ Neovim config: present"
        else
            log_warn "✗ Neovim config: not found"
        fi

        return 0
    else
        log_error "✗ Neovim verification: not found"
        return 1
    fi
}

# Export functions
export -f install_neovim install_lazyvim_prerequisites bootstrap_lazyvim verify_neovim
