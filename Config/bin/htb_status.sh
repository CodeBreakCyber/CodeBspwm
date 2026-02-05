#!/usr/bin/env bash

#==============================================================================
# Módulo de Estado de VPN (HTB) para Polybar
# Actualizado para usar 'ip' en lugar de 'ifconfig' (deprecated)
#==============================================================================

# Verificar si tun0 existe y está activa
if ip link show tun0 &>/dev/null && ip link show tun0 | grep -q "state UNKNOWN\|state UP"; then
    IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ -n "$IP" ]; then
        echo "%{A1:echo -n $IP | xclip -selection clipboard & notify-send -u low 'HTB VPN' 'IP Copiada: $IP':}%{F#9fef00} %{F#ffffff}$IP%{u-}%{A}"
    else
        echo "%{F#9fef00} %{F#666666}No IP%{u-}"
    fi
else
    echo "%{F#9fef00} %{F#666666}Disconnected%{u-}"
fi
