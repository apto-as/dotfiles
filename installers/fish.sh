#!/usr/bin/env bash
# ============================================================================
# installers/fish.sh - Fish Shell Installation
# Purpose: Install and configure Fish shell with dotfiles integration
# ============================================================================

install_fish() {
    log_info "Installing Fish shell..."

    if command_exists fish; then
        log_success "Fish shell already installed"
        return 0
    fi

    case "${DETECTED_OS}" in
        macos)
            brew install fish
            ;;
        linux)
            # Detect Linux distribution
            if command_exists apt-get; then
                sudo apt-add-repository ppa:fish-shell/release-3 -y
                sudo apt-get update
                sudo apt-get install fish -y
            elif command_exists dnf; then
                sudo dnf install fish -y
            elif command_exists yum; then
                sudo yum install fish -y
            elif command_exists pacman; then
                sudo pacman -S fish --noconfirm
            else
                log_error "Unsupported Linux distribution for Fish installation"
                return 1
            fi
            ;;
        *)
            log_error "Fish installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    log_success "Fish shell installed"
}

# Configure Fish shell with dotfiles
configure_fish() {
    log_info "Configuring Fish shell..."

    local fish_config_dir="${HOME}/.config/fish"
    local dotfiles_fish_dir="${DOTFILES_DIR}/config/fish"
    local secure_credentials_dir="${HOME}/.secure_credentials"

    # Create Fish config directory
    mkdir -p "${fish_config_dir}"/{conf.d,functions,completions}

    # Symlink main config.fish
    if [ -f "${fish_config_dir}/config.fish" ] && [ ! -L "${fish_config_dir}/config.fish" ]; then
        log_warn "Backing up existing config.fish"
        mv "${fish_config_dir}/config.fish" "${fish_config_dir}/config.fish.backup-$(date +%Y%m%d-%H%M%S)"
    fi

    ln -sf "${dotfiles_fish_dir}/config.fish" "${fish_config_dir}/config.fish"
    log_success "✓ Symlinked config.fish"

    # Symlink conf.d/secure_credentials.fish
    if [ -f "${dotfiles_fish_dir}/conf.d/secure_credentials.fish" ]; then
        ln -sf "${dotfiles_fish_dir}/conf.d/secure_credentials.fish" \
               "${fish_config_dir}/conf.d/secure_credentials.fish"
        log_success "✓ Symlinked conf.d/secure_credentials.fish"
    fi

    # Create secure credentials directory
    if [ ! -d "${secure_credentials_dir}" ]; then
        mkdir -p "${secure_credentials_dir}"
        chmod 700 "${secure_credentials_dir}"
        log_success "✓ Created ~/.secure_credentials/ (chmod 700)"
    fi

    # Create example credentials file
    if [ ! -f "${secure_credentials_dir}/api_keys.env.example" ]; then
        cat > "${secure_credentials_dir}/api_keys.env.example" <<'EOF'
# ============================================================================
# API Keys and Credentials (EXAMPLE - DO NOT USE REAL KEYS)
# ============================================================================
# Copy this file to api_keys.env and fill in your actual credentials:
#   cp ~/.secure_credentials/api_keys.env.example ~/.secure_credentials/api_keys.env
#   chmod 600 ~/.secure_credentials/api_keys.env
#
# ⚠️  NEVER commit api_keys.env to Git (already in .gitignore)
#
# Alternatively, use 1Password CLI for better security:
#   brew install 1password-cli
#   op item create --category=login --title="Gemini API Key" credential=your-key-here
# ============================================================================

# Gemini API Key (Google AI)
GEMINI_API_KEY=your-gemini-api-key-here

# OpenAI API Key
OPENAI_API_KEY=your-openai-api-key-here

# Google Application Credentials Path
GOOGLE_APPLICATION_CREDENTIALS=~/.gemini/credentials.json

# AWS Profile
AWS_PROFILE=your-aws-profile-name
EOF
        chmod 644 "${secure_credentials_dir}/api_keys.env.example"
        log_success "✓ Created api_keys.env.example"
    fi

    # Detect machine type
    local machine_type=""
    if [ -n "${MACHINE_TYPE}" ]; then
        machine_type="${MACHINE_TYPE}"
    else
        # Auto-detect from hostname
        local hostname_short=$(hostname -s 2>/dev/null || hostname)
        case "${hostname_short}" in
            *macbook*|*MacBook*)
                machine_type="macbook"
                ;;
            *macmini*|*MacMini*)
                machine_type="macmini"
                ;;
            *ec2*|*aws*|ip-*)
                machine_type="ec2"
                ;;
            *)
                case "${DETECTED_OS}" in
                    macos)
                        machine_type="macos"
                        ;;
                    linux)
                        machine_type="linux"
                        ;;
                    *)
                        machine_type="unknown"
                        ;;
                esac
                ;;
        esac
    fi

    log_info "Detected machine type: ${machine_type}"

    # Check if machine-specific config exists
    local machine_config="${DOTFILES_DIR}/machines/${machine_type}/fish.local.fish"
    if [ -f "${machine_config}" ]; then
        log_success "✓ Machine-specific config found: ${machine_type}"
    else
        log_warn "⚠️  Machine-specific config not found"
        log_info "   Create: ${machine_config}"
        log_info "   See: ${DOTFILES_DIR}/machines/macbook/fish.local.fish (example)"
    fi

    log_success "Fish shell configured"
}

# Add Fish to valid shells (if not already)
add_fish_to_shells() {
    local fish_path=$(which fish)

    if ! grep -q "^${fish_path}$" /etc/shells 2>/dev/null; then
        log_info "Adding Fish to /etc/shells..."
        echo "${fish_path}" | sudo tee -a /etc/shells > /dev/null
        log_success "✓ Fish added to /etc/shells"
    else
        log_success "✓ Fish already in /etc/shells"
    fi
}

# Set Fish as default shell (optional)
set_fish_as_default() {
    local fish_path=$(which fish)
    local current_shell=$(basename "${SHELL}")

    if [ "${current_shell}" = "fish" ]; then
        log_success "✓ Fish is already the default shell"
        return 0
    fi

    log_warn "Fish is installed but not set as default shell"
    log_info "Current shell: ${SHELL}"
    log_info ""
    log_info "To set Fish as default shell, run:"
    log_info "  chsh -s ${fish_path}"
    log_info ""
    log_info "Or set it manually in your terminal app preferences"
}

# Verify Fish installation
verify_fish() {
    if command_exists fish; then
        local version=$(fish --version 2>/dev/null)
        log_success "✓ Fish verification: ${version}"

        # Check if config.fish is symlinked
        if [ -L "${HOME}/.config/fish/config.fish" ]; then
            log_success "✓ config.fish is symlinked"
        else
            log_warn "⚠️  config.fish is not symlinked"
        fi

        # Check if secure_credentials.fish exists
        if [ -f "${HOME}/.config/fish/conf.d/secure_credentials.fish" ]; then
            log_success "✓ secure_credentials.fish configured"
        else
            log_warn "⚠️  secure_credentials.fish not found"
        fi

        return 0
    else
        log_error "✗ Fish verification: not found"
        return 1
    fi
}

# Export functions
export -f install_fish configure_fish add_fish_to_shells set_fish_as_default verify_fish
