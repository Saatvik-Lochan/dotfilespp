#!/bin/bash

screenshot() {
    case $1 in
        "window" )
            grim -g "$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"')" - ;;

        "monitor" )
            grim -o $(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') - ;;

        "select" )
            grim -g "$(slurp -b 0x333333)" - ;;

        "everything" )
            grim - ;;
    esac
}

do_with() {
    case $1 in
        "copy" ) 
            wl-copy ;;
        "edit" )
            satty --copy-command wl-copy --early-exit -f - ;;
    esac
}

full() {
    screenshot $1 | do_with $2
}

full $1 $2
