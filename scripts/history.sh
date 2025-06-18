populate() {
    set -o pipefail
    sqlite3 ~/.mozilla/firefox/imwegtih.default-release/places.sqlite -tabs \
        "select coalesce(p.title, p.url) as c, p.url, o.host, p.frecency 
            from moz_places as p left 
            join moz_origins as o on o.id = p.origin_id" \
        | ~/.config/sway/scripts/parse-history > ~/.history \
                    && notify-send "Firefox history updated" \
                    || notify-send "Could not update firefox history"

}

get_url(){
    bat ~/.history | fzfmenu --with-nth=2.. --tiebreak=index | awk '{ print $1 }'
}

open_url() {
    file=$(get_url) && firefox $file
}

set -o pipefail

case $1 in 
    populate )
        populate;;
    get )
        get_url;;
    open )
        open_url;;
    open-and-update)
        pgrep firefox || populate
        open_url;;
esac

