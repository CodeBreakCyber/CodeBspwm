#!/usr/bin/env bash

#==============================================================================
# Módulo de Volumen para Polybar
# Muestra volumen actual con icono dinámico
#==============================================================================

# Obtener volumen actual
if command -v pactl &> /dev/null; then
    # PulseAudio
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
    muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -oP 'yes|no')
else
    # ALSA fallback
    volume=$(amixer get Master 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
    muted=$(amixer get Master 2>/dev/null | grep -oP '\[on\]|\[off\]' | head -1)
    [ "$muted" = "[off]" ] && muted="yes" || muted="no"
fi

# Valores por defecto si no se pudo obtener
[ -z "$volume" ] && volume=0
[ -z "$muted" ] && muted="no"

# Determinar icono y color
if [ "$muted" = "yes" ]; then
    icon=""
    color="#e57474"  # Rojo
elif [ "$volume" -eq 0 ]; then
    icon=""
    color="#666666"  # Gris
elif [ "$volume" -lt 33 ]; then
    icon=""
    color="#67b0e8"  # Azul
elif [ "$volume" -lt 66 ]; then
    icon=""
    color="#67b0e8"
else
    icon=""
    color="#67b0e8"
fi

# Output para polybar
if [ "$muted" = "yes" ]; then
    echo "%{F$color}$icon%{F-} %{F#666666}Muted%{F-}"
else
    echo "%{F$color}$icon%{F-} %{F#ffffff}${volume}%%{F-}"
fi
