# ============================================================================
# ts.fish - tmux Sessionizer
# Purpose: Quick project-based tmux session management (like tmux-sessionizer)
# Usage: ts [project_path]
# ============================================================================

function ts --description "tmux Sessionizer - Quick project session management"
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

    # Check if already in tmux
    if test -n "$TMUX"
        # Inside tmux: switch to session or create new one
        if tmux has-session -t "$session_name" 2>/dev/null
            tmux switch-client -t "$session_name"
        else
            tmux new-session -d -s "$session_name" -c "$selected"
            tmux switch-client -t "$session_name"
        end
        return 0
    end

    # Outside tmux: attach or create
    if tmux has-session -t "$session_name" 2>/dev/null
        echo "Attaching to existing session: $session_name"
        tmux attach -t "$session_name"
    else
        echo "Creating new session: $session_name in $selected"
        tmux new-session -s "$session_name" -c "$selected"
    end
end

# ============================================================================
# ts-list - List all tmux sessions
# ============================================================================

function ts-list --description "List all tmux sessions"
    tmux list-sessions 2>/dev/null || echo "No active sessions"
end

# ============================================================================
# ts-kill - Kill a tmux session
# ============================================================================

function ts-kill --description "Kill a tmux session"
    if test (count $argv) -eq 1
        tmux kill-session -t $argv[1]
    else
        # Interactive selection
        set -l session (tmux list-sessions -F '#{session_name}' 2>/dev/null | fzf --header "Select session to kill")
        if test -n "$session"
            tmux kill-session -t "$session"
            echo "Killed session: $session"
        end
    end
end

# ============================================================================
# ts-clean - Kill all tmux sessions except current
# ============================================================================

function ts-clean --description "Kill all tmux sessions except current"
    if test -n "$TMUX"
        # Inside tmux: kill all other sessions
        set -l current (tmux display-message -p '#{session_name}')
        for sess in (tmux list-sessions -F '#{session_name}' 2>/dev/null)
            if test "$sess" != "$current"
                tmux kill-session -t "$sess"
            end
        end
        echo "All other sessions killed (current: $current)"
    else
        # Outside tmux: kill server
        tmux kill-server 2>/dev/null
        echo "All tmux sessions killed"
    end
end

# ============================================================================
# Usage Examples
# ============================================================================
#
# Interactive project selection:
#   ts                    # Opens fzf to select a project
#
# Direct path:
#   ts ~/Projects/myapp   # Creates/attaches to session "myapp"
#
# Session management:
#   ts-list               # List all sessions
#   ts-kill myapp         # Kill specific session
#   ts-kill               # Interactive session kill
#   ts-clean              # Kill all other sessions
#
# ============================================================================
