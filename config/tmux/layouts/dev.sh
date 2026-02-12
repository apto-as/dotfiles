#!/usr/bin/env bash
# ============================================================================
# Development Layout - Three-Pane Workspace
# Purpose: Editor (60%) | Terminal (60h%) + Logs (40h%)
# Usage: ~/.config/tmux/layouts/dev.sh [session-name]
#
# Layout:
#   ┌────────────────────┬────────────────┐
#   │                    │                │
#   │                    │   Terminal     │
#   │                    │   (60%)        │
#   │     Editor         ├────────────────┤
#   │     (60%)          │                │
#   │                    │   Logs         │
#   │                    │   (40%)        │
#   └────────────────────┴────────────────┘
# ============================================================================

SESSION_NAME="${1:-dev}"

# Attach if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    exec tmux attach -t "$SESSION_NAME"
fi

tmux new-session -d -s "$SESSION_NAME" -n dev

# Split right 40%
tmux split-window -h -t "$SESSION_NAME":dev -p 40

# Split bottom-right 40%
tmux split-window -v -t "$SESSION_NAME":dev.1 -p 40

# Focus editor pane (left)
tmux select-pane -t "$SESSION_NAME":dev.0

exec tmux attach -t "$SESSION_NAME"
