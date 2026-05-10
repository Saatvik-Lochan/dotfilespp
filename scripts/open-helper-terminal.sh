#!/usr/bin/env bash

root=$(~/scripts/tmux-sessionizer.sh path)

if [[ -z "$root" ]]; then
  root="$HOME"
fi

exec ~/scripts/tmux-sessionizer.sh new "$root"
