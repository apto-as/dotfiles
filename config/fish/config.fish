# ============================================================================
# Environment Variables
# ============================================================================
set -gx EDITOR nvim
set -x LANG ja_JP.UTF-8
set -gx PYTORCH_ENABLE_MPS_FALLBACK 1

# ============================================================================
# PATH Configuration (Artemis Optimization - 2025-11-13)
# ============================================================================
# Using fish_add_path for proper PATH management:
# - Automatically prevents duplicates
# - Maintains correct order
# - More efficient than manual PATH manipulation
#
# ❌ REMOVED: Relative "bin" path (security risk)
# ❌ OLD: set -gx PATH bin $PATH

# User binaries (highest priority)
fish_add_path -p $HOME/.local/bin
fish_add_path -p $HOME/bin

# Rust toolchain
fish_add_path -a $HOME/.cargo/bin

# API KEY
# ⚠️ SECURITY: API keys moved to secure storage (Hestia Security Audit 2025-11-13)
# Load credentials: load_all_credentials
# See: ~/.config/fish/conf.d/secure_credentials.fish
#
# Option 1 (Recommended): Use 1Password CLI
#   brew install 1password-cli
#   op item create --category=login --title="Gemini API Key" credential=your-key-here
#
# Option 2: Use secure local file (gitignored)
#   cp ~/.secure_credentials/api_keys.env.example ~/.secure_credentials/api_keys.env
#   chmod 600 ~/.secure_credentials/api_keys.env
#   # Edit api_keys.env with real keys

# SEARCH ENGINE API KEY
# ⚠️ SECURITY: Moved to secure storage (Hestia Security Audit 2025-11-13)
# See: SECURITY_CREDENTIALS_GUIDE.md

# AWS CLI
set -x AWS_PROFILE aws-mcp-admin-agents

# NVM
function __check_rvm --on-variable PWD --description 'Do nvm stuff'
    status --is-command-substitution; and return

    if test -f .nvmrc; and test -r .nvmrc
        nvm use lts
    else
    end
end

# alias
alias ls "exa -ahl"
alias la "exa -ahl --git --icons"
alias vim nvim

# ⚠️ SECURITY WARNING: This alias bypasses Claude Code's permission system
# Only use for trusted operations in controlled environments
# Renamed from 'cc' to 'cc-unsafe' per Hestia security audit (2025-12-18)
alias cc-unsafe "claude --dangerously-skip-permissions"

# Safe Claude Code alias (recommended for normal use)
alias cc "claude"

# Zellij quick launch aliases (Trinitas 2025-12-18)
alias zcc "zellij --layout claude-code"  # Claude Code development layout
alias zdev "zellij --layout dev"          # Standard development layout

#-----------
# exa config and function
#-----------
function cd
    if test (count $argv) -eq 0
        cd $HOME
        return 0
    else if test (count $argv) -gt 1
        printf "%s\n" (_ "Too many args for cd command")
        return 1
    end
    # Avoid set completions.
    set -l previous $PWD

    if test "$argv" = -
        if test "$__fish_cd_direction" = next
            nextd
        else
            prevd
        end
        return $status
    end
    builtin cd $argv
    set -l cd_status $status
    # Log history
    if test $cd_status -eq 0 -a "$PWD" != "$previous"
        set -q dirprev[$MAX_DIR_HIST] and set -e dirprev[1]
        set -g dirprev $dirprev $previous
        set -e dirnext
        set -g __fish_cd_direction prev
    end

    if test $cd_status -ne 0
        return 1
    end
    pwd
    exa -ahl --git --icons
    return $status
end

# FZF OPTIONS
function fzf
    command fzf --height 30% --reverse --border $argv
end

# ============================================================================
# OS-Specific Configuration (Legacy Support)
# ============================================================================
# Load OS-specific config files for backward compatibility with existing setup
# IMPORTANT: This must be loaded BEFORE dotfiles machine-specific config
#            to allow machine configs to override OS-level settings

switch (uname)
    case Darwin
        # macOS-specific configuration (Homebrew environment variables, etc.)
        set os_config (dirname (status --current-filename))/config-osx.fish
        if test -f $os_config
            source $os_config
        else if test -f ~/.config/fish/config-osx.fish
            # Fallback to ~/.config/fish/ location
            source ~/.config/fish/config-osx.fish
        end
    case Linux
        # Linux-specific configuration (if needed)
        set os_config (dirname (status --current-filename))/config-linux.fish
        if test -f $os_config
            source $os_config
        end
    case '*'
        # Windows or other OS
        set os_config (dirname (status --current-filename))/config-windows.fish
        if test -f $os_config
            source $os_config
        end
end

# ============================================================================
# Machine-Specific Configuration (Dotfiles Integration)
# ============================================================================
# Load machine-specific Fish config from dotfiles/machines/{MACHINE_TYPE}/
#
# Setup Instructions:
#   1. Set MACHINE_TYPE environment variable (e.g., "macbook", "macmini", "ec2")
#   2. Create ~/dotfiles/machines/{MACHINE_TYPE}/fish.local.fish
#   3. Symlink this config to ~/.config/fish/config.fish
#
# Example:
#   export MACHINE_TYPE="macbook"  # Add to ~/.zshrc or ~/.bashrc

# Detect machine type (fallback to hostname-based detection)
if not set -q MACHINE_TYPE
    # Auto-detect from hostname
    set detected_hostname (hostname -s)
    switch $detected_hostname
        case 'Mac' '*9dw-main01*' '*macbookpro*' '*MacBookPro*' '*m3max*'
            # Specific hostname "Mac" or full "9dw-main01-m3max-macbookpro" → macbook
            set -gx MACHINE_TYPE "macbook"
        case '*macbook*' '*MacBook*'
            set -gx MACHINE_TYPE "macbook"
        case '*macmini*' '*MacMini*'
            set -gx MACHINE_TYPE "macmini"
        case '*ec2*' '*aws*' '*ip-*'
            set -gx MACHINE_TYPE "ec2"
        case '*'
            # Default: detect by OS
            switch (uname)
                case Darwin
                    set -gx MACHINE_TYPE "macos"
                case Linux
                    set -gx MACHINE_TYPE "linux"
                case '*'
                    set -gx MACHINE_TYPE "unknown"
            end
    end
    # Only show auto-detection message in interactive mode (not in scripts/Zellij startup)
    if status is-interactive; and not set -q FISH_STARTUP_QUIET
        echo "ℹ️  Auto-detected MACHINE_TYPE: $MACHINE_TYPE" >&2
    end
end

# Load machine-specific configuration
set MACHINE_CONFIG "$HOME/dotfiles/machines/$MACHINE_TYPE/fish.local.fish"
if test -f $MACHINE_CONFIG
    source $MACHINE_CONFIG
    # Only show success message in interactive mode
    if status is-interactive; and not set -q FISH_STARTUP_QUIET
        echo "✓ Loaded machine config: $MACHINE_TYPE" >&2
    end
else
    # Only show warning in truly interactive sessions (first terminal window)
    if status is-interactive; and not set -q FISH_STARTUP_QUIET; and not set -q ZELLIJ
        echo "⚠️  Machine config not found: $MACHINE_CONFIG" >&2
        echo "   Create it with: touch ~/dotfiles/machines/$MACHINE_TYPE/fish.local.fish" >&2
    end
end

# Terminal Integration (Artemis Technical Fix - 2025-11-13)
# ❌ iTerm2 integration removed (using Wezterm)
# source ~/.iterm2_shell_integration.fish

# Wezterm Integration
# Wezterm supports OSC sequences natively, no additional shell integration needed.
# See: https://wezfurlong.org/wezterm/shell-integration.html
#
# Optional: Enable semantic prompt for better navigation
# printf "\033]133;A\007"  # Mark prompt start

# ============================================================================
# tmux Integration (TPM - Tmux Plugin Manager)
# ============================================================================
# Ensure TPM (Tmux Plugin Manager) binaries are accessible
# TPM is installed at ~/.tmux/plugins/tpm
# Configuration: ~/.tmux.conf, ~/.tmux.conf.osx, ~/.tmux.conf.powerline
#
# Usage:
#   - Install plugins: Ctrl+b I (in tmux session)
#   - Update plugins: Ctrl+b U
#   - Remove plugins: Ctrl+b alt+u
#
# Note: tmux configuration is sourced by tmux itself, not by Fish shell.
# This section only ensures TPM utilities are in PATH if needed.

if test -d "$HOME/.tmux/plugins/tpm/bin"
    # Add TPM binaries to PATH (for manual plugin management if needed)
    fish_add_path "$HOME/.tmux/plugins/tpm/bin"
end

# Optional: Auto-attach to tmux session on terminal startup
# Uncomment the following if you want automatic tmux session management
#
# if not set -q TMUX; and not set -q ZELLIJ
#     # Not already in tmux or Zellij
#     if command -v tmux &> /dev/null
#         # Check if any tmux sessions exist
#         if tmux has-session 2>/dev/null
#             # Attach to existing session
#             exec tmux attach-session
#         else
#             # Create new session
#             exec tmux new-session
#         end
#     end
# end

# ============================================================================
# Prompt Configuration - oh-my-posh (default) with Starship fallback
# ============================================================================
# Toggle between oh-my-posh and Starship:
#   set -gx USE_STARSHIP 1  # Use Starship (experimental)
#   set -e USE_STARSHIP     # Use oh-my-posh (default)
#
# Theme configuration (set in machine-specific config if needed):
#   set -gx OMP_THEME_PATH "/path/to/theme.omp.json"
# ============================================================================

if set -q USE_STARSHIP
    # Experimental: Starship (Rust-based, ~8.1ms render time)
    if command -q starship
        set -x STARSHIP_CONFIG ~/.config/starship/dracula.toml
        starship init fish | source
    end
else
    # Default: oh-my-posh (Go-based, proven design)
    if command -q oh-my-posh
        # Use custom theme path if set, otherwise try common locations
        if not set -q OMP_THEME_PATH
            # Try common theme locations
            for theme_path in \
                /opt/homebrew/opt/oh-my-posh/themes/tsuyoshi.omp.json \
                /usr/local/opt/oh-my-posh/themes/tsuyoshi.omp.json \
                ~/.config/oh-my-posh/themes/tsuyoshi.omp.json \
                ~/.poshthemes/tsuyoshi.omp.json
                if test -f $theme_path
                    set -gx OMP_THEME_PATH $theme_path
                    break
                end
            end
        end

        if set -q OMP_THEME_PATH; and test -f $OMP_THEME_PATH
            oh-my-posh init fish --config $OMP_THEME_PATH | source
        else
            # Fallback to built-in theme if no custom theme found
            oh-my-posh init fish | source
        end
    end
end

# ============================================================================
# Tool PATH Configuration (Portable - uses $HOME)
# ============================================================================
# These paths use $HOME for portability across machines
# Machine-specific tools (conda, etc.) are configured in:
#   machines/{MACHINE_TYPE}/fish.local.fish

# Common development tools (if installed)
# These only add to PATH if the directory exists
for tool_path in \
    $HOME/.cache/lm-studio/bin \
    $HOME/.pixi/bin \
    $HOME/.codeium/windsurf/bin \
    $HOME/.bun/bin
    if test -d $tool_path
        fish_add_path -a $tool_path
    end
end

# Bun environment variable (if installed)
if test -d "$HOME/.bun"
    set -gx BUN_INSTALL "$HOME/.bun"
end

# ============================================================
# Trinitas v2.2.1 Context Profile Management
# ============================================================

# デフォルトプロファイル: coding
if not set -q TRINITAS_CONTEXT_PROFILE
    set -gx TRINITAS_CONTEXT_PROFILE coding
end

# プロファイル切り替え関数
function trinitas-context
    if test (count $argv) -eq 0
        echo "📊 Current Trinitas Context Profile: $TRINITAS_CONTEXT_PROFILE"
        echo ""
        echo "Available profiles:"
        echo "  minimal  - Core + agents only (4.5k tokens)"
        echo "  coding   - + performance, mcp-tools (9.5k tokens) [DEFAULT]"
        echo "  security - + security, tmws (11.5k tokens)"
        echo "  full     - All contexts (18.5k tokens)"
        echo ""
        echo "Usage: trinitas-context <profile_name>"
        echo "Alias: tc <profile_name>"
        return
    end

    set profile $argv[1]

    switch $profile
        case minimal coding security full
            set -gx TRINITAS_CONTEXT_PROFILE $profile
            echo "✓ Trinitas context profile switched to: $profile"
            echo "  Restart Claude Code for changes to take effect"
        case '*'
            echo "✗ Invalid profile: $profile"
            echo "  Valid profiles: minimal, coding, security, full"
            return 1
    end
end

# エイリアス
alias tc='trinitas-context'

# Only show load message in interactive mode
if status is-interactive; and not set -q FISH_STARTUP_QUIET
    echo "✓ Trinitas v2.2.1 context management loaded (profile: $TRINITAS_CONTEXT_PROFILE)"
end

# Open Code Memory Cookbook Context Management (v2.2.1)
if not set -q OPENCODE_CONTEXT_PROFILE
    set -gx OPENCODE_CONTEXT_PROFILE coding
end

function opencode-context
    if test (count $argv) -eq 0
        echo "📊 Current Open Code Context Profile: $OPENCODE_CONTEXT_PROFILE"
        echo ""
        echo "Available profiles:"
        echo "  minimal  - Core + agents only (~2.8k tokens)"
        echo "  coding   - + performance, mcp-tools (~5.7k tokens) [DEFAULT]"
        echo "  security - + security, tmws (~9.9k tokens)"
        echo "  full     - All contexts (~15.5k tokens)"
        echo ""
        echo "Usage: opencode-context <profile_name>"
        echo "Alias: oc <profile_name>"
        return
    end

    set profile $argv[1]

    switch $profile
        case minimal coding security full
            set -gx OPENCODE_CONTEXT_PROFILE $profile
            echo "✓ Open Code context profile switched to: $profile"
            echo "  Restart Open Code for changes to take effect"
        case '*'
            echo "✗ Invalid profile: $profile"
            echo "  Valid profiles: minimal, coding, security, full"
            return 1
    end
end

# エイリアス
alias oc='opencode-context'

# Only show load message in interactive mode
if status is-interactive; and not set -q FISH_STARTUP_QUIET
    echo "✓ Open Code v2.2.1 context management loaded (profile: $OPENCODE_CONTEXT_PROFILE)"
end
