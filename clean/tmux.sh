#!/bin/bash

SESSION_NAME="$1"

if [ -z "$SESSION_NAME" ]; then
    echo "Usage: $0 <session-name>"
    exit 1
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists. Aborting."
    exit 1
fi

# Start new detached session
tmux new-session -d -s "$SESSION_NAME"

# Vertical split (right)
tmux split-window -h -t "$SESSION_NAME":0

# Select left pane and split it horizontally
tmux select-pane -t "$SESSION_NAME":0.0
tmux split-window -v -t "$SESSION_NAME":0.0

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
