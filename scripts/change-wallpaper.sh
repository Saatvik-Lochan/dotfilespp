#!/usr/bin/env bash

set -euo pipefail

BASE_WALLPAPER_DIR="${BASE_WALLPAPER_DIR:-$HOME/Documents/misc/wallpapers}"
CURRENT_WALLPAPER_LINK="$BASE_WALLPAPER_DIR/current"

# Fail fast if wallpaper directory is missing.
if [ ! -d "$BASE_WALLPAPER_DIR" ]; then
  notify-send "wallpaper dir missing: $BASE_WALLPAPER_DIR"
  exit 1
fi

# If a file is passed, link it into wallpaper dir; otherwise pick from wallpaper dir.
if [ -n "${1:-}" ]; then
  if [ ! -f "$1" ]; then
    notify-send "wallpaper input must be a file"
    exit 1
  fi

  wallpaper_file="$(realpath "$1")"
else
  wallpaper_file="$(fd --no-ignore --type f --type l -E current . "$BASE_WALLPAPER_DIR" | fzfmenu)"

  # Empty picker output means user cancelled selection.
  if [ -z "$wallpaper_file" ]; then
    notify-send "wallpaper change cancelled"
    exit
  fi

  chosen="$(basename "$wallpaper_file")"
fi

ln -s -f "$wallpaper_file" "$CURRENT_WALLPAPER_LINK"

swww img -t grow "$CURRENT_WALLPAPER_LINK"

# update the theming
wallust run -s "$CURRENT_WALLPAPER_LINK"
echo "" >> ~/.config/waybar/style.css && truncate -s -1 ~/.config/waybar/style.css
touch ~/.config/niri/colors.kdl
pywalfox update

notify-send "wallpaper now $chosen"
