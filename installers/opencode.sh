#!/usr/bin/env bash
# ============================================================================
# installers/opencode.sh - Open Code CLI
# Purpose: Install Open Code (open-source AI coding assistant)
# Platforms: macOS, Ubuntu
# ============================================================================

# Configuration
readonly OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"

# ============================================================================
# Main Installation
# ============================================================================

install_opencode() {
    log_info "Installing Open Code..."

    # Check prerequisites
    if ! check_opencode_prerequisites; then
        return 1
    fi

    # Install Open Code
    case "${DETECTED_OS}" in
        macos)
            install_opencode_macos
            ;;
        ubuntu|debian)
            install_opencode_ubuntu
            ;;
        *)
            log_error "Open Code installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    # Setup configuration directory
    setup_opencode_config

    log_success "Open Code installation complete"
}

# ============================================================================
# Prerequisites Check
# ============================================================================

check_opencode_prerequisites() {
    log_info "Checking Open Code prerequisites..."

    # Open Code is typically installed via Go or binary download
    # Check if Go is available for source installation
    if command_exists go; then
        log_debug "Go is available for Open Code installation"
    else
        log_warn "Go not found - will attempt binary installation"
    fi

    return 0
}

# ============================================================================
# macOS Installation
# ============================================================================

install_opencode_macos() {
    if command_exists opencode; then
        log_debug "Open Code already installed"
        local version
        version=$(opencode version 2>/dev/null || echo "unknown")
        log_info "Open Code version: ${version}"
        return 0
    fi

    # Try Homebrew first
    if command_exists brew; then
        log_info "Attempting Open Code installation via Homebrew..."

        # Check if opencode formula exists
        if brew search opencode | grep -q "opencode"; then
            brew install opencode
            return 0
        fi
    fi

    # Fallback to Go install
    if command_exists go; then
        install_opencode_go
        return $?
    fi

    # Fallback to binary download
    install_opencode_binary
}

# ============================================================================
# Ubuntu Installation
# ============================================================================

install_opencode_ubuntu() {
    if command_exists opencode; then
        log_debug "Open Code already installed"
        local version
        version=$(opencode version 2>/dev/null || echo "unknown")
        log_info "Open Code version: ${version}"
        return 0
    fi

    # Try Go install first
    if command_exists go; then
        install_opencode_go
        return $?
    fi

    # Fallback to binary download
    install_opencode_binary
}

# ============================================================================
# Go Installation
# ============================================================================

install_opencode_go() {
    log_info "Installing Open Code via go install..."

    # Ensure GOPATH/bin is in PATH
    export GOPATH="${GOPATH:-${HOME}/go}"
    export PATH="${GOPATH}/bin:${PATH}"

    go install github.com/opencode-ai/opencode@latest

    if command_exists opencode || [[ -x "${GOPATH}/bin/opencode" ]]; then
        log_success "Open Code installed via go install"
        return 0
    else
        log_warn "Go installation may have failed, trying binary download..."
        install_opencode_binary
    fi
}

# ============================================================================
# Binary Installation
# ============================================================================

install_opencode_binary() {
    log_info "Installing Open Code via binary download..."

    local arch
    arch=$(detect_arch)

    local os
    os=$(detect_os)

    # Map to download names
    case "${os}" in
        macos) os="darwin" ;;
        ubuntu|debian) os="linux" ;;
    esac

    case "${arch}" in
        x86_64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
    esac

    # Download from GitHub releases
    local download_url="https://github.com/opencode-ai/opencode/releases/latest/download/opencode_${os}_${arch}"

    log_info "Downloading Open Code binary..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local binary_path="${tmp_dir}/opencode"

    if curl -fsSL "${download_url}" -o "${binary_path}"; then
        chmod +x "${binary_path}"
        sudo mv "${binary_path}" /usr/local/bin/opencode

        if command_exists opencode; then
            log_success "Open Code binary installed"
        else
            log_error "Open Code binary installation failed"
            rm -rf "${tmp_dir}"
            return 1
        fi
    else
        log_warn "Binary download failed - Open Code may not be available in releases"
        log_info "Please install manually or via Go: go install github.com/opencode-ai/opencode@latest"
        rm -rf "${tmp_dir}"
        return 1
    fi

    rm -rf "${tmp_dir}"
}

# ============================================================================
# Configuration Setup
# ============================================================================

setup_opencode_config() {
    log_info "Setting up Open Code configuration..."

    # Create config directory if it doesn't exist
    if [[ ! -d "${OPENCODE_CONFIG_DIR}" ]]; then
        mkdir -p "${OPENCODE_CONFIG_DIR}"
        log_debug "Created config directory: ${OPENCODE_CONFIG_DIR}"
    fi

    # Note: opencode.md and other config files should be symlinked from dotfiles
    # This is handled in the main install.sh symlink setup

    log_success "Open Code configuration directory ready: ${OPENCODE_CONFIG_DIR}"
}

# ============================================================================
# Verification
# ============================================================================

verify_opencode() {
    local errors=0

    # Check opencode command
    if command_exists opencode; then
        local version
        version=$(opencode version 2>/dev/null || echo "unknown")
        log_success "Open Code installed: ${version}"
    else
        log_warn "Open Code not found (optional)"
        # Not counting as error since it's optional
    fi

    # Check config directory
    if [[ -d "${OPENCODE_CONFIG_DIR}" ]]; then
        log_success "Config directory exists: ${OPENCODE_CONFIG_DIR}"
    else
        log_warn "Config directory not found"
    fi

    # Check for opencode.md
    if [[ -f "${OPENCODE_CONFIG_DIR}/opencode.md" ]]; then
        log_success "opencode.md found"
    else
        log_warn "opencode.md not found (optional custom instructions)"
    fi

    return "${errors}"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Update Open Code
update_opencode() {
    log_info "Updating Open Code..."

    if command_exists go; then
        export GOPATH="${GOPATH:-${HOME}/go}"
        export PATH="${GOPATH}/bin:${PATH}"

        go install github.com/opencode-ai/opencode@latest
        log_success "Open Code updated"
    else
        # Re-run binary installation
        install_opencode_binary
    fi
}

# Show Open Code version info
opencode_info() {
    echo "Open Code Information:"
    echo "======================"

    if command_exists opencode; then
        echo "Version: $(opencode version 2>/dev/null || echo 'unknown')"
        echo "Location: $(which opencode)"
        echo ""
        echo "Configuration:"
        echo "  Directory: ${OPENCODE_CONFIG_DIR}"

        if [[ -f "${OPENCODE_CONFIG_DIR}/opencode.md" ]]; then
            echo "  opencode.md: Found"
        else
            echo "  opencode.md: Not found"
        fi
    else
        echo "Open Code is not installed"
    fi
}

# Export functions
export -f install_opencode check_opencode_prerequisites
export -f install_opencode_macos install_opencode_ubuntu
export -f install_opencode_go install_opencode_binary
export -f setup_opencode_config verify_opencode update_opencode opencode_info
