#!/bin/sh
# This shell script is PUBLIC DOMAIN. You may do whatever you want with it.

TOGGLE=.toggle

if [ ! -e $TOGGLE ]; then
    touch $TOGGLE
    swaysome focus-group 2
else
    rm $TOGGLE
    swaysome focus-group 1
fi
