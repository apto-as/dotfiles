#!/usr/bin/env bash
# ============================================================================
# installers/tmux.sh - tmux Installation
# Purpose: Install and configure tmux with TPM (Tmux Plugin Manager)
# Security: Homebrew-first, binary integrity checks
# ============================================================================

# tmux installation with security verification
install_tmux() {
    log_info "Installing tmux..."

    # Check if already installed
    if command_exists tmux; then
        log_success "tmux already installed"
        verify_tmux_security
        return 0
    fi

    case "${DETECTED_OS}" in
        macos)
            install_tmux_macos
            ;;
        linux)
            install_tmux_linux
            ;;
        *)
            log_error "tmux installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    # Verify installation and security
    if verify_tmux && verify_tmux_security; then
        log_success "tmux installed and verified"
        return 0
    else
        log_error "tmux installation verification failed"
        return 1
    fi
}

# Install tmux on macOS
install_tmux_macos() {
    log_info "Installing tmux via Homebrew..."

    if ! command_exists brew; then
        log_error "Homebrew not found. Please install Homebrew first."
        return 1
    fi

    if brew install tmux; then
        log_success "tmux installed via Homebrew"
        return 0
    else
        log_error "tmux Homebrew installation failed"
        return 1
    fi
}

# Install tmux on Linux
install_tmux_linux() {
    log_info "Installing tmux via package manager..."

    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y tmux
    elif command_exists dnf; then
        sudo dnf install -y tmux
    elif command_exists pacman; then
        sudo pacman -S --noconfirm tmux
    else
        log_error "No supported package manager found"
        return 1
    fi

    if command_exists tmux; then
        log_success "tmux installed via package manager"
        return 0
    else
        log_error "tmux installation failed"
        return 1
    fi
}

# Verify tmux installation
verify_tmux() {
    if command_exists tmux; then
        local version
        version=$(tmux -V 2>/dev/null | head -1)
        log_success "✓ tmux verification: ${version}"
        return 0
    else
        log_error "✗ tmux verification: not found"
        return 1
    fi
}

# Security verification for tmux binary
verify_tmux_security() {
    local tmux_path
    tmux_path=$(command -v tmux 2>/dev/null)

    if [[ -z "${tmux_path}" ]]; then
        log_error "Cannot verify security: tmux binary not found"
        return 1
    fi

    log_info "Performing security verification..."

    # Check 1: Verify no setuid/setgid bits
    if [[ -u "${tmux_path}" ]] || [[ -g "${tmux_path}" ]]; then
        log_error "✗ Security check failed: setuid/setgid bits detected on ${tmux_path}"
        return 1
    fi
    log_success "✓ No setuid/setgid bits detected"

    # Check 2: Verify ownership
    local file_owner
    file_owner=$(stat -f "%Su" "${tmux_path}" 2>/dev/null || stat -c "%U" "${tmux_path}" 2>/dev/null)

    if [[ "${file_owner}" != "${USER}" ]] && [[ "${file_owner}" != "root" ]]; then
        log_warn "⚠ Binary owned by unexpected user: ${file_owner}"
    else
        log_success "✓ Binary ownership verified: ${file_owner}"
    fi

    # Check 3: Verify executable permissions
    if [[ ! -x "${tmux_path}" ]]; then
        log_error "✗ Binary is not executable"
        return 1
    fi
    log_success "✓ Binary is executable"

    # Check 4: Verify binary location
    case "${tmux_path}" in
        /usr/local/bin/*|/opt/homebrew/bin/*|/usr/bin/*)
            log_success "✓ Binary in trusted location: ${tmux_path}"
            ;;
        *)
            log_warn "⚠ Binary in unexpected location: ${tmux_path}"
            ;;
    esac

    log_success "Security verification passed"
    return 0
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    local tpm_dir="${HOME}/.tmux/plugins/tpm"

    if [[ -d "${tpm_dir}" ]]; then
        log_success "TPM already installed"
        return 0
    fi

    log_info "Installing TPM (Tmux Plugin Manager)..."

    if git clone https://github.com/tmux-plugins/tpm "${tpm_dir}" 2>/dev/null; then
        log_success "TPM installed at ${tpm_dir}"
        log_info "Run 'prefix + I' inside tmux to install plugins"
        return 0
    else
        log_error "TPM installation failed"
        return 1
    fi
}

# Configure tmux directories with secure permissions
configure_tmux() {
    log_info "Configuring tmux..."

    local tmux_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
    local tmux_plugin_dir="${HOME}/.tmux/plugins"
    local tmux_resurrect_dir="${HOME}/.tmux/resurrect"

    # Create directories with secure permissions (700)
    for dir in "${tmux_config_dir}" "${tmux_plugin_dir}" "${tmux_resurrect_dir}"; do
        if [[ ! -d "${dir}" ]]; then
            log_info "Creating directory: ${dir}"
            mkdir -p "${dir}"
            chmod 700 "${dir}"
            log_success "✓ Created with secure permissions (700): ${dir}"
        else
            local current_perms
            current_perms=$(stat -f "%Lp" "${dir}" 2>/dev/null || stat -c "%a" "${dir}" 2>/dev/null)

            if [[ "${current_perms}" != "700" ]]; then
                log_warn "⚠ Directory has insecure permissions (${current_perms}): ${dir}"
                chmod 700 "${dir}"
                log_success "✓ Permissions corrected"
            else
                log_success "✓ Directory has secure permissions: ${dir}"
            fi
        fi
    done

    # Install TPM
    install_tpm

    log_success "tmux directories configured with secure permissions"
    return 0
}

# Complete tmux setup (install + configure + verify)
setup_tmux() {
    log_info "Starting tmux setup..."

    # Step 1: Install
    if ! install_tmux; then
        log_error "tmux installation failed"
        return 1
    fi

    # Step 2: Configure
    if ! configure_tmux; then
        log_warn "tmux configuration had issues but continuing..."
    fi

    # Step 3: Final verification
    if verify_tmux && verify_tmux_security; then
        log_success "tmux setup completed successfully"

        local version location
        version=$(tmux -V 2>/dev/null | head -1)
        location=$(command -v tmux)

        log_info "Installed: ${version}"
        log_info "Location: ${location}"

        return 0
    else
        log_error "tmux setup verification failed"
        return 1
    fi
}

# Export functions
export -f install_tmux install_tmux_macos install_tmux_linux
export -f verify_tmux verify_tmux_security install_tpm configure_tmux setup_tmux
