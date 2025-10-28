#!/usr/bin/env bash
# ============================================================================
# installers/fonts.sh - Font Installation
# Purpose: Install PlemolJP Console NF and other fonts
# ============================================================================

install_fonts() {
    log_info "Installing fonts..."

    case "${DETECTED_OS}" in
        macos)
            install_fonts_macos
            ;;
        linux)
            install_fonts_linux
            ;;
        *)
            log_warn "Font installation not supported on ${DETECTED_OS}"
            ;;
    esac
}

install_fonts_macos() {
    local font_name="font-plemoljp-nf"

    # Check if already installed via Homebrew
    if is_installed "${font_name}"; then
        log_success "PlemolJP Console NF already installed (Homebrew)"
        return 0
    fi

    # Install via Homebrew cask (fastest and most reliable method)
    log_info "Installing PlemolJP Console NF via Homebrew..."

    # Ensure cask-fonts tap is added
    brew tap homebrew/cask-fonts 2>/dev/null || true

    brew install --cask "${font_name}"

    log_success "PlemolJP Console NF installed"
}

install_fonts_linux() {
    local font_dir="${HOME}/.local/share/fonts"
    local dotfiles_fonts="${DOTFILES_DIR}/assets/fonts"

    mkdir -p "${font_dir}"

    if [[ -d "${dotfiles_fonts}" ]]; then
        log_info "Copying fonts from dotfiles..."
        find "${dotfiles_fonts}" -name "*.ttf" -o -name "*.otf" | while read -r font; do
            cp "${font}" "${font_dir}/"
            log_debug "Copied: $(basename "${font}")"
        done

        # Rebuild font cache
        if command_exists fc-cache; then
            fc-cache -f -v &>/dev/null
            log_success "Font cache rebuilt"
        fi
    else
        log_warn "No fonts found in ${dotfiles_fonts}"
    fi
}

# Verify fonts are installed
verify_fonts() {
    case "${DETECTED_OS}" in
        macos)
            if is_installed "font-plemoljp-nf"; then
                log_success "✓ Font verification: PlemolJP Console NF installed"
                return 0
            else
                log_error "✗ Font verification: PlemolJP Console NF not found"
                return 1
            fi
            ;;
        linux)
            if fc-list | grep -i "plemoljp" &>/dev/null; then
                log_success "✓ Font verification: PlemolJP installed"
                return 0
            else
                log_warn "Font verification: PlemolJP not found in fc-list"
                return 1
            fi
            ;;
    esac
}

# Export functions
export -f install_fonts install_fonts_macos install_fonts_linux verify_fonts
