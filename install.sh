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
source "${LIB_DIR}/versions.sh"
source "${LIB_DIR}/pkg.sh"

# Source installers
source "${INSTALLERS_DIR}/homebrew.sh"
source "${INSTALLERS_DIR}/fonts.sh"
source "${INSTALLERS_DIR}/wezterm.sh"
source "${INSTALLERS_DIR}/zellij.sh"
source "${INSTALLERS_DIR}/tmux.sh"
source "${INSTALLERS_DIR}/neovim.sh"
source "${INSTALLERS_DIR}/fish.sh"
source "${INSTALLERS_DIR}/tools.sh"
source "${INSTALLERS_DIR}/node.sh"
source "${INSTALLERS_DIR}/golang.sh"
source "${INSTALLERS_DIR}/rust.sh"
source "${INSTALLERS_DIR}/conda.sh"
source "${INSTALLERS_DIR}/ohmyposh.sh"
source "${INSTALLERS_DIR}/docker.sh"
source "${INSTALLERS_DIR}/claude-code.sh"
source "${INSTALLERS_DIR}/opencode.sh"

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
    log_info "[Phase 1/8] System Validation"
    check_dependencies
    export_system_info
    display_system_info

    # Prefetch versions in background (parallel optimization)
    log_info "Prefetching latest tool versions..."
    prefetch_versions &
    local prefetch_pid=$!
    echo ""

    # Phase 2: Backup existing configs
    log_info "[Phase 2/8] Backup Existing Configurations"
    backup_existing_configs
    echo ""

    # Phase 3: Install Homebrew (macOS) / apt update (Ubuntu)
    log_info "[Phase 3/8] Install Package Manager"
    install_homebrew
    configure_homebrew
    echo ""

    # Phase 4: Install dependencies (parallel where possible)
    log_info "[Phase 4/8] Install Core Dependencies"

    # Ensure version prefetch is complete before installations
    wait "${prefetch_pid}" 2>/dev/null || true
    log_debug "Version cache ready: NVM=$(get_latest_nvm_version), Go=$(get_latest_go_version)"

    # Phase 4a: Core tools and shell (parallel)
    install_fonts &
    local fonts_pid=$!

    install_wezterm &
    local wezterm_pid=$!

    install_zellij &
    local zellij_pid=$!

    install_tmux &
    local tmux_pid=$!

    install_neovim &
    local neovim_pid=$!

    install_fish &
    local fish_pid=$!

    install_tools &
    local tools_pid=$!

    # Wait for core tools
    wait $fonts_pid && log_success "Fonts installed" || log_warn "Fonts installation had issues"
    wait $wezterm_pid && log_success "Wezterm installed" || log_warn "Wezterm installation had issues"
    wait $zellij_pid && log_success "Zellij installed" || log_warn "Zellij installation had issues"
    wait $tmux_pid && log_success "tmux installed" || log_warn "tmux installation had issues"
    wait $neovim_pid && log_success "Neovim installed" || log_warn "Neovim installation had issues"
    wait $fish_pid && log_success "Fish shell installed" || log_warn "Fish installation had issues"
    wait $tools_pid && log_success "Tools installed" || log_warn "Tools installation had issues"
    echo ""

    # Phase 5: Install development languages (parallel)
    log_info "[Phase 5/8] Install Development Languages"

    install_node &
    local node_pid=$!

    install_golang &
    local golang_pid=$!

    install_rust &
    local rust_pid=$!

    install_conda &
    local conda_pid=$!

    # Wait for language installations
    wait $node_pid && log_success "Node.js (NVM) installed" || log_warn "Node.js installation had issues"
    wait $golang_pid && log_success "Go installed" || log_warn "Go installation had issues"
    wait $rust_pid && log_success "Rust installed" || log_warn "Rust installation had issues"
    wait $conda_pid && log_success "Miniforge3 installed" || log_warn "Conda installation had issues"
    echo ""

    # Phase 6: Install additional tools (parallel)
    log_info "[Phase 6/8] Install Additional Tools"

    install_ohmyposh &
    local ohmyposh_pid=$!

    install_docker &
    local docker_pid=$!

    # Wait for additional tools
    wait $ohmyposh_pid && log_success "oh-my-posh installed" || log_warn "oh-my-posh installation had issues"
    wait $docker_pid && log_success "Docker installed" || log_warn "Docker installation had issues"

    # Install AI coding assistants (requires Node.js, so sequential after Phase 5)
    install_claude_code && log_success "Claude Code installed" || log_warn "Claude Code installation had issues"
    install_opencode && log_success "Open Code installed" || log_warn "Open Code installation had issues"
    echo ""

    # Phase 7: Setup configurations (symlinks)
    log_info "[Phase 7/8] Setup Configurations"
    setup_symlinks
    setup_machine_specific_configs
    configure_zellij  # Initialize Zellij directories
    configure_tmux    # Initialize tmux directories and TPM
    configure_fish    # Setup Fish shell configurations
    add_fish_to_shells
    echo ""

    # Phase 8: Verification
    log_info "[Phase 8/8] Verification"
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
        "${HOME}/.config/zellij"
        "${HOME}/.config/tmux"
    )

    backup_batch "${configs[@]}"
}

# Setup symlinks for all configurations
setup_symlinks() {
    local -a symlink_mappings=(
        "${DOTFILES_DIR}/config/nvim:${HOME}/.config/nvim"
        "${DOTFILES_DIR}/config/wezterm:${HOME}/.config/wezterm"
        "${DOTFILES_DIR}/config/zellij:${HOME}/.config/zellij"
        "${DOTFILES_DIR}/config/tmux:${HOME}/.config/tmux"
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

    # Verify core commands
    verify_wezterm || ((errors++))
    verify_zellij || ((errors++))
    verify_tmux || ((errors++))
    verify_neovim || ((errors++))
    verify_fish || ((errors++))
    verify_fonts || ((errors++))
    verify_tools || ((errors++))

    # Verify development languages
    verify_node || log_warn "Node.js verification skipped"
    verify_golang || log_warn "Go verification skipped"
    verify_rust || log_warn "Rust verification skipped"
    verify_conda || log_warn "Conda verification skipped"

    # Verify additional tools
    verify_ohmyposh || log_warn "oh-my-posh verification skipped"
    verify_docker || log_warn "Docker verification skipped"
    verify_claude_code || log_warn "Claude Code verification skipped"
    verify_opencode || log_warn "Open Code verification skipped"

    # Verify symlinks
    local -a symlink_mappings=(
        "${DOTFILES_DIR}/config/nvim:${HOME}/.config/nvim"
        "${DOTFILES_DIR}/config/wezterm:${HOME}/.config/wezterm"
        "${DOTFILES_DIR}/config/zellij:${HOME}/.config/zellij"
        "${DOTFILES_DIR}/config/tmux:${HOME}/.config/tmux"
    )

    verify_symlinks "${symlink_mappings[@]}" || ((errors++))

    # Verify Zellij security
    verify_zellij_security || {
        log_error "Zellij security verification failed"
        ((errors++))
    }

    # Verify tmux security
    verify_tmux_security || {
        log_error "tmux security verification failed"
        ((errors++))
    }

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
    echo "  2. (Optional) Set Fish as default shell: chsh -s \$(which fish)"
    echo "  3. Configure API keys in ~/.secure_credentials/api_keys.env (see example file)"
    echo "  4. Open Wezterm to see the new configuration"
    echo "  5. Launch Zellij: zellij (or press Ctrl+a z in Wezterm)"
    echo "  6. Open Neovim to trigger LazyVim bootstrap: nvim"
    echo "  7. (Optional) Start Docker Desktop (macOS) or enable Docker service (Linux)"
    echo "  8. (Optional) Configure Claude Code: claude config"
    echo ""
    log_info "Configuration locations:"
    echo "  • Dotfiles: ${DOTFILES_DIR}"
    echo "  • Neovim: ~/.config/nvim -> ${DOTFILES_DIR}/config/nvim"
    echo "  • Wezterm: ~/.config/wezterm -> ${DOTFILES_DIR}/config/wezterm"
    echo "  • Zellij: ~/.config/zellij -> ${DOTFILES_DIR}/config/zellij"
    echo "  • Fish: ~/.config/fish/config.fish -> ${DOTFILES_DIR}/config/fish/config.fish"
    echo "  • Claude Code: ~/.claude/"
    echo "  • Open Code: ~/.config/opencode/"
    echo "  • Credentials: ~/.secure_credentials/ (chmod 700)"
    echo "  • Backup: ${BACKUP_DIR}/${BACKUP_TIMESTAMP}"
    echo ""
    log_info "Installed Development Tools:"
    echo "  • Languages: Node.js (nvm), Go, Rust, Python (conda/miniforge)"
    echo "  • Containers: Docker"
    echo "  • AI Assistants: Claude Code, Open Code"
    echo "  • Shell: Fish, oh-my-posh, zoxide, fzf"
    echo ""
    log_info "Useful commands:"
    echo "  • Update dotfiles: ${DOTFILES_DIR}/update.sh"
    echo "  • List backups: ${DOTFILES_DIR}/install.sh --list-backups"
    echo "  • Rollback: ${DOTFILES_DIR}/install.sh --rollback"
    echo "  • Launch Zellij: zellij"
    echo "  • Start Claude Code: claude"
    echo "  • Activate conda: conda activate <env>"
    echo "  • Node version: nvm use <version>"
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
