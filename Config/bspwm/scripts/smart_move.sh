#!/bin/bash
# Uso: smart_move.sh <direction>
# direction: west, south, north, east
DIR=$1

# Si es flotante, mover geométricamente
if bspc query -N -n focused.floating > /dev/null; then
    case "$DIR" in
        west)  bspc node -v -20 0 ;;
        south) bspc node -v 0 20 ;;
        north) bspc node -v 0 -20 ;;
        east)  bspc node -v 20 0 ;;
    esac
else
    # Si es tiled, intercambiar (swap)
    bspc node -s "$DIR"
fi
