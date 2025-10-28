#!/usr/bin/env bash
# ============================================================================
# update.sh - Dotfiles Update Script
# Purpose: Update dotfiles and sync all configurations
# ============================================================================

set -euo pipefail

readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${DOTFILES_DIR}/lib"

# Source core library
source "${LIB_DIR}/core.sh"
source "${LIB_DIR}/backup.sh"

main() {
    local start_time
    start_time=$(start_timer)

    clear
    echo -e "${CYAN}"
    echo "============================================="
    echo "  Dotfiles Update"
    echo "============================================="
    echo -e "${NC}"

    # Phase 1: Git pull
    log_info "[1/5] Pulling latest changes from remote..."
    cd "${DOTFILES_DIR}"

    if [[ -d .git ]]; then
        git pull origin main 2>&1 | while read -r line; do
            log_debug "git: ${line}"
        done
        log_success "Git pull complete"
    else
        log_warn "Not a git repository. Skipping git pull."
    fi
    echo ""

    # Phase 2: Update submodules (if any)
    log_info "[2/5] Updating git submodules..."
    if [[ -f .gitmodules ]]; then
        git submodule update --init --recursive 2>&1 | while read -r line; do
            log_debug "git submodule: ${line}"
        done
        log_success "Submodules updated"
    else
        log_info "No submodules found. Skipping."
    fi
    echo ""

    # Phase 3: Update Homebrew packages
    log_info "[3/5] Updating Homebrew packages..."
    if command_exists brew; then
        log_info "Running brew update..."
        brew update &>/dev/null

        log_info "Running brew upgrade..."
        brew upgrade 2>&1 | grep -v "^$" | while read -r line; do
            log_debug "brew: ${line}"
        done

        log_success "Homebrew packages updated"
    else
        log_warn "Homebrew not found. Skipping."
    fi
    echo ""

    # Phase 4: Update Neovim plugins
    log_info "[4/5] Updating Neovim plugins..."
    if command_exists nvim; then
        log_info "Running :Lazy sync..."
        nvim --headless "+Lazy! sync" +qa 2>&1 | grep -v "^$" | while read -r line; do
            log_debug "nvim: ${line}"
        done
        log_success "Neovim plugins updated"
    else
        log_warn "Neovim not found. Skipping."
    fi
    echo ""

    # Phase 5: Cleanup old backups
    log_info "[5/5] Cleaning up old backups..."
    cleanup_old_backups 5
    log_success "Old backups cleaned (kept last 5)"
    echo ""

    local elapsed
    elapsed=$(end_timer "${start_time}")

    echo -e "${GREEN}"
    echo "============================================="
    echo "  Update Complete!"
    echo "  Time elapsed: $(format_time ${elapsed})"
    echo "============================================="
    echo -e "${NC}"

    show_post_update_info
}

show_post_update_info() {
    echo ""
    log_info "Post-Update Checklist:"
    echo ""
    echo "  1. Restart your terminal (or run: exec \$SHELL)"
    echo "  2. Verify Wezterm still works correctly"
    echo "  3. Open Neovim and check for plugin issues"
    echo "  4. Review changelog: ${DOTFILES_DIR}/CHANGELOG.md (if exists)"
    echo ""
    log_info "If something broke:"
    echo "  • Check the log: ${LOG_FILE}"
    echo "  • Rollback: ${DOTFILES_DIR}/install.sh --rollback"
    echo "  • Report issue: Create an issue in your dotfiles repo"
    echo ""
}

# Entry point
main "$@"
