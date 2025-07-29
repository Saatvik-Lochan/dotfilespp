#!/bin/bash

# Loop through each tmux session
tmux list-sessions -F '#S' | while read -r session; do
    # Check if the session is attached to any clients
    if [[ $(tmux list-clients) ]]; then
        # Get all PIDs in this session's panes
        pids=$(tmux list-panes -t "$session" -F '#{pane_pid}')
        active_processes=0

        # For each PID, check if it has any child processes (i.e., user-launched)
        for pid in $pids; do
            # Count children (excluding tmux's own shell)
            if pgrep -P "$pid" > /dev/null; then
                active_processes=$((active_processes + 1))
            fi
        done

        # If no active processes found, kill the session
        if [[ "$active_processes" -eq 0 ]]; then
            echo "Killing idle session: $session" >> /tmp/tmux-session-kill.log
            tmux kill-session -t "$session"
        fi
    fi
done
