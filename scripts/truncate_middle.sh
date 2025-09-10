#!/bin/bash

# Ripped straight from gpt, love it
# Usage: ./truncate_middle.sh "long_string" max_length
# Example: ./truncate_middle.sh "ThisIsAVeryLongStringToTruncate" 15

input="$1"
max_length="$2"

# If the string is short enough, just print it
if [ "${#input}" -le "$max_length" ]; then
    echo "$input"
    exit 0
fi

# Calculate lengths for start and end parts
# Subtract 3 for the "..."
half_length=$(( (max_length - 3) / 2 ))
start="${input:0:half_length}"
end_length=$(( max_length - 3 - half_length ))
end="${input: -$end_length}"

echo "${start}...${end}"
