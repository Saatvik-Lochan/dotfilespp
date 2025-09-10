#!/usr/bin/env bash

# First we get the current tmux session
current_session=$(tmux display-message -p '#{session_name}' || echo "main")
current_path=$(tmux display-message -p -F "#{pane_current_path}" || echo "/home/saatvikl")

increment_string() {
    local str="$1"

    if [[ "$str" =~ (.*)\+([0-9]+)$ ]]; then
        local prefix="${BASH_REMATCH[1]}"
        local num="${BASH_REMATCH[2]}"

        # Increment the number
        local new_num=$((10#$num + 1))
    else
        local prefix="${str}"
        local new_num="1"
    fi

    while tmux has-session -t "${prefix}+${new_num}" 2>/dev/null; do
        ((new_num++))
    done

    echo "$prefix+$new_num"
}

new_session=$(increment_string $current_session)
exec tmux new -s "$new_session" -c "$current_path"

