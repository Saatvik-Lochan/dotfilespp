#!/usr/bin/env zsh

# terminal
# --------
# Central terminal/tmux-sessionizer controller.
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
#   launch-emulator
#       Window-manager entrypoint. Launches kitty. If the focused app is kitty,
#       sets OPEN_COPIED_TERM=1 so shell startup creates a same-root session.
#
#   enter-sessionizer
#       Shell-startup entrypoint. Normal terminals create a new home-rooted
#       session. Copied/helper terminals create a new session for the current
#       sessionizer root, falling back to home.
#
#   clean
#       Tmux detach hook. Kills unattached idle sessions.
#
#   projects
#       Fuzzy-pick a project path. Uses a no-TTL /tmp project cache.
#       Enter  -> switch --path <path> --create
#       Ctrl-y -> new --path <path>
#       Ctrl-r -> regenerate project list and update cache
#
#   switch [--all|--current|--path PATH] [--persist-if-one] [--create]
#       Switch within a scope. Scope defines candidate sessions:
#       --all: all sessionizer sessions; --current: current root; --path: path.
#       --persist-if-one shows the picker even for one candidate.
#       --create creates a new session at the scope's root if there are none.
#
#   new [--home|--current|--path PATH]
#       Always create a new session for the selected target root.
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
#   __rows-path <path>, __rows-all, __preview <session>, __kill-session <session>,
#   __kill-zsh-path <path>, __kill-zsh-all, __projects-refresh
#       Used by fzf reload/preview/key bindings. Not intended as stable public API.

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

session_exists_in_list() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

choose_survivor_session() {
    local current="$1"
    shift
    local session root

    session_records | while IFS=$'\t' read -r session root; do
        [[ -z "$root" ]] && continue
        [[ "$session" == "$current" ]] && continue
        if ! session_exists_in_list "$session" "$@"; then
            print -r -- "$session"
            return
        fi
    done
}

kill_sessions_safe() {
    local current survivor session
    local -a victims
    victims=("$@")
    (( ${#victims} == 0 )) && return

    current=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
    if [[ -n "$current" ]] && session_exists_in_list "$current" "${victims[@]}"; then
        survivor=$(choose_survivor_session "$current" "${victims[@]}")
        [[ -n "$survivor" ]] && tmux switch-client -t "$survivor" 2>/dev/null || true
    fi

    for session in "${victims[@]}"; do
        tmux kill-session -t "$session" 2>/dev/null || true
    done
}

kill_session_safe() {
    kill_sessions_safe "$1"
}

kill_zsh_sessions() {
    local filter_root="${1:-}"
    local session root cmd window_active pane_active
    local -A commands
    local -a victims

    while IFS=$'\t' read -r session window_active pane_active cmd; do
        if [[ "$window_active" == "1" && "$pane_active" == "1" ]]; then
            commands[$session]="$cmd"
        fi
    done < <(tmux list-panes -a -F '#{session_name}	#{window_active}	#{pane_active}	#{pane_current_command}' 2>/dev/null || true)

    while IFS=$'\t' read -r session root; do
        [[ -z "$root" ]] && continue
        [[ -n "$filter_root" && "$root" != "$filter_root" ]] && continue
        [[ "${commands[$session]-}" == "zsh" ]] && victims+=("$session")
    done < <(session_records)

    kill_sessions_safe "${victims[@]}"
}

session_picker() {
    local reload_cmd="$1"
    local kill_zsh_cmd="$2"
    local selected

    selected=$(
        eval "$reload_cmd" | fzf \
            --footer='enter: switch | ctrl-y: new | ctrl-i/tab: kill | ctrl-x: kill zsh | esc: cancel' \
            --delimiter='\t' \
            --with-nth=4 \
            --preview="${(q)SCRIPT} __preview {1}" \
            --preview-window=down:50% \
            --bind "ctrl-i:execute-silent(${(q)SCRIPT} __kill-session {1})+reload($reload_cmd)" \
            --bind "ctrl-y:become(${(q)SCRIPT} new --path {3})" \
            --bind "ctrl-x:execute-silent($kill_zsh_cmd)+reload($reload_cmd)"
    )

    [[ -z "$selected" ]] && exit 0
    switch_to_session "${selected%%$'\t'*}"
}

pick_session_for_root() {
    local root_path="$1"
    session_picker "${(q)SCRIPT} __rows-path ${(q)root_path}" "${(q)SCRIPT} __kill-zsh-path ${(q)root_path}"
}

pick_all_sessions() {
    session_picker "${(q)SCRIPT} __rows-all" "${(q)SCRIPT} __kill-zsh-all"
}

all_sessionizer_sessions() {
    local session root
    session_records | while IFS=$'\t' read -r session root; do
        [[ -n "$root" ]] && print -r -- "$session"
    done
}

notify_no_sessions() {
    local msg="$1"
    tmux display-message "$msg" 2>/dev/null || print -u2 -- "$msg"
}

switch_scope() {
    local scope="$1"
    local root_path="$2"
    local persist_if_one="$3"
    local create_if_none="$4"
    local create_root count
    local -a sessions

    if [[ "$scope" == "all" ]]; then
        sessions=(${(f)"$(all_sessionizer_sessions)"})
        create_root=$(canonical_path ~)
    else
        sessions=(${(f)"$(sessions_for_root "$root_path")"})
        create_root="$root_path"
    fi

    count=${#sessions}

    if (( count == 0 )); then
        if (( create_if_none )); then
            create_session "$create_root"
        else
            notify_no_sessions "no sessions found"
        fi
    elif (( count == 1 && ! persist_if_one )); then
        switch_to_session "$sessions[1]"
    else
        if [[ "$scope" == "all" ]]; then
            pick_all_sessions
        else
            pick_session_for_root "$root_path"
        fi
    fi
}

switch_command() {
    local scope="all"
    local root_path=""
    local scope_count=0
    local persist_if_one=0
    local create_if_none=0

    while (( $# > 0 )); do
        case "$1" in
            --all)
                ((++scope_count)); scope="all"; root_path=""; shift ;;
            --current)
                ((++scope_count)); scope="root"; root_path=$(session_root); shift ;;
            --path)
                [[ $# -ge 2 ]] || { usage; exit 2; }
                ((++scope_count)); scope="root"; root_path=$(canonical_path "$2"); shift 2 ;;
            --persist-if-one)
                persist_if_one=1; shift ;;
            --create)
                create_if_none=1; shift ;;
            *)
                usage; exit 2 ;;
        esac
    done

    if (( scope_count > 1 )); then
        usage
        exit 2
    fi

    if [[ "$scope" == "root" && -z "$root_path" ]]; then
        notify_no_sessions "no current sessionizer root"
        exit 0
    fi

    switch_scope "$scope" "$root_path" "$persist_if_one" "$create_if_none"
}

new_command() {
    local target="home"
    local root_path=""
    local target_count=0

    while (( $# > 0 )); do
        case "$1" in
            --home)
                ((++target_count)); target="home"; root_path=""; shift ;;
            --current)
                ((++target_count)); target="current"; root_path=$(session_root); shift ;;
            --path)
                [[ $# -ge 2 ]] || { usage; exit 2; }
                ((++target_count)); target="path"; root_path=$(canonical_path "$2"); shift 2 ;;
            *)
                usage; exit 2 ;;
        esac
    done

    if (( target_count > 1 )); then
        usage
        exit 2
    fi

    case "$target" in
        home)
            create_session ~ ;;
        current)
            if [[ -n "$root_path" ]]; then
                create_session "$root_path"
            else
                notify_no_sessions "no current sessionizer root"
            fi ;;
        path)
            create_session "$root_path" ;;
    esac
}

enter_sessionizer() {
    local root

    if [[ -z "${OPEN_COPIED_TERM:-}" ]]; then
        create_session ~
    else
        root=$(session_root)
        if [[ -n "$root" ]]; then
            create_session "$root"
        else
            create_session ~
        fi
    fi
}

launch_emulator() {
    local current_app
    current_app=$(niri msg -j focused-window 2>/dev/null | jq .app_id 2>/dev/null || true)

    if [[ "$current_app" == '"kitty"' ]]; then
        exec kitty -o env=OPEN_COPIED_TERM=1
    else
        exec kitty
    fi
}

clean_tmux() {
    local session active_processes pid cmd

    tmux list-sessions -F '#S' 2>/dev/null | while IFS= read -r session; do
        if [[ -n "$(tmux list-clients -t "$session" 2>/dev/null)" ]]; then
            continue
        fi

        active_processes=0
        while read -r pid cmd; do
            if [[ "$cmd" != "bash" && "$cmd" != "zsh" && "$cmd" != "fish" ]]; then
                active_processes=$((active_processes + 1))
            elif pgrep -P "$pid" >/dev/null 2>&1; then
                active_processes=$((active_processes + 1))
            fi
        done < <(tmux list-panes -t "$session" -F '#{pane_pid} #{pane_current_command}' 2>/dev/null)

        if [[ "$active_processes" -eq 0 ]]; then
            echo "Killing idle session: $session" >> /tmp/tmux-session-kill.log
            tmux kill-session -t "$session" 2>/dev/null || true
        fi
    done
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
    out=$(cached_projects | fzf \
        --footer='enter: open | ctrl-y: new | ctrl-r: refresh | esc: cancel' \
        --expect=ctrl-y \
        --bind "ctrl-r:reload($refresh_cmd)")
    [[ -z "$out" ]] && exit 0

    lines=(${(f)out})
    key="$lines[1]"
    selected="$lines[-1]"
    [[ -z "$selected" ]] && exit 0

    if [[ "$key" == "ctrl-y" ]]; then
        create_session "$selected"
    else
        switch_command --path "$selected" --create
    fi
}

usage() {
    cat <<EOF
usage: $SCRIPT launch-emulator | enter-sessionizer | clean | projects | switch [--all|--current|--path PATH] [--persist-if-one] [--create] | new [--home|--current|--path PATH]
EOF
}

cmd="${1:-}"
[[ -n "$cmd" ]] || { usage; exit 2; }
shift
case "$cmd" in
    launch-emulator)
        [[ $# -eq 0 ]] || { usage; exit 2; }
        launch_emulator
        ;;
    enter-sessionizer)
        [[ $# -eq 0 ]] || { usage; exit 2; }
        enter_sessionizer
        ;;
    clean)
        [[ $# -eq 0 ]] || { usage; exit 2; }
        clean_tmux
        ;;
    projects)
        [[ $# -eq 0 ]] || { usage; exit 2; }
        pick_path
        ;;
    switch)
        switch_command "$@"
        ;;
    new)
        new_command "$@"
        ;;
    __rows-path)
        [[ $# -eq 1 ]] || exit 2
        session_picker_rows "$(canonical_path "$1")"
        ;;
    __rows-all)
        [[ $# -eq 0 ]] || exit 2
        session_picker_rows
        ;;
    __preview)
        [[ $# -eq 1 ]] || exit 2
        preview_session "$1"
        ;;
    __kill-session)
        [[ $# -eq 1 ]] || exit 2
        kill_session_safe "$1"
        ;;
    __kill-zsh-path)
        [[ $# -eq 1 ]] || exit 2
        kill_zsh_sessions "$(canonical_path "$1")"
        ;;
    __kill-zsh-all)
        [[ $# -eq 0 ]] || exit 2
        kill_zsh_sessions
        ;;
    __projects-refresh)
        [[ $# -eq 0 ]] || exit 2
        refresh_project_cache
        ;;
    *)
        usage
        exit 2
        ;;
esac
