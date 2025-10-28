#!/usr/bin/env bash
# ============================================================================
# bootstrap-nvim.sh - Manual LazyVim Bootstrap
# Purpose: Manually trigger LazyVim plugin installation
# ============================================================================

set -euo pipefail

readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly NVIM_CONFIG="${HOME}/.config/nvim"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_info() {
    echo -e "${CYAN}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

main() {
    clear
    echo -e "${CYAN}"
    echo "============================================="
    echo "  LazyVim Bootstrap"
    echo "============================================="
    echo -e "${NC}"

    # Check if nvim is installed
    if ! command -v nvim &>/dev/null; then
        log_error "Neovim is not installed"
        log_info "Please run: ${DOTFILES_DIR}/install.sh"
        exit 1
    fi

    # Check if config exists
    if [[ ! -d "${NVIM_CONFIG}" ]]; then
        log_error "Neovim config not found at: ${NVIM_CONFIG}"
        log_info "Please run: ${DOTFILES_DIR}/install.sh"
        exit 1
    fi

    log_info "Starting LazyVim bootstrap..."
    echo ""

    # Run headless sync
    log_info "Running :Lazy! sync (this may take a few minutes)..."
    nvim --headless "+Lazy! sync" +qa 2>&1 | while read -r line; do
        echo "  nvim: ${line}"
    done

    echo ""

    # Check if lazy-lock.json was created
    if [[ -f "${NVIM_CONFIG}/lazy-lock.json" ]]; then
        log_success "LazyVim bootstrapped successfully!"
        log_info "Plugin lockfile: ${NVIM_CONFIG}/lazy-lock.json"
    else
        log_warn "Bootstrap may be incomplete"
        log_info "Please open Neovim and run: :Lazy sync"
    fi

    echo ""
    echo -e "${GREEN}"
    echo "============================================="
    echo "  Bootstrap Complete!"
    echo "============================================="
    echo -e "${NC}"
    echo ""
    log_info "Next steps:"
    echo "  1. Open Neovim: nvim"
    echo "  2. Wait for any remaining plugins to install"
    echo "  3. Run health check: :checkhealth"
    echo ""
}

main "$@"
