#!/usr/bin/env bash
alacritty -o 'font.size=14' -T "fzfmenu" -e zsh -c "fzf $* < /proc/$$/fd/0 > /proc/$$/fd/1"
