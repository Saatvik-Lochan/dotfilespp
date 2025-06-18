set -e
set -o pipefail

wallpaper_dir=$(realpath "${1%/}")

chosen=$(fd --no-ignore --type f . "$wallpaper_dir" | parallel basename | fzfmenu)

if [ -z "$chosen" ]; then 
  notify-send "wallpaper change cancelled"
  exit; 
fi

chosen_full_file="$wallpaper_dir/$chosen"
ln -s -f "$chosen_full_file" "$wallpaper_dir/current"

pkill swaybg
swaybg -i "$wallpaper_dir/current" -m fill &
disown

notify-send "wallpaper now $chosen"
