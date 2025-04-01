#!/bin/bash

set -e
set -o pipefail

pdf=$(fd -e pdf . ~/ | awk 'sub(/^\/home\/saatvikl\//, "")' | fzfmenu -m)

name=$(basename "$pdf")

if [ -z "$name" ]; then 
  exit; 
fi

notify-send "opening $name in zathura" 
zathura "$pdf"
