#!/usr/bin/env bash
# ============================================================================
# installers/zellij.sh - Zellij Installation
# Purpose: Install and configure Zellij multiplexer with security verification
# Security: Homebrew-first, fallback to Cargo, binary integrity checks
# ============================================================================

# Zellij installation with security verification
install_zellij() {
    log_info "Installing Zellij..."

    # Check if already installed
    if command_exists zellij; then
        log_success "Zellij already installed"
        verify_zellij_security
        return 0
    fi

    case "${DETECTED_OS}" in
        macos)
            install_zellij_macos
            ;;
        linux)
            install_zellij_linux
            ;;
        *)
            log_error "Zellij installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    # Verify installation and security
    if verify_zellij && verify_zellij_security; then
        log_success "Zellij installed and verified"
        return 0
    else
        log_error "Zellij installation verification failed"
        return 1
    fi
}

# Install Zellij on macOS
install_zellij_macos() {
    log_info "Installing Zellij via Homebrew..."

    # Ensure Homebrew is available
    if ! command_exists brew; then
        log_error "Homebrew not found. Please install Homebrew first."
        return 1
    fi

    # Install via Homebrew (primary method)
    if brew install zellij; then
        log_success "Zellij installed via Homebrew"
        return 0
    else
        log_warn "Homebrew installation failed, attempting Cargo fallback..."
        return install_zellij_cargo
    fi
}

# Install Zellij on Linux
install_zellij_linux() {
    log_info "Installing Zellij via Cargo..."

    # Check for Cargo
    if ! command_exists cargo; then
        log_error "Cargo not found. Please install Rust toolchain first."
        log_info "Visit: https://rustup.rs/"
        return 1
    fi

    return install_zellij_cargo
}

# Cargo installation (fallback method)
install_zellij_cargo() {
    if ! command_exists cargo; then
        log_error "Cargo not available for installation"
        return 1
    fi

    log_info "Installing Zellij via Cargo (this may take 3-5 minutes)..."

    # Install with locked dependencies for reproducibility
    if cargo install --locked zellij; then
        log_success "Zellij installed via Cargo"
        return 0
    else
        log_error "Cargo installation failed"
        return 1
    fi
}

# Verify Zellij installation
verify_zellij() {
    if command_exists zellij; then
        local version
        version=$(zellij --version 2>/dev/null | head -1)
        log_success "✓ Zellij verification: ${version}"
        return 0
    else
        log_error "✗ Zellij verification: not found"
        return 1
    fi
}

# Security verification for Zellij binary
verify_zellij_security() {
    local zellij_path
    zellij_path=$(command -v zellij 2>/dev/null)

    if [[ -z "${zellij_path}" ]]; then
        log_error "Cannot verify security: Zellij binary not found"
        return 1
    fi

    log_info "Performing security verification..."

    # Check 1: Verify no setuid/setgid bits
    if [[ -u "${zellij_path}" ]] || [[ -g "${zellij_path}" ]]; then
        log_error "✗ Security check failed: setuid/setgid bits detected on ${zellij_path}"
        log_error "This is a security risk. Please investigate."
        return 1
    fi
    log_success "✓ No setuid/setgid bits detected"

    # Check 2: Verify ownership
    local file_owner
    file_owner=$(stat -f "%Su" "${zellij_path}" 2>/dev/null || stat -c "%U" "${zellij_path}" 2>/dev/null)

    if [[ "${file_owner}" != "${USER}" ]] && [[ "${file_owner}" != "root" ]]; then
        log_warn "⚠ Binary owned by unexpected user: ${file_owner}"
    else
        log_success "✓ Binary ownership verified: ${file_owner}"
    fi

    # Check 3: Verify executable permissions
    if [[ ! -x "${zellij_path}" ]]; then
        log_error "✗ Binary is not executable"
        return 1
    fi
    log_success "✓ Binary is executable"

    # Check 4: Verify binary location
    case "${zellij_path}" in
        /usr/local/bin/*|/opt/homebrew/bin/*|~/.cargo/bin/*|/home/*/.cargo/bin/*)
            log_success "✓ Binary in trusted location: ${zellij_path}"
            ;;
        *)
            log_warn "⚠ Binary in unexpected location: ${zellij_path}"
            ;;
    esac

    log_success "Security verification passed"
    return 0
}

# Configure Zellij directories with secure permissions
configure_zellij() {
    log_info "Configuring Zellij..."

    local zellij_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zellij"
    local zellij_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zellij"
    local zellij_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zellij"

    # Create directories with secure permissions (700)
    for dir in "${zellij_config_dir}" "${zellij_data_dir}" "${zellij_cache_dir}"; do
        if [[ ! -d "${dir}" ]]; then
            log_info "Creating directory: ${dir}"
            mkdir -p "${dir}"
            chmod 700 "${dir}"
            log_success "✓ Created with secure permissions (700): ${dir}"
        else
            # Verify existing directory permissions
            local current_perms
            current_perms=$(stat -f "%Lp" "${dir}" 2>/dev/null || stat -c "%a" "${dir}" 2>/dev/null)

            if [[ "${current_perms}" != "700" ]]; then
                log_warn "⚠ Directory has insecure permissions (${current_perms}): ${dir}"
                log_info "Setting secure permissions (700)..."
                chmod 700 "${dir}"
                log_success "✓ Permissions corrected"
            else
                log_success "✓ Directory has secure permissions: ${dir}"
            fi
        fi
    done

    log_success "Zellij directories configured with secure permissions"
    return 0
}

# Complete Zellij setup (install + configure + verify)
setup_zellij() {
    log_info "Starting Zellij setup..."

    # Step 1: Install
    if ! install_zellij; then
        log_error "Zellij installation failed"
        return 1
    fi

    # Step 2: Configure
    if ! configure_zellij; then
        log_warn "Zellij configuration had issues but continuing..."
    fi

    # Step 3: Final verification
    if verify_zellij && verify_zellij_security; then
        log_success "Zellij setup completed successfully"

        # Display version and location
        local version location
        version=$(zellij --version 2>/dev/null | head -1)
        location=$(command -v zellij)

        log_info "Installed: ${version}"
        log_info "Location: ${location}"

        return 0
    else
        log_error "Zellij setup verification failed"
        return 1
    fi
}

# Export functions
export -f install_zellij install_zellij_macos install_zellij_linux install_zellij_cargo
export -f verify_zellij verify_zellij_security configure_zellij setup_zellij
