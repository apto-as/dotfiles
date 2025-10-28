#!/usr/bin/env bash
# ============================================================================
# installers/homebrew.sh - Homebrew Installation
# Purpose: Install and configure Homebrew (macOS package manager)
# ============================================================================

install_homebrew() {
    if command_exists brew; then
        log_success "Homebrew already installed"

        # Update homebrew (non-blocking background update)
        log_info "Updating Homebrew..."
        brew update &>/dev/null &

        return 0
    fi

    log_info "Installing Homebrew..."

    # Official Homebrew installation
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for current session
    if [[ "${DETECTED_ARCH}" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"
}

# Configure Homebrew
configure_homebrew() {
    if ! command_exists brew; then
        log_error "Homebrew not found. Cannot configure."
        return 1
    fi

    # Disable analytics
    brew analytics off 2>/dev/null || true

    # Add taps
    log_info "Adding Homebrew taps..."
    brew tap homebrew/cask-fonts 2>/dev/null || true

    log_success "Homebrew configured"
}

# Export function
export -f install_homebrew configure_homebrew
