get_instances() {
    busctl --user list -j | jq '.[] | select(.name | contains("org.pwmt.zathura")) | .name'
}

files_pid() {
    while IFS= read -r line; do
        trimmed=$(echo $line | tr -d '"')
        echo "$trimmed $(busctl --user get-property $trimmed /org/pwmt/zathura org.pwmt.zathura filename -j | jq '.data')"
    done
}

# $1 is filename, $2 is page number
parse_open() {
    while IFS= read -r line; do
        pid=$(echo $line | awk '{ print $1 }')
        name=$(echo $line | awk '{ print $2 }' | tr -d '"')

        in=$(echo $1 | tr -d '"')

        if [[ $in == $name ]]; then
            busctl --user call $pid /org/pwmt/zathura org.pwmt.zathura GotoPage u $(( $2 - 1 )) -j | jq '.data[0]'
            exit 0
        fi
    done

    zathura $1 -P $2 && echo "true" || echo "oops"
}

open() {
    file=$(echo $1 | sed -r 's/(.*)::[0-9]*$/\1/')
    p_no=$(echo $1 | sed -r 's/.*::([0-9]*)$/\1/')

    success=$(get_instances | files_pid | parse_open $file $p_no)

    if [[ $success == "true" ]]; then
        echo "Opened $file to page $p_no"
    else
        echo "Could not open link $1, it must have a page number following the file (eg. test.pdf::32). It must be within range."
    fi
}

open $1
