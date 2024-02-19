#!/usr/bin/env zsh

dirs() {
    depth=$1; shift
    fd . "$@" --exact-depth $depth --type d -L
}

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$({ echo ~/dotfiles & dirs 1 ~/repos ~/.config & dirs 2 ~/Documents } | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _ | awk '{ print toupper($0) }')
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

tmux switch-client -t $selected_name
