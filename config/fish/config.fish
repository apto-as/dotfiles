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
alias cc "claude --dangerously-skip-permissions"

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
    echo "ℹ️  Auto-detected MACHINE_TYPE: $MACHINE_TYPE" >&2
end

# Load machine-specific configuration
set MACHINE_CONFIG "$HOME/dotfiles/machines/$MACHINE_TYPE/fish.local.fish"
if test -f $MACHINE_CONFIG
    source $MACHINE_CONFIG
    echo "✓ Loaded machine config: $MACHINE_TYPE" >&2
else
    echo "⚠️  Machine config not found: $MACHINE_CONFIG" >&2
    echo "   Create it with: touch ~/dotfiles/machines/$MACHINE_TYPE/fish.local.fish" >&2
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

oh-my-posh init fish --config /opt/homebrew/opt/oh-my-posh/themes/tsuyoshi.omp.json | source

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /Users/apto-as/miniforge3/bin/conda
    eval /Users/apto-as/miniforge3/bin/conda "shell.fish" hook $argv | source
else
    if test -f "/Users/apto-as/miniforge3/etc/fish/conf.d/conda.fish"
        . "/Users/apto-as/miniforge3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH /Users/apto-as/miniforge3/bin $PATH
    end
end
# <<< conda initialize <<<

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/apto-as/.cache/lm-studio/bin
fish_add_path /Users/apto-as/.pixi/bin

# Added by Windsurf
fish_add_path /Users/apto-as/.codeium/windsurf/bin

# bun
set -gx BUN_INSTALL "$HOME/.bun"
set -gx PATH $BUN_INSTALL/bin $PATH

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

echo "✓ Trinitas v2.2.1 context management loaded (profile: $TRINITAS_CONTEXT_PROFILE)"

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

echo "✓ Open Code v2.2.1 context management loaded (profile: $OPENCODE_CONTEXT_PROFILE)"
