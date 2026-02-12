#!/usr/bin/env bash
# ============================================================================
# Default Layout - Single pane session
# Usage: ~/.config/tmux/layouts/default.sh [session-name]
# ============================================================================

SESSION_NAME="${1:-main}"

# Attach if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    exec tmux attach -t "$SESSION_NAME"
fi

exec tmux new-session -s "$SESSION_NAME"
