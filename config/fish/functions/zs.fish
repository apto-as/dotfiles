# ============================================================================
# zs.fish - Zellij Sessionizer
# Purpose: Quick project-based Zellij session management (like tmux-sessionizer)
# Usage: zs [project_path]
# Author: Trinitas System (Clotho + Lachesis)
# ============================================================================

function zs --description "Zellij Sessionizer - Quick project session management"
    # If a directory is provided, use it; otherwise, use fzf to select
    set -l selected

    if test (count $argv) -eq 1
        set selected $argv[1]
    else
        # Project directories to search
        set -l search_dirs \
            ~/Projects \
            ~/Work \
            ~/dotfiles \
            ~/.config

        # Filter existing directories
        set -l existing_dirs
        for dir in $search_dirs
            if test -d $dir
                set -a existing_dirs $dir
            end
        end

        # Use fd if available, fallback to find
        if command -q fd
            set selected (fd --type d --max-depth 2 --hidden --exclude .git . $existing_dirs 2>/dev/null | fzf \
                --header "Select Project Directory" \
                --preview "ls -la {}" \
                --preview-window right:40% \
                --bind "ctrl-d:preview-down,ctrl-u:preview-up")
        else if command -q fzf
            set selected (find $existing_dirs -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf \
                --header "Select Project Directory" \
                --preview "ls -la {}" \
                --preview-window right:40%)
        else
            echo "Error: fzf is required for interactive selection"
            echo "Install with: brew install fzf"
            return 1
        end
    end

    # Exit if no selection
    if test -z "$selected"
        return 0
    end

    # Validate selected directory
    if not test -d "$selected"
        echo "Error: Directory does not exist: $selected"
        return 1
    end

    # Generate session name from directory name
    set -l session_name (basename "$selected" | string replace -a '.' '_' | string replace -a ' ' '-')

    # Check if already in Zellij
    if test -n "$ZELLIJ"
        echo "Already inside Zellij. Use 'zellij attach $session_name' to switch sessions."
        return 0
    end

    # Check if session exists
    set -l existing_sessions (zellij list-sessions 2>/dev/null | string match -r '^\S+')

    if contains $session_name $existing_sessions
        # Attach to existing session
        echo "Attaching to existing session: $session_name"
        zellij attach $session_name
    else
        # Create new session in the selected directory
        echo "Creating new session: $session_name in $selected"
        cd "$selected"
        zellij --session $session_name
    end
end

# ============================================================================
# zs-list - List all Zellij sessions
# ============================================================================

function zs-list --description "List all Zellij sessions"
    zellij list-sessions 2>/dev/null || echo "No active sessions"
end

# ============================================================================
# zs-kill - Kill a Zellij session
# ============================================================================

function zs-kill --description "Kill a Zellij session"
    if test (count $argv) -eq 1
        zellij kill-session $argv[1]
    else
        # Interactive selection
        set -l session (zellij list-sessions 2>/dev/null | fzf --header "Select session to kill")
        if test -n "$session"
            set -l session_name (echo $session | awk '{print $1}')
            zellij kill-session $session_name
            echo "Killed session: $session_name"
        end
    end
end

# ============================================================================
# zs-clean - Kill all detached Zellij sessions
# ============================================================================

function zs-clean --description "Kill all detached Zellij sessions"
    zellij kill-all-sessions --yes 2>/dev/null
    echo "All detached sessions have been killed"
end

# ============================================================================
# Usage Examples
# ============================================================================
#
# Interactive project selection:
#   zs                    # Opens fzf to select a project
#
# Direct path:
#   zs ~/Projects/myapp   # Creates/attaches to session "myapp"
#
# Session management:
#   zs-list               # List all sessions
#   zs-kill myapp         # Kill specific session
#   zs-kill               # Interactive session kill
#   zs-clean              # Kill all detached sessions
#
# ============================================================================
