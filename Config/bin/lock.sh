#!/bin/bash
# LOCKSCREEN V10 - "Spider Core"
# Sin texto de estado. Solo el anillo reaccionando alrededor del icono estampado.

IMAGE="$HOME/.cache/lock_wallpaper.png"
[ ! -f "$IMAGE" ] && IMAGE="$HOME/Pictures/Wallpapers/solo_leveling_1.jpg"

# =============================================================================
# COLORES (Standard Sci-Fi)
# =============================================================================
BST='#00000000'
WHITE='#ffffffff'
BLUE='#ff3333ff'      # Morales Red (Primary)
RED='#ff0000ff'       # Alert Red
GREEN='#00ffccff'     # Success Cyan
RING_IDLE='#ff333322' # Anillo rojo sutil en reposo

# =============================================================================
# CONFIGURACIÓN
# =============================================================================
FONT="Montserrat"

# POSICIONES
# El anillo debe rodear la araña de 280pt.
# Radius ~160 debería encajar visualmente.

i3lock \
--inside-color=$BST \
--ring-color=$RING_IDLE \
--line-color=$BST \
--separator-color=$BST \
\
--insidever-color=$BST \
--ringver-color=$GREEN \
\
--insidewrong-color=$BST \
--ringwrong-color=$RED \
\
--keyhl-color=$BLUE \
--bshl-color=$RED \
\
--verif-color=$GREEN \
--wrong-color=$RED \
--time-color=$WHITE \
--date-color=$WHITE \
--layout-color=$BST \
\
--screen 1 \
--clock \
--indicator \
--keylayout 1 \
\
--time-str="%H:%M" \
--time-font="$FONT:style=Bold" \
--time-size=120 \
--time-pos="w/2:200" \
\
--date-str="%A, %d" \
--date-font="$FONT:style=Light" \
--date-size=24 \
--date-pos="tx:ty+40" \
\
--ind-pos="w/2:h/2" \
\
--verif-text="" \
--wrong-text="" \
--noinput="" \
--lock-text="" \
--lockfailed="" \
\
--radius=160 \
--ring-width=12 \
\
--pass-media-keys \
--pass-screen-keys \
--pass-volume-keys \
-i "$IMAGE" --tiling
