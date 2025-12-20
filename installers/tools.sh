#!/usr/bin/env bash
# ============================================================================
# installers/tools.sh - Additional Development Tools
# Purpose: Install useful CLI tools and utilities
# Platforms: macOS (Homebrew), Ubuntu (apt + official installers)
# ============================================================================

# Main entry point
install_tools() {
    log_info "Installing additional tools..."

    case "${DETECTED_OS}" in
        macos)
            install_tools_macos
            ;;
        ubuntu|debian)
            install_tools_ubuntu
            ;;
        *)
            log_warn "Tool installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    log_success "Additional tools installation complete"
}

# ============================================================================
# macOS Installation (Homebrew)
# ============================================================================

install_tools_macos() {
    log_info "Installing tools via Homebrew..."

    local -a tools=(
        # Core utilities
        "curl"         # HTTP client
        "wget"         # File downloader
        "git"          # Version control

        # JSON/YAML processing
        "jq"           # JSON processor
        "yq"           # YAML processor

        # Search and navigation
        "ripgrep"      # Fast grep (rg)
        "fd"           # Fast find
        "fzf"          # Fuzzy finder
        "zoxide"       # Smarter cd

        # File viewing
        "bat"          # Better cat
        "eza"          # Better ls
        "tree"         # Directory tree

        # System monitoring
        "htop"         # Better top

        # GitHub
        "gh"           # GitHub CLI
        "ghq"          # Repository manager

        # AWS
        "awscli"       # AWS CLI v2

        # Python tooling
        "uv"           # Fast Python package manager
    )

    for tool in "${tools[@]}"; do
        if ! is_installed "${tool}"; then
            log_info "Installing ${tool}..."
            brew install "${tool}"
        else
            log_debug "${tool} already installed"
        fi
    done
}

# ============================================================================
# Ubuntu Installation (apt + official installers)
# ============================================================================

install_tools_ubuntu() {
    log_info "Installing tools on Ubuntu..."

    # Update apt cache first
    log_info "Updating apt package cache..."
    sudo apt-get update

    # Phase 1: Standard apt packages
    install_tools_ubuntu_apt

    # Phase 2: Setup external repositories
    install_tools_ubuntu_repos

    # Phase 3: Install from external repos
    install_tools_ubuntu_external

    # Phase 4: Official installers (not in apt)
    install_tools_ubuntu_installers

    # Phase 5: Setup compatibility aliases
    setup_ubuntu_fish_aliases
}

# Standard apt packages
install_tools_ubuntu_apt() {
    log_info "Installing standard apt packages..."

    local -a apt_packages=(
        # Core utilities
        "curl"
        "wget"
        "git"
        "unzip"
        "zip"

        # JSON processing
        "jq"

        # Search tools
        "ripgrep"
        "fzf"
        "fd-find"  # Note: command is 'fdfind', alias needed

        # File viewing
        "bat"      # Note: command is 'batcat', alias needed
        "tree"

        # System monitoring
        "htop"

        # Build essentials (for some installers)
        "build-essential"
        "ca-certificates"
        "gnupg"
    )

    local -a to_install=()

    for pkg in "${apt_packages[@]}"; do
        if ! dpkg -l "${pkg}" 2>/dev/null | grep -q "^ii"; then
            to_install+=("${pkg}")
        else
            log_debug "${pkg} already installed"
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing ${#to_install[@]} packages via apt..."
        sudo apt-get install -y "${to_install[@]}"
    fi
}

# Setup external repositories for Ubuntu
install_tools_ubuntu_repos() {
    log_info "Setting up external repositories..."

    # GitHub CLI repository
    if ! command_exists gh; then
        setup_gh_repo_ubuntu
    fi

    # eza repository
    if ! command_exists eza; then
        setup_eza_repo_ubuntu
    fi
}

# Install packages from external repositories
install_tools_ubuntu_external() {
    log_info "Installing packages from external repositories..."

    local -a external_packages=(
        "gh"       # GitHub CLI
        "eza"      # Better ls
    )

    for pkg in "${external_packages[@]}"; do
        if ! command_exists "${pkg}"; then
            log_info "Installing ${pkg}..."
            sudo apt-get install -y "${pkg}"
        else
            log_debug "${pkg} already installed"
        fi
    done
}

# Install tools via official installers (not available in apt)
install_tools_ubuntu_installers() {
    log_info "Installing tools via official installers..."

    # zoxide - Smarter cd
    install_zoxide_ubuntu

    # uv - Fast Python package manager
    install_uv

    # yq - YAML processor
    install_yq

    # AWS CLI v2
    install_awscli

    # ghq - Repository manager (requires Go)
    # Note: Deferred to after Go installation
    # See installers/golang.sh for ghq installation
}

# ============================================================================
# Verification
# ============================================================================

verify_tools() {
    local -a essential_tools=(
        "git"
        "curl"
        "fzf"
        "jq"
    )
    local errors=0

    for tool in "${essential_tools[@]}"; do
        if command_exists "${tool}"; then
            log_success "${tool} installed"
        else
            log_error "${tool} not found"
            ((errors++))
        fi
    done

    # Platform-specific verification
    case "${DETECTED_OS}" in
        macos)
            verify_tools_macos || ((errors++))
            ;;
        ubuntu|debian)
            verify_tools_ubuntu || ((errors++))
            ;;
    esac

    return "${errors}"
}

verify_tools_macos() {
    local -a brew_tools=("ripgrep" "fd" "bat" "eza" "zoxide" "gh" "ghq" "uv" "yq")
    local errors=0

    for tool in "${brew_tools[@]}"; do
        if command_exists "${tool}" || is_installed "${tool}"; then
            log_success "${tool} installed"
        else
            log_warn "${tool} not found (optional)"
        fi
    done

    return "${errors}"
}

verify_tools_ubuntu() {
    local -a tools=(
        "rg:ripgrep"
        "fdfind:fd-find"
        "batcat:bat"
        "eza:eza"
        "zoxide:zoxide"
        "gh:gh"
        "uv:uv"
        "yq:yq"
    )
    local errors=0

    for tool_pair in "${tools[@]}"; do
        local cmd="${tool_pair%%:*}"
        local name="${tool_pair##*:}"

        if command_exists "${cmd}"; then
            log_success "${name} installed (${cmd})"
        else
            log_warn "${name} not found (optional)"
        fi
    done

    # Check AWS CLI
    if command_exists aws; then
        log_success "AWS CLI installed"
    else
        log_warn "AWS CLI not found (optional)"
    fi

    return "${errors}"
}

# ============================================================================
# Helper: Add GitHub CLI repo (Ubuntu)
# ============================================================================

setup_gh_repo_ubuntu() {
    if [[ -f /etc/apt/sources.list.d/github-cli.list ]]; then
        log_debug "GitHub CLI repo already configured"
        return 0
    fi

    log_info "Adding GitHub CLI official repository..."

    # Import GPG key
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    # Add repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt-get update
}

# ============================================================================
# Helper: Add eza repo (Ubuntu)
# ============================================================================

setup_eza_repo_ubuntu() {
    if [[ -f /etc/apt/sources.list.d/gierens.list ]]; then
        log_debug "eza repo already configured"
        return 0
    fi

    log_info "Adding eza official repository..."

    sudo mkdir -p /etc/apt/keyrings

    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
        sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true

    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
        sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null

    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
    sudo apt-get update
}

# ============================================================================
# Helper: Install zoxide (Ubuntu)
# ============================================================================

install_zoxide_ubuntu() {
    if command_exists zoxide; then
        log_debug "zoxide already installed"
        return 0
    fi

    log_info "Installing zoxide via official installer..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

# ============================================================================
# Helper: Install uv
# ============================================================================

install_uv() {
    if command_exists uv; then
        log_debug "uv already installed"
        return 0
    fi

    log_info "Installing uv via official installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

# ============================================================================
# Helper: Install yq
# ============================================================================

install_yq() {
    if command_exists yq; then
        log_debug "yq already installed"
        return 0
    fi

    log_info "Installing yq..."

    local arch
    arch=$(detect_arch)

    case "${arch}" in
        x86_64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
    esac

    local os="linux"
    [[ "${DETECTED_OS}" == "macos" ]] && os="darwin"

    local yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_${os}_${arch}"
    sudo wget -qO /usr/local/bin/yq "${yq_url}"
    sudo chmod +x /usr/local/bin/yq
}

# ============================================================================
# Helper: Install AWS CLI
# ============================================================================

install_awscli() {
    if command_exists aws; then
        log_debug "AWS CLI already installed"
        return 0
    fi

    log_info "Installing AWS CLI v2..."

    local arch
    arch=$(detect_arch)

    local tmp_dir
    tmp_dir=$(mktemp -d)

    (
        cd "${tmp_dir}"

        case "${arch}" in
            x86_64)
                curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                ;;
            arm64|aarch64)
                curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
                ;;
            *)
                log_error "Unsupported architecture for AWS CLI: ${arch}"
                return 1
                ;;
        esac

        unzip -q awscliv2.zip
        sudo ./aws/install
    )

    rm -rf "${tmp_dir}"
    log_success "AWS CLI v2 installed"
}

# ============================================================================
# Helper: Setup Ubuntu Fish aliases
# ============================================================================

setup_ubuntu_fish_aliases() {
    local alias_file="${HOME}/.config/fish/conf.d/ubuntu-compat.fish"

    if [[ -f "${alias_file}" ]]; then
        log_debug "Ubuntu Fish aliases already configured"
        return 0
    fi

    mkdir -p "$(dirname "${alias_file}")"

    cat > "${alias_file}" << 'EOF'
# ============================================================================
# Ubuntu Compatibility Aliases
# Purpose: Bridge command name differences between macOS and Ubuntu
# Generated by dotfiles installer
# ============================================================================

# fd-find -> fd
if command -q fdfind; and not command -q fd
    alias fd 'fdfind'
end

# batcat -> bat
if command -q batcat; and not command -q bat
    alias bat 'batcat'
end
EOF

    log_success "Ubuntu Fish aliases configured: ${alias_file}"
}

# Export functions
export -f install_tools install_tools_macos install_tools_ubuntu verify_tools
