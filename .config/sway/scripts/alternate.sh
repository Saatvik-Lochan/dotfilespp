save_alternate() {
    WORKSPACE=$(swaymsg -t get_workspaces | \
        jq '[.[] | select(.focused==false and .visible==true) | .name] | first')
}

save_alternate

if [[ $WORKSPACE != "null" ]]; then
    case $1 in 
        "focus" )
            swaymsg workspace $WORKSPACE;;
        "move" )
            swaymsg move container to workspace $WORKSPACE;;
        "print" )
            echo $WORKSPACE;;
        * )
            echo "Must be either 'move' or 'focus'"
            exit 2
    esac
else
    notify-send "No alternate workspace"
    echo "No 'alternate' workspace"
    exit 1
fi

exit 0
