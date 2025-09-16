current_app=$(niri msg -j focused-window | jq .app_id)

if [[ $current_app == '"kitty"' ]]; then
  kitty -o env=OPEN_COPIED_TERM=1
else
  kitty
fi



