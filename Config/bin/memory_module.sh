#!/usr/bin/env bash

#==============================================================================
# Módulo de Memoria para Polybar
# Muestra RAM usada/disponible con icono dinámico
#==============================================================================

# Obtener memoria total y usada en MB
mem_total=$(free -m | awk '/^Mem:/ {print $2}')
mem_used=$(free -m | awk '/^Mem:/ {print $3}')
mem_available=$(free -m | awk '/^Mem:/ {print $7}')

# Calcular porcentaje de uso
mem_percent=$((mem_used * 100 / mem_total))

# Convertir a GB si es mayor a 1024 MB
if [ "$mem_used" -gt 1024 ]; then
    mem_used_display="$(awk "BEGIN {printf \"%.1f\", $mem_used/1024}")G"
else
    mem_used_display="${mem_used}M"
fi

if [ "$mem_available" -gt 1024 ]; then
    mem_avail_display="$(awk "BEGIN {printf \"%.1f\", $mem_available/1024}")G"
else
    mem_avail_display="${mem_available}M"
fi

# Icono y color según porcentaje de uso
if [ $mem_percent -lt 50 ]; then
    icon=""
    color="#8ccf7e"  # Verde
elif [ $mem_percent -lt 80 ]; then
    icon=""
    color="#e5c76b"  # Amarillo
else
    icon=""
    color="#e57474"  # Rojo
fi

# Output para polybar
echo "%{F$color}$icon%{F-} %{F#ffffff}${mem_used_display}%{F-}%{F#666666}/%{F-}%{F#b3b9b8}${mem_avail_display}%{F-}"
