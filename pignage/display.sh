#!/bin/bash

#Environment Vars
SLIDE_TIME=10
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACT_DIR="$BASE_DIR/act"

CONFIG="$BASE_DIR/pignage.conf"
[ -f "$CONFIG" ] && source "$CONFIG"


#Display Script
xset s off
xset -dpms
xset s noblank

exec feh -F -Y -D "$SLIDE_TIME" -R 60 "$ACT_DIR"
