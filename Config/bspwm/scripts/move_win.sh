#!/bin/bash

# move_win.sh
echo "$(date): Executed with arg $1" >> /tmp/move_debug.log

# Uso: move_win.sh {west,south,north,east}
# Comportamiento:
# 1. Intenta intercambiar (swap) con la ventana adyacente.
# 2. Si falla (no hay vecina), convierte la ventana a Flotante.
# 3. Mueve la ventana geométricamente.

DIR=$1
STEP=40

case "$DIR" in
    west)  X="-$STEP"; Y="0" ;;
    east)  X="$STEP";  Y="0" ;;
    north) X="0";   Y="-$STEP" ;;
    south) X="0";   Y="$STEP" ;;
esac

# 1. Intentar Swap (si es tiled y tiene vecino)
if bspc node -s "$DIR" > /dev/null 2>&1; then
    exit 0
fi

# 2. Si falló el Swap, verificar si es Tiled
if [ -z "$(bspc query -N -n focused.floating)" ]; then
    # Es Tiled y no pudo hacer swap -> Hacerla Flotante
    bspc node -t floating
    notify-send -u low -t 1000 "Auto-Float" "Ventana liberada para mover"
    
    # Hack: Pequeña pausa a veces necesaria, o forzar focus
    bspc node -f focused
fi

# 3. Mover geométricamente (ahora seguro es floating o falló swap)
bspc node -v "$X" "$Y"
