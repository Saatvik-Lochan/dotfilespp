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
#       Uses a no-TTL /tmp project cache.
#       Enter  -> open <path>
#       Ctrl-y -> new <path>
#       Ctrl-r -> regenerate project list and update cache
#
#   open [--persist-if-one] <path>
#       Canonicalize path with realpath.
#       If no sessions exist for that root, create one.
#       If one exists, switch to it, unless --persist-if-one is given.
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
#   Ctrl-i -> kill hovered session and reload picker
#   Ctrl-y -> create a new session for the hovered root and switch to it
#   Ctrl-x -> kill all sessions in the current picker whose active command is zsh
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
#   __rows-path <path>, __rows-all, __preview <session>,
#   __kill-zsh-path <path>, __kill-zsh-all, __projects-cache,
#   __projects-refresh
#       Used by fzf reload bindings. Not intended as stable public API.

set -euo pipefail

SCRIPT="${0:A}"
typeset -g SESSION_RECORDS_CACHE=""
typeset -g SESSION_RECORDS_CACHE_LOADED=0

canonical_path() {
    realpath "$1"
}

path_components_for_name() {
    local root_path="$1"
    local rel
    local -a comps

    if [[ "$root_path" == "$HOME" ]]; then
        print -r -- "HOME"
        return
    fi

    if [[ "$root_path" == "$HOME"/* ]]; then
        rel="${root_path#$HOME/}"
        comps=(HOME ${(s:/:)rel})
    else
        rel="${root_path#/}"
        comps=(${(s:/:)rel})
    fi

    print -rl -- "${comps[@]}"
}

sanitize_name() {
    local name="$1"
    name="${name//./_}"
    name="${name// /_}"
    name="${name//-/_}"
    print -r -- "${name:u}"
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

session_records() {
    if [[ "$SESSION_RECORDS_CACHE_LOADED" != "1" ]]; then
        SESSION_RECORDS_CACHE=$(tmux list-sessions -F '#{session_name}	#{E:TMUX_SESSIONIZER_DIR}' 2>/dev/null || true)
        SESSION_RECORDS_CACHE_LOADED=1
    fi
    print -r -- "$SESSION_RECORDS_CACHE"
}

tmux_has_sessions() {
    [[ -n "$(session_records)" ]]
}

sessions_for_root() {
    local root_path="$1"
    local session root

    session_records | while IFS=$'\t' read -r session root; do
        if [[ "$root" == "$root_path" ]]; then
            print -r -- "$session"
        fi
    done
}

sessions_for_path() {
    local root_path
    root_path=$(canonical_path "$1")
    sessions_for_root "$root_path"
}

available_session_name_for_root() {
    local root_path="$1"
    local session root
    local -A roots

    while IFS=$'\t' read -r session root; do
        roots[$session]="$root"
    done < <(session_records)

    local -a comps
    comps=(${(f)"$(path_components_for_name "$root_path")"})

    local n start candidate name i
    for ((n=1; n<=${#comps}; n++)); do
        start=$((${#comps} - n + 1))
        candidate=$(sanitize_name "${(j:_:)comps[$start,-1]}")

        if [[ -n "${roots[$candidate]+set}" && "${roots[$candidate]}" != "$root_path" ]]; then
            continue
        fi

        if [[ -z "${roots[$candidate]+set}" ]]; then
            print -r -- "$candidate"
            return
        fi

        i=1
        while [[ -n "${roots[${candidate}+${i}]+set}" ]]; do
            ((i++))
        done
        print -r -- "${candidate}+${i}"
        return
    done

    candidate=$(sanitize_name "$root_path")
    i=1
    name="$candidate"
    while [[ -n "${roots[$name]+set}" ]]; do
        name="${candidate}+${i}"
        ((i++))
    done
    print -r -- "$name"
}

create_session() {
    local root_path name
    root_path=$(canonical_path "$1")
    name=$(available_session_name_for_root "$root_path")

    if [[ -z "${TMUX:-}" ]] && ! tmux_has_sessions; then
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
    local filter_root="${1:-}"
    local session root cmd window_active pane_active
    local -A commands

    while IFS=$'\t' read -r session window_active pane_active cmd; do
        if [[ "$window_active" == "1" && "$pane_active" == "1" ]]; then
            commands[$session]="$cmd"
        fi
    done < <(tmux list-panes -a -F '#{session_name}	#{window_active}	#{pane_active}	#{pane_current_command}' 2>/dev/null || true)

    session_records | while IFS=$'\t' read -r session root; do
        [[ -z "$root" ]] && continue
        [[ -n "$filter_root" && "$root" != "$filter_root" ]] && continue
        cmd="${commands[$session]-}"
        cmd="${cmd[1,40]}"
        printf '%s\t%s\t%s\t%-24s %-40s %s\n' "$session" "$cmd" "$root" "$session" "$cmd" "$root"
    done
}

preview_session() {
    local session="$1"
    tmux capture-pane -ep -t "$session" 2>/dev/null | perl -e '
        $n = $ENV{FZF_PREVIEW_LINES} || 40;
        while (<STDIN>) {
            push @lines, $_;
            $s = $_;
            $s =~ s/\e\[[0-?]*[ -\/]*[@-~]//g;
            $last = scalar @lines if $s =~ /\S/;
        }
        exit unless defined $last;
        @lines = @lines[0 .. $last - 1];
        $start = @lines - $n;
        $start = 0 if $start < 0;
        print @lines[$start .. $#lines] if @lines;
    '
}

kill_zsh_sessions() {
    local filter_root="${1:-}"
    local session root cmd window_active pane_active
    local -A commands

    while IFS=$'\t' read -r session window_active pane_active cmd; do
        if [[ "$window_active" == "1" && "$pane_active" == "1" ]]; then
            commands[$session]="$cmd"
        fi
    done < <(tmux list-panes -a -F '#{session_name}	#{window_active}	#{pane_active}	#{pane_current_command}' 2>/dev/null || true)

    session_records | while IFS=$'\t' read -r session root; do
        [[ -z "$root" ]] && continue
        [[ -n "$filter_root" && "$root" != "$filter_root" ]] && continue
        [[ "${commands[$session]-}" == "zsh" ]] && tmux kill-session -t "$session" 2>/dev/null || true
    done
}

session_picker() {
    local reload_cmd="$1"
    local kill_zsh_cmd="$2"
    local selected

    selected=$(
        eval "$reload_cmd" | fzf \
            --delimiter='\t' \
            --with-nth=4 \
            --preview="${(q)SCRIPT} __preview {1}" \
            --preview-window=down:50% \
            --bind "ctrl-i:execute-silent(tmux kill-session -t {1})+reload($reload_cmd)" \
            --bind "ctrl-y:become(${(q)SCRIPT} new {3})" \
            --bind "ctrl-x:execute-silent($kill_zsh_cmd)+reload($reload_cmd)"
    )

    [[ -z "$selected" ]] && exit 0
    switch_to_session "${selected%%$'\t'*}"
}

pick_session_for_root() {
    local root_path="$1"
    session_picker "${(q)SCRIPT} __rows-path ${(q)root_path}" "${(q)SCRIPT} __kill-zsh-path ${(q)root_path}"
}

pick_session_for_path() {
    local root_path
    root_path=$(canonical_path "$1")
    pick_session_for_root "$root_path"
}

pick_all_sessions() {
    session_picker "${(q)SCRIPT} __rows-all" "${(q)SCRIPT} __kill-zsh-all"
}

open_path() {
    local persist_if_one=0
    if [[ "${1:-}" == "--persist-if-one" ]]; then
        persist_if_one=1
        shift
    fi

    local root_path count session
    root_path=$(canonical_path "$1")

    local -a sessions
    sessions=(${(f)"$(sessions_for_root "$root_path")"})
    count=${#sessions}

    if (( count == 0 )); then
        create_session "$root_path"
    elif (( count == 1 && ! persist_if_one )); then
        switch_to_session "$sessions[1]"
    else
        pick_session_for_root "$root_path"
    fi
}

project_cache_file() {
    print -r -- "/tmp/tmux-sessionizer-projects-${USER:-$(id -u)}"
}

dirs() {
    local depth=$1; shift
    local -a excludes
    excludes=(-E .git -E __pycache__ -E node_modules -E target -E build -E dist -E .venv -E venv)
    fd . "$@" --exact-depth "$depth" --type d -L "${excludes[@]}"
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

refresh_project_cache() {
    local cache tmp
    cache=$(project_cache_file)
    tmp="${cache}.$$"

    projects | tee "$tmp"
    mv "$tmp" "$cache" 2>/dev/null || true
}

cached_projects() {
    local cache
    cache=$(project_cache_file)

    if [[ -f "$cache" ]]; then
        cat "$cache"
    else
        refresh_project_cache
    fi
}

pick_path() {
    local out key selected refresh_cmd
    local -a lines
    refresh_cmd="${(q)SCRIPT} __projects-refresh"
    out=$(cached_projects | fzf --expect=ctrl-y --bind "ctrl-r:reload($refresh_cmd)")
    [[ -z "$out" ]] && exit 0

    lines=(${(f)out})
    key="$lines[1]"
    selected="$lines[-1]"
    [[ -z "$selected" ]] && exit 0

    if [[ "$key" == "ctrl-y" ]]; then
        create_session "$selected"
    else
        open_path "$selected"
    fi
}

usage() {
    cat <<EOF
usage: $SCRIPT pick | open [--persist-if-one] <path> | new <path> | list <path> | path [session] | sessions
EOF
}

cmd="${1:-pick}"
case "$cmd" in
    pick)
        pick_path
        ;;
    open)
        if [[ $# -eq 2 ]]; then
            open_path "$2"
        elif [[ $# -eq 3 && "$2" == "--persist-if-one" ]]; then
            open_path --persist-if-one "$3"
        else
            usage
            exit 2
        fi
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
        session_picker_rows "$(canonical_path "$2")"
        ;;
    __rows-all)
        [[ $# -eq 1 ]] || exit 2
        session_picker_rows
        ;;
    __preview)
        [[ $# -eq 2 ]] || exit 2
        preview_session "$2"
        ;;
    __kill-zsh-path)
        [[ $# -eq 2 ]] || exit 2
        kill_zsh_sessions "$(canonical_path "$2")"
        ;;
    __kill-zsh-all)
        [[ $# -eq 1 ]] || exit 2
        kill_zsh_sessions
        ;;
    __projects-cache)
        [[ $# -eq 1 ]] || exit 2
        cached_projects
        ;;
    __projects-refresh)
        [[ $# -eq 1 ]] || exit 2
        refresh_project_cache
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
