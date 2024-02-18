usage() {
    echo "pdf-filename [file] [page] "
}

get_zathura_instances() {
    busctl --user list -j | jq '.[] | select(.name | contains("org.pwmt.zathura")) | .name'
}  

sfi() {
    res=$(echo $1 | tr -d '"')
    name=$(busctl --user get-property $res /org/pwmt/zathura org.pwmt.zathura filename -j | jq '.data' | tr -d '"')
    pno=$(busctl --user get-property $res /org/pwmt/zathura org.pwmt.zathura pagenumber -j | jq '.data')
    pno=$(( pno + 1 ))
    echo "$name::$pno"
}

sfis() {
    while IFS= read -r line; do
        echo $(sfi $line | tr -d '"')
    done
}

select_zathura_instances() {
    all=""

    count=0
    while IFS= read -r line; do
        line=$(echo $line | tr -d '"')
        all="$line
$all"

        count=$(( count + 1 ))
    done

    all=$(echo "$all" | awk 'NF')

    if [[ $count -eq 0 ]]; then
        exit
    elif [[ $count -eq 1 ]]; then
        sfi $all 
    else
        echo "$all" | sfis | fzfmenu -d '/' --with-nth=6.. | awk '{ print "\""$0"\"" }'
    fi
}

set -o pipefail

case $1 in 
    print )
        get_zathura_instances | sfis;;
    ss)
        sfis;;
    select )
        get_zathura_instances | select_zathura_instances | tr -d '\n' | tr -d '"';;
    string )
        sfi $2;;
    *)
        get_zathura_instances;;
esac
