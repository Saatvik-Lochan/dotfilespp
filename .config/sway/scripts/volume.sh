update_wob() {
    awk '{ if (match($0, /\[(.*)%\]/, m)) { print m[1]; exit } }' \
        > /tmp/wobpipe
}

decrease() {
    amixer -D pulse sset Master $1%- | update_wob
}

increase() {
    amixer -D pulse sset Master $1%+ | update_wob
}

case $1 in 
    "inc" )
        increase $2;;
    "dec" )
        decrease $2;;
    * )
        echo "Must be 'inc' or 'dec'"
        exit 1
esac
