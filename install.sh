#!/usr/bin/env bash
# ============================================================================
# install.sh - Main Dotfiles Installation Script
# Purpose: Orchestrate complete dotfiles setup
# Architecture: Modular, Parallel, Idempotent
# ============================================================================

set -euo pipefail

readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${DOTFILES_DIR}/lib"
readonly INSTALLERS_DIR="${DOTFILES_DIR}/installers"

# Source core libraries
source "${LIB_DIR}/core.sh"
source "${LIB_DIR}/detect.sh"
source "${LIB_DIR}/backup.sh"
source "${LIB_DIR}/symlink.sh"

# Source installers
source "${INSTALLERS_DIR}/homebrew.sh"
source "${INSTALLERS_DIR}/fonts.sh"
source "${INSTALLERS_DIR}/wezterm.sh"
source "${INSTALLERS_DIR}/neovim.sh"
source "${INSTALLERS_DIR}/tools.sh"

# Main installation flow
main() {
    local start_time
    start_time=$(start_timer)

    clear
    echo -e "${CYAN}"
    echo "============================================="
    echo "  Dotfiles Installation"
    echo "  Architecture: Modular, Parallel, Idempotent"
    echo "============================================="
    echo -e "${NC}"

    # Phase 1: Validation
    log_info "[Phase 1/6] System Validation"
    check_dependencies
    export_system_info
    display_system_info
    echo ""

    # Phase 2: Backup existing configs
    log_info "[Phase 2/6] Backup Existing Configurations"
    backup_existing_configs
    echo ""

    # Phase 3: Install Homebrew (required for everything else)
    log_info "[Phase 3/6] Install Homebrew"
    install_homebrew
    configure_homebrew
    echo ""

    # Phase 4: Install dependencies (parallel where possible)
    log_info "[Phase 4/6] Install Dependencies"
    install_fonts &
    local fonts_pid=$!

    install_wezterm &
    local wezterm_pid=$!

    install_neovim &
    local neovim_pid=$!

    install_tools &
    local tools_pid=$!

    # Wait for all parallel installations
    wait $fonts_pid && log_success "Fonts installed" || log_warn "Fonts installation had issues"
    wait $wezterm_pid && log_success "Wezterm installed" || log_warn "Wezterm installation had issues"
    wait $neovim_pid && log_success "Neovim installed" || log_warn "Neovim installation had issues"
    wait $tools_pid && log_success "Tools installed" || log_warn "Tools installation had issues"
    echo ""

    # Phase 5: Setup configurations (symlinks)
    log_info "[Phase 5/6] Setup Configurations"
    setup_symlinks
    setup_machine_specific_configs
    echo ""

    # Phase 6: Verification
    log_info "[Phase 6/6] Verification"
    verify_installation
    echo ""

    local elapsed
    elapsed=$(end_timer "${start_time}")

    echo -e "${GREEN}"
    echo "============================================="
    echo "  Installation Complete!"
    echo "  Time elapsed: $(format_time ${elapsed})"
    echo "============================================="
    echo -e "${NC}"

    show_next_steps
}

# Backup existing configurations
backup_existing_configs() {
    local -a configs=(
        "${HOME}/.config/nvim"
        "${HOME}/.config/wezterm"
    )

    backup_batch "${configs[@]}"
}

# Setup symlinks for all configurations
setup_symlinks() {
    local -a symlink_mappings=(
        "${DOTFILES_DIR}/config/nvim:${HOME}/.config/nvim"
        "${DOTFILES_DIR}/config/wezterm:${HOME}/.config/wezterm"
    )

    create_symlinks "${symlink_mappings[@]}"
}

# Setup machine-specific configurations
setup_machine_specific_configs() {
    local machine_dir="${DOTFILES_DIR}/machines/${MACHINE_TYPE}"

    if [[ ! -d "${machine_dir}" ]]; then
        log_warn "No machine-specific config found for: ${MACHINE_TYPE}"
        log_info "Using default configuration"
        return
    fi

    log_info "Applying machine-specific configs for: ${MACHINE_TYPE}"

    # Wezterm local.lua
    if [[ -f "${machine_dir}/wezterm.local.lua" ]]; then
        create_symlink "${machine_dir}/wezterm.local.lua" "${HOME}/.config/wezterm/local.lua"
    fi

    # Neovim local.lua
    if [[ -f "${machine_dir}/nvim.local.lua" ]]; then
        mkdir -p "${HOME}/.config/nvim/lua"
        create_symlink "${machine_dir}/nvim.local.lua" "${HOME}/.config/nvim/lua/local.lua"
    fi
}

# Verify installation completeness
verify_installation() {
    local errors=0

    # Verify commands
    verify_wezterm || ((errors++))
    verify_neovim || ((errors++))
    verify_fonts || ((errors++))
    verify_tools || ((errors++))

    # Verify symlinks
    local -a symlink_mappings=(
        "${DOTFILES_DIR}/config/nvim:${HOME}/.config/nvim"
        "${DOTFILES_DIR}/config/wezterm:${HOME}/.config/wezterm"
    )

    verify_symlinks "${symlink_mappings[@]}" || ((errors++))

    if [[ ${errors} -gt 0 ]]; then
        log_warn "Installation completed with ${errors} issue(s)"
        log_info "Check the log for details: ${LOG_FILE}"
        log_info "You can run: ${DOTFILES_DIR}/install.sh --rollback"
        return 1
    fi

    log_success "All verifications passed!"
    return 0
}

# Show next steps
show_next_steps() {
    echo ""
    log_info "Next Steps:"
    echo ""
    echo "  1. Restart your terminal (or run: exec \$SHELL)"
    echo "  2. Open Wezterm to see the new configuration"
    echo "  3. Open Neovim to trigger LazyVim bootstrap: nvim"
    echo "  4. (Optional) Bootstrap LazyVim now: ${DOTFILES_DIR}/scripts/bootstrap-nvim.sh"
    echo ""
    log_info "Configuration locations:"
    echo "  • Dotfiles: ${DOTFILES_DIR}"
    echo "  • Neovim: ~/.config/nvim -> ${DOTFILES_DIR}/config/nvim"
    echo "  • Wezterm: ~/.config/wezterm -> ${DOTFILES_DIR}/config/wezterm"
    echo "  • Backup: ${BACKUP_DIR}/${BACKUP_TIMESTAMP}"
    echo ""
    log_info "Useful commands:"
    echo "  • Update dotfiles: ${DOTFILES_DIR}/update.sh"
    echo "  • List backups: ${DOTFILES_DIR}/install.sh --list-backups"
    echo "  • Rollback: ${DOTFILES_DIR}/install.sh --rollback"
    echo ""
}

# Handle command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --rollback)
                rollback
                exit 0
                ;;
            --list-backups)
                list_backups
                exit 0
                ;;
            --debug)
                export DEBUG=1
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

show_help() {
    cat <<EOF
Dotfiles Installation Script

Usage: ${0} [OPTIONS]

Options:
    --rollback          Rollback to previous backup
    --list-backups      List available backups
    --debug             Enable debug logging
    --help              Show this help message

Examples:
    ${0}                    # Full installation
    ${0} --rollback         # Rollback to latest backup
    ${0} --debug            # Install with debug output

Documentation:
    ${DOTFILES_DIR}/README.md
    ${DOTFILES_DIR}/SECURITY.md

EOF
}

# Entry point
parse_args "$@"
main
