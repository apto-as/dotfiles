#!/usr/bin/env bash
# ============================================================================
# installers/wezterm.sh - Wezterm Installation
# Purpose: Install and configure Wezterm terminal emulator
# ============================================================================

install_wezterm() {
    log_info "Installing Wezterm..."

    if command_exists wezterm; then
        log_success "Wezterm already installed"
        return 0
    fi

    case "${DETECTED_OS}" in
        macos)
            brew install --cask wezterm
            ;;
        linux)
            log_warn "Wezterm installation on Linux requires manual setup"
            log_info "Visit: https://wezfurlong.org/wezterm/installation.html"
            return 1
            ;;
        *)
            log_error "Wezterm installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    log_success "Wezterm installed"
}

# Verify Wezterm installation
verify_wezterm() {
    if command_exists wezterm; then
        local version
        version=$(wezterm --version 2>/dev/null | head -1)
        log_success "✓ Wezterm verification: ${version}"
        return 0
    else
        log_error "✗ Wezterm verification: not found"
        return 1
    fi
}

# Export functions
export -f install_wezterm verify_wezterm
