focused=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name')
swaymsg input type:tablet_tool map_to_output $focused && \
    notify-send "Tablet mapped to $focused" || \
    notify-send "Tablet failed to map to $focused" 

