update_wob() {
    pactl get-sink-volume "$1" | awk '{ if (match($0, /([0-9]+)%/, m)) { print m[1]; exit } }' > /tmp/wobpipe
}

current_sink() {
    pactl list sink-inputs | awk '
        /^Sink Input #[0-9]+/ { sink = ""; corked = "yes" }
        /^\tSink: / { sink = $2 }
        /^\tCorked: / {
            corked = $2
            if (sink != "" && corked == "no") {
                print sink
                exit
            }
        }
    '
}

target_sink() {
    current_sink || true
}

decrease() {
    sink="$(target_sink)"
    sink="${sink:-@DEFAULT_SINK@}"
    pactl set-sink-volume "$sink" "-${1}%"
    update_wob "$sink"
}

increase() {
    sink="$(target_sink)"
    sink="${sink:-@DEFAULT_SINK@}"
    pactl set-sink-volume "$sink" "+${1}%"
    update_wob "$sink"
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
