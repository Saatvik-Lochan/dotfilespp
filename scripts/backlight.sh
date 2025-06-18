set_light() {
    echo $1 > $(readlink -f /sys/class/leds/tpacpi::kbd_backlight/brightness)
}

set_light $1
