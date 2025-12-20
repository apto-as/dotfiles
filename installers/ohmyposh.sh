#!/usr/bin/env bash
# ============================================================================
# installers/ohmyposh.sh - Oh My Posh Prompt
# Purpose: Install oh-my-posh for beautiful shell prompts
# Platforms: macOS (Homebrew), Ubuntu (official binary)
# ============================================================================

# Configuration
readonly OMP_THEMES_DIR="${HOME}/.config/oh-my-posh/themes"
readonly DEFAULT_THEME="tsuyoshi"  # User's preferred theme

# ============================================================================
# Main Installation
# ============================================================================

install_ohmyposh() {
    log_info "Installing oh-my-posh..."

    case "${DETECTED_OS}" in
        macos)
            install_ohmyposh_macos
            ;;
        ubuntu|debian)
            install_ohmyposh_ubuntu
            ;;
        *)
            log_error "oh-my-posh installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    # Setup Fish integration
    setup_ohmyposh_fish

    log_success "oh-my-posh installation complete"
}

# ============================================================================
# macOS Installation (Homebrew)
# ============================================================================

install_ohmyposh_macos() {
    if command_exists oh-my-posh; then
        log_debug "oh-my-posh already installed via Homebrew"
        return 0
    fi

    log_info "Installing oh-my-posh via Homebrew..."
    brew install oh-my-posh

    log_success "oh-my-posh installed via Homebrew"
}

# ============================================================================
# Ubuntu Installation (Official Binary)
# ============================================================================

install_ohmyposh_ubuntu() {
    if command_exists oh-my-posh; then
        log_debug "oh-my-posh already installed"

        # Update to latest
        log_info "Updating oh-my-posh..."
        curl -s https://ohmyposh.dev/install.sh | bash -s
        return 0
    fi

    log_info "Installing oh-my-posh via official installer..."

    # Use official installer script
    curl -s https://ohmyposh.dev/install.sh | bash -s

    # Verify installation
    if command_exists oh-my-posh; then
        local version
        version=$(oh-my-posh --version 2>/dev/null)
        log_success "oh-my-posh installed: v${version}"
    else
        log_error "oh-my-posh installation failed"
        return 1
    fi
}

# ============================================================================
# Fish Shell Integration
# ============================================================================

setup_ohmyposh_fish() {
    log_info "Setting up oh-my-posh Fish integration..."

    # Note: The main config.fish already handles oh-my-posh initialization
    # This function ensures themes are available and creates any necessary setup

    # Create themes directory
    mkdir -p "${OMP_THEMES_DIR}"

    # Download default theme if not using Homebrew themes
    download_ohmyposh_themes

    log_success "oh-my-posh Fish integration ready"
}

# ============================================================================
# Theme Management
# ============================================================================

download_ohmyposh_themes() {
    log_info "Checking oh-my-posh themes..."

    # On macOS with Homebrew, themes are at /opt/homebrew/opt/oh-my-posh/themes/
    # On Ubuntu, we need to download them manually or use ~/.config/oh-my-posh/themes/

    case "${DETECTED_OS}" in
        macos)
            # Homebrew manages themes, check if they exist
            local brew_themes="/opt/homebrew/opt/oh-my-posh/themes"
            local intel_brew_themes="/usr/local/opt/oh-my-posh/themes"

            if [[ -d "${brew_themes}" ]]; then
                log_debug "Using Homebrew themes: ${brew_themes}"
            elif [[ -d "${intel_brew_themes}" ]]; then
                log_debug "Using Homebrew themes: ${intel_brew_themes}"
            else
                log_warn "Homebrew themes not found, downloading default theme..."
                download_theme "${DEFAULT_THEME}"
            fi
            ;;
        ubuntu|debian)
            # Download themes for Ubuntu
            log_info "Downloading oh-my-posh themes..."
            download_theme "${DEFAULT_THEME}"

            # Also download a few popular alternatives
            download_theme "dracula" || true
            download_theme "catppuccin" || true
            ;;
    esac
}

download_theme() {
    local theme_name="$1"
    local theme_file="${OMP_THEMES_DIR}/${theme_name}.omp.json"

    if [[ -f "${theme_file}" ]]; then
        log_debug "Theme already exists: ${theme_name}"
        return 0
    fi

    log_info "Downloading theme: ${theme_name}..."

    local theme_url="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/${theme_name}.omp.json"

    mkdir -p "${OMP_THEMES_DIR}"

    if curl -fsSL "${theme_url}" -o "${theme_file}"; then
        log_success "Theme downloaded: ${theme_name}"
    else
        log_warn "Failed to download theme: ${theme_name}"
        return 1
    fi
}

# ============================================================================
# Verification
# ============================================================================

verify_ohmyposh() {
    local errors=0

    # Check oh-my-posh
    if command_exists oh-my-posh; then
        local version
        version=$(oh-my-posh --version 2>/dev/null)
        log_success "oh-my-posh installed: v${version}"
    else
        log_error "oh-my-posh not found"
        ((errors++))
    fi

    # Check for theme files
    local theme_found=0

    # Check Homebrew themes (macOS)
    for theme_dir in \
        "/opt/homebrew/opt/oh-my-posh/themes" \
        "/usr/local/opt/oh-my-posh/themes" \
        "${OMP_THEMES_DIR}"; do
        if [[ -d "${theme_dir}" ]] && [[ -f "${theme_dir}/${DEFAULT_THEME}.omp.json" ]]; then
            log_success "Theme found: ${DEFAULT_THEME} (${theme_dir})"
            theme_found=1
            break
        fi
    done

    if [[ ${theme_found} -eq 0 ]]; then
        log_warn "Default theme (${DEFAULT_THEME}) not found"
    fi

    return "${errors}"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Update oh-my-posh
update_ohmyposh() {
    log_info "Updating oh-my-posh..."

    case "${DETECTED_OS}" in
        macos)
            brew upgrade oh-my-posh
            ;;
        ubuntu|debian)
            curl -s https://ohmyposh.dev/install.sh | bash -s
            ;;
    esac

    log_success "oh-my-posh updated to: v$(oh-my-posh --version)"
}

# List available themes
list_ohmyposh_themes() {
    echo "Available oh-my-posh themes:"

    local theme_dirs=(
        "/opt/homebrew/opt/oh-my-posh/themes"
        "/usr/local/opt/oh-my-posh/themes"
        "${OMP_THEMES_DIR}"
    )

    for theme_dir in "${theme_dirs[@]}"; do
        if [[ -d "${theme_dir}" ]]; then
            echo ""
            echo "Themes in ${theme_dir}:"
            ls -1 "${theme_dir}"/*.omp.json 2>/dev/null | xargs -I {} basename {} .omp.json | sort
        fi
    done
}

# Preview a theme
preview_ohmyposh_theme() {
    local theme_name="${1:-${DEFAULT_THEME}}"

    local theme_file=""
    for theme_dir in \
        "/opt/homebrew/opt/oh-my-posh/themes" \
        "/usr/local/opt/oh-my-posh/themes" \
        "${OMP_THEMES_DIR}"; do
        if [[ -f "${theme_dir}/${theme_name}.omp.json" ]]; then
            theme_file="${theme_dir}/${theme_name}.omp.json"
            break
        fi
    done

    if [[ -z "${theme_file}" ]]; then
        echo "Theme not found: ${theme_name}"
        return 1
    fi

    echo "Previewing theme: ${theme_name}"
    oh-my-posh print primary --config "${theme_file}"
}

# Export functions
export -f install_ohmyposh install_ohmyposh_macos install_ohmyposh_ubuntu
export -f setup_ohmyposh_fish download_ohmyposh_themes download_theme
export -f verify_ohmyposh update_ohmyposh list_ohmyposh_themes preview_ohmyposh_theme
