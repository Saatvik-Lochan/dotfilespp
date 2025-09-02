set -e
set -o pipefail

wallpaper_dir=$(realpath "${1:-/home/saatvikl/Documents/misc/wallpapers}")
wallpaper_dir="${wallpaper_dir%/}"

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

swaybg "*" bg $wallpaperdir

notify-send "wallpaper now $chosen"
