#!/bin/bash

set -e
set -o pipefail

pdf=$(fd --no-ignore -e pdf . ~/ | awk 'sub(/^\/home\/saatvikl\//, "")' | fzfmenu -m)

name=$(basename "$pdf")

if [ -z "$name" ]; then 
  exit; 
fi

notify-send "opening $name in zathura" 
zathura "$pdf"
