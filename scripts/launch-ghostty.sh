current_app=$(niri msg -j focused-window | jq .app_id)

if [[ $current_app == '"com.mitchellh.ghostty"' ]]; then
  # then in .zshrc it checks for this env
  ghostty --env=OPEN_COPIED_TERM=1 --gtk-single-instance=true 
else
  ghostty --gtk-single-instance=true
fi



