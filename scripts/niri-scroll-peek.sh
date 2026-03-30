#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") --left | --right" >&2
}

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required" >&2
    exit 1
fi

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

case "$1" in
    --left)
        direction="left"
        ;;
    --right)
        direction="right"
        ;;
    *)
        usage
        exit 1
        ;;
esac

focused_window_json=$(niri msg --json focused-window)
focused_id=$(jq -r '.id // empty' <<<"$focused_window_json")

if [[ -z "$focused_id" ]]; then
    exit 0
fi

niri msg action "focus-column-${direction}"
niri msg action focus-window --id "$focused_id"
