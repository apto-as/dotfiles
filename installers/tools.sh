#!/usr/bin/env bash
# ============================================================================
# installers/tools.sh - Additional Development Tools
# Purpose: Install useful CLI tools and utilities
# ============================================================================

install_tools() {
    log_info "Installing additional tools..."

    case "${DETECTED_OS}" in
        macos)
            install_tools_macos
            ;;
        linux)
            install_tools_linux
            ;;
        *)
            log_warn "Tool installation not supported on ${DETECTED_OS}"
            ;;
    esac
}

install_tools_macos() {
    local -a tools=(
        "git"          # Version control
        "curl"         # HTTP client
        "wget"         # File downloader
        "fzf"          # Fuzzy finder
        "bat"          # Better cat
        "eza"          # Better ls
        "zoxide"       # Smarter cd
        "jq"           # JSON processor
        "gh"           # GitHub CLI
    )

    for tool in "${tools[@]}"; do
        if ! is_installed "${tool}"; then
            log_info "Installing ${tool}..."
            brew install "${tool}"
        else
            log_debug "${tool} already installed"
        fi
    done

    log_success "Additional tools installed"
}

install_tools_linux() {
    log_warn "Linux tool installation requires manual setup"
    log_info "Suggested tools: git, curl, wget, fzf, bat, eza, zoxide, jq, gh"
}

# Verify essential tools
verify_tools() {
    local -a essential_tools=("git" "curl" "fzf")
    local errors=0

    for tool in "${essential_tools[@]}"; do
        if command_exists "${tool}"; then
            log_success "✓ ${tool} installed"
        else
            log_error "✗ ${tool} not found"
            ((errors++))
        fi
    done

    return "${errors}"
}

# Export functions
export -f install_tools install_tools_macos install_tools_linux verify_tools
