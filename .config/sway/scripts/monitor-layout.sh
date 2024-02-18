save() {
    NAME=$(zenity --entry --text="layout name" | sed 's/ /-/g')
    FILE=~/.layouts/$NAME

    if [[ -z $NAME ]]; then
        notify-send "Your name file name was empty"
        exit 1
    fi

    swaymsg -t get_outputs | jq '.[] | "\(.name) pos \(.rect.x) \(.rect.y)"' | tr -d '"' > $FILE
}

apply() {
    NAME=$(ls ~/.layouts | fzfmenu)
    FILE=~/.layouts/$NAME

    while IFS= read -r line; do
        swaymsg output $line
    done < $FILE

    notify-send "Applied monitor layout '$NAME'"
}

case $1 in 
    save )
        save;;
    apply )
        apply;;
esac
