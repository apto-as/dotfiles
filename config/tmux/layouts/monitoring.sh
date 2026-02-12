#!/usr/bin/env bash
# ============================================================================
# Monitoring Layout - Four-Pane System Dashboard
# Purpose: Real-time system monitoring (2x2 grid)
# Usage: ~/.config/tmux/layouts/monitoring.sh [session-name]
#
# Layout:
#   ┌──────────────────┬──────────────────┐
#   │                  │                  │
#   │   Resources      │    Network       │
#   │   (htop/top)     │   (netstat)      │
#   ├──────────────────┼──────────────────┤
#   │                  │                  │
#   │   Disk/Memory    │     Logs         │
#   │   (df/free)      │   (tail -f)      │
#   └──────────────────┴──────────────────┘
# ============================================================================

SESSION_NAME="${1:-monitor}"

# Attach if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    exec tmux attach -t "$SESSION_NAME"
fi

tmux new-session -d -s "$SESSION_NAME" -n monitor

# Split right 50%
tmux split-window -h -t "$SESSION_NAME":monitor -p 50

# Split bottom-left 50%
tmux split-window -v -t "$SESSION_NAME":monitor.0 -p 50

# Split bottom-right 50%
tmux split-window -v -t "$SESSION_NAME":monitor.1 -p 50

# Focus top-left (resources)
tmux select-pane -t "$SESSION_NAME":monitor.0

exec tmux attach -t "$SESSION_NAME"
