#!/usr/bin/env bash
# ============================================================================
# lib/pkg.sh - Package Manager Abstraction Layer
# Purpose: Unified package installation across macOS (Homebrew) and Ubuntu (apt)
# Architecture: Abstract package operations for cross-platform compatibility
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/core.sh"
source "${SCRIPT_DIR}/detect.sh"

# ============================================================================
# Package Name Mapping
# ============================================================================
# Some packages have different names across package managers.
# This mapping translates from canonical names to platform-specific names.
# Note: Using function-based lookup for Bash 3.x compatibility (macOS default)

# Helper function to get apt package name (canonical -> apt name)
_get_apt_pkg_name() {
    local pkg="$1"
    case "$pkg" in
        fd)      echo "fd-find" ;;
        # Note: bat package is 'bat' but command is 'batcat' on Ubuntu
        *)       echo "$pkg" ;;
    esac
}

# Check if a package requires external repository on Ubuntu
_is_apt_external_pkg() {
    local pkg="$1"
    case "$pkg" in
        gh|eza|zoxide|yq|uv|ghq)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Core Package Functions
# ============================================================================

# Install a package using the appropriate package manager
# Args: $1 = package name (canonical)
# Returns: 0 on success, 1 on failure
pkg_install() {
    local pkg="$1"
    local os
    os=$(detect_os)

    case "${os}" in
        macos)
            _pkg_install_brew "${pkg}"
            ;;
        ubuntu|debian)
            _pkg_install_apt "${pkg}"
            ;;
        *)
            log_error "Unsupported OS for package installation: ${os}"
            return 1
            ;;
    esac
}

# Install multiple packages
# Args: $@ = package names
pkg_install_batch() {
    local -a packages=("$@")
    local os
    os=$(detect_os)

    case "${os}" in
        macos)
            _pkg_install_brew_batch "${packages[@]}"
            ;;
        ubuntu|debian)
            _pkg_install_apt_batch "${packages[@]}"
            ;;
        *)
            log_error "Unsupported OS for package installation: ${os}"
            return 1
            ;;
    esac
}

# Check if package is installed
# Args: $1 = package name or command name
# Returns: 0 if installed, 1 if not
pkg_is_installed() {
    local pkg="$1"

    # First, check if command exists
    if command_exists "${pkg}"; then
        return 0
    fi

    # Check package manager
    local os
    os=$(detect_os)

    case "${os}" in
        macos)
            brew list "${pkg}" &>/dev/null
            ;;
        ubuntu|debian)
            local apt_pkg
            apt_pkg=$(_get_apt_pkg_name "$pkg")
            dpkg -l "${apt_pkg}" 2>/dev/null | grep -q "^ii"
            ;;
    esac
}

# Update package manager cache
pkg_update() {
    local os
    os=$(detect_os)

    case "${os}" in
        macos)
            brew update
            ;;
        ubuntu|debian)
            sudo apt-get update
            ;;
    esac
}

# ============================================================================
# Homebrew Functions (macOS)
# ============================================================================

_pkg_install_brew() {
    local pkg="$1"

    if brew list "${pkg}" &>/dev/null; then
        log_debug "${pkg} already installed (brew)"
        return 0
    fi

    log_info "Installing ${pkg} via Homebrew..."
    brew install "${pkg}"
}

_pkg_install_brew_batch() {
    local -a packages=("$@")
    local -a to_install=()

    for pkg in "${packages[@]}"; do
        if ! brew list "${pkg}" &>/dev/null; then
            to_install+=("${pkg}")
        else
            log_debug "${pkg} already installed (brew)"
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing ${#to_install[@]} packages via Homebrew..."
        brew install "${to_install[@]}"
    fi
}

# ============================================================================
# APT Functions (Ubuntu/Debian)
# ============================================================================

_pkg_install_apt() {
    local pkg="$1"
    local apt_pkg
    apt_pkg=$(_get_apt_pkg_name "$pkg")

    if dpkg -l "${apt_pkg}" 2>/dev/null | grep -q "^ii"; then
        log_debug "${pkg} (${apt_pkg}) already installed (apt)"
        return 0
    fi

    log_info "Installing ${apt_pkg} via apt..."
    sudo apt-get install -y "${apt_pkg}"
}

_pkg_install_apt_batch() {
    local -a packages=("$@")
    local -a to_install=()

    for pkg in "${packages[@]}"; do
        local apt_pkg
        apt_pkg=$(_get_apt_pkg_name "$pkg")
        if ! dpkg -l "${apt_pkg}" 2>/dev/null | grep -q "^ii"; then
            to_install+=("${apt_pkg}")
        else
            log_debug "${pkg} (${apt_pkg}) already installed (apt)"
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Installing ${#to_install[@]} packages via apt..."
        sudo apt-get install -y "${to_install[@]}"
    fi
}

# ============================================================================
# External Package Installers (Ubuntu)
# ============================================================================

# Add GitHub CLI official repository for Ubuntu
setup_gh_repo_ubuntu() {
    if [[ -f /etc/apt/sources.list.d/github-cli.list ]]; then
        log_debug "GitHub CLI repo already configured"
        return 0
    fi

    log_info "Adding GitHub CLI official repository..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
}

# Add eza official repository for Ubuntu
setup_eza_repo_ubuntu() {
    if [[ -f /etc/apt/sources.list.d/gierens.list ]]; then
        log_debug "eza repo already configured"
        return 0
    fi

    log_info "Adding eza official repository..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
        sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
        sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update
}

# Install zoxide via official installer
install_zoxide_ubuntu() {
    if command_exists zoxide; then
        log_debug "zoxide already installed"
        return 0
    fi

    log_info "Installing zoxide via official installer..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

# Install uv via official installer
install_uv() {
    if command_exists uv; then
        log_debug "uv already installed"
        return 0
    fi

    log_info "Installing uv via official installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

# Install yq via official binary
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

    local os
    os=$(detect_os)

    case "${os}" in
        macos) os="darwin" ;;
        ubuntu|debian|linux) os="linux" ;;
    esac

    local yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_${os}_${arch}"
    sudo wget -qO /usr/local/bin/yq "${yq_url}"
    sudo chmod +x /usr/local/bin/yq
}

# Install ghq via go install
install_ghq() {
    if command_exists ghq; then
        log_debug "ghq already installed"
        return 0
    fi

    if ! command_exists go; then
        log_warn "Go is required to install ghq. Please install Go first."
        return 1
    fi

    log_info "Installing ghq via go install..."
    go install github.com/x-motemen/ghq@latest
}

# Install AWS CLI v2
install_awscli() {
    if command_exists aws; then
        log_debug "AWS CLI already installed"
        return 0
    fi

    log_info "Installing AWS CLI v2..."
    local os
    os=$(detect_os)
    local arch
    arch=$(detect_arch)

    case "${os}" in
        macos)
            # Use Homebrew on macOS
            brew install awscli
            ;;
        ubuntu|debian|linux)
            local tmp_dir
            tmp_dir=$(mktemp -d)
            cd "${tmp_dir}"

            case "${arch}" in
                x86_64)
                    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    ;;
                arm64|aarch64)
                    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
                    ;;
            esac

            unzip -q awscliv2.zip
            sudo ./aws/install
            cd - > /dev/null
            rm -rf "${tmp_dir}"
            ;;
    esac
}

# ============================================================================
# Ubuntu Compatibility Aliases
# ============================================================================

# Setup Fish aliases for Ubuntu command name differences
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

# fd-find → fd
if command -q fdfind; and not command -q fd
    alias fd 'fdfind'
end

# batcat → bat
if command -q batcat; and not command -q bat
    alias bat 'batcat'
end
EOF

    log_success "Ubuntu Fish aliases configured: ${alias_file}"
}

# ============================================================================
# Helper Functions
# ============================================================================

# Check if a package requires external repository on Ubuntu
pkg_needs_external_repo() {
    local pkg="$1"
    _is_apt_external_pkg "$pkg"
}

# Get the command name for a package (may differ from package name)
pkg_command_name() {
    local pkg="$1"
    local os
    os=$(detect_os)

    if [[ "${os}" == "ubuntu" || "${os}" == "debian" ]]; then
        case "${pkg}" in
            fd) echo "fdfind" ;;
            bat) echo "batcat" ;;
            *) echo "${pkg}" ;;
        esac
    else
        echo "${pkg}"
    fi
}

# Export functions
export -f pkg_install pkg_install_batch pkg_is_installed pkg_update
export -f setup_gh_repo_ubuntu setup_eza_repo_ubuntu
export -f install_zoxide_ubuntu install_uv install_yq install_ghq install_awscli
export -f setup_ubuntu_fish_aliases pkg_needs_external_repo pkg_command_name
