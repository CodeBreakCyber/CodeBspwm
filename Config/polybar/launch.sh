#!/usr/bin/env bash
#==============================================================================
# KaliBspwm - Polybar Launch Script
# Descripción: Inicia las barras de polybar para BSPWM
#==============================================================================

# Terminar instancias existentes
killall -q polybar
killall -q dunst
killall -q xfce4-notifyd
killall -q notify-osd

# Esperar a que terminen
while pgrep -u "$(id -u)" -x polybar >/dev/null; do sleep 0.5; done

# Iniciar Dunst con configuración limpia
dunst -config "${HOME}/.config/dunst/dunstrc" &

# Directorio de configuración
CONFIG_DIR="${HOME}/.config/polybar"

#==============================================================================
# LANZAR BARRAS
#==============================================================================

# Barras izquierda (información del sistema)
polybar log -c "${CONFIG_DIR}/configs/current.ini" &
polybar secondary -c "${CONFIG_DIR}/configs/current.ini" &
polybar terciary -c "${CONFIG_DIR}/configs/current.ini" &
polybar quaternary -c "${CONFIG_DIR}/configs/current.ini" &
polybar quinary -c "${CONFIG_DIR}/configs/current.ini" &

# Barras derecha (sistema y menú)
polybar top -c "${CONFIG_DIR}/configs/current.ini" &
polybar power -c "${CONFIG_DIR}/configs/current.ini" &

# Barra central (workspaces)
polybar primary -c "${CONFIG_DIR}/configs/workspace.ini" &

echo "Polybar lanzado correctamente"
