echo -n "cd " > ~/.pd && echo $PWD >> ~/.pd
kitty --detach --session ~/.pd && notify-send "new term - $PWD"
