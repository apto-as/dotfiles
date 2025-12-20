#!/usr/bin/env bash
# ============================================================================
# installers/claude-code.sh - Claude Code CLI
# Purpose: Install Claude Code (Anthropic's official CLI for Claude)
# Platforms: macOS, Ubuntu (requires Node.js/npm)
# ============================================================================

# ============================================================================
# Main Installation
# ============================================================================

install_claude_code() {
    log_info "Installing Claude Code..."

    # Check prerequisites
    if ! check_claude_code_prerequisites; then
        return 1
    fi

    # Install Claude Code via npm
    install_claude_code_npm

    # Setup configuration directory
    setup_claude_code_config

    log_success "Claude Code installation complete"
}

# ============================================================================
# Prerequisites Check
# ============================================================================

check_claude_code_prerequisites() {
    log_info "Checking Claude Code prerequisites..."

    # Check Node.js
    if ! command_exists node; then
        log_error "Node.js is required to install Claude Code"
        log_info "Please run: install_node first"
        return 1
    fi

    # Check npm
    if ! command_exists npm; then
        log_error "npm is required to install Claude Code"
        return 1
    fi

    log_debug "Prerequisites met: Node.js $(node --version), npm $(npm --version)"
    return 0
}

# ============================================================================
# npm Installation
# ============================================================================

install_claude_code_npm() {
    if command_exists claude; then
        log_debug "Claude Code already installed"
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        log_info "Claude Code version: ${version}"

        # Update to latest
        log_info "Updating Claude Code to latest version..."
        npm update -g @anthropic-ai/claude-code
        return 0
    fi

    log_info "Installing Claude Code via npm..."

    # Install globally via npm
    npm install -g @anthropic-ai/claude-code

    # Verify installation
    if command_exists claude; then
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        log_success "Claude Code installed: ${version}"
    else
        log_error "Claude Code installation failed"
        return 1
    fi
}

# ============================================================================
# Configuration Setup
# ============================================================================

setup_claude_code_config() {
    log_info "Setting up Claude Code configuration..."

    local config_dir="${HOME}/.claude"

    # Create config directory if it doesn't exist
    if [[ ! -d "${config_dir}" ]]; then
        mkdir -p "${config_dir}"
        log_debug "Created config directory: ${config_dir}"
    fi

    # Note: CLAUDE.md and other config files should be symlinked from dotfiles
    # This is handled in the main install.sh symlink setup

    log_success "Claude Code configuration directory ready: ${config_dir}"
}

# ============================================================================
# Verification
# ============================================================================

verify_claude_code() {
    local errors=0

    # Check claude command
    if command_exists claude; then
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        log_success "Claude Code installed: ${version}"
    else
        log_error "Claude Code not found"
        ((errors++))
    fi

    # Check config directory
    if [[ -d "${HOME}/.claude" ]]; then
        log_success "Config directory exists: ~/.claude"
    else
        log_warn "Config directory not found"
    fi

    # Check for CLAUDE.md
    if [[ -f "${HOME}/.claude/CLAUDE.md" ]]; then
        log_success "CLAUDE.md found"
    else
        log_warn "CLAUDE.md not found (optional custom instructions)"
    fi

    return "${errors}"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Update Claude Code
update_claude_code() {
    log_info "Updating Claude Code..."

    if ! command_exists npm; then
        log_error "npm is required to update Claude Code"
        return 1
    fi

    npm update -g @anthropic-ai/claude-code

    if command_exists claude; then
        log_success "Claude Code updated to: $(claude --version 2>/dev/null)"
    fi
}

# Show Claude Code version info
claude_code_info() {
    echo "Claude Code Information:"
    echo "========================"

    if command_exists claude; then
        echo "Version: $(claude --version 2>/dev/null)"
        echo "Location: $(which claude)"
        echo ""
        echo "Configuration:"
        echo "  Directory: ~/.claude"

        if [[ -f "${HOME}/.claude/CLAUDE.md" ]]; then
            echo "  CLAUDE.md: Found"
        else
            echo "  CLAUDE.md: Not found"
        fi

        if [[ -d "${HOME}/.claude/commands" ]]; then
            echo "  Custom commands: $(ls -1 "${HOME}/.claude/commands" 2>/dev/null | wc -l)"
        fi
    else
        echo "Claude Code is not installed"
    fi
}

# Export functions
export -f install_claude_code check_claude_code_prerequisites install_claude_code_npm
export -f setup_claude_code_config verify_claude_code update_claude_code claude_code_info
