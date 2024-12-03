toggled=$(wl-paste | python ~/.config/sway/scripts/solutions.py)
notify-send "swapped"
firefox "$toggled"
