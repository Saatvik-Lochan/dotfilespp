#!/bin/bash

set -e
set -o pipefail

pdf=$(fd -e pdf . ~/ | awk 'sub(/^\/home\/saatvikl\//, "")' | fzfmenu -m)

name=$(basename "$pdf")
notify-send "opening $name in zathura" 
zathura "$pdf"
