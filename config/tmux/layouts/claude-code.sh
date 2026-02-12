#!/usr/bin/env bash
# ============================================================================
# Claude Code Layout - AI-Assisted Development Workspace
# Purpose: Optimized layout for Claude Code CLI development workflow
#
# Tab 1 (claude): Editor (55%) | Claude Code (70h%) + Terminal (30h%)
# Tab 2 (research): Research (70%) | Notes (30%)
# Tab 3 (git): Git main (50%) | Git ops (50%)
#
# Usage: ~/.config/tmux/layouts/claude-code.sh [session-name]
#
# Layout (Tab 1):
#   ┌────────────────────┬────────────────┐
#   │                    │                │
#   │                    │  Claude Code   │
#   │                    │  (70%)         │
#   │     Editor         ├────────────────┤
#   │     (55%)          │                │
#   │                    │  Terminal      │
#   │                    │  (30%)         │
#   └────────────────────┴────────────────┘
# ============================================================================

SESSION_NAME="${1:-claude}"

# Attach if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    exec tmux attach -t "$SESSION_NAME"
fi

# --- Tab 1: claude ---
tmux new-session -d -s "$SESSION_NAME" -n claude

# Split right 45%
tmux split-window -h -t "$SESSION_NAME":claude -p 45

# Split bottom-right 30%
tmux split-window -v -t "$SESSION_NAME":claude.1 -p 30

# Launch Claude Code in top-right pane
tmux send-keys -t "$SESSION_NAME":claude.1 "claude" C-m

# Focus editor pane (left)
tmux select-pane -t "$SESSION_NAME":claude.0

# --- Tab 2: research ---
tmux new-window -t "$SESSION_NAME" -n research

# Split bottom 30%
tmux split-window -v -t "$SESSION_NAME":research -p 30

# Focus top pane
tmux select-pane -t "$SESSION_NAME":research.0

# --- Tab 3: git ---
tmux new-window -t "$SESSION_NAME" -n git

# Split right 50%
tmux split-window -h -t "$SESSION_NAME":git -p 50

# Show git status in left pane
tmux send-keys -t "$SESSION_NAME":git.0 "git status && echo '---' && git log --oneline -10" C-m

# Focus tab 1
tmux select-window -t "$SESSION_NAME":claude

exec tmux attach -t "$SESSION_NAME"
