#!/usr/bin/env bash

# prompted starting with most recently added files in Downloads
file_to_move="$(ls -1t ~/Downloads | fzf)"
dest_dir="$1"

if [ -z "$dest_dir" ]; then
    dest_dir="."
fi

if [ -n "$file_to_move" ]; then

    if [ -n "$dest_dir" ]; then
        mv "$HOME/Downloads/$file_to_move" "$dest_dir/"
        echo "Moved '$file_to_move' to '$dest_dir/'"
    else
        echo "No destination directory selected. Operation cancelled."
    fi
else
    echo "No file selected. Operation cancelled."
fi
