#!/usr/bin/env bash

set -euo pipefail

coproc TITLE_PROC { ~/scripts/useful-title.pl; }
exec {TITLE_IN}>&${TITLE_PROC[1]}
exec {TITLE_OUT}<&${TITLE_PROC[0]}

cleanup() {
  exec {TITLE_IN}>&-
  exec {TITLE_OUT}<&-
}

trap cleanup EXIT

print_current() {
  workspace="$(niri msg --json workspaces | jq '.[] | select(.is_active) | .id')"
  while IFS=$'\x1f' read -r focused window; do
    printf '%s\n' "$window" >&$TITLE_IN
    read -r title <&$TITLE_OUT

    if [[ -n "$focused" ]]; then
      printf '[%s]\n' "$title"
    else
      printf ' %s \n' "$title"
    fi
  done < <(
    niri msg --json windows | jq -r --arg active_workspace "$workspace" '
      map(select(.workspace_id == ($active_workspace | tonumber)))
      | sort_by(.layout.pos_in_scrolling_layout)
      | .[]
      | (if .is_focused then "1" else "" end) + "\u001f" + tojson
    '
  ) | jq -R -r -s 'split("\n")[:-1] | join("")'
}

# Initial state
print_current

# Follow niri events and refresh when window-related state changes
niri msg --json event-stream | jq -c --unbuffered '
  select(
    has("WindowFocusChanged")
    or has("WindowOpenedOrChanged")
    or has("WindowClosed")
    or has("WindowsChanged")
    or has("WindowLayoutsChanged")
  )
' | while read -r _; do
  print_current
done
