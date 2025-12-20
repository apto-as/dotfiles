#!/usr/bin/env bash
# ============================================================================
# installers/docker.sh - Docker
# Purpose: Install Docker (Desktop for macOS, Engine for Ubuntu)
# Platforms: macOS (Docker Desktop via Homebrew), Ubuntu (Docker Engine)
# ============================================================================

# ============================================================================
# Main Installation
# ============================================================================

install_docker() {
    log_info "Installing Docker..."

    case "${DETECTED_OS}" in
        macos)
            install_docker_desktop_macos
            ;;
        ubuntu|debian)
            install_docker_engine_ubuntu
            ;;
        *)
            log_error "Docker installation not supported on ${DETECTED_OS}"
            return 1
            ;;
    esac

    # Setup Fish integration
    setup_docker_fish

    log_success "Docker installation complete"
}

# ============================================================================
# macOS Installation (Docker Desktop via Homebrew)
# ============================================================================

install_docker_desktop_macos() {
    # Check if Docker Desktop is already installed
    if [[ -d "/Applications/Docker.app" ]]; then
        log_debug "Docker Desktop already installed"

        # Check if docker command works
        if command_exists docker; then
            log_info "Docker Desktop is installed and running"
            return 0
        else
            log_warn "Docker Desktop is installed but not running"
            log_info "Please start Docker Desktop from Applications"
            return 0
        fi
    fi

    log_info "Installing Docker Desktop via Homebrew..."

    # Install Docker Desktop cask
    brew install --cask docker

    log_success "Docker Desktop installed"
    log_info "Please start Docker Desktop from Applications to complete setup"
}

# ============================================================================
# Ubuntu Installation (Docker Engine)
# ============================================================================

install_docker_engine_ubuntu() {
    if command_exists docker; then
        log_debug "Docker already installed"
        docker --version
        return 0
    fi

    log_info "Installing Docker Engine on Ubuntu..."

    # Remove old versions
    log_info "Removing old Docker packages if present..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Install prerequisites
    log_info "Installing prerequisites..."
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    log_info "Adding Docker GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    log_info "Setting up Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    log_info "Installing Docker Engine..."
    sudo apt-get update
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # Add current user to docker group
    setup_docker_group

    # Enable and start Docker service
    log_info "Enabling Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker

    # Verify installation
    if docker --version &>/dev/null; then
        log_success "Docker Engine installed: $(docker --version)"
    else
        log_error "Docker installation failed"
        return 1
    fi
}

# ============================================================================
# User Group Setup (Ubuntu)
# ============================================================================

setup_docker_group() {
    local current_user="${USER:-$(whoami)}"

    # Check if docker group exists
    if ! getent group docker &>/dev/null; then
        log_info "Creating docker group..."
        sudo groupadd docker
    fi

    # Check if user is already in docker group
    if id -nG "${current_user}" | grep -qw docker; then
        log_debug "User ${current_user} is already in docker group"
        return 0
    fi

    log_info "Adding ${current_user} to docker group..."
    sudo usermod -aG docker "${current_user}"

    log_warn "You need to log out and back in for docker group changes to take effect"
    log_info "Or run: newgrp docker"
}

# ============================================================================
# Fish Shell Integration
# ============================================================================

setup_docker_fish() {
    log_info "Setting up Docker Fish integration..."

    local fish_conf_dir="${HOME}/.config/fish/conf.d"
    local docker_fish_file="${fish_conf_dir}/docker.fish"

    mkdir -p "${fish_conf_dir}"

    cat > "${docker_fish_file}" << 'EOF'
# ============================================================================
# Docker Configuration for Fish
# Generated by dotfiles installer
# ============================================================================

# Docker aliases
if command -q docker
    # Container management
    alias dps 'docker ps'
    alias dpsa 'docker ps -a'
    alias di 'docker images'
    alias drm 'docker rm'
    alias drmi 'docker rmi'
    alias dexec 'docker exec -it'
    alias dlogs 'docker logs -f'

    # Docker Compose
    alias dc 'docker compose'
    alias dcu 'docker compose up -d'
    alias dcd 'docker compose down'
    alias dcl 'docker compose logs -f'

    # Cleanup
    alias dprune 'docker system prune -af'
    alias dvprune 'docker volume prune -f'

    # Quick container shell
    function dsh --description "Start a shell in a container"
        docker exec -it $argv[1] sh
    end

    function dbash --description "Start bash in a container"
        docker exec -it $argv[1] bash
    end
end
EOF

    log_success "Docker Fish integration configured: ${docker_fish_file}"
}

# ============================================================================
# Verification
# ============================================================================

verify_docker() {
    local errors=0

    # Check docker command
    if command_exists docker; then
        local version
        version=$(docker --version 2>/dev/null)
        log_success "Docker installed: ${version}"
    else
        log_error "Docker not found"
        ((errors++))
    fi

    # Check docker compose
    if docker compose version &>/dev/null; then
        local version
        version=$(docker compose version 2>/dev/null)
        log_success "Docker Compose: ${version}"
    else
        log_warn "Docker Compose not found (optional)"
    fi

    # Check if Docker daemon is running
    if docker info &>/dev/null; then
        log_success "Docker daemon is running"
    else
        log_warn "Docker daemon is not running"
        log_info "Please start Docker Desktop (macOS) or 'sudo systemctl start docker' (Linux)"
    fi

    return "${errors}"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Update Docker
update_docker() {
    log_info "Updating Docker..."

    case "${DETECTED_OS}" in
        macos)
            brew upgrade --cask docker
            log_info "Please restart Docker Desktop to complete the update"
            ;;
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
    esac

    log_success "Docker updated"
}

# Clean up Docker resources
cleanup_docker() {
    log_info "Cleaning up Docker resources..."

    # Remove stopped containers
    docker container prune -f

    # Remove unused images
    docker image prune -f

    # Remove unused volumes
    docker volume prune -f

    # Remove unused networks
    docker network prune -f

    log_success "Docker cleanup complete"
}

# Full Docker system cleanup (including build cache)
cleanup_docker_all() {
    log_warn "This will remove all unused Docker data including build cache"

    if confirm "Continue with full Docker cleanup?"; then
        docker system prune -af --volumes
        log_success "Full Docker cleanup complete"
    else
        log_info "Cleanup cancelled"
    fi
}

# Check Docker status
docker_status() {
    echo "Docker Status:"
    echo "=============="

    if command_exists docker; then
        echo "Version: $(docker --version)"

        if docker info &>/dev/null; then
            echo "Daemon: Running"
            echo ""
            echo "Containers:"
            docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            echo ""
            echo "Images:"
            docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
            echo ""
            echo "Disk Usage:"
            docker system df
        else
            echo "Daemon: Not running"
        fi
    else
        echo "Docker is not installed"
    fi
}

# Export functions
export -f install_docker install_docker_desktop_macos install_docker_engine_ubuntu
export -f setup_docker_group setup_docker_fish verify_docker
export -f update_docker cleanup_docker cleanup_docker_all docker_status
