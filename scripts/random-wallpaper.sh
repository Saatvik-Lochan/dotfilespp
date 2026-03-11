#!/usr/bin/env bash

set -euo pipefail

wallpaper_dirs=(
  "$HOME/repos/aesthetic-wallpapers/images"
)

picked_log="$HOME/.local/state/wallpaper-picked.log"

mkdir -p "$(dirname "$picked_log")"

wallpaper_files=()

for wallpaper_dir in "${wallpaper_dirs[@]}"; do
  [ -d "$wallpaper_dir" ] || continue

  while IFS= read -r file; do
    wallpaper_files+=("$file")
  done < <(
    fd --no-ignore --type f \
      . "$wallpaper_dir"
  )
done

if [ "${#wallpaper_files[@]}" -eq 0 ]; then
  notify-send "no wallpapers found"
  exit 1
fi

chosen_full_file="$(realpath "${wallpaper_files[$((RANDOM % ${#wallpaper_files[@]}))]}")"

printf '%s\n' "$chosen_full_file" >> "$picked_log"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/change-wallpaper.sh" "$chosen_full_file"
