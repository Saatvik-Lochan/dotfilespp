#!/usr/bin/env bash
parent=$$
exec kitty -o 'font_size=14' --title "fzfmenu" \
  bash -c 'parent=$1; shift; exec fzf "$@" <"/proc/$parent/fd/0" >"/proc/$parent/fd/1"' \
  bash "$parent" "$@"
