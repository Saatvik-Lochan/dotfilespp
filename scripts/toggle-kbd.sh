#!/usr/bin/env bash

toggle_user_service() {
    local svc="$1"
    if systemctl --user is-active --quiet "$svc"; then
        notify-send "Stopping $svc"
        systemctl --user stop "$svc"
    else
        notify-send "Starting $svc"
        systemctl --user start "$svc"
    fi
}

toggle_user_service "kmonad"
