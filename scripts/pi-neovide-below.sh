#!/bin/sh

before_ids=$(niri msg --json windows 2>/dev/null | jq -r 'map(.id) | @tsv')

neovide --wayland_app_id pi-neovide "$@" &
neovide_pid=$!

new_id=""
for _ in $(seq 1 50); do
  new_id=$(
    niri msg --json windows 2>/dev/null |
      BEFORE_IDS="$before_ids" jq -r '
        (env.BEFORE_IDS | split("\t") | map(select(length > 0) | tonumber)) as $before
        | map(select(.app_id == "pi-neovide" and (.id as $id | $before | index($id) | not)))
        | sort_by(.id)
        | last
        | .id // empty
      '
  )

  [ -n "$new_id" ] && break
done

if [ -n "$new_id" ]; then
  niri msg action consume-or-expel-window-left --id "$new_id" >/dev/null 2>&1
  niri msg action set-window-height --id "$new_id" "20%" >/dev/null 2>&1
fi

wait "$neovide_pid"
