#!/usr/bin/env bash

#==============================================================================
# Módulo de Estado de Ethernet para Polybar
# Actualizado para usar 'ip' en lugar de 'ifconfig' (deprecated)
#==============================================================================

# Detectar interfaz activa (prioriza la que tiene IP y está UP)
ETH_INTERFACE=$(ip -4 -o addr show | awk '$2 ~ /^(eth|enp|ens|wlan|wl)/ {print $2; exit}')

# Si no hay ninguna con IP, buscar la primera que esté UP
if [ -z "$ETH_INTERFACE" ]; then
    ETH_INTERFACE=$(ip -o link show | grep "state UP" | awk -F': ' '$2 ~ /^(eth|enp|ens|wlan|wl)/ {print $2; exit}')
fi

# Fallback al primero disponible si nada de lo anterior funciona
if [ -z "$ETH_INTERFACE" ]; then
    ETH_INTERFACE=$(ip -o link show | awk -F': ' '$2 ~ /^(eth|enp|ens|wlan|wl)/ {print $2; exit}')
fi

if [ -n "$ETH_INTERFACE" ] && ip link show "$ETH_INTERFACE" | grep -q "state UP"; then
    IP=$(ip -4 addr show "$ETH_INTERFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ -n "$IP" ]; then
        echo "%{A1:echo -n $IP | xclip -selection clipboard & notify-send -t 2000 'IP Copiada' '$IP':}%{F#2498db} %{F#ffffff}$IP%{u-}%{A}"
    else
        echo "%{F#2498db} %{F#666666}No IP%{u-}"
    fi
else
    echo "%{F#2498db} %{F#666666}Disconnected%{u-}"
fi
