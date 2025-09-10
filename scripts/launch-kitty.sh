current_app=$(niri msg -j windows | \
  jq '.[] | select(.["is_focused"] == true) | .app_id' | tr -d '"')

if [[ $current_app == "kitty" ]]; then
  kitty -o env=OPEN_COPIED_TERM=1
else
  kitty
fi



