#!/usr/bin/env bash
parent=$$
exec alacritty -o 'font.size=14' -T "fzfmenu" \
  -e bash -c 'parent=$1; shift; exec fzf "$@" <"/proc/$parent/fd/0" >"/proc/$parent/fd/1"' \
  bash "$parent" "$@"
