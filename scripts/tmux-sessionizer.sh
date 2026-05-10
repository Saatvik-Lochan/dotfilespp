#!/usr/bin/env zsh

# tmux-sessionizer
# ----------------
# Directory-rooted tmux session manager.
#
# Core idea:
#   The real identity of a session is not its tmux name; it is the canonical
#   project/root path stored in the tmux session environment variable:
#
#       TMUX_SESSIONIZER_DIR=/canonical/root/path
#
#   Session names are only display labels. They are chosen to be short and
#   vaguely identifiable, but they are not semantic state and are never renamed
#   retroactively.
#
# Public commands:
#   pick
#       Fuzzy-pick a project path.
#       Enter  -> open <path>
#       Ctrl-y -> new <path>
#
#   open <path>
#       Canonicalize path with realpath.
#       If no sessions exist for that root, create one.
#       If one exists, switch to it.
#       If multiple exist, show the session picker.
#
#   new <path>
#       Always create a new session associated with that canonical root.
#
#   sessions
#       Show the session picker over all sessionizer-managed sessions.
#
#   list <path>
#       Print session names associated with the canonical root, one per line.
#
#   path [session]
#       Print TMUX_SESSIONIZER_DIR for the given session, or for the current
#       tmux session if omitted.
#
# Session picker:
#   Rows are:
#       SESSION_NAME    ACTIVE_COMMAND    ROOT_PATH
#
#   Enter  -> switch to hovered session
#   Ctrl-x -> kill hovered session and reload picker
#
#   Preview is the active pane capture of the hovered session.
#
# Naming algorithm for newly-created sessions:
#   - Generate suffix names from path components, shortest first.
#     Example: /home/saatvikl/a/foo -> FOO, A_FOO, HOME_A_FOO, ...
#   - If a candidate is used by a different root, try a longer suffix.
#   - If a candidate is free, use it.
#   - If a candidate is already used by the same root, use candidate+N.
#   - If candidate+1 exists but candidate is free, candidate may be used;
#     +N has no semantic meaning.
#
# Internal commands:
#   __rows-path <path>, __rows-all
#       Used by fzf reload bindings. Not intended as stable public API.

set -euo pipefail

SCRIPT="$0"

canonical_path() {
    realpath "$1"
}

path_components_for_name() {
    local root_path="$1"
    local rel

    if [[ "$root_path" == "$HOME" ]]; then
        echo "HOME"
        return
    fi

    if [[ "$root_path" == "$HOME"/* ]]; then
        rel="${root_path#$HOME/}"
        echo "HOME"
        print -r -- "$rel" | tr '/' '\n'
        return
    fi

    print -r -- "$root_path" | sed 's#^/##' | tr '/' '\n'
}

sanitize_name() {
    print -r -- "$1" | tr '. -' '___' | awk '{ print toupper($0) }'
}

session_root() {
    local session="${1:-}"
    local out

    if [[ -z "$session" ]]; then
        session=$(tmux display-message -p '#{session_name}')
    fi

    out=$(tmux show-environment -t "$session" TMUX_SESSIONIZER_DIR 2>/dev/null || true)
    if [[ "$out" == TMUX_SESSIONIZER_DIR=* ]]; then
        print -r -- "${out#TMUX_SESSIONIZER_DIR=}"
    fi
}

session_active_pane() {
    local session="$1"
    tmux list-panes -t "$session" -F '#{?window_active,#{?pane_active,#{pane_id},},}' | grep -m1 . || true
}

session_active_command() {
    local session="$1"
    tmux list-panes -t "$session" -F '#{?window_active,#{?pane_active,#{pane_current_command},},}' 2>/dev/null | grep -m1 . || true
}

preview_session() {
    local session="$1"
    local pane
    pane=$(session_active_pane "$session")
    if [[ -z "$pane" ]]; then
        echo "No active pane"
        return
    fi
    tmux capture-pane -ep -t "$pane" 2>/dev/null || true
}

all_sessions() {
    tmux list-sessions -F '#{session_name}' 2>/dev/null || true
}

sessions_for_path() {
    local root_path
    root_path=$(canonical_path "$1")

    local s root
    all_sessions | while IFS= read -r s; do
        root=$(session_root "$s")
        if [[ "$root" == "$root_path" ]]; then
            print -r -- "$s"
        fi
    done
}

name_used_by_other_path() {
    local name="$1"
    local root_path="$2"
    local root

    if ! tmux has-session -t="$name" 2>/dev/null; then
        return 1
    fi

    root=$(session_root "$name")
    [[ "$root" != "$root_path" ]]
}

available_session_name() {
    local root_path
    root_path=$(canonical_path "$1")

    local -a comps
    comps=(${(f)"$(path_components_for_name "$root_path")"})

    local n start candidate name i
    for ((n=1; n<=${#comps}; n++)); do
        start=$((${#comps} - n + 1))
        candidate=$(sanitize_name "${(j:_:)comps[$start,-1]}")

        if name_used_by_other_path "$candidate" "$root_path"; then
            continue
        fi

        if ! tmux has-session -t="$candidate" 2>/dev/null; then
            print -r -- "$candidate"
            return
        fi

        i=1
        while tmux has-session -t="${candidate}+${i}" 2>/dev/null; do
            ((i++))
        done
        print -r -- "${candidate}+${i}"
        return
    done

    candidate=$(sanitize_name "$root_path")
    i=1
    name="$candidate"
    while tmux has-session -t="$name" 2>/dev/null; do
        name="${candidate}+${i}"
        ((i++))
    done
    print -r -- "$name"
}

create_session() {
    local root_path name
    root_path=$(canonical_path "$1")
    name=$(available_session_name "$root_path")

    if [[ -z "${TMUX:-}" ]] && ! pgrep tmux >/dev/null 2>&1; then
        exec tmux new-session -s "$name" -c "$root_path" -e "TMUX_SESSIONIZER_DIR=$root_path"
    fi

    tmux new-session -ds "$name" -c "$root_path" -e "TMUX_SESSIONIZER_DIR=$root_path"
    switch_to_session "$name"
}

switch_to_session() {
    local session="$1"
    if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$session"
    else
        exec tmux attach-session -t "$session"
    fi
}

session_picker_rows() {
    local session root cmd

    while IFS= read -r session; do
        root=$(session_root "$session")
        [[ -z "$root" ]] && continue
        cmd=$(session_active_command "$session")
        cmd="${cmd[1,40]}"
        printf '%-24s %-40s %s\n' "$session" "$cmd" "$root"
    done
}

session_picker() {
    local reload_cmd="$1"
    local selected

    selected=$(
        eval "$reload_cmd" | fzf \
            --with-nth=1,2,3.. \
            --preview='tmux capture-pane -ep -t {1} 2>/dev/null' \
            --preview-window=down:50% \
            --bind "ctrl-x:execute-silent(tmux kill-session -t {1})+reload($reload_cmd)"
    )

    [[ -z "$selected" ]] && exit 0
    switch_to_session "${selected%%[[:space:]]*}"
}

pick_session_for_path() {
    local root_path
    root_path=$(canonical_path "$1")
    session_picker "${(q)SCRIPT} __rows-path ${(q)root_path}"
}

pick_all_sessions() {
    session_picker "${(q)SCRIPT} __rows-all"
}

open_path() {
    local root_path count session
    root_path=$(canonical_path "$1")

    local -a sessions
    sessions=(${(f)"$(sessions_for_path "$root_path")"})
    count=${#sessions}

    if (( count == 0 )); then
        create_session "$root_path"
    elif (( count == 1 )); then
        switch_to_session "$sessions[1]"
    else
        pick_session_for_path "$root_path"
    fi
}

dirs() {
    local depth=$1; shift
    fd . "$@" --exact-depth "$depth" --type d -L
}

singles() {
    echo ~/dotfiles
    echo ~/mounts
    echo ~/Documents
    echo ~/Downloads
    echo ~/shows
    echo ~/ArchivedDownloads
    echo ~/repos
    echo ~/scripts
    echo ~
    echo ~/Documents/studies/part-ii/project/main/qemu/
}

projects() {
   {
     singles &
     dirs 1 ~/repos ~/.config &
     dirs 2 ~/Documents
     dirs 3 ~/Documents
     dirs 1 ~/mounts
     dirs 2 ~/mounts
   }
}

pick_path() {
    local out key selected
    out=$(projects | fzf --expect=ctrl-y)
    [[ -z "$out" ]] && exit 0

    key=$(print -r -- "$out" | head -n1)
    selected=$(print -r -- "$out" | tail -n1)
    [[ -z "$selected" ]] && exit 0

    if [[ "$key" == "ctrl-y" ]]; then
        create_session "$selected"
    else
        open_path "$selected"
    fi
}

usage() {
    cat <<EOF
usage: $SCRIPT pick | open <path> | new <path> | list <path> | path [session] | sessions
EOF
}

cmd="${1:-pick}"
case "$cmd" in
    pick)
        pick_path
        ;;
    open)
        [[ $# -eq 2 ]] || { usage; exit 2; }
        open_path "$2"
        ;;
    new)
        [[ $# -eq 2 ]] || { usage; exit 2; }
        create_session "$2"
        ;;
    list)
        [[ $# -eq 2 ]] || { usage; exit 2; }
        sessions_for_path "$2"
        ;;
    sessions)
        [[ $# -eq 1 ]] || { usage; exit 2; }
        pick_all_sessions
        ;;
    path)
        [[ $# -le 2 ]] || { usage; exit 2; }
        session_root "${2:-}"
        ;;
    __rows-path)
        [[ $# -eq 2 ]] || exit 2
        sessions_for_path "$2" | session_picker_rows
        ;;
    __rows-all)
        [[ $# -eq 1 ]] || exit 2
        all_sessions | session_picker_rows
        ;;
    *)
        # Backwards compatibility: one arg means open that path.
        if [[ $# -eq 1 && -e "$1" ]]; then
            open_path "$1"
        else
            usage
            exit 2
        fi
        ;;
esac
