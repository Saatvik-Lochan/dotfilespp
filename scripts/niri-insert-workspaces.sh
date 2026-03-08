#!/bin/bash
set -euo pipefail

case "${1:-}" in
    --up)   DIRECTION="up" ;;
    --down) DIRECTION="down" ;;
    *)
        echo "Usage: $(basename "$0") --up | --down" >&2
        exit 1
        ;;
esac

WORKSPACES=$(niri msg --json workspaces)
WINDOWS=$(niri msg --json windows)

# Get focused workspace info
FOCUSED_WS=$(echo "$WORKSPACES" | jq 'first(.[] | select(.is_focused))')
FOCUSED_WS_ID=$(echo "$FOCUSED_WS" | jq '.id')
FOCUSED_WS_IDX=$(echo "$FOCUSED_WS" | jq '.idx')
FOCUSED_OUTPUT=$(echo "$FOCUSED_WS" | jq -r '.output')

# Count windows on the focused workspace
WINDOW_COUNT=$(echo "$WINDOWS" | jq "[.[] | select(.workspace_id == $FOCUSED_WS_ID)] | length")

# Count total workspaces on the focused output
TOTAL=$(echo "$WORKSPACES" | jq "[.[] | select(.output == \"$FOCUSED_OUTPUT\")] | length")

if [ "$WINDOW_COUNT" -eq 1 ]; then
    # Only window on this workspace: bail out if already at the edge to avoid
    # moving onto the trailing empty workspace (causes visual glitch)
    if [ "$DIRECTION" = "down" ] && [ "$FOCUSED_WS_IDX" -ge $(( TOTAL - 1 )) ]; then
        exit 0
    fi
    if [ "$DIRECTION" = "up" ] && [ "$FOCUSED_WS_IDX" -le 1 ]; then
        exit 0
    fi
    niri msg action move-column-to-workspace-"$DIRECTION"
else
    # Multiple windows: insert a new workspace and move the column there
    if [ "$DIRECTION" = "down" ]; then
        MOVES=$(( TOTAL - FOCUSED_WS_IDX - 1 ))
    else
        MOVES=$(( TOTAL - FOCUSED_WS_IDX ))
    fi

    niri msg action move-column-to-workspace "$TOTAL"
    niri msg action focus-workspace "$TOTAL"

    for (( i = 0; i < MOVES; i++ )); do
        niri msg action move-workspace-up
    done
fi
