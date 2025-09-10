#!/usr/bin/env bash

tmux list-sessions -F '#S' | while read -r session; do
    # Skip if the session has an attached client

    if [[ -n $(tmux list-clients -t "$session") ]]; then
        continue
    fi

    active_processes=0

    # Check each pane in the session
    while read -r pid cmd; do
        # If the pane is not just an idle shell, count it as active
        if [[ "$cmd" != "bash" && "$cmd" != "zsh" && "$cmd" != "fish" ]]; then
            active_processes=$((active_processes + 1))

        # Or, if the shell has spawned children (something is running), count it as active
        elif pgrep -P "$pid" > /dev/null; then
            active_processes=$((active_processes + 1))
        fi

    done < <(tmux list-panes -t "$session" -F '#{pane_pid} #{pane_current_command}')

    # Kill session if no active processes found
    if [[ "$active_processes" -eq 0 ]]; then
        echo "Killing idle session: $session" >> /tmp/tmux-session-kill.log
        tmux kill-session -t "$session"
    fi
done
