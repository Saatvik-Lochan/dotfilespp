get_modes() {
	swaymsg -t get_outputs | \
		jq -r --arg name "$1" \
		'.[] | select(.name == $name) | .modes | .[] | (.width | tostring) + "x" + (.height | tostring) + " @ " + (.refresh / 1000 | tostring) + " Hz"'
}

get_names() {
	swaymsg -t get_outputs | jq -r ".[] | .name"
}

pick_name() {
	get_names | fzfmenu
}

pick_and_set_mode() {
	name=$(pick_name)
	mode_raw=$(get_modes "$name" | fzfmenu)
	mode=$(echo $mode_raw | sed 's/ //g')
	swaymsg output $name mode $mode 
	notify-send "$name set to $mode_raw"
}

pick_and_set_mode
